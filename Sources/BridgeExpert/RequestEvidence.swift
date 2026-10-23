import Foundation

public struct TokenUsage: Codable, Equatable, Sendable {
    public let inputTokens: Int
    public let cachedInputTokens: Int
    public let outputTokens: Int
    public let reasoningOutputTokens: Int
    public let totalTokens: Int
    public init(inputTokens: Int, cachedInputTokens: Int, outputTokens: Int, reasoningOutputTokens: Int, totalTokens: Int) {
        self.inputTokens = inputTokens; self.cachedInputTokens = cachedInputTokens
        self.outputTokens = outputTokens; self.reasoningOutputTokens = reasoningOutputTokens; self.totalTokens = totalTokens
    }
}

public struct RequestEvidence: Codable, Sendable {
    public enum Role: String, Codable, Sendable { case player, reviewer }
    public enum Outcome: String, Codable, Sendable { case received, valid, transportFailure, protocolFailure, identityFailure, timeout, late }
    public let role: Role
    public let requestID: UUID
    public let decisionID: UUID
    public let candidateID: UUID?
    public let semanticRound: Int
    public let technicalAttempt: Int
    public let instructions: String
    public let input: String
    public let outputSchema: String
    public let timeoutSeconds: Double
    public let rawOutput: String?
    public let identity: RuntimeIdentity?
    public let replyRequestID: UUID?
    public let usage: TokenUsage?
    public let elapsedSeconds: Double
    public var outcome: Outcome
    public var detail: String?
}

actor RequestJournal {
    private var rows: [RequestEvidence] = []
    func append(_ row: RequestEvidence) { rows.append(row) }
    func mark(_ requestID: UUID, _ outcome: RequestEvidence.Outcome, detail: String? = nil) {
        guard let index = rows.lastIndex(where: { $0.requestID == requestID && $0.outcome != .late }) else { return }
        rows[index].outcome = outcome; rows[index].detail = detail
    }
    func read() -> [RequestEvidence] { rows }
}

/// Fatal adapter failures must not be disguised as a recoverable reviewer outage.
public enum PlayingBoundaryFailure: Error, Sendable {
    case identity(String), sessionLost(String), state(String)
}

struct NativeRequestTimeout: Error, Sendable {}

/// The caller returns at its deadline even if an external transport ignores cancellation.
/// Late completions only reach the journal; the one-shot continuation cannot be reused.
private actor RequestRace {
    private var continuation: CheckedContinuation<PlayingReply, Error>?
    private var finished = false
    private let deadline: Date
    private let record: @Sendable (Result<PlayingReply, Error>, RequestEvidence.Outcome) async -> Void
    private var worker: Task<Void, Never>?
    private var timer: Task<Void, Never>?
    init(continuation: CheckedContinuation<PlayingReply, Error>, deadline: Date,
         record: @escaping @Sendable (Result<PlayingReply, Error>, RequestEvidence.Outcome) async -> Void) {
        self.continuation = continuation; self.deadline = deadline; self.record = record
    }
    func install(worker: Task<Void, Never>, timer: Task<Void, Never>) {
        self.worker = worker; self.timer = timer
        if finished { timer.cancel() }
    }
    func finish(_ result: Result<PlayingReply, Error>, timeout: Bool = false) async {
        if finished {
            if !timeout { await record(result, .late) }
            return
        }
        finished = true
        let expired = timeout || Date() >= deadline
        let delivered: Result<PlayingReply, Error> = expired ? .failure(NativeRequestTimeout()) : result
        if expired { worker?.cancel() } else { timer?.cancel() }
        let outcome: RequestEvidence.Outcome
        switch delivered {
        case .success: outcome = .received
        case let .failure(error): outcome = expired ? .timeout : (error is PlayingBoundaryFailure || (error as? PlayingTransportFailure)?.fatal == true) ? .identityFailure : .transportFailure
        }
        await record(delivered, outcome)
        continuation?.resume(with: delivered); continuation = nil
        if expired && !timeout { await record(result, .late) }
    }
}

func boundedReply(transport: any PlayingTransport, request: PlayingRequest,
                  record: @escaping @Sendable (Result<PlayingReply, Error>, RequestEvidence.Outcome) async -> Void) async throws -> PlayingReply {
    let deadline = Date().addingTimeInterval(request.timeoutSeconds)
    return try await withCheckedThrowingContinuation { continuation in
        let race = RequestRace(continuation: continuation, deadline: deadline, record: record)
        let worker = Task.detached {
            do { await race.finish(.success(try await transport.respond(to: request))) }
            catch { await race.finish(.failure(error)) }
        }
        let timer = Task.detached {
            do { try await Task.sleep(nanoseconds: UInt64(max(0, request.timeoutSeconds) * 1_000_000_000)) }
            catch { return }
            await race.finish(.failure(NativeRequestTimeout()), timeout: true)
        }
        Task { await race.install(worker: worker, timer: timer) }
    }
}

/// Available public diagnostics even when a native request fails after starting a turn.
public struct PlayingTransportFailure: Error, Sendable {
    public let detail: String
    public let fatal: Bool
    public let identity: RuntimeIdentity?
    public let rawOutput: String?
    public let usage: TokenUsage?
    public init(detail: String, fatal: Bool = false, identity: RuntimeIdentity? = nil, rawOutput: String? = nil, usage: TokenUsage? = nil) {
        self.detail = detail; self.fatal = fatal; self.identity = identity; self.rawOutput = rawOutput; self.usage = usage
    }
}
