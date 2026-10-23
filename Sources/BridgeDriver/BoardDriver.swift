import Foundation
import BridgeDomain
import BridgeEngine
import BridgeExpert

/// Limited environment policy; complete holdings never cross into the Expert request.
public enum OpponentPolicy: String, Sendable {
    case lowLegal = "low-legal", conserveHigh = "conserve-high", pavlicekEntry = "pavlicek-entry"

    public func choose(in board: BoardState) throws -> Card {
        let legal = try board.legalCards()
        func lowest(_ cards: [Card]) -> Card {
            cards.min { $0.rank == $1.rank ? $0.description < $1.description : $0.rank < $1.rank }!
        }
        guard self != .lowLegal else { return lowest(legal) }
        // Frozen teaching-case policy: preserve the diamond entry problem, responding to actual play.
        if self == .pavlicekEntry, board.actingSeat == .east,
           board.currentTrick.last?.seat == .north,
           let lead = board.currentTrick.last?.card, lead.suit == .diamonds,
           legal.contains(try Card("DA")), legal.contains(try Card("DJ")) {
            if lead == (try Card("D9")) { return try Card("DJ") }
            if [try Card("DK"), try Card("DQ")].contains(lead),
               !board.events.dropLast(board.currentTrick.count).contains(where: { $0.seat == .north && $0.card.suit == .diamonds }) {
                let low = legal.filter { $0.rank < 11 }
                if !low.isEmpty { return lowest(low) }
            }
        }
        if let winner = board.winningPlay(in: board.currentTrick) {
            if winner.seat == board.actingSeat?.partner { return lowest(legal) }
            let winners = legal.filter { card in
                let play = PlayEvent(sequence: board.events.count, seat: board.actingSeat!, card: card)
                return board.winningPlay(in: board.currentTrick + [play])?.seat == board.actingSeat
            }
            return winners.isEmpty ? lowest(legal) : lowest(winners)
        }
        // Continue the opening suit when on lead; otherwise lead the top of the longest suit.
        let openingSuit = board.events.first?.card.suit
        let opening = legal.filter { $0.suit == openingSuit }
        let candidates = opening.isEmpty ? legal : opening
        let suit = Suit.allCases.max { a, b in candidates.filter { $0.suit == a }.count < candidates.filter { $0.suit == b }.count }!
        return candidates.filter { $0.suit == suit }.max { $0.rank < $1.rank }!
    }
}

public struct DriverStep: Codable, Sendable {
    public let execution: ActualExecution
    public let decision: DecisionRecord?
    public let actualEvents: [PlayEvent]
}

public struct DriverTrace: Codable, Sendable {
    public let boardID: UUID
    public let steps: [DriverStep]
    public let modelRequests: Int
    public let controlledActions: Int
    public let opponentActions: Int
    public let mechanicalActions: Int
    public let complete: Bool
    public let elapsedSeconds: Double
    public let initialEvents: [PlayEvent]
    public let initialControlledActions: Int
    public let initialOpponentActions: Int
    public let modelActions: Int
    public let nonforcedControlledActions: Int
    public let initialRequestSeconds: Double?
    public let subsequentRequestSeconds: [Double]
    public let lastControlledActionSeconds: Double?
    public let environmentOverheadSeconds: Double
    public let declarerTricks: Int
    public let defenderTricks: Int
    public let failure: String?
    public let requestTimeoutSeconds: Double
    public let runTimeoutSeconds: Double
    public let retries: Int
    public let failedRequestSeconds: Double?
    public let requestEvidence: [RequestEvidence]?
    public let playerRequests: Int?
    public let reviewerRequests: Int?
    public let semanticReviews: Int?
    public let automaticRuntimeSeconds: Double?
    public let humanWaitingSeconds: Double?
    public let needsInput: NeedsInputState?
}

public struct DriverFailure: Error, Sendable {
    public let decision: DecisionRecord
    public let detail: String
}

/// Public, UI-independent execution boundary. Each advance performs exactly one actual play.
public actor BoardDriver {
    private var board: BoardState
    private let expert: ExpertSession
    private let opponent: OpponentPolicy
    private let mechanicalSoleLegal: Bool
    private var steps: [DriverStep] = []
    private var pending: [ActualExecution] = []
    private var hasInitialPlan = false
    private var busy = false
    private var failed = false
    private let started: Date
    private let initialEvents: [PlayEvent]
    private let requestTimeoutSeconds: Double
    private let runTimeoutSeconds: Double
    private var lastControlledActionSeconds: Double?
    private var stoppedSeconds: Double?
    private var failureDetail: String?
    private var failedRequestSeconds: Double?
    private var nonforcedControlledActions = 0
    private var waitingSince: Date?
    private var humanWaitingSeconds = 0.0

    public init(board: BoardState, expert: ExpertSession, opponent: OpponentPolicy = .lowLegal, mechanicalSoleLegal: Bool = false, requestTimeoutSeconds: Double = 180, runTimeoutSeconds: Double = 1800, started: Date = Date()) {
        self.started = started
        self.initialEvents = board.events
        self.requestTimeoutSeconds = min(180, requestTimeoutSeconds); self.runTimeoutSeconds = min(1800, runTimeoutSeconds)
        self.board = board; self.expert = expert; self.opponent = opponent; self.mechanicalSoleLegal = mechanicalSoleLegal
    }

    public func advance() async throws -> DriverStep {
        guard !busy else { throw ExpertSessionError.overlappingDecision }
        guard !failed else { throw ExpertSessionError.endedSession }
        guard !board.isComplete else { throw DomainError.finished }
        if let waitingSince {
            humanWaitingSeconds += Date().timeIntervalSince(waitingSince)
            self.waitingSince = nil
        }
        busy = true
        defer { busy = false }
        do {
            let remaining = runTimeoutSeconds - (Date().timeIntervalSince(started) - humanWaitingSeconds)
            guard remaining > 0, requestTimeoutSeconds > 0, runTimeoutSeconds.isFinite, requestTimeoutSeconds.isFinite else {
                throw DriverBudgetError.expired
            }
            guard let seat = board.actingSeat else { throw DomainError.finished }
            let controlled = seat == board.contract.declarer || seat == board.contract.declarer.partner
            let legal = try board.legalCards()
            let decision: DecisionRecord?
            let source: ActualExecution.Source
            if controlled && !(mechanicalSoleLegal && hasInitialPlan && legal.count == 1) {
                decision = try await expert.decide(board.snapshot(controller: board.contract.declarer), executions: hasInitialPlan ? pending : [], timeoutSeconds: min(requestTimeoutSeconds, remaining), automaticDeadline: started.addingTimeInterval(runTimeoutSeconds + humanWaitingSeconds))
                guard Date().timeIntervalSince(started) - humanWaitingSeconds < runTimeoutSeconds else {
                    throw DriverFailure(decision: decision!, detail: "Run wall-clock budget expired before execution")
                }
                pending = []
                var nextBoard = board
                do { try nextBoard.apply(decision!.action) }
                catch { throw DriverFailure(decision: decision!, detail: String(describing: error)) }
                do { try await expert.commit(decision!, execution: ActualExecution(event: nextBoard.events.last!, source: .model)) }
                catch { throw DriverFailure(decision: decision!, detail: String(describing: error)) }
                board = nextBoard
                hasInitialPlan = true
                source = .model
            } else {
                decision = nil
                source = controlled ? .forced : .opponent
                try board.play(controlled ? legal[0] : opponent.choose(in: board), by: seat)
            }
            if controlled {
                lastControlledActionSeconds = Date().timeIntervalSince(started)
                if legal.count > 1 { nonforcedControlledActions += 1 }
            }
            if board.isComplete { stoppedSeconds = Date().timeIntervalSince(started) }
            let execution = ActualExecution(event: board.events.last!, source: source)
            pending.append(execution)
            let step = DriverStep(execution: execution, decision: decision, actualEvents: board.events)
            steps.append(step)
            return step
        } catch {
            if let failure = error as? ExpertFailure, failure.category == .needsInput {
                waitingSince = Date()
                failureDetail = "needs-input: " + failure.detail
                throw failure
            }
            await expert.abandonPending()
            failed = true
            failureDetail = String(describing: error)
            if let failure = error as? ExpertFailure { failedRequestSeconds = failure.elapsedSeconds }
            if let failure = error as? DriverFailure { failedRequestSeconds = failure.decision.elapsedSeconds }
            stoppedSeconds = Date().timeIntervalSince(started)
            throw error
        }
    }

    public func trace() async -> DriverTrace {
        let evidence = await expert.requestEvidence()
        let needsInput = await expert.needsInputState()
        let waiting = humanWaitingSeconds + (waitingSince.map { Date().timeIntervalSince($0) } ?? 0)
        let actualRequests = evidence.filter { $0.outcome != .late }
        let players = actualRequests.filter { $0.role == .player }.count
        let reviewers = actualRequests.filter { $0.role == .reviewer }.count
        let elapsed = stoppedSeconds ?? Date().timeIntervalSince(started)
        let latencies = steps.compactMap { $0.decision?.elapsedSeconds }
        return DriverTrace(boardID: board.id, steps: steps, modelRequests: players,
                    controlledActions: steps.filter { $0.execution.source == .model || $0.execution.source == .forced }.count,
                    opponentActions: steps.filter { $0.execution.source == .opponent }.count,
                    mechanicalActions: steps.filter { $0.execution.source == .forced }.count,
                    complete: board.isComplete && !failed, elapsedSeconds: elapsed,
                    initialEvents: initialEvents,
                    initialControlledActions: initialEvents.filter { $0.seat == board.contract.declarer || $0.seat == board.contract.declarer.partner }.count,
                    initialOpponentActions: initialEvents.filter { $0.seat != board.contract.declarer && $0.seat != board.contract.declarer.partner }.count,
                    modelActions: steps.filter { $0.execution.source == .model }.count,
                    nonforcedControlledActions: nonforcedControlledActions,
                    initialRequestSeconds: latencies.first ?? failedRequestSeconds, subsequentRequestSeconds: Array(latencies.dropFirst()),
                    lastControlledActionSeconds: lastControlledActionSeconds,
                    environmentOverheadSeconds: max(0, elapsed - waiting - latencies.reduce(0, +) - (failedRequestSeconds ?? 0)),
                    declarerTricks: board.declarerTricks, defenderTricks: board.defenderTricks, failure: failureDetail,
                    requestTimeoutSeconds: requestTimeoutSeconds, runTimeoutSeconds: runTimeoutSeconds,
                    retries: actualRequests.filter { $0.role == .reviewer && $0.technicalAttempt > 1 }.count, failedRequestSeconds: failedRequestSeconds,
                    requestEvidence: evidence, playerRequests: players, reviewerRequests: reviewers,
                    semanticReviews: actualRequests.filter { $0.role == .reviewer && $0.outcome == .valid }.count,
                    automaticRuntimeSeconds: max(0, elapsed - waiting), humanWaitingSeconds: waiting, needsInput: needsInput)
    }
}

public enum DriverBudgetError: Error { case expired }
