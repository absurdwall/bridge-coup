import Foundation
import BridgeDomain
import BridgeEngine
import BridgeExpert

public struct ExternalBoardConfiguration: Codable, Equatable, Sendable {
    public let boardID: UUID
    public let contract: Contract
    public let vulnerability: String
    public let scoring: String
    public let objective: String
    public let publicBackground: String?
    public let initialHands: [Hand]
    public let events: [PlayEvent]
    public init(boardID: UUID, contract: Contract, vulnerability: String, scoring: String, objective: String,
                publicBackground: String?, initialHands: [Hand], events: [PlayEvent]) {
        self.boardID = boardID; self.contract = contract; self.vulnerability = vulnerability; self.scoring = scoring
        self.objective = objective; self.publicBackground = publicBackground; self.initialHands = initialHands; self.events = events
    }
    func board() throws -> PublicBoardState {
        try PublicBoardState(id: boardID, contract: contract, vulnerability: vulnerability, scoring: scoring,
            objective: objective, publicBackground: publicBackground, initialHands: initialHands, events: events)
    }
}

public struct ExternalBoardStatus: Codable, Sendable {
    public let events: [PlayEvent]
    public let actingSeat: Seat?
    public let snapshot: DecisionSnapshot?
    public let activePlan: PlanAssociation?
    public let pendingAuthorization: UUID?
    public let reconstructed: Bool
    public let stopped: Bool
}

public struct ExternalAdvice: Codable, Sendable {
    public let authorization: UUID?
    public let source: ActualExecution.Source
    public let action: CurrentAction
    public let decision: DecisionRecord?
}

public struct ExternalBoardCheckpoint: Codable, Sendable {
    public let configuration: ExternalBoardConfiguration
    public let lastCommittedSnapshot: DecisionSnapshot?
    public let activePlan: PlanAssociation?
    public let executions: [ActualExecution]
    /// False while a decision is pending/in flight or after failure. Never roll back to an earlier safe file.
    public var safeToResume: Bool
    public let automaticDeadline: Date
}

public enum ExternalBoardError: Error { case pendingDecision, invalidAuthorization, stopped, reconciliationRequired, unsafeCheckpoint }

/// An external table supplies actual events; this session never chooses or simulates defenders.
public actor ExternalBoardSession {
    private var board: PublicBoardState
    private let configuration: ExternalBoardConfiguration
    private let expert: ExpertSession
    private var pending: ExternalAdvice?
    private var busy = false
    private var stopped = false
    private var hasCommittedDecision = false
    private let reconstructed: Bool
    private var executions: [ActualExecution] = []
    private var lastCommittedSnapshot: DecisionSnapshot?
    private let automaticDeadline: Date

    public init(configuration: ExternalBoardConfiguration, transport: any PlayingTransport, reviewer: any PlayingTransport, started: Date = Date()) throws {
        self.configuration = configuration; board = try configuration.board()
        expert = ExpertSession(transport: transport, reviewer: reviewer); reconstructed = false
        automaticDeadline = started.addingTimeInterval(1800)
    }

    private init(configuration: ExternalBoardConfiguration, board: PublicBoardState, expert: ExpertSession,
                 checkpoint: ExternalBoardCheckpoint) {
        self.configuration = configuration; self.board = board; self.expert = expert; reconstructed = true
        automaticDeadline = checkpoint.automaticDeadline
        lastCommittedSnapshot = checkpoint.lastCommittedSnapshot
        hasCommittedDecision = checkpoint.lastCommittedSnapshot != nil; executions = checkpoint.executions
    }

    public static func resume(_ checkpoint: ExternalBoardCheckpoint, reconciled: ExternalBoardConfiguration,
                              transport: any PlayingTransport, reviewer: any PlayingTransport) async throws -> ExternalBoardSession {
        guard checkpoint.safeToResume, checkpoint.automaticDeadline > Date(), reconciled == checkpoint.configuration else { throw ExternalBoardError.reconciliationRequired }
        let board = try reconciled.board()
        let expert = ExpertSession(transport: transport, reviewer: reviewer)
        if let previous = checkpoint.lastCommittedSnapshot {
            guard previous.boardID == reconciled.boardID, previous.contract == reconciled.contract,
                  previous.scoring == reconciled.scoring, previous.vulnerability == reconciled.vulnerability,
                  previous.objective == reconciled.objective, previous.publicBackground == reconciled.publicBackground,
                  board.events.starts(with: previous.events), board.events.count > previous.events.count else {
                throw ExternalBoardError.reconciliationRequired
            }
            let prior = try PublicBoardState(id: reconciled.boardID, contract: reconciled.contract,
                vulnerability: reconciled.vulnerability, scoring: reconciled.scoring, objective: reconciled.objective,
                publicBackground: reconciled.publicBackground, initialHands: reconciled.initialHands, events: previous.events)
            guard try prior.snapshot() == previous,
                  checkpoint.executions.map(\.event) == Array(board.events.dropFirst(previous.events.count)) else {
                throw ExternalBoardError.reconciliationRequired
            }
            try await expert.restorePublicContinuation(after: previous, activePlan: checkpoint.activePlan)
        } else {
            guard checkpoint.activePlan == nil else { throw ExternalBoardError.reconciliationRequired }
        }
        return ExternalBoardSession(configuration: reconciled, board: board, expert: expert, checkpoint: checkpoint)
    }

    public func checkpoint() async throws -> ExternalBoardCheckpoint {
        let current = ExternalBoardConfiguration(boardID: configuration.boardID, contract: configuration.contract,
            vulnerability: configuration.vulnerability, scoring: configuration.scoring, objective: configuration.objective,
            publicBackground: configuration.publicBackground, initialHands: configuration.initialHands, events: board.events)
        return ExternalBoardCheckpoint(configuration: current, lastCommittedSnapshot: lastCommittedSnapshot,
            activePlan: await expert.activePlan(), executions: executions, safeToResume: !stopped && !busy && pending == nil,
            automaticDeadline: automaticDeadline)
    }

    public func status() async throws -> ExternalBoardStatus {
        ExternalBoardStatus(events: board.events, actingSeat: board.actingSeat, snapshot: try? board.snapshot(),
            activePlan: await expert.activePlan(), pendingAuthorization: pending?.authorization, reconstructed: reconstructed, stopped: stopped)
    }

    public func decide() async throws -> ExternalAdvice {
        guard !stopped else { throw ExternalBoardError.stopped }
        guard !busy, pending == nil else { throw ExternalBoardError.pendingDecision }
        guard automaticDeadline > Date() else { stopped = true; throw ExpertSessionError.automaticBudgetExpired }
        let snapshot = try board.snapshot()
        if hasCommittedDecision && snapshot.legalCards.count == 1 {
            let result = ExternalAdvice(authorization: UUID(), source: .forced, action: .init(snapshot: snapshot, card: snapshot.legalCards[0]), decision: nil)
            pending = result; return result
        }
        busy = true; defer { busy = false }
        do {
            let decision = try await expert.decide(snapshot, executions: hasCommittedDecision ? executions : [], automaticDeadline: automaticDeadline)
            let result = ExternalAdvice(authorization: decision.session.id, source: .model, action: decision.action, decision: decision)
            pending = result; executions = []; return result
        } catch {
            stopped = true
            throw error
        }
    }

    /// The caller attests this is observed on the actual table, not merely attempted.
    public func observe(_ event: PlayEvent, authorization: UUID? = nil) async throws -> ActualExecution {
        guard !stopped else { throw ExternalBoardError.stopped }
        guard !busy else { throw ExternalBoardError.pendingDecision }
        guard automaticDeadline > Date() else { stopped = true; throw ExpertSessionError.automaticBudgetExpired }
        busy = true; defer { busy = false }
        var next = board
        try next.observe(event)
        let controlled = event.seat == board.contract.declarer || event.seat == board.contract.declarer.partner
        let execution: ActualExecution
        if controlled {
            guard let pending, let authorization, authorization == pending.authorization,
                  pending.action.revision == board.events.count, pending.action.card == event.card,
                  pending.action.actingSeat == event.seat else { throw ExternalBoardError.invalidAuthorization }
            execution = .init(event: event, source: pending.source)
            if let decision = pending.decision {
                do { try await expert.commit(decision, execution: execution) }
                catch { stopped = true; throw error }
                lastCommittedSnapshot = decision.snapshot
                hasCommittedDecision = true
            }
            self.pending = nil
        } else {
            guard pending == nil, authorization == nil else { throw ExternalBoardError.invalidAuthorization }
            execution = .init(event: event, source: .opponent)
        }
        board = next; executions.append(execution)
        return execution
    }

    public func requestEvidence() async -> [RequestEvidence] { await expert.requestEvidence() }
}
