import Foundation
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeKnowledge

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
    public let explanationSettings: ExplanationSettings?
    public init(boardID: UUID, userSeat: Seat, dealer: Seat, vulnerability: String, scoring: String, objective: String,
                agreements: String, initialHand: Hand, auction: [AuctionEvent] = [], events: [PlayEvent] = [],
                revealedHands: [Hand] = [], confirmedContract: Contract? = nil, explanationSettings: ExplanationSettings? = nil) {
        self.boardID = boardID; self.userSeat = userSeat; self.dealer = dealer; self.vulnerability = vulnerability
        self.scoring = scoring; self.objective = objective; self.agreements = agreements; self.initialHand = initialHand
        self.auction = auction; self.events = events; self.revealedHands = revealedHands; self.confirmedContract = confirmedContract; self.explanationSettings = explanationSettings
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
    public let pendingExplanation: ExplanationRequest?
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
    public let explanationEvidence: [ExplanationResult]?
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
    let explanationStore: ExplanationStore?
    var explanationEvidence: [ExplanationResult] = []
    var pendingExplanation: ExplanationRequest?
    var hasUncommittedInformation = false
    init(configuration: ContinuousBoardConfiguration, transport: any PlayingTransport, reviewer: any PlayingTransport, started: Date, explanationStore: ExplanationStore? = nil) throws {
        self.configuration = configuration; board = try configuration.board(); exposed = configuration.revealedHands; self.explanationStore = explanationStore
        expert = ExpertSession(transport: transport, reviewer: reviewer); automaticDeadline = started.addingTimeInterval(1800)
    }
    func status() async throws -> ContinuousExternalStatus {
        .init(snapshot: try board.snapshot(), activePlan: await expert.continuousPlan(), pendingAuthorization: pending?.authorization,
              pendingExplanation: pendingExplanation, reconstructed: reconstructed, stopped: stopped)
    }
    func checkpoint() async throws -> ContinuousExternalCheckpoint {
        let current = ContinuousBoardConfiguration(boardID: configuration.boardID, userSeat: configuration.userSeat,
            dealer: configuration.dealer, vulnerability: configuration.vulnerability, scoring: configuration.scoring,
            objective: configuration.objective, agreements: configuration.agreements, initialHand: configuration.initialHand,
            auction: board.auction, events: board.events, revealedHands: exposed, confirmedContract: board.contractConfirmed ? board.contract : nil, explanationSettings: configuration.explanationSettings)
        return .init(configuration: current, lastCommittedSnapshot: lastCommittedSnapshot, activePlan: await expert.continuousPlan(),
            executions: executions, safeToResume: !stopped && !busy && pending == nil && pendingExplanation == nil && !hasUncommittedInformation, automaticDeadline: automaticDeadline, explanationEvidence: explanationEvidence)
    }
    static func resume(_ checkpoint: ContinuousExternalCheckpoint, reconciled: ContinuousBoardConfiguration,
                       transport: any PlayingTransport, reviewer: any PlayingTransport, explanationStore: ExplanationStore? = nil) async throws -> ContinuousExternalBoardSession {
        guard checkpoint.safeToResume, checkpoint.automaticDeadline > Date(), checkpoint.configuration == reconciled else {
            throw ExternalBoardError.reconciliationRequired
        }
        let session = try ContinuousExternalBoardSession(configuration: reconciled, transport: transport, reviewer: reviewer,
            started: checkpoint.automaticDeadline.addingTimeInterval(-1800), explanationStore: explanationStore)
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
        reconstructed = true; lastCommittedSnapshot = checkpoint.lastCommittedSnapshot; executions = checkpoint.executions; explanationEvidence = checkpoint.explanationEvidence ?? []
    }
    func decide() async throws -> ContinuousExternalAdvice {
        try available(); guard pending == nil else { throw ExternalBoardError.pendingDecision }
        if let request = pendingExplanation { throw ExplanationRequestNeeded(request: request) }
        let snapshot = try board.snapshot()
        guard let seat = snapshot.actingSeat, board.isControlled(seat) else { throw DomainError.invalidController }
        if snapshot.phase != .bidding, snapshot.legalCards.count == 1, lastCommittedSnapshot != nil {
            let result = ContinuousExternalAdvice(authorization: UUID(), source: .forced, snapshotID: snapshot.id,
                actingSeat: seat, selectedAction: snapshot.legalCards[0].description, decision: nil)
            pending = result; return result
        }
        busy = true; defer { busy = false }
        do {
            let decision = try await expert.decide(snapshot, automaticDeadline: automaticDeadline, explanationContext: context(snapshot), explanationEvidence: explanationEvidence)
            let result = ContinuousExternalAdvice(authorization: decision.rounds.last!.candidateID, source: .model, snapshotID: snapshot.id,
                actingSeat: seat, selectedAction: decision.advice.selectedAction, decision: decision)
            pending = result; return result
        } catch let needed as ExplanationRequestNeeded {
            pendingExplanation = needed.request; hasUncommittedInformation = true
            let request = try await enrich(needed.request); pendingExplanation = request
            throw ExplanationRequestNeeded(request: request)
        } catch { stopped = true; throw error }
    }

    func inspectCalls(candidates: [AuctionCall], reason: String) async throws -> ExplanationRequest {
        try available(); guard pendingExplanation == nil else { throw ExternalBoardError.pendingDecision }
        let snapshot = try board.snapshot()
        guard let seat = snapshot.actingSeat, board.isControlled(seat) else { throw DomainError.invalidController }
        busy = true; defer { busy = false }
        let request = try await expert.inspectCalls(snapshot, context: context(snapshot), candidates: candidates, reason: reason,
            automaticDeadline: automaticDeadline, evidence: explanationEvidence)
        pending = nil; pendingExplanation = request; hasUncommittedInformation = true
        let enriched = try await enrich(request); pendingExplanation = enriched
        return enriched
    }

    func provideExplanations(requestID: UUID, snapshotID: String, results: [ExplanationResult]) async throws {
        try available()
        guard let request = pendingExplanation, request.id == requestID, request.snapshotID == snapshotID,
              try board.snapshot().id == snapshotID else { throw ExplanationExchangeError.staleRequest }
        guard results.count == request.candidates.count, Set(results.map(\.candidate)) == Set(request.candidates),
              results.allSatisfy({ $0.provider == .environment && ($0.context == nil || $0.context == request.context) &&
                  (($0.status == .found && !$0.references.isEmpty && $0.references.count <= 5) || ($0.status != .found && $0.references.isEmpty)) }) else { throw ExplanationExchangeError.invalidResult }
        for result in results {
            for reference in result.references {
                guard reference.status == .exact, reference.differences.isEmpty,
                      reference.observation.context == request.context, reference.observation.candidate == result.candidate else { throw ExplanationExchangeError.invalidResult }
            }
        }
        busy = true; defer { busy = false }
        for result in results {
            for reference in result.references {
                guard let explanationStore else { throw ExplanationExchangeError.missingStore }
                try await explanationStore.save(reference.observation)
            }
        }
        let associated = results.map { ExplanationResult(candidate: $0.candidate, provider: $0.provider, status: $0.status,
            references: $0.references, detail: $0.detail, context: request.context) }
        let updated = explanationEvidence + request.localResults + associated
        try await expert.provideExplanations(requestID: requestID, evidence: updated)
        explanationEvidence = updated; pendingExplanation = nil
    }

    private func context(_ snapshot: ContinuousSnapshot) -> ExplanationContext {
        let settings = configuration.explanationSettings
        return ExplanationContext(dealer: snapshot.dealer, actingSeat: snapshot.actingSeat ?? configuration.userSeat,
            auction: snapshot.auction, vulnerability: snapshot.vulnerability, nsSystem: settings?.nsSystem ?? "unknown",
            ewSystem: settings?.ewSystem ?? "unknown", conditions: settings?.conditions ?? snapshot.agreements,
            handRecordReference: settings?.handRecordReference)
    }
    private func enrich(_ request: ExplanationRequest) async throws -> ExplanationRequest {
        var local: [ExplanationResult] = []
        for candidate in request.candidates {
            let matches = try await explanationStore?.lookup(context: request.context, candidate: candidate, limit: 5) ?? []
            local.append(.init(candidate: candidate, provider: .knowledge, status: matches.isEmpty ? .noMatch : .found,
                references: matches, detail: matches.isEmpty ? "No local observation; no curated Knowledge corpus is installed." : "Stored observations are sourced references, not adopted agreements.", context: request.context))
        }
        return ExplanationRequest(id: request.id, snapshotID: request.snapshotID, context: request.context,
            candidates: request.candidates, reason: request.reason, localResults: local)
    }

    func observeCall(_ event: AuctionEvent, authorization: UUID?) async throws -> ContinuousActualExecution {
        try available(); guard pendingExplanation == nil else { throw ExternalBoardError.pendingDecision }
        busy = true; defer { busy = false }
        let snapshot = try board.snapshot(); var next = board; try next.observeCall(event)
        let source = try await authorize(snapshot: snapshot, seat: event.seat, action: event.call.description,
            authorization: authorization, automatic: false)
        let execution = ContinuousActualExecution(snapshotID: snapshot.id, call: event, play: nil, source: source, authorization: authorization)
        board = next; executions.append(execution); return execution
    }
    func observePlay(_ event: PlayEvent, authorization: UUID?, automatic: Bool) async throws -> ContinuousActualExecution {
        try available(); guard pendingExplanation == nil else { throw ExternalBoardError.pendingDecision }
        busy = true; defer { busy = false }
        let snapshot = try board.snapshot(); var next = board; try next.observePlay(event)
        let source = try await authorize(snapshot: snapshot, seat: event.seat, action: event.card.description,
            authorization: authorization, automatic: automatic)
        let execution = ContinuousActualExecution(snapshotID: snapshot.id, call: nil, play: event, source: source, authorization: authorization)
        board = next; executions.append(execution); return execution
    }
    func confirmContract(_ contract: Contract) throws { try available(); guard pending == nil, pendingExplanation == nil else { throw ExternalBoardError.pendingDecision }; try board.confirmContract(contract) }
    func reveal(_ hand: Hand) throws { try available(); guard pending == nil, pendingExplanation == nil else { throw ExternalBoardError.pendingDecision }; try board.reveal(hand); exposed.append(hand) }
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
                try await expert.commit(decision); lastCommittedSnapshot = decision.snapshot; executions = []; hasUncommittedInformation = false
            }
            self.pending = nil; return pending.source
        }
        guard pending == nil, authorization == nil, !automatic else { throw ExternalBoardError.invalidAuthorization }
        return .opponent
    }
}
