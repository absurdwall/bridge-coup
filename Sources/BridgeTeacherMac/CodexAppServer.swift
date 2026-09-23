import AppKit
import BridgeTeacherCore
import Foundation

struct CodexRuntimeInfo: Equatable {
    let executableURL: URL
    let version: String
}

enum CodexRuntimeSetupError: Error, LocalizedError {
    case runtimeNotFound
    case invalidVersion(String)
    case unsupportedVersion(found: String, minimum: String)
    case notSignedIn
    case loginCouldNotStart
    case transport(String)
    case request(String)
    case timedOut
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .runtimeNotFound:
            PlanRuntimeError.runtimeNotFound.localizedDescription
        case let .invalidVersion(value):
            "无法读取 Codex runtime 版本（\(value)）。请重新选择 codex 可执行文件。"
        case let .unsupportedVersion(found, minimum):
            PlanRuntimeError.unsupportedRuntime(found: found, minimum: minimum).localizedDescription
        case .notSignedIn:
            PlanRuntimeError.chatGPTSignInRequired.localizedDescription
        case .loginCouldNotStart:
            "Codex 没有返回可打开的 ChatGPT 登录链接，请重试。"
        case let .transport(message):
            "Codex runtime 无法启动或已退出：\(message)"
        case let .request(message):
            "Codex 请求失败：\(message)"
        case .timedOut:
            PlanRuntimeError.timedOut.localizedDescription
        case .emptyResponse:
            PlanRuntimeError.emptyResponse.localizedDescription
        }
    }
}

actor CodexTeachingService: DeclarerTeachingRuntime {
    static let minimumVersion = "0.156.1"

    private var runtimeInfo: CodexRuntimeInfo?
    private var client: CodexJSONRPCClient?
    private let appSupportURL: URL
    private let fileManager = FileManager.default

    init(appSupportURL: URL? = nil) {
        self.appSupportURL = appSupportURL ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Bridge Teacher", isDirectory: true)
    }

    func configure(executableURL: URL) async throws -> CodexRuntimeInfo {
        try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        let version = try Self.readVersion(executableURL: executableURL)
        guard let parsed = CodexVersion(versionText: version) else {
            throw CodexRuntimeSetupError.invalidVersion(version)
        }
        let minimum = CodexVersion(0, 156, 1)
        guard parsed >= minimum else {
            throw CodexRuntimeSetupError.unsupportedVersion(found: version, minimum: Self.minimumVersion)
        }

        client?.stop()
        let home = appSupportURL.appendingPathComponent("Codex Home", isDirectory: true)
        let workspace = appSupportURL.appendingPathComponent("Runtime Workspace", isDirectory: true)
        try fileManager.createDirectory(at: home, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: workspace, withIntermediateDirectories: true)

        var environment = ProcessInfo.processInfo.environment
        environment["CODEX_HOME"] = home.path
        environment["PATH"] = Self.applicationPath(environment: environment)

        let nextClient = CodexJSONRPCClient(
            executableURL: executableURL,
            currentDirectoryURL: workspace,
            environment: environment
        )
        do {
            try nextClient.start()
            _ = try await nextClient.request("initialize", params: [
                "clientInfo": [
                    "name": "bridge_teacher",
                    "title": "Bridge Teacher",
                    "version": "0.1.0",
                ],
            ])
            try nextClient.notify("initialized", params: [:])
        } catch {
            nextClient.stop()
            throw Self.map(error)
        }

        let info = CodexRuntimeInfo(executableURL: executableURL, version: version)
        runtimeInfo = info
        client = nextClient
        return info
    }

    func isChatGPTSignedIn() async throws -> Bool {
        let response = try await requireClient().request("account/read", params: [:])
        let account = response["account"] as? [String: Any]
        return account?["type"] as? String == "chatgpt"
    }

    func beginChatGPTLogin() async throws -> URL {
        let response: [String: Any]
        do {
            response = try await requireClient().request("account/login/start", params: ["type": "chatgpt"])
        } catch {
            throw Self.map(error)
        }
        guard response["type"] as? String == "chatgpt",
              let value = response["authUrl"] as? String,
              let url = URL(string: value) else {
            throw CodexRuntimeSetupError.loginCouldNotStart
        }
        return url
    }

    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        try await generateTemporaryReply(prompt: request.prompt)
    }

    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        try await generateTemporaryReply(prompt: request.prompt)
    }

    private func generateTemporaryReply(prompt: String) async throws -> DeclarerPlanResponse {
        let server = try requireClient()
        do {
            guard try await isChatGPTSignedIn() else {
                throw CodexRuntimeSetupError.notSignedIn
            }

            let notifications = server.notifications()
            let workspace = appSupportURL.appendingPathComponent("Runtime Workspace", isDirectory: true)
            let threadResponse = try await server.request("thread/start", params: [
                "cwd": workspace.path,
                "sandbox": "read-only",
                "approvalPolicy": "never",
                "ephemeral": true,
                "serviceName": "Bridge Teacher",
                "developerInstructions": "本线程只用于桥牌做庄教学。只依据用户消息明确提供的决策时信息回答。不得访问文件、执行命令、调用搜索、MCP 或其他工具；不得推断未知牌为已知牌。对标注为条件假设的内容，只能在该条件成立时进行条件讨论，不能将其写成已确认牌面或事实。",
            ])
            guard let thread = threadResponse["thread"] as? [String: Any],
                  let threadID = thread["id"] as? String else {
                throw CodexRuntimeSetupError.request("Codex 未返回新建会话 ID。")
            }
            let model = threadResponse["model"] as? String ?? thread["model"] as? String

            let turnResponse = try await server.request("turn/start", params: [
                "threadId": threadID,
                "input": [["type": "text", "text": prompt]],
            ])
            guard let startedTurn = turnResponse["turn"] as? [String: Any],
                  let turnID = startedTurn["id"] as? String else {
                throw CodexRuntimeSetupError.request("Codex 未返回生成任务 ID。")
            }

            let completion = try await Self.waitForCompletion(
                threadID: threadID,
                turnID: turnID,
                notifications: notifications
            )
            let turn = completion["turn"] as? [String: Any] ?? [:]
            guard turn["status"] as? String == "completed" else {
                let error = turn["error"] as? [String: Any]
                throw Self.mapTurnError(
                    error?["message"] as? String ?? "Codex 未能完成这次请求。",
                    code: error?["codexErrorInfo"] as? String
                )
            }

            var text = Self.agentText(from: turn)
            if text.isEmpty {
                let readResponse = try await server.request("thread/read", params: [
                    "threadId": threadID,
                    "includeTurns": true,
                ])
                let thread = readResponse["thread"] as? [String: Any]
                let turns = thread?["turns"] as? [[String: Any]] ?? []
                let completedTurn = turns.first(where: { $0["id"] as? String == turnID })
                text = Self.agentText(from: completedTurn ?? [:])
            }
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CodexRuntimeSetupError.emptyResponse
            }

            return DeclarerPlanResponse(text: text, model: model, runtimeVersion: runtimeInfo?.version)
        } catch {
            throw Self.map(error)
        }
    }

    private func requireClient() throws -> CodexJSONRPCClient {
        guard runtimeInfo != nil, let client else {
            throw CodexRuntimeSetupError.runtimeNotFound
        }
        return client
    }

    private static func waitForCompletion(
        threadID: String,
        turnID: String,
        notifications: AsyncStream<CodexServerNotification>
    ) async throws -> [String: Any] {
        try await withThrowingTaskGroup(of: [String: Any].self) { group in
            group.addTask {
                for await event in notifications {
                    guard event.method == "turn/completed",
                          event.params["threadId"] as? String == threadID,
                          let turn = event.params["turn"] as? [String: Any],
                          turn["id"] as? String == turnID else {
                        continue
                    }
                    return event.params
                }
                throw CodexRuntimeSetupError.transport("连接在 Codex 返回结果前结束。")
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 180_000_000_000)
                throw CodexRuntimeSetupError.timedOut
            }
            defer { group.cancelAll() }
            guard let completion = try await group.next() else {
                throw CodexRuntimeSetupError.transport("Codex 响应流已结束。")
            }
            return completion
        }
    }

    private static func agentText(from turn: [String: Any]) -> String {
        let items = turn["items"] as? [[String: Any]] ?? []
        return items.reversed().first(where: {
            $0["type"] as? String == "agentMessage"
                && !($0["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        })?["text"] as? String ?? ""
    }

    private static func readVersion(executableURL: URL) throws -> String {
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw CodexRuntimeSetupError.runtimeNotFound
        }
        let process = Process()
        let output = Pipe()
        let errors = Pipe()
        process.executableURL = executableURL
        process.arguments = ["--version"]
        process.environment = ["PATH": applicationPath(environment: ProcessInfo.processInfo.environment)]
        process.standardOutput = output
        process.standardError = errors
        do {
            try process.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw CodexRuntimeSetupError.transport("版本检查命令退出码 \(process.terminationStatus)。")
            }
            return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch let error as CodexRuntimeSetupError {
            throw error
        } catch {
            throw CodexRuntimeSetupError.transport(error.localizedDescription)
        }
    }

    private static func applicationPath(environment: [String: String]) -> String {
        var paths = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
        paths.append(contentsOf: ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"])
        let nodeVersions = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".nvm/versions/node", isDirectory: true)
        if let versions = try? FileManager.default.contentsOfDirectory(at: nodeVersions, includingPropertiesForKeys: nil) {
            paths.append(contentsOf: versions.map { $0.appendingPathComponent("bin").path })
        }
        return Array(NSOrderedSet(array: paths)).compactMap { $0 as? String }.joined(separator: ":")
    }

    private static func mapTurnError(_ message: String, code: String?) -> Error {
        if code == "usageLimitExceeded" || code == "rateLimitExceeded" || code == "serverOverloaded" {
            return PlanRuntimeError.usageLimited(message)
        }
        if code == "unauthorized" {
            return PlanRuntimeError.chatGPTSignInRequired
        }
        return mapMessage(message)
    }

    private static func mapMessage(_ message: String) -> Error {
        let lowered = message.lowercased()
        if ["usage", "quota", "rate limit", "capacity", "too many requests"].contains(where: lowered.contains) {
            return PlanRuntimeError.usageLimited(message)
        }
        if ["unauthorized", "authentication", "sign in", "login"].contains(where: lowered.contains) {
            return PlanRuntimeError.chatGPTSignInRequired
        }
        return PlanRuntimeError.requestFailed(message)
    }

    private static func map(_ error: Error) -> Error {
        if let setup = error as? CodexRuntimeSetupError { return setup }
        if let runtime = error as? PlanRuntimeError { return runtime }
        if let rpc = error as? CodexRPCError {
            return mapMessage(rpc.message)
        }
        if error is CodexTransportError {
            return PlanRuntimeError.temporarilyUnavailable
        }
        return PlanRuntimeError.requestFailed(error.localizedDescription)
    }
}

private struct CodexVersion: Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    let isPrerelease: Bool

    init(_ major: Int, _ minor: Int, _ patch: Int, isPrerelease: Bool = false) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.isPrerelease = isPrerelease
    }

    init?(versionText: String) {
        let pattern = #"(\d+)\.(\d+)\.(\d+)(-[A-Za-z0-9.-]+)?"#
        guard let range = versionText.range(of: pattern, options: .regularExpression) else { return nil }
        let value = String(versionText[range])
        let components = value.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let numbers = components[0].split(separator: ".").compactMap { Int($0) }
        guard numbers.count == 3 else { return nil }
        self.init(numbers[0], numbers[1], numbers[2], isPrerelease: components.count > 1)
    }

    static func < (lhs: CodexVersion, rhs: CodexVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        return lhs.isPrerelease && !rhs.isPrerelease
    }
}

private struct CodexServerNotification: @unchecked Sendable {
    let method: String
    let params: [String: Any]
}

private enum CodexTransportError: Error {
    case processExited(Int32)
    case notRunning
}

private struct CodexRPCError: Error {
    let code: Int
    let message: String
}

private final class CodexJSONRPCClient: @unchecked Sendable {
    private let executableURL: URL
    private let currentDirectoryURL: URL
    private let environment: [String: String]
    private let lock = NSLock()
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var outputBuffer = Data()
    private var nextID = 1
    private var pending: [Int: CheckedContinuation<[String: Any], Error>] = [:]
    private var notificationContinuations: [UUID: AsyncStream<CodexServerNotification>.Continuation] = [:]

    init(executableURL: URL, currentDirectoryURL: URL, environment: [String: String]) {
        self.executableURL = executableURL
        self.currentDirectoryURL = currentDirectoryURL
        self.environment = environment
    }

    func start() throws {
        lock.lock()
        if process?.isRunning == true {
            lock.unlock()
            return
        }

        let child = Process()
        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()
        child.executableURL = executableURL
        child.arguments = ["app-server", "--listen", "stdio://"]
        child.environment = environment
        child.currentDirectoryURL = currentDirectoryURL
        child.standardInput = input
        child.standardOutput = output
        child.standardError = errors
        process = child
        inputPipe = input
        outputPipe = output
        errorPipe = errors
        lock.unlock()

        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            self?.consume(data)
        }
        errors.fileHandleForReading.readabilityHandler = { handle in
            _ = handle.availableData
        }
        child.terminationHandler = { [weak self] terminated in
            self?.failPending(CodexTransportError.processExited(terminated.terminationStatus))
        }
        do {
            try child.run()
        } catch {
            stop()
            throw CodexTransportError.notRunning
        }
    }

    func request(_ method: String, params: [String: Any]) async throws -> [String: Any] {
        try start()
        let id = allocateID()
        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            guard process?.isRunning == true else {
                lock.unlock()
                continuation.resume(throwing: CodexTransportError.notRunning)
                return
            }
            pending[id] = continuation
            lock.unlock()

            do {
                try send(["id": id, "method": method, "params": params])
            } catch {
                let waiter = removePending(id)
                waiter?.resume(throwing: error)
            }
        }
    }

    func notify(_ method: String, params: [String: Any]) throws {
        try send(["method": method, "params": params])
    }

    func notifications() -> AsyncStream<CodexServerNotification> {
        let streamID = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(250)) { continuation in
            lock.lock()
            notificationContinuations[streamID] = continuation
            lock.unlock()
            continuation.onTermination = { [weak self] _ in
                self?.removeNotificationStream(streamID)
            }
        }
    }

    func stop() {
        lock.lock()
        let child = process
        process = nil
        let output = outputPipe
        let errors = errorPipe
        outputPipe = nil
        inputPipe = nil
        errorPipe = nil
        lock.unlock()
        output?.fileHandleForReading.readabilityHandler = nil
        errors?.fileHandleForReading.readabilityHandler = nil
        if let child, child.isRunning { child.terminate() }
        failPending(CodexTransportError.notRunning)
    }

    private func allocateID() -> Int {
        lock.lock()
        defer { lock.unlock() }
        defer { nextID += 1 }
        return nextID
    }

    private func send(_ message: [String: Any]) throws {
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: message, options: [.fragmentsAllowed])
        } catch {
            throw CodexTransportError.notRunning
        }

        lock.lock()
        defer { lock.unlock() }
        guard process?.isRunning == true, let inputPipe else {
            throw CodexTransportError.notRunning
        }
        var line = data
        line.append(0x0A)
        do {
            try inputPipe.fileHandleForWriting.write(contentsOf: line)
        } catch {
            throw CodexTransportError.notRunning
        }
    }

    private func consume(_ data: Data) {
        lock.lock()
        outputBuffer.append(data)
        var lines: [Data] = []
        while let range = outputBuffer.range(of: Data([0x0A])) {
            lines.append(outputBuffer.subdata(in: outputBuffer.startIndex..<range.lowerBound))
            outputBuffer.removeSubrange(outputBuffer.startIndex..<range.upperBound)
        }
        lock.unlock()
        for line in lines where !line.isEmpty {
            receive(line)
        }
    }

    private func receive(_ line: Data) {
        guard let message = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] else { return }

        if let rawID = message["id"] as? NSNumber, let method = message["method"] as? String {
            let id = rawID.intValue
            try? send(["id": id, "error": ["code": -32601, "message": "Client request is not supported."]])
            _ = method
            return
        }

        if let rawID = message["id"] as? NSNumber {
            let id = rawID.intValue
            let continuation = removePending(id)
            guard let continuation else { return }
            if let failure = message["error"] as? [String: Any] {
                continuation.resume(throwing: CodexRPCError(
                    code: (failure["code"] as? NSNumber)?.intValue ?? -1,
                    message: failure["message"] as? String ?? "Unknown Codex error"
                ))
            } else {
                continuation.resume(returning: message["result"] as? [String: Any] ?? [:])
            }
            return
        }

        guard let method = message["method"] as? String,
              let params = message["params"] as? [String: Any] else { return }
        lock.lock()
        let continuations = Array(notificationContinuations.values)
        lock.unlock()
        let event = CodexServerNotification(method: method, params: params)
        continuations.forEach { $0.yield(event) }
    }

    private func removePending(_ id: Int) -> CheckedContinuation<[String: Any], Error>? {
        lock.lock()
        defer { lock.unlock() }
        return pending.removeValue(forKey: id)
    }

    private func failPending(_ error: Error) {
        lock.lock()
        let waiters = Array(pending.values)
        pending.removeAll()
        let streams = Array(notificationContinuations.values)
        notificationContinuations.removeAll()
        lock.unlock()
        waiters.forEach { $0.resume(throwing: error) }
        streams.forEach { $0.finish() }
    }

    private func removeNotificationStream(_ id: UUID) {
        lock.lock()
        notificationContinuations.removeValue(forKey: id)
        lock.unlock()
    }
}
