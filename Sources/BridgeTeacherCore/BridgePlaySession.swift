import Foundation

public struct BridgePlayedCard: Codable, Equatable, Sendable {
    public let seat: Seat
    public let card: DoubleDummyCard
    public init(seat: Seat, card: DoubleDummyCard) { self.seat = seat; self.card = card }
}

public enum BridgePlayError: Error, LocalizedError, Equatable {
    case incomplete(Seat)
    case missingContract
    case invalidLead
    case wrongTurn
    case mustFollowSuit
    case collectFirst
    case notReadyToCollect
    case finished
    public var errorDescription: String? {
        switch self {
        case let .incomplete(seat): "\(seat.chineseName)需要四门明确、恰好 13 张牌；留空仍是未知。"
        case .missingContract: "请先选择有效的庄家和 1–7 阶定约。"
        case .invalidLead: "首攻必须是庄家左手方原始手牌中的一张牌，请先核对。"
        case .wrongTurn: "只能由当前行动家打出手中仍持有的牌。"
        case .mustFollowSuit: "手中仍有首引花色，必须跟牌。"
        case .collectFirst: "四张已出齐，请先收墩。"
        case .notReadyToCollect: "四张牌出齐后才能收墩。"
        case .finished: "整副 13 墩已完成，不能继续出牌。"
        }
    }
}

/// All play positions are derived values. The original entered board never changes.
public struct BridgePlaySession: Codable, Equatable, Sendable {
    public let originalBoardID: UUID
    public let originalVersion: Int
    public let declarerSeat: Seat
    public let contractLevel: Int
    public let strain: ContractStrain
    public private(set) var remainingHands: [Seat: [Suit: [CardRank]]]
    public private(set) var trickLeader: Seat
    public private(set) var currentTrick: [BridgePlayedCard] = []
    public private(set) var completedTricks: [[BridgePlayedCard]] = []
    public private(set) var northSouthTricks = 0
    public private(set) var eastWestTricks = 0
    public let suppliedOpeningLead: DoubleDummyCard?

    public var isComplete: Bool { completedTricks.count == 13 }
    public var awaitingCollection: Bool { currentTrick.count == 4 }
    public var actingSeat: Seat? {
        guard !isComplete, !awaitingCollection else { return nil }
        return Self.next(trickLeader, by: currentTrick.count)
    }
    public var declarerTricks: Int { Self.isNS(declarerSeat) ? northSouthTricks : eastWestTricks }
    public var actualContractDelta: Int? { isComplete ? declarerTricks - 6 - contractLevel : nil }
    public var legalCards: [DoubleDummyCard] {
        guard let seat = actingSeat else { return [] }
        let hand = remainingHands[seat] ?? [:]
        let suits: [Suit]
        if let led = currentTrick.first?.card.suit, !(hand[led] ?? []).isEmpty { suits = [led] }
        else { suits = Suit.allCases }
        return suits.flatMap { suit in (hand[suit] ?? []).map { DoubleDummyCard(suit: suit, rank: $0) } }
    }

    public init(original: OriginalHandFacts, draft: DeclarerPlanDraft) throws {
        let hands = try original.validatedHands()
        for seat in Seat.allCases {
            guard let hand = hands.first(where: { $0.seat == seat }),
                  hand.cardsBySuit.count == 4,
                  hand.cardsBySuit.values.reduce(0, { $0 + $1.count }) == 13 else {
                throw BridgePlayError.incomplete(seat)
            }
        }
        guard let declarer = draft.declarerSeat, let level = draft.contractLevel,
              (1...7).contains(level), let strain = draft.contractStrain else { throw BridgePlayError.missingContract }
        originalBoardID = original.boardID
        originalVersion = original.version
        declarerSeat = declarer
        contractLevel = level
        self.strain = strain
        remainingHands = Dictionary(uniqueKeysWithValues: hands.map { ($0.seat, $0.cardsBySuit) })
        trickLeader = Self.next(declarer)
        let normalizedLead = try OpeningLead.normalizedValue(from: draft.openingLead)
        if let normalizedLead, let lead = OpeningLead(input: normalizedLead) {
            let card = DoubleDummyCard(suit: lead.suit, rank: lead.rank)
            guard remainingHands[trickLeader]?[card.suit]?.contains(card.rank) == true else { throw BridgePlayError.invalidLead }
            suppliedOpeningLead = card
            try play(card, by: trickLeader)
        } else { suppliedOpeningLead = nil }
    }

    /// History and archive restoration share the original board's dependency boundary.
    public func isCompatible(with original: OriginalHandFacts, context: DeclarerPlanDraft) -> Bool {
        guard originalBoardID == original.boardID, originalVersion == original.version,
              original.decisionTimeConfirmed, context.decisionTimeConfirmed,
              declarerSeat == context.declarerSeat, contractLevel == context.contractLevel,
              strain == context.contractStrain else { return false }
        do {
            let normalized = try OpeningLead.normalizedValue(from: context.openingLead)
            let lead = normalized.flatMap(OpeningLead.init(input:)).map { DoubleDummyCard(suit: $0.suit, rank: $0.rank) }
            return lead == suppliedOpeningLead
        } catch { return false }
    }

    public mutating func play(_ card: DoubleDummyCard, by seat: Seat) throws {
        guard !isComplete else { throw BridgePlayError.finished }
        guard !awaitingCollection else { throw BridgePlayError.collectFirst }
        guard actingSeat == seat, remainingHands[seat]?[card.suit]?.contains(card.rank) == true else { throw BridgePlayError.wrongTurn }
        guard legalCards.contains(card) else { throw BridgePlayError.mustFollowSuit }
        remainingHands[seat]?[card.suit]?.removeAll { $0 == card.rank }
        currentTrick.append(BridgePlayedCard(seat: seat, card: card))
    }

    public mutating func collectTrick() throws {
        guard awaitingCollection else { throw BridgePlayError.notReadyToCollect }
        let led = currentTrick[0].card.suit
        let trump: Suit? = Suit(rawValue: strain.rawValue)
        let winner = currentTrick.max { lhs, rhs in
            func score(_ card: DoubleDummyCard) -> Int {
                let category = card.suit == trump ? 2 : (card.suit == led ? 1 : 0)
                return category * 100 + (14 - (CardRank.allCases.firstIndex(of: card.rank) ?? 12))
            }
            return score(lhs.card) < score(rhs.card)
        }!
        if Self.isNS(winner.seat) { northSouthTricks += 1 } else { eastWestTricks += 1 }
        trickLeader = winner.seat
        completedTricks.append(currentTrick)
        currentTrick = []
    }

    public func teachingDraft(from original: DeclarerPlanDraft) -> DeclarerPlanDraft {
        var draft = original
        draft.hands = Dictionary(uniqueKeysWithValues: Seat.allCases.map { seat in
            (seat, Dictionary(uniqueKeysWithValues: Suit.allCases.map { suit in
                let ranks = remainingHands[seat]?[suit] ?? []
                return (suit, ranks.isEmpty ? "-" : ranks.map(\.rawValue).joined())
            }))
        })
        let played = completedTricks.flatMap { $0 } + currentTrick
        draft.observedPlays = played
        let publicFacts = played.map { "\($0.seat.chineseName)：\($0.card.description)" }.joined(separator: "，")
        draft.openingLead = "" // Already-played lead is public history, never repeated as a pending lead.
        draft.otherDecisionTimeFacts += "\n自主推演当前局面：已收 \(completedTricks.count) 墩；NS \(northSouthTricks)，EW \(eastWestTricks)。\n已知出牌（按顺序）：\(publicFacts.isEmpty ? "尚未出牌" : publicFacts)\n当前行动家：\(actingSeat?.chineseName ?? (isComplete ? "全副结束" : "等待收墩"))。手牌为当前剩余牌，未勾选的暗手仍未知。"
        return draft
    }

    public func doubleDummyDraft() -> DoubleDummyVerificationDraft {
        var draft = DoubleDummyVerificationDraft()
        draft.trump = strain
        draft.trickLeader = trickLeader
        draft.currentTrickCards = currentTrick.map { $0.card.description }.joined(separator: " ")
        draft.hands = teachingDraft(from: DeclarerPlanDraft()).hands
        draft.declarerSeat = declarerSeat
        draft.contractLevel = contractLevel
        draft.declarerTricksAlreadyTaken = declarerTricks
        return draft
    }

    private static func next(_ seat: Seat, by count: Int = 1) -> Seat {
        Seat.allCases[(Seat.allCases.firstIndex(of: seat)! + count) % 4]
    }
    private static func isNS(_ seat: Seat) -> Bool { seat == .north || seat == .south }
}
