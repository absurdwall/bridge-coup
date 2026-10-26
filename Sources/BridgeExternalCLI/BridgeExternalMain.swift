import Foundation
import Darwin
import BridgeDomain
import BridgeExpert
import BridgeCodex
import BridgeDriver
import BridgeKnowledge

private struct Command: Decodable {
    let op: String
    let configuration: ExternalBoardConfiguration?
    let continuousConfiguration: ContinuousBoardConfiguration?
    let callEvent: AuctionEvent?
    let contract: Contract?
    let hand: Hand?
    let checkpointPath: String?
    let event: PlayEvent?
    let authorization: UUID?
    let automatic: Bool?
    let candidates: [AuctionCall]?
    let reason: String?
    let explanationRequestID: UUID?
    let snapshotID: String?
    let explanationResults: [ExplanationResult]?
    let explanationContext: ExplanationContext?
    let candidate: AuctionCall?
    let limit: Int?
}

/// One JSON command/response per line; stdin owns the continuous Expert conversation.
@main struct BridgeExternalMain {
    static let encoder: JSONEncoder = {
        let value = JSONEncoder(); value.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]; return value
    }()
    static func main() async {
        do { try await run() }
        catch { emit(["ok": false, "error": String(describing: error)]); exit(1) }
    }

    static func run() async throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.count % 2 == 0 else { throw CLIError.usage }
        var options: [String: String] = [:]
        for index in stride(from: 0, to: arguments.count, by: 2) { options[arguments[index]] = arguments[index + 1] }
        guard Set(options.keys).isSubset(of: ["--output", "--codex", "--auth", "--observations"]),
              let outputPath = options["--output"], let codexPath = options["--codex"] else { throw CLIError.usage }
        let output = URL(fileURLWithPath: outputPath, isDirectory: true)
        let fm = FileManager.default
        if fm.fileExists(atPath: output.path), try !fm.contentsOfDirectory(atPath: output.path).isEmpty {
            throw CLIError.outputMustBeEmpty
        }
        try fm.createDirectory(at: output, withIntermediateDirectories: true)
        let authHome = ProcessInfo.processInfo.environment["CODEX_HOME"] ?? fm.homeDirectoryForCurrentUser.appendingPathComponent(".codex").path
        let auth = URL(fileURLWithPath: options["--auth"] ?? URL(fileURLWithPath: authHome).appendingPathComponent("auth.json").path)
        let storeURL = options["--observations"].map { URL(fileURLWithPath: $0) } ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/BridgeCoup/explanation-observations.sqlite")
        let explanationStore = try ExplanationStore(url: storeURL)
        var session: ExternalBoardSession?
        var continuousMode = false
        emit(["ok": true, "state": "ready", "protocol": "bridge-external-v3", "supportedProtocols": ["bridge-external-v1", "bridge-external-v2", "bridge-external-v3"], "observationStore": storeURL.path])
        while let line = readLine() {
            do {
                let command = try JSONDecoder().decode(Command.self, from: Data(line.utf8))
                if command.op == "lookupExplanations" {
                    guard let context = command.explanationContext, let candidate = command.candidate else { throw CLIError.invalidCommand }
                    try emitValue(await explanationStore.lookup(context: context, candidate: candidate, limit: command.limit ?? 5), kind: "explanationLookup")
                    continue
                }
                if ["start", "resume"].contains(command.op), let configuration = command.continuousConfiguration {
                    guard session == nil else { throw CLIError.invalidCommand }
                    let player = try CodexPlayingTransport(executable: URL(fileURLWithPath: codexPath), authenticationFile: auth, evidenceDirectory: output.appendingPathComponent("player"))
                    let reviewer = CodexReviewTransport(executable: URL(fileURLWithPath: codexPath), authenticationFile: auth, evidenceDirectory: output.appendingPathComponent("reviewer"))
                    if command.op == "resume" {
                        guard let path = command.checkpointPath else { throw CLIError.invalidCommand }
                        let checkpoint = try JSONDecoder().decode(ContinuousExternalCheckpoint.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
                        session = try await ExternalBoardSession.resume(checkpoint, reconciled: configuration, transport: player, reviewer: reviewer, explanationStore: explanationStore)
                    } else { session = try ExternalBoardSession(continuous: configuration, transport: player, reviewer: reviewer, explanationStore: explanationStore) }
                    continuousMode = true
                    try save(await session!.continuousCheckpoint(), to: output.appendingPathComponent("continuation.json"))
                    try emitValue(await session!.continuousStatus(), kind: "status")
                    continue
                }
                if continuousMode, let session {
                    let shouldStop = try await continuous(command, session: session, output: output)
                    if shouldStop { return }
                    continue
                }
                switch command.op {
                case "start", "resume":
                    guard session == nil, let configuration = command.configuration else { throw CLIError.invalidCommand }
                    let player = try CodexPlayingTransport(executable: URL(fileURLWithPath: codexPath), authenticationFile: auth,
                        evidenceDirectory: output.appendingPathComponent("player"))
                    let reviewer = CodexReviewTransport(executable: URL(fileURLWithPath: codexPath), authenticationFile: auth,
                        evidenceDirectory: output.appendingPathComponent("reviewer"))
                    if command.op == "resume" {
                        guard let path = command.checkpointPath else { throw CLIError.invalidCommand }
                        let checkpoint = try JSONDecoder().decode(ExternalBoardCheckpoint.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
                        session = try await ExternalBoardSession.resume(checkpoint, reconciled: configuration, transport: player, reviewer: reviewer)
                    } else {
                        session = try ExternalBoardSession(configuration: configuration, transport: player, reviewer: reviewer)
                    }
                    try await persist(session!, output: output)
                    try emitValue(await session!.status(), kind: "status")
                case "status", "checkpoint":
                    guard let session else { throw CLIError.notStarted }
                    try await persist(session, output: output)
                    try emitValue(await session.status(), kind: "status")
                case "decide":
                    guard let session else { throw CLIError.notStarted }
                    // Crash/failure during review cannot leave a resumable authorization or reset its budget.
                    var unsafe = try await session.checkpoint(); unsafe.safeToResume = false
                    try save(unsafe, to: output.appendingPathComponent("continuation.json"))
                    let advice = try await session.decide()
                    if let decision = advice.decision {
                        try save(decision, to: output.appendingPathComponent("decision-\(decision.snapshot.revision).json"))
                    }
                    try await persist(session, output: output)
                    var value: [String: Any] = ["source": advice.source.rawValue,
                        "action": try JSONSerialization.jsonObject(with: encoder.encode(advice.action)),
                        "authorization": advice.authorization?.uuidString as Any? ?? NSNull()]
                    if let decision = advice.decision {
                        value["publicReason"] = decision.advice.publicReason
                        value["effectivePlan"] = decision.effectivePlan as Any? ?? NSNull()
                        value["plan"] = try JSONSerialization.jsonObject(with: encoder.encode(decision.advice.plan))
                        value["reviewVerdict"] = decision.review?.result.verdict.rawValue
                        value["executionDisposition"] = decision.executionDisposition?.rawValue
                        value["elapsedSeconds"] = decision.elapsedSeconds
                        value["decisionPath"] = output.appendingPathComponent("decision-\(decision.snapshot.revision).json").path
                    }
                    emit(["ok": true, "kind": "advice", "value": value])
                case "observe":
                    guard let session, let event = command.event else { throw CLIError.invalidCommand }
                    let execution = try await session.observe(event, authorization: command.authorization, automatic: command.automatic ?? false)
                    try await persist(session, output: output)
                    try emitValue(execution, kind: "observed")
                case "stop":
                    if let session { try await persist(session, output: output) }
                    emit(["ok": true, "state": "stopped"]); return
                default: throw CLIError.invalidCommand
                }
            } catch {
                if let session {
                    if continuousMode { try? save(await session.continuousCheckpoint(), to: output.appendingPathComponent("continuation.json")) }
                    else { try? await persist(session, output: output) }
                    try? save(await session.requestEvidence(), to: output.appendingPathComponent("request-evidence.json"))
                }
                if let failure = error as? ExpertFailure {
                    emit(["ok": false, "error": failure.detail, "category": failure.category.rawValue,
                          "elapsedSeconds": failure.elapsedSeconds, "stopped": true])
                } else { emit(["ok": false, "error": String(describing: error)]) }
            }
        }
    }

    private static func continuous(_ command: Command, session: ExternalBoardSession, output: URL) async throws -> Bool {
        switch command.op {
        case "status", "checkpoint": try emitValue(await session.continuousStatus(), kind: "status")
        case "decide":
            var checkpoint = try await session.continuousCheckpoint(); checkpoint.safeToResume = false
            try save(checkpoint, to: output.appendingPathComponent("continuation.json"))
            do {
                let advice = try await session.decideContinuous()
                if let decision = advice.decision {
                    try save(decision, to: output.appendingPathComponent("decision-\(decision.snapshot.revision).json"))
                    try save(decision, to: output.appendingPathComponent("decision-\(decision.snapshot.revision)-\(advice.authorization.uuidString).json"))
                }
                try emitValue(advice, kind: "advice")
            } catch let needed as ExplanationRequestNeeded {
                try save(needed.request, to: output.appendingPathComponent("explanation-request-\(needed.request.id.uuidString).json"))
                try emitValue(needed.request, kind: "informationRequest")
            }
        case "inspectCalls":
            var checkpoint = try await session.continuousCheckpoint(); checkpoint.safeToResume = false
            try save(checkpoint, to: output.appendingPathComponent("continuation.json"))
            guard let candidates = command.candidates, let reason = command.reason else { throw CLIError.invalidCommand }
            let request = try await session.inspectCalls(candidates: candidates, reason: reason)
            try save(request, to: output.appendingPathComponent("explanation-request-\(request.id.uuidString).json"))
            try emitValue(request, kind: "informationRequest")
        case "provideExplanations":
            guard let id = command.explanationRequestID, let snapshot = command.snapshotID, let results = command.explanationResults else { throw CLIError.invalidCommand }
            try await session.provideExplanations(requestID: id, snapshotID: snapshot, results: results)
            try save(results, to: output.appendingPathComponent("explanation-return-\(id.uuidString).json"))
            try emitValue(await session.continuousStatus(), kind: "status")
        case "observeCall":
            guard let event = command.callEvent else { throw CLIError.invalidCommand }
            try emitValue(await session.observeCall(event, authorization: command.authorization), kind: "observed")
        case "observe":
            guard let event = command.event else { throw CLIError.invalidCommand }
            try emitValue(await session.observeContinuousPlay(event, authorization: command.authorization, automatic: command.automatic ?? false), kind: "observed")
        case "confirmContract":
            guard let contract = command.contract else { throw CLIError.invalidCommand }
            try await session.confirmContract(contract); try emitValue(await session.continuousStatus(), kind: "status")
        case "reveal":
            guard let hand = command.hand else { throw CLIError.invalidCommand }
            try await session.reveal(hand); try emitValue(await session.continuousStatus(), kind: "status")
        case "stop":
            try save(await session.continuousCheckpoint(), to: output.appendingPathComponent("continuation.json"))
            emit(["ok": true, "state": "stopped"]); return true
        default: throw CLIError.invalidCommand
        }
        try save(await session.continuousCheckpoint(), to: output.appendingPathComponent("continuation.json"))
        try save(await session.requestEvidence(), to: output.appendingPathComponent("request-evidence.json"))
        return false
    }

    static func persist(_ session: ExternalBoardSession, output: URL) async throws {
        try save(await session.checkpoint(), to: output.appendingPathComponent("continuation.json"))
    }
    static func save<T: Encodable>(_ value: T, to url: URL) throws { try encoder.encode(value).write(to: url, options: .atomic) }
    static func emitValue<T: Encodable>(_ value: T, kind: String) throws {
        emit(["ok": true, "kind": kind, "value": try JSONSerialization.jsonObject(with: encoder.encode(value))])
    }
    static func emit(_ value: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .withoutEscapingSlashes]) {
            print(String(decoding: data, as: UTF8.self)); fflush(stdout)
        }
    }
}
private enum CLIError: Error {
    case invalidCommand, notStarted, outputMustBeEmpty
    case usage // bridge-external --output NEW_DIRECTORY --codex EXECUTABLE [--auth AUTH_JSON] [--observations SQLITE_PATH]
}
