import Foundation
import BridgeDomain
import BridgeEngine
import BridgeExpert

public struct ContinuousBoardConfiguration: Codable, Equatable, Sendable {
    public let boardID: UUID
    public let userSeat: Seat
    public let dealer: Seat
    public let vulnerability: String
    public let scoring: String
    public let objective: String
    public let agreements: String
    public let initialHand: Hand
    public let auction: [AuctionEvent]
    public let events: [PlayEvent]
    public let revealedHands: [Hand]
    public let confirmedContract: Contract?
    public init(boardID: UUID, userSeat: Seat, dealer: Seat, vulnerability: String, scoring: String, objective: String,
                agreements: String, initialHand: Hand, auction: [AuctionEvent] = [], events: [PlayEvent] = [],
                revealedHands: [Hand] = [], confirmedContract: Contract? = nil) {
        self.boardID = boardID; self.userSeat = userSeat; self.dealer = dealer; self.vulnerability = vulnerability
        self.scoring = scoring; self.objective = objective; self.agreements = agreements; self.initialHand = initialHand
        self.auction = auction; self.events = events; self.revealedHands = revealedHands; self.confirmedContract = confirmedContract
    }
    func board() throws -> ContinuousBoardState {
        try ContinuousBoardState(id: boardID, userSeat: userSeat, dealer: dealer, vulnerability: vulnerability,
            scoring: scoring, objective: objective, agreements: agreements, initialHand: initialHand,
            auction: auction, events: events, revealedHands: revealedHands, confirmedContract: confirmedContract)
    }
}
public struct ContinuousExternalAdvice: Codable, Sendable {
    public let authorization: UUID
    public let source: ActualExecution.Source
    public let snapshotID: String
    public let actingSeat: Seat
    public let selectedAction: String
    public let decision: ContinuousDecisionRecord?
}
public struct ContinuousActualExecution: Codable, Sendable {
    public let snapshotID: String
    public let call: AuctionEvent?
    public let play: PlayEvent?
    public let source: ActualExecution.Source
    public let authorization: UUID?
}
public struct ContinuousExternalStatus: Codable, Sendable {
    public let snapshot: ContinuousSnapshot
    public let activePlan: String?
    public let pendingAuthorization: UUID?
    public let reconstructed: Bool
    public let stopped: Bool
}
public struct ContinuousExternalCheckpoint: Codable, Sendable {
    public let configuration: ContinuousBoardConfiguration
    public let lastCommittedSnapshot: ContinuousSnapshot?
    public let activePlan: String?
    public let executions: [ContinuousActualExecution]
    public var safeToResume: Bool
    public let automaticDeadline: Date
}

actor ContinuousExternalBoardSession {
    var board: ContinuousBoardState
    let configuration: ContinuousBoardConfiguration
    var exposed: [Hand]
    let expert: ExpertSession
    var pending: ContinuousExternalAdvice?
    var busy = false
    var stopped = false
    var reconstructed = false
    var lastCommittedSnapshot: ContinuousSnapshot?
    var executions: [ContinuousActualExecution] = []
    let automaticDeadline: Date
    init(configuration: ContinuousBoardConfiguration, transport: any PlayingTransport, reviewer: any PlayingTransport, started: Date) throws {
        self.configuration = configuration; board = try configuration.board(); exposed = configuration.revealedHands
        expert = ExpertSession(transport: transport, reviewer: reviewer); automaticDeadline = started.addingTimeInterval(1800)
    }
    func status() async throws -> ContinuousExternalStatus {
        .init(snapshot: try board.snapshot(), activePlan: await expert.continuousPlan(), pendingAuthorization: pending?.authorization,
              reconstructed: reconstructed, stopped: stopped)
    }
    func checkpoint() async throws -> ContinuousExternalCheckpoint {
        let current = ContinuousBoardConfiguration(boardID: configuration.boardID, userSeat: configuration.userSeat,
            dealer: configuration.dealer, vulnerability: configuration.vulnerability, scoring: configuration.scoring,
            objective: configuration.objective, agreements: configuration.agreements, initialHand: configuration.initialHand,
            auction: board.auction, events: board.events, revealedHands: exposed, confirmedContract: board.contractConfirmed ? board.contract : nil)
        return .init(configuration: current, lastCommittedSnapshot: lastCommittedSnapshot, activePlan: await expert.continuousPlan(),
            executions: executions, safeToResume: !stopped && !busy && pending == nil, automaticDeadline: automaticDeadline)
    }
    static func resume(_ checkpoint: ContinuousExternalCheckpoint, reconciled: ContinuousBoardConfiguration,
                       transport: any PlayingTransport, reviewer: any PlayingTransport) async throws -> ContinuousExternalBoardSession {
        guard checkpoint.safeToResume, checkpoint.automaticDeadline > Date(), checkpoint.configuration == reconciled else {
            throw ExternalBoardError.reconciliationRequired
        }
        let session = try ContinuousExternalBoardSession(configuration: reconciled, transport: transport, reviewer: reviewer,
            started: checkpoint.automaticDeadline.addingTimeInterval(-1800))
        try await session.restore(checkpoint)
        return session
    }
    private func restore(_ checkpoint: ContinuousExternalCheckpoint) async throws {
        if let previous = checkpoint.lastCommittedSnapshot {
            let now = try board.snapshot()
            guard now.boardID == previous.boardID, now.userSeat == previous.userSeat,
                  now.auction.starts(with: previous.auction), now.events.starts(with: previous.events),
                  now.revision > previous.revision else { throw ExternalBoardError.reconciliationRequired }
            let priorExposures = exposed.filter { hand in previous.hands.contains { $0.seat == hand.seat } }
            let prior = try ContinuousBoardState(id: configuration.boardID, userSeat: configuration.userSeat,
                dealer: configuration.dealer, vulnerability: configuration.vulnerability, scoring: configuration.scoring,
                objective: configuration.objective, agreements: configuration.agreements, initialHand: configuration.initialHand,
                auction: previous.auction, events: previous.events, revealedHands: priorExposures,
                confirmedContract: previous.contractConfirmed ? previous.contract : nil)
            guard try prior.snapshot() == previous,
                  checkpoint.executions.compactMap(\.call) == Array(now.auction.dropFirst(previous.auction.count)),
                  checkpoint.executions.compactMap(\.play) == Array(now.events.dropFirst(previous.events.count)),
                  checkpoint.executions.allSatisfy({ ($0.call == nil) != ($0.play == nil) }) else {
                throw ExternalBoardError.reconciliationRequired
            }
        } else if checkpoint.activePlan != nil { throw ExternalBoardError.reconciliationRequired }
        try await expert.restoreContinuous(snapshot: checkpoint.lastCommittedSnapshot, plan: checkpoint.activePlan)
        reconstructed = true; lastCommittedSnapshot = checkpoint.lastCommittedSnapshot; executions = checkpoint.executions
    }
    func decide() async throws -> ContinuousExternalAdvice {
        try available(); guard pending == nil else { throw ExternalBoardError.pendingDecision }
        let snapshot = try board.snapshot()
        guard let seat = snapshot.actingSeat, board.isControlled(seat) else { throw DomainError.invalidController }
        if snapshot.phase != .bidding, snapshot.legalCards.count == 1, lastCommittedSnapshot != nil {
            let result = ContinuousExternalAdvice(authorization: UUID(), source: .forced, snapshotID: snapshot.id,
                actingSeat: seat, selectedAction: snapshot.legalCards[0].description, decision: nil)
            pending = result; return result
        }
        busy = true; defer { busy = false }
        do {
            let decision = try await expert.decide(snapshot, automaticDeadline: automaticDeadline)
            let result = ContinuousExternalAdvice(authorization: decision.id, source: .model, snapshotID: snapshot.id,
                actingSeat: seat, selectedAction: decision.advice.selectedAction, decision: decision)
            pending = result; return result
        } catch { stopped = true; throw error }
    }
    func observeCall(_ event: AuctionEvent, authorization: UUID?) async throws -> ContinuousActualExecution {
        try available()
        busy = true; defer { busy = false }
        let snapshot = try board.snapshot(); var next = board; try next.observeCall(event)
        let source = try await authorize(snapshot: snapshot, seat: event.seat, action: event.call.description,
            authorization: authorization, automatic: false)
        let execution = ContinuousActualExecution(snapshotID: snapshot.id, call: event, play: nil, source: source, authorization: authorization)
        board = next; executions.append(execution); return execution
    }
    func observePlay(_ event: PlayEvent, authorization: UUID?, automatic: Bool) async throws -> ContinuousActualExecution {
        try available()
        busy = true; defer { busy = false }
        let snapshot = try board.snapshot(); var next = board; try next.observePlay(event)
        let source = try await authorize(snapshot: snapshot, seat: event.seat, action: event.card.description,
            authorization: authorization, automatic: automatic)
        let execution = ContinuousActualExecution(snapshotID: snapshot.id, call: nil, play: event, source: source, authorization: authorization)
        board = next; executions.append(execution); return execution
    }
    func confirmContract(_ contract: Contract) throws { try available(); guard pending == nil else { throw ExternalBoardError.pendingDecision }; try board.confirmContract(contract) }
    func reveal(_ hand: Hand) throws { try available(); guard pending == nil else { throw ExternalBoardError.pendingDecision }; try board.reveal(hand); exposed.append(hand) }
    func evidence() async -> [RequestEvidence] { await expert.continuousEvidence() }
    private func available() throws {
        guard !stopped else { throw ExternalBoardError.stopped }
        guard !busy else { throw ExternalBoardError.pendingDecision }
        guard Date() < automaticDeadline else { stopped = true; throw ExpertSessionError.automaticBudgetExpired }
    }
    private func authorize(snapshot: ContinuousSnapshot, seat: Seat, action: String, authorization: UUID?, automatic: Bool) async throws -> ActualExecution.Source {
        if board.isControlled(seat) {
            if automatic {
                guard snapshot.phase != .bidding, pending == nil, authorization == nil,
                      snapshot.legalCards.map(\.description) == [action] else { throw ExternalBoardError.invalidAuthorization }
                return .forced
            }
            guard let pending, pending.authorization == authorization, pending.snapshotID == snapshot.id,
                  pending.actingSeat == seat, pending.selectedAction == action else { throw ExternalBoardError.invalidAuthorization }
            if let decision = pending.decision {
                try await expert.commit(decision); lastCommittedSnapshot = decision.snapshot; executions = []
            }
            self.pending = nil; return pending.source
        }
        guard pending == nil, authorization == nil, !automatic else { throw ExternalBoardError.invalidAuthorization }
        return .opponent
    }
}
