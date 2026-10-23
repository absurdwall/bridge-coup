import Foundation
import BridgeDomain

public struct NeedsInputState: Codable, Sendable {
    public let session: DecisionSession
    public let snapshot: DecisionSnapshot
    public let priorPlan: PlanAssociation?
    public let detail: String
    public let waitingSince: Date
    public let semanticRounds: Int
}

extension ExpertSession {
    static func invalidPositionFacts(_ snapshot: DecisionSnapshot) -> String? {
        guard snapshot.revision == snapshot.events.count else { return "Position revision conflicts with actual public plays." }
        let required: Set<Seat> = [snapshot.controller, snapshot.controller.partner]
        let seats = snapshot.hands.map(\.seat)
        let held = snapshot.hands.flatMap(\.cards)
        guard Set(seats).isSubset(of: required), Set(seats).count == seats.count,
              Set(held).count == held.count, Set(snapshot.events.map(\.card)).count == snapshot.events.count,
              Set(held).isDisjoint(with: snapshot.events.map(\.card)),
              snapshot.events.enumerated().allSatisfy({ $0.offset == $0.element.sequence }) else {
            return "Public holdings/history conflict or exceed the authorized perspective."
        }
        if let completed = snapshot.completedTricks,
           (completed.contains(where: { $0.plays.count != 4 }) || completed.flatMap(\.plays) + snapshot.currentTrick != snapshot.events) {
            return "Serialized trick history conflicts with actual public plays."
        }
        if let winner = snapshot.currentWinningPlay, !snapshot.currentTrick.contains(winner) { return "Current winner is not an actual current play." }
        if let acting = snapshot.hands.first(where: { $0.seat == snapshot.actingSeat }),
           !Set(snapshot.legalCards).isSubset(of: acting.cards) { return "Legal choices conflict with the acting hand." }
        for hand in snapshot.hands {
            if hand.cards.count + snapshot.events.filter({ $0.seat == hand.seat }).count > 13 { return "Authorized hand has too many cards." }
        }
        return nil
    }

    /// Completion may add missing public facts at the same frozen position, never rewrite them.
    static func completes(_ original: DecisionSnapshot, with supplied: DecisionSnapshot) -> Bool {
        original.boardID == supplied.boardID && original.revision == supplied.revision &&
        original.controller == supplied.controller && original.actingSeat == supplied.actingSeat &&
        original.contract == supplied.contract && original.vulnerability == supplied.vulnerability &&
        original.scoring == supplied.scoring && original.objective == supplied.objective &&
        original.publicBackground == supplied.publicBackground && original.events == supplied.events &&
        original.currentTrick == supplied.currentTrick && original.declarerTricks == supplied.declarerTricks &&
        original.defenderTricks == supplied.defenderTricks &&
        original.hands.allSatisfy { known in supplied.hands.contains { $0.seat == known.seat && Set(known.cards).isSubset(of: $0.cards) } } &&
        (original.completedTricks == nil || original.completedTricks == supplied.completedTricks) &&
        (original.currentWinningPlay == nil || original.currentWinningPlay == supplied.currentWinningPlay) &&
        (original.legalCards.isEmpty || original.legalCards == supplied.legalCards)
    }
}
