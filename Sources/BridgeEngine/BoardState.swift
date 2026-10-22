import Foundation
import BridgeDomain

/// Authoritative sequential rules, independent of any model or user interface.
public struct BoardState: Sendable {
    public let id: UUID
    public let contract: Contract
    public let vulnerability: String
    public let scoring: String
    public let objective: String
    public let publicBackground: String?
    public private(set) var hands: [Seat: [Card]]
    public private(set) var events: [PlayEvent] = []
    public private(set) var currentTrick: [PlayEvent] = []
    public private(set) var declarerTricks = 0
    public private(set) var defenderTricks = 0
    private var leader: Seat
    public var isComplete: Bool { events.count == 52 }
    public var actingSeat: Seat? {
        guard !isComplete else { return nil }
        return (0..<currentTrick.count).reduce(leader) { seat, _ in seat.next }
    }

    public init(id: UUID = UUID(), deal: [Seat: [Card]], contract: Contract, vulnerability: String = "neither",
                scoring: String = "IMP", objective: String = "Normal IMP strategy, weighing contract risk and overtricks.",
                publicBackground: String? = nil) throws {
        guard (1...7).contains(contract.level), Seat.allCases.allSatisfy({ deal[$0]?.count == 13 }),
              Set(deal.values.flatMap { $0 }).count == 52 else { throw DomainError.invalidDeal }
        self.id = id; self.hands = deal; self.contract = contract; self.vulnerability = vulnerability
        self.scoring = scoring; self.objective = objective; self.publicBackground = publicBackground
        leader = contract.declarer.next
    }

    public func legalCards() throws -> [Card] {
        guard let seat = actingSeat else { throw DomainError.finished }
        let holding = hands[seat]!
        if let led = currentTrick.first?.card.suit {
            let follows = holding.filter { $0.suit == led }
            if !follows.isEmpty { return follows }
        }
        return holding
    }

    public mutating func play(_ card: Card, by seat: Seat) throws {
        guard let acting = actingSeat else { throw DomainError.finished }
        guard seat == acting else { throw DomainError.wrongTurn }
        guard hands[seat]!.contains(card) else { throw DomainError.cardNotHeld }
        guard try legalCards().contains(card) else { throw DomainError.mustFollowSuit }
        hands[seat]!.removeAll { $0 == card }
        let event = PlayEvent(sequence: events.count, seat: seat, card: card)
        events.append(event); currentTrick.append(event)
        if currentTrick.count == 4 {
            let winner = winningPlay(in: currentTrick)!.seat
            if winner == contract.declarer || winner == contract.declarer.partner { declarerTricks += 1 }
            else { defenderTricks += 1 }
            leader = winner; currentTrick = []
        }
    }

    /// Basic trick rule shared with the environment policy; no strategic analysis.
    public func winningPlay(in trick: [PlayEvent]) -> PlayEvent? {
        guard let led = trick.first?.card.suit else { return nil }
        func strength(_ card: Card) -> Int {
            (card.suit == contract.strain.trump ? 200 : card.suit == led ? 100 : 0) + card.rank
        }
        return trick.max { strength($0.card) < strength($1.card) }
    }

    public func snapshot(controller: Seat) throws -> DecisionSnapshot {
        guard controller == contract.declarer else { throw DomainError.invalidController }
        guard let acting = actingSeat else { throw DomainError.finished }
        guard acting == controller || acting == controller.partner else { throw DomainError.invalidController }
        let completed = stride(from: 0, to: events.count - currentTrick.count, by: 4).map { start in
            let plays = Array(events[start..<start + 4])
            return CompletedTrick(plays: plays, winner: winningPlay(in: plays)!.seat)
        }
        return DecisionSnapshot(boardID: id, revision: events.count, controller: controller, actingSeat: acting,
                                contract: contract, vulnerability: vulnerability, scoring: scoring, objective: objective,
                                publicBackground: publicBackground,
                                hands: [controller, controller.partner].map { Hand(seat: $0, cards: hands[$0]!) },
                                events: events, currentTrick: currentTrick, declarerTricks: declarerTricks, defenderTricks: defenderTricks, legalCards: try legalCards(), currentWinningPlay: winningPlay(in: currentTrick), completedTricks: completed)
    }

    public mutating func apply(_ action: CurrentAction) throws {
        guard action.boardID == id, action.revision == events.count,
              action.snapshotID == "\(id.uuidString):\(events.count):\(action.controller.rawValue)" else { throw DomainError.staleSnapshot }
        guard action.controller == contract.declarer,
              action.actingSeat == action.controller || action.actingSeat == action.controller.partner else { throw DomainError.invalidController }
        try play(action.card, by: action.actingSeat)
    }
}
