import Foundation
import BridgeDomain

/// One public board from the first call. Only actually exposed holdings enter this state.
public struct ContinuousBoardState: Sendable {
    public let id: UUID
    public let userSeat: Seat
    public let dealer: Seat
    public let vulnerability: String
    public let scoring: String
    public let objective: String
    public let agreements: String
    public private(set) var revision = 0
    public private(set) var auction: [AuctionEvent] = []
    public private(set) var contract: Contract?
    public private(set) var contractConfirmed = false
    public private(set) var passedOut = false
    public private(set) var events: [PlayEvent] = []
    public private(set) var hands: [Seat: [Card]] = [:]
    public private(set) var currentTrick: [PlayEvent] = []
    public private(set) var completedTricks: [CompletedTrick] = []
    private var initialHands: [Seat: [Card]] = [:]
    private var leader: Seat?
    private var auctionEnded = false

    public init(id: UUID, userSeat: Seat, dealer: Seat, vulnerability: String, scoring: String,
                objective: String, agreements: String, initialHand: Hand, auction: [AuctionEvent] = [],
                events: [PlayEvent] = [], revealedHands: [Hand] = [], confirmedContract: Contract? = nil) throws {
        guard initialHand.seat == userSeat, initialHand.cards.count == 13,
              Set(initialHand.cards).count == 13,
              !vulnerability.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !scoring.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw DomainError.invalidDeal }
        self.id = id; self.userSeat = userSeat; self.dealer = dealer; self.vulnerability = vulnerability
        self.scoring = scoring; self.objective = objective; self.agreements = agreements
        hands[userSeat] = initialHand.cards; initialHands[userSeat] = initialHand.cards
        for event in auction { try observeCall(event) }
        if let confirmedContract { try confirmContract(confirmedContract) }
        guard revealedHands.isEmpty || !events.isEmpty else { throw ContinuousBoardError.invalidExposure }
        for event in events {
            try observePlay(event)
            if event.sequence == 0 { for hand in revealedHands { try reveal(hand) } }
        }
    }

    public var phase: BoardPhase {
        if passedOut || events.count == 52 { return .finished }
        guard let contract else { return .bidding }
        if events.isEmpty { return .openingLead }
        return owns(contract.declarer) ? .declarer : .defense
    }

    public var controller: Seat {
        if contractConfirmed, let contract, owns(contract.declarer) { return contract.declarer }
        return userSeat
    }

    public var actingSeat: Seat? {
        if phase == .finished { return nil }
        if !auctionEnded { return (0..<auction.count % 4).reduce(dealer) { seat, _ in seat.next } }
        guard contractConfirmed, let leader else { return nil }
        return (0..<currentTrick.count).reduce(leader) { seat, _ in seat.next }
    }

    public func isControlled(_ seat: Seat) -> Bool {
        guard contractConfirmed, let contract else { return seat == userSeat }
        return owns(contract.declarer) ? owns(seat) : seat == userSeat
    }

    public func legalCalls() -> [AuctionCall] {
        guard !auctionEnded, let actingSeat else { return [] }
        var calls = ["P"]
        let latestBid = auction.last { $0.call.bidIndex != nil }
        let afterBid = latestBid.map { Array(auction.dropFirst($0.sequence + 1)) } ?? []
        let doubled = afterBid.contains { $0.call.description == "X" }
        let redoubled = afterBid.contains { $0.call.description == "XX" }
        if let latestBid {
            let sameSide = actingSeat == latestBid.seat || actingSeat == latestBid.seat.partner
            if !sameSide && !doubled { calls.append("X") }
            if sameSide && doubled && !redoubled { calls.append("XX") }
        }
        calls += AuctionCall.bids.dropFirst((latestBid?.call.bidIndex ?? -1) + 1)
        return calls.compactMap { try? AuctionCall($0) }
    }

    public mutating func observeCall(_ event: AuctionEvent) throws {
        guard !auctionEnded else { throw ContinuousBoardError.auctionComplete }
        guard event.sequence == auction.count else { throw DomainError.staleSnapshot }
        guard event.seat == actingSeat else { throw DomainError.wrongTurn }
        guard legalCalls().contains(event.call) else { throw ContinuousBoardError.illegalCall }
        auction.append(event); revision += 1
        let trailingPasses = auction.reversed().prefix { $0.call.description == "P" }.count
        guard let lastBid = auction.last(where: { $0.call.bidIndex != nil }) else {
            if trailingPasses == 4 { passedOut = true; auctionEnded = true }
            return
        }
        if trailingPasses == 3 {
            let firstBidder = auction.first { event in
                event.call.strain == lastBid.call.strain && (event.seat == lastBid.seat || event.seat == lastBid.seat.partner)
            }!.seat
            let doubles = auction.dropFirst(lastBid.sequence + 1).map(\.call.description)
            let doubling: Contract.Doubling = doubles.contains("XX") ? .redoubled : doubles.contains("X") ? .doubled : .undoubled
            contract = try Contract(level: lastBid.call.level!, strain: lastBid.call.strain!, declarer: firstBidder, doubling: doubling)
            auctionEnded = true
        }
    }

    /// Platform agreement is an actual event, never inferred from an Expert proposal.
    public mutating func confirmContract(_ observed: Contract) throws {
        guard auctionEnded, !passedOut, observed == contract else { throw ContinuousBoardError.contractMismatch }
        guard !contractConfirmed else { throw DomainError.staleSnapshot }
        contractConfirmed = true; leader = observed.declarer.next; revision += 1
    }

    /// Supply the actually exposed complete original holding, retaining any plays for audit.
    public mutating func reveal(_ hand: Hand) throws {
        guard contractConfirmed, let contract, !events.isEmpty,
              hand.cards.count == 13, Set(hand.cards).count == 13 else { throw ContinuousBoardError.invalidExposure }
        let permitted = hand.seat == contract.declarer.partner || (owns(contract.declarer) && hand.seat == contract.declarer)
        guard permitted, initialHands[hand.seat] == nil else { throw ContinuousBoardError.invalidExposure }
        let others = initialHands.filter { $0.key != hand.seat }.values.flatMap { $0 }
        guard Set(others).isDisjoint(with: hand.cards),
              events.filter({ $0.seat != hand.seat }).allSatisfy({ !hand.cards.contains($0.card) }),
              events.filter({ $0.seat == hand.seat }).allSatisfy({ hand.cards.contains($0.card) }) else { throw DomainError.invalidDeal }
        var holding = hand.cards
        for event in events where event.seat == hand.seat {
            let lead = events[(event.sequence / 4) * 4].card.suit
            guard BoardState.legalCards(in: holding, ledSuit: lead).contains(event.card) else { throw DomainError.mustFollowSuit }
            holding.removeAll { $0 == event.card }
        }
        initialHands[hand.seat] = hand.cards; hands[hand.seat] = holding; revision += 1
    }

    public func legalCards() -> [Card] {
        guard contractConfirmed, let actingSeat, let holding = hands[actingSeat] else { return [] }
        if !events.isEmpty, let contract {
            guard hands[contract.declarer.partner] != nil else { return [] }
            if owns(contract.declarer) && hands[contract.declarer] == nil { return [] }
        }
        return BoardState.legalCards(in: holding, ledSuit: currentTrick.first?.card.suit)
    }

    public mutating func observePlay(_ event: PlayEvent) throws {
        guard phase != .finished else { throw DomainError.finished }
        guard contractConfirmed, let contract else { throw ContinuousBoardError.contractNotConfirmed }
        guard event.sequence == events.count else { throw DomainError.staleSnapshot }
        guard event.seat == actingSeat else { throw DomainError.wrongTurn }
        guard !events.contains(where: { $0.card == event.card }) else { throw DomainError.cardNotHeld }
        // Once the opening lead is observed, dummy's exposure must be supplied before play continues.
        if !events.isEmpty && hands[contract.declarer.partner] == nil { throw ContinuousBoardError.missingVisibleHand }
        if isControlled(event.seat) {
            guard hands[event.seat] != nil else { throw ContinuousBoardError.missingVisibleHand }
            if owns(contract.declarer) && hands[contract.declarer] == nil { throw ContinuousBoardError.missingVisibleHand }
        }
        if let holding = hands[event.seat] {
            guard holding.contains(event.card) else { throw DomainError.cardNotHeld }
            guard legalCards().contains(event.card) else { throw DomainError.mustFollowSuit }
        } else {
            guard !hands.values.contains(where: { $0.contains(event.card) }) else { throw DomainError.cardNotHeld }
            for earlier in events where earlier.seat == event.seat {
                let lead = events[(earlier.sequence / 4) * 4].card.suit
                if earlier.card.suit != lead && event.card.suit == lead { throw DomainError.mustFollowSuit }
            }
        }
        hands[event.seat]?.removeAll { $0 == event.card }
        events.append(event); currentTrick.append(event); revision += 1
        if currentTrick.count == 4 {
            let winner = BoardState.winningPlay(in: currentTrick, trump: contract.strain.trump)!.seat
            completedTricks.append(.init(plays: currentTrick, winner: winner))
            leader = winner; currentTrick = []
        }
    }

    public func snapshot() throws -> ContinuousSnapshot {
        let declarerTricks = completedTricks.filter { trick in
            guard let contract else { return false }
            return trick.winner == contract.declarer || trick.winner == contract.declarer.partner
        }.count
        return ContinuousSnapshot(boardID: id, revision: revision, phase: phase, userSeat: userSeat, controller: controller,
            actingSeat: actingSeat, contract: contract, contractConfirmed: contractConfirmed, dealer: dealer,
            vulnerability: vulnerability, scoring: scoring, objective: objective, agreements: agreements, auction: auction,
            hands: Seat.allCases.compactMap { seat in hands[seat].map { Hand(seat: seat, cards: $0) } },
            events: events, currentTrick: currentTrick, completedTricks: completedTricks,
            currentWinningPlay: BoardState.winningPlay(in: currentTrick, trump: contract?.strain.trump),
            legalCalls: legalCalls(), legalCards: legalCards(), declarerTricks: declarerTricks,
            defenderTricks: completedTricks.count - declarerTricks)
    }

    private func owns(_ seat: Seat) -> Bool { seat == userSeat || seat == userSeat.partner }
}
