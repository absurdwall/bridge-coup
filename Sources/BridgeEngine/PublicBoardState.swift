import Foundation
import BridgeDomain

/// Public play tracked from declarer/dummy holdings. Defender holdings are never filled in.
public struct PublicBoardState: Sendable {
    public let id: UUID
    public let contract: Contract
    public let vulnerability: String
    public let scoring: String
    public let objective: String
    public let publicBackground: String?
    public private(set) var hands: [Seat: [Card]]
    public private(set) var events: [PlayEvent] = []
    public private(set) var currentTrick: [PlayEvent] = []
    public private(set) var completedTricks: [CompletedTrick] = []
    private var leader: Seat
    public var actingSeat: Seat? { events.count == 52 ? nil : (0..<currentTrick.count).reduce(leader) { seat, _ in seat.next } }

    public init(id: UUID, contract: Contract, vulnerability: String, scoring: String, objective: String,
                publicBackground: String?, initialHands: [Hand], events: [PlayEvent]) throws {
        guard initialHands.count == 2, Set(initialHands.map(\.seat)) == [contract.declarer, contract.declarer.partner],
              initialHands.allSatisfy({ $0.cards.count == 13 }), Set(initialHands.flatMap(\.cards)).count == 26,
              !vulnerability.isEmpty, !scoring.isEmpty, !objective.isEmpty else { throw DomainError.invalidDeal }
        self.id = id; self.contract = contract; self.vulnerability = vulnerability; self.scoring = scoring
        self.objective = objective; self.publicBackground = publicBackground
        hands = Dictionary(uniqueKeysWithValues: initialHands.map { ($0.seat, $0.cards) })
        leader = contract.declarer.next
        for event in events { try observe(event) }
    }

    public func legalCards() throws -> [Card] {
        guard let actingSeat else { throw DomainError.finished }
        guard let holding = hands[actingSeat] else { throw DomainError.invalidController }
        return BoardState.legalCards(in: holding, ledSuit: currentTrick.first?.card.suit)
    }

    public mutating func observe(_ event: PlayEvent) throws {
        guard let actingSeat else { throw DomainError.finished }
        guard event.sequence == events.count else { throw DomainError.staleSnapshot }
        guard event.seat == actingSeat else { throw DomainError.wrongTurn }
        guard !events.contains(where: { $0.card == event.card }) else { throw DomainError.cardNotHeld }
        if hands[event.seat] != nil {
            guard hands[event.seat]!.contains(event.card) else { throw DomainError.cardNotHeld }
            guard try legalCards().contains(event.card) else { throw DomainError.mustFollowSuit }
            hands[event.seat]!.removeAll { $0 == event.card }
        } else {
            guard !hands.values.contains(where: { $0.contains(event.card) }) else { throw DomainError.cardNotHeld }
            // A later observed card cannot contradict an earlier public failure to follow suit.
            for earlier in events where earlier.seat == event.seat {
                let lead = events[(earlier.sequence / 4) * 4].card.suit
                if earlier.card.suit != lead && event.card.suit == lead { throw DomainError.mustFollowSuit }
            }
        }
        events.append(event); currentTrick.append(event)
        if currentTrick.count == 4 {
            let winner = BoardState.winningPlay(in: currentTrick, trump: contract.strain.trump)!.seat
            completedTricks.append(.init(plays: currentTrick, winner: winner))
            leader = winner; currentTrick = []
        }
    }

    public func snapshot() throws -> DecisionSnapshot {
        guard let actingSeat else { throw DomainError.finished }
        guard hands[actingSeat] != nil else { throw DomainError.invalidController }
        let declarerTricks = completedTricks.filter { $0.winner == contract.declarer || $0.winner == contract.declarer.partner }.count
        return DecisionSnapshot(boardID: id, revision: events.count, controller: contract.declarer, actingSeat: actingSeat,
            contract: contract, vulnerability: vulnerability, scoring: scoring, objective: objective, publicBackground: publicBackground,
            hands: [contract.declarer, contract.declarer.partner].map { Hand(seat: $0, cards: hands[$0]!) },
            events: events, currentTrick: currentTrick, declarerTricks: declarerTricks,
            defenderTricks: completedTricks.count - declarerTricks, legalCards: try legalCards(),
            currentWinningPlay: BoardState.winningPlay(in: currentTrick, trump: contract.strain.trump), completedTricks: completedTricks)
    }
}
