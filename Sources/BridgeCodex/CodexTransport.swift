import Foundation
import Darwin
import BridgeExpert

public enum CodexPlayingError: Error, CustomStringConvertible {
    case failure(String)
    public var description: String { switch self { case let .failure(message): message } }
}

/// Stdio app-server adapter. An isolated home/cwd contains authentication only, never bridge fixtures.
public final class CodexPlayingTransport: PlayingTransport, @unchecked Sendable {
    public let evidenceDirectory: URL
    public let runtimeDirectory: URL
    private let executable: URL
    private let timeout: Double
    private let queue = DispatchQueue(label: "bridge.playing.codex")
    private var process: Process?
    private var ownedProcessGroup: pid_t?
    private var requestDeadline: DispatchTime?
    private var input: FileHandle?
    private var output: FileHandle?
    private var buffer = Data()
    private var nextID = 1
    private var threadID: String?
    private var runtimeVersion = ""
    private var observedModel: String?
    private static let model = "gpt-6-luna"
    private static let effort = "medium"

    public init(executable: URL, authenticationFile: URL, evidenceDirectory: URL, timeoutSeconds: Double = 180) throws {
        guard timeoutSeconds > 0 && timeoutSeconds.isFinite else { throw CodexPlayingError.failure("Invalid timeout") }
        self.executable = executable; self.evidenceDirectory = evidenceDirectory; timeout = timeoutSeconds
        let fm = FileManager.default
        try fm.createDirectory(at: evidenceDirectory, withIntermediateDirectories: true)
        runtimeDirectory = fm.temporaryDirectory.appendingPathComponent("bridge-playing-\(UUID().uuidString)")
        try fm.createDirectory(at: runtimeDirectory.appendingPathComponent("home"), withIntermediateDirectories: true)
        try fm.createDirectory(at: runtimeDirectory.appendingPathComponent("cwd"), withIntermediateDirectories: true)
        let auth = runtimeDirectory.appendingPathComponent("home/auth.json")
        try fm.copyItem(at: authenticationFile, to: auth)
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: auth.path)
        let systemSkills = ["imagegen", "openai-docs", "skill-creator", "skill-installer"].map {
            "\n[[skills.config]]\npath = \"\(runtimeDirectory.appendingPathComponent("home/skills/.system/" + $0 + "/SKILL.md").resolvingSymlinksInPath().path)\"\nenabled = false\n"
        }.joined()
        let configuration = Self.configuration + systemSkills
        try configuration.write(to: runtimeDirectory.appendingPathComponent("home/config.toml"), atomically: true, encoding: .utf8)
        try configuration.write(to: evidenceDirectory.appendingPathComponent("runtime-config.toml"), atomically: true, encoding: .utf8)
    }

    deinit {
        terminateRuntime(force: true)
        try? FileManager.default.removeItem(at: runtimeDirectory)
    }

    public func respond(to request: PlayingRequest) async throws -> PlayingReply {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do { continuation.resume(returning: try self.perform(request)) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func perform(_ request: PlayingRequest) throws -> PlayingReply {
        let alarm = DispatchWorkItem { [weak self] in self?.terminateRuntime(force: false) }
        let hardStop = DispatchWorkItem { [weak self] in self?.terminateRuntime(force: true) }
        let deadline = min(timeout, request.timeoutSeconds)
        requestDeadline = .now() + deadline
        var succeeded = false
        DispatchQueue.global().asyncAfter(deadline: .now() + deadline, execute: alarm)
        DispatchQueue.global().asyncAfter(deadline: .now() + deadline + 0.2, execute: hardStop)
        defer {
            alarm.cancel(); hardStop.cancel(); requestDeadline = nil
            if !succeeded { terminateRuntime(force: true) }
        }
        if process == nil { try start() }
        if threadID == nil {
            let result = try rpc("thread/start", ["cwd": runtimeDirectory.appendingPathComponent("cwd").path,
                "sandbox": "read-only", "approvalPolicy": "never", "ephemeral": true,
                "model": Self.model, "baseInstructions": request.instructions,
                "developerInstructions": "", "serviceName": "bridge-declarer"])
            guard let thread = result["thread"] as? [String: Any], let id = thread["id"] as? String else {
                throw CodexPlayingError.failure("Missing thread identity")
            }
            threadID = id
            observedModel = result["model"] as? String ?? thread["model"] as? String
            if let observedModel, observedModel != Self.model { throw CodexPlayingError.failure("Runtime model mismatch: \(observedModel)") }
        }
        let result = try rpc("turn/start", ["threadId": threadID!, "model": Self.model, "effort": Self.effort,
            "input": [["type": "text", "text": request.input, "text_elements": []]],
            "outputSchema": try JSONSerialization.jsonObject(with: Data(request.outputSchema.utf8))], outputSchema: request.outputSchema)
        guard let turn = result["turn"] as? [String: Any], let turnID = turn["id"] as? String else {
            throw CodexPlayingError.failure("Missing turn identity")
        }
        while true {
            let message = try read()
            if message["id"] != nil && message["method"] != nil {
                try send(["id": message["id"]!, "error": ["code": -32601, "message": "This playing client does not service tool or approval requests."]])
                throw CodexPlayingError.failure("Unexpected runtime tool or approval request")
            }
            guard message["method"] as? String == "turn/completed",
                  let params = message["params"] as? [String: Any], params["threadId"] as? String == threadID,
                  let completed = params["turn"] as? [String: Any], completed["id"] as? String == turnID else { continue }
            var publicCompletion = completed
            publicCompletion["items"] = (completed["items"] as? [[String: Any]] ?? []).filter { $0["type"] as? String == "agentMessage" }
            try log("completion", publicCompletion)
            guard completed["status"] as? String == "completed" else {
                throw CodexPlayingError.failure("Unsuccessful turn: \(completed["error"] ?? "unknown")")
            }
            let items = completed["items"] as? [[String: Any]] ?? []
            guard let text = items.last(where: { $0["type"] as? String == "agentMessage" })?["text"] as? String else {
                throw CodexPlayingError.failure("Missing public model output")
            }
            let identity = RuntimeIdentity(requestedModel: Self.model, requestedEffort: Self.effort, runtimeVersion: runtimeVersion,
                                           observedModel: observedModel, threadID: threadID!, turnID: turnID)
            succeeded = true
            return PlayingReply(rawOutput: text, identity: identity)
        }
    }

    private var isolatedEnvironment: [String: String] {
        ["HOME": runtimeDirectory.path,
         "CODEX_HOME": runtimeDirectory.appendingPathComponent("home").path,
         "PATH": executable.deletingLastPathComponent().path + ":/usr/bin:/bin:/usr/sbin:/sbin"]
    }

    /// Uses the installed runtime's bundled metadata, without refreshing from a service.
    /// Unsupported catalog formats fail before thread creation; there is no tool-enabled fallback.
    private func prepareModelCatalog() throws {
        let source = evidenceDirectory.appendingPathComponent("runtime-bundled-catalog.json")
        _ = FileManager.default.createFile(atPath: source.path, contents: nil)
        let saved = try FileHandle(forWritingTo: source)
        let command = Process()
        command.executableURL = executable; command.arguments = ["debug", "models", "--bundled"]
        command.environment = isolatedEnvironment
        command.currentDirectoryURL = runtimeDirectory.appendingPathComponent("cwd")
        command.standardInput = FileHandle.nullDevice
        command.standardOutput = saved; command.standardError = FileHandle.nullDevice
        process = command; ownedProcessGroup = nil
        try command.run(); trackProcessGroup(command); command.waitUntilExit()
        try saved.close()
        guard command.terminationStatus == 0,
              let deadline = requestDeadline, DispatchTime.now() < deadline else {
            throw CodexPlayingError.failure("Bundled runtime model catalog unavailable or timed out")
        }
        guard var catalog = try JSONSerialization.jsonObject(with: Data(contentsOf: source)) as? [String: Any],
              var models = catalog["models"] as? [[String: Any]],
              models.filter({ $0["slug"] as? String == Self.model }).count == 1,
              let index = models.firstIndex(where: { $0["slug"] as? String == Self.model }),
              ["tool_mode", "experimental_supported_tools", "apply_patch_tool_type", "shell_type"].allSatisfy({ models[index].keys.contains($0) }) else {
            throw CodexPlayingError.failure("Installed runtime cannot provide the required no-tools model catalog")
        }
        models[index]["tool_mode"] = "direct"
        models[index]["experimental_supported_tools"] = [String]()
        models[index]["apply_patch_tool_type"] = NSNull()
        models[index]["shell_type"] = "disabled"
        catalog["models"] = models
        let data = try JSONSerialization.data(withJSONObject: catalog, options: [.sortedKeys])
        let effective = runtimeDirectory.appendingPathComponent("home/model-catalog.json")
        try data.write(to: effective)
        try data.write(to: evidenceDirectory.appendingPathComponent("runtime-model-catalog.json"))
        let encoder = JSONEncoder(); encoder.outputFormatting = [.withoutEscapingSlashes]
        let pathLiteral = String(decoding: try encoder.encode(effective.path), as: UTF8.self)
        let configURL = runtimeDirectory.appendingPathComponent("home/config.toml")
        let configuration = "model_catalog_json = " + pathLiteral + "\n" + (try String(contentsOf: configURL, encoding: .utf8))
        try configuration.write(to: configURL, atomically: true, encoding: .utf8)
        try configuration.write(to: evidenceDirectory.appendingPathComponent("runtime-config.toml"), atomically: true, encoding: .utf8)
    }

    private func start() throws {
        let versionProcess = Process(); let versionPipe = Pipe()
        versionProcess.executableURL = executable; versionProcess.arguments = ["--version"]
        versionProcess.standardOutput = versionPipe; versionProcess.standardError = FileHandle.nullDevice
        process = versionProcess
        ownedProcessGroup = nil
        try versionProcess.run(); trackProcessGroup(versionProcess); versionProcess.waitUntilExit()
        guard versionProcess.terminationStatus == 0 else { throw CodexPlayingError.failure("Runtime version unavailable") }
        runtimeVersion = String(decoding: versionPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        try prepareModelCatalog()
        let child = Process(); let stdin = Pipe(); let stdout = Pipe()
        child.executableURL = executable; child.arguments = ["app-server", "--listen", "stdio://"]
        // Deliberately pass no inherited Codex features, project paths, tool hosts, or API credentials.
        child.environment = isolatedEnvironment
        child.currentDirectoryURL = runtimeDirectory.appendingPathComponent("cwd")
        child.standardInput = stdin; child.standardOutput = stdout
        child.standardError = FileHandle.nullDevice
        process = child; input = stdin.fileHandleForWriting; output = stdout.fileHandleForReading
        ownedProcessGroup = nil
        try child.run(); trackProcessGroup(child)
        _ = try rpc("initialize", ["clientInfo": ["name": "bridge-declarer", "version": "1"], "capabilities": ["experimentalApi": true]])
        try send(["method": "initialized", "params": [:]])
        let models = try rpc("model/list", ["includeHidden": true])
        guard let entries = models["data"] as? [[String: Any]],
              let model = entries.first(where: { $0["model"] as? String == Self.model }),
              let efforts = model["supportedReasoningEfforts"] as? [[String: Any]],
              efforts.contains(where: { $0["reasoningEffort"] as? String == Self.effort }) else {
            throw CodexPlayingError.failure("Requested gpt-6-luna / medium configuration unavailable")
        }
        try log("catalogAcknowledgement", model)
    }

    private func trackProcessGroup(_ child: Process) {
        let pid = child.processIdentifier
        // Foundation normally creates a new group. Verify ownership before group signals.
        ownedProcessGroup = getpgid(pid) == pid ? pid : nil
    }

    private func terminateRuntime(force: Bool) {
        let signal = force ? SIGKILL : SIGTERM
        if let group = ownedProcessGroup { kill(-group, signal) }
        else if let process, process.isRunning { kill(process.processIdentifier, signal) }
    }

    private func rpc(_ method: String, _ params: [String: Any], outputSchema: String? = nil) throws -> [String: Any] {
        let id = nextID; nextID += 1
        try send(["id": id, "method": method, "params": params], outputSchema: outputSchema)
        while true {
            let message = try read()
            guard (message["id"] as? NSNumber)?.intValue == id else { continue }
            if let error = message["error"] { throw CodexPlayingError.failure("\(method): \(error)") }
            guard let result = message["result"] as? [String: Any] else { throw CodexPlayingError.failure("Malformed \(method) response") }
            if method != "model/list" { try log("response", ["method": method, "result": result]) }
            return result
        }
    }

    private func send(_ message: [String: Any], outputSchema: String? = nil) throws {
        var data: Data
        if let outputSchema, let params = message["params"] as? [String: Any] {
            // The schema was parsed when constructing params. Embed that validated JSON verbatim;
            // recursively sorting it would change the model's structured generation order.
            func json(_ value: Any) throws -> String {
                String(decoding: try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .sortedKeys]), as: UTF8.self)
            }
            let parameterMembers = try params.keys.sorted().map { key in
                let value = key == "outputSchema" ? outputSchema : try json(params[key]!)
                return try json(key) + ":" + value
            }.joined(separator: ",")
            let members = try message.keys.sorted().map { key in
                let value = key == "params" ? "{" + parameterMembers + "}" : try json(message[key]!)
                return try json(key) + ":" + value
            }.joined(separator: ",")
            data = Data(("{" + members + "}").utf8)
        } else {
            data = try JSONSerialization.data(withJSONObject: message, options: [.sortedKeys])
        }
        try log("request", message, encodedValue: data)
        data.append(10)
        try input?.write(contentsOf: data)
    }

    private func read() throws -> [String: Any] {
        while true {
            if let end = buffer.firstIndex(of: 10) {
                let line = buffer.prefix(upTo: end); buffer.removeSubrange(...end)
                if let object = try JSONSerialization.jsonObject(with: line) as? [String: Any] { return object }
                throw CodexPlayingError.failure("Malformed app-server message")
            }
            guard let output, let deadline = requestDeadline else { throw CodexPlayingError.failure("Missing runtime output or request deadline") }
            let now = DispatchTime.now().uptimeNanoseconds
            guard now < deadline.uptimeNanoseconds else { throw CodexPlayingError.failure("App-server request timed out") }
            let milliseconds = Int32(min(UInt64(Int32.max), max(1, (deadline.uptimeNanoseconds - now) / 1_000_000)))
            var descriptor = pollfd(fd: output.fileDescriptor, events: Int16(POLLIN), revents: 0)
            let ready = poll(&descriptor, 1, milliseconds)
            if ready < 0 && errno == EINTR { continue }
            guard ready > 0 else { throw CodexPlayingError.failure("App-server request timed out or output unavailable") }
            let data = output.availableData
            guard !data.isEmpty else { throw CodexPlayingError.failure("App-server exited or request timed out") }
            buffer.append(data)
        }
    }

    private func log(_ kind: String, _ value: [String: Any], encodedValue: Data? = nil) throws {
        let url = evidenceDirectory.appendingPathComponent("rpc.jsonl")
        if !FileManager.default.fileExists(atPath: url.path) { _ = FileManager.default.createFile(atPath: url.path, contents: nil) }
        let handle = try FileHandle(forWritingTo: url); defer { try? handle.close() }
        try handle.seekToEnd()
        var data: Data
        if let encodedValue {
            data = Data("{\"kind\":\"request\",\"value\":".utf8)
            data.append(encodedValue); data.append(Data("}".utf8))
        } else {
            data = try JSONSerialization.data(withJSONObject: ["kind": kind, "value": value], options: [.sortedKeys])
        }
        data.append(10)
        try handle.write(contentsOf: data)
    }

    public static let configuration = """
    model = "gpt-6-luna"
    model_reasoning_effort = "medium"
    approval_policy = "never"
    sandbox_mode = "read-only"
    web_search = "disabled"
    include_permissions_instructions = false
    include_apps_instructions = false
    include_collaboration_mode_instructions = false
    include_environment_context = false
    project_doc_max_bytes = 0
    cli_auth_credentials_store = "file"
    [features]
    code_mode_host = false
    shell_tool = false
    unified_exec = false
    shell_snapshot = false
    view_image = false
    image_generation = false
    browser_use = false
    computer_use = false
    in_app_browser = false
    apps = false
    plugins = false
    remote_plugin = false
    multi_agent = false
    multi_agent_v2 = false
    memories = false
    chronicle = false
    hooks = false
    skill_search = false
    skip_host_skill_discovery = true
    tool_suggest = false
    sleep_tool = false
    goals = false
    worktrees = false
    workspace_dependencies = false
    current_time_reminder = false
    [tools.experimental_request_user_input]
    enabled = false
    [agents]
    enabled = false
    [orchestrator.skills]
    enabled = false
    [orchestrator.mcp]
    enabled = false
    """
}
