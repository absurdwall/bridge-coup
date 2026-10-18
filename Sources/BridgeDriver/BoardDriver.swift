import Foundation
import BridgeDomain
import BridgeEngine
import BridgeExpert

/// Limited environment policy; complete holdings never cross into the Expert request.
public enum OpponentPolicy: String, Sendable {
    case lowLegal = "low-legal", conserveHigh = "conserve-high"

    public func choose(in board: BoardState) throws -> Card {
        let legal = try board.legalCards()
        func lowest(_ cards: [Card]) -> Card {
            cards.min { $0.rank == $1.rank ? $0.description < $1.description : $0.rank < $1.rank }!
        }
        guard self == .conserveHigh else { return lowest(legal) }
        func strength(_ card: Card) -> Int {
            let led = board.currentTrick.first?.card.suit
            return (card.suit == board.contract.strain.trump ? 200 : card.suit == led ? 100 : 0) + card.rank
        }
        if let winner = board.currentTrick.max(by: { strength($0.card) < strength($1.card) }) {
            if winner.seat == board.actingSeat?.partner { return lowest(legal) }
            let winners = legal.filter { strength($0) > strength(winner.card) }
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
    private var modelRequests = 0
    private var hasInitialPlan = false
    private var busy = false
    private var failed = false
    private let started = Date()

    public init(board: BoardState, expert: ExpertSession, opponent: OpponentPolicy = .lowLegal, mechanicalSoleLegal: Bool = false) {
        self.board = board; self.expert = expert; self.opponent = opponent; self.mechanicalSoleLegal = mechanicalSoleLegal
    }

    public func advance() async throws -> DriverStep {
        guard !busy else { throw ExpertSessionError.overlappingDecision }
        guard !failed else { throw ExpertSessionError.endedSession }
        busy = true
        defer { busy = false }
        do {
            guard let seat = board.actingSeat else { throw DomainError.finished }
            let controlled = seat == board.contract.declarer || seat == board.contract.declarer.partner
            let legal = try board.legalCards()
            let decision: DecisionRecord?
            let source: ActualExecution.Source
            if controlled && !(mechanicalSoleLegal && hasInitialPlan && legal.count == 1) {
                modelRequests += 1
                decision = try await expert.decide(board.snapshot(controller: board.contract.declarer), executions: hasInitialPlan ? pending : [])
                pending = []
                do { try board.apply(decision!.action) }
                catch { throw DriverFailure(decision: decision!, detail: String(describing: error)) }
                hasInitialPlan = true
                source = .model
            } else {
                decision = nil
                source = controlled ? .forced : .opponent
                try board.play(controlled ? legal[0] : opponent.choose(in: board), by: seat)
            }
            let execution = ActualExecution(event: board.events.last!, source: source)
            pending.append(execution)
            let step = DriverStep(execution: execution, decision: decision, actualEvents: board.events)
            steps.append(step)
            return step
        } catch {
            failed = true
            throw error
        }
    }

    public func trace() -> DriverTrace {
        DriverTrace(boardID: board.id, steps: steps, modelRequests: modelRequests,
                    controlledActions: steps.filter { $0.execution.source == .model || $0.execution.source == .forced }.count,
                    opponentActions: steps.filter { $0.execution.source == .opponent }.count,
                    mechanicalActions: steps.filter { $0.execution.source == .forced }.count,
                    complete: board.isComplete, elapsedSeconds: Date().timeIntervalSince(started))
    }
}
