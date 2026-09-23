import Foundation

public enum Seat: String, CaseIterable, Codable, Hashable, Sendable {
    case north
    case east
    case south
    case west

    public var chineseName: String {
        switch self {
        case .north: "北家"
        case .east: "东家"
        case .south: "南家"
        case .west: "西家"
        }
    }
}

public enum Suit: String, CaseIterable, Codable, Hashable, Sendable {
    case spades
    case hearts
    case diamonds
    case clubs

    public var symbol: String {
        switch self {
        case .spades: "♠"
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        }
    }

    public var chineseName: String {
        switch self {
        case .spades: "黑桃"
        case .hearts: "红心"
        case .diamonds: "方块"
        case .clubs: "梅花"
        }
    }
}

public enum ContractStrain: String, CaseIterable, Codable, Hashable, Sendable {
    case spades
    case hearts
    case diamonds
    case clubs
    case noTrump

    public var symbol: String {
        switch self {
        case .spades: "♠"
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        case .noTrump: "NT"
        }
    }
}

public enum CardRank: String, CaseIterable, Codable, Hashable, Sendable {
    case ace = "A"
    case king = "K"
    case queen = "Q"
    case jack = "J"
    case ten = "10"
    case nine = "9"
    case eight = "8"
    case seven = "7"
    case six = "6"
    case five = "5"
    case four = "4"
    case three = "3"
    case two = "2"
}

public struct VisibleHand: Equatable, Sendable {
    public let seat: Seat
    /// An absent suit means unknown. An empty array means the user confirmed a void.
    public let cardsBySuit: [Suit: [CardRank]]

    public init(seat: Seat, cardsBySuit: [Suit: [CardRank]]) {
        self.seat = seat
        self.cardsBySuit = cardsBySuit
    }
}

public struct DeclarerPlanDraft: Equatable, Sendable {
    public var declarerSeat: Seat = .south
    public var contractLevel: Int?
    public var contractStrain: ContractStrain?
    public var openingLead = ""
    public var otherDecisionTimeFacts = ""
    public var question = "请为当前定约给出做庄计划。"
    /// Each entered holding contains cards known to have been visible at the decision point.
    /// Blank fields remain unknown; a dash explicitly records a known void.
    public var hands: [Seat: [Suit: String]] = [:]

    public init() {}
}

public struct DeclarerPlanRequest: Equatable, Sendable {
    public let declarerSeat: Seat
    public let contractLevel: Int
    public let contractStrain: ContractStrain
    public let openingLead: String?
    public let otherDecisionTimeFacts: String?
    public let question: String
    public let scoring: String
    public let visibleHands: [VisibleHand]
    public let unknownSeats: [Seat]
    public let prompt: String

    public init(
        declarerSeat: Seat,
        contractLevel: Int,
        contractStrain: ContractStrain,
        openingLead: String?,
        otherDecisionTimeFacts: String?,
        question: String,
        scoring: String,
        visibleHands: [VisibleHand],
        unknownSeats: [Seat],
        prompt: String
    ) {
        self.declarerSeat = declarerSeat
        self.contractLevel = contractLevel
        self.contractStrain = contractStrain
        self.openingLead = openingLead
        self.otherDecisionTimeFacts = otherDecisionTimeFacts
        self.question = question
        self.scoring = scoring
        self.visibleHands = visibleHands
        self.unknownSeats = unknownSeats
        self.prompt = prompt
    }
}

public enum DeclarerPlanInputError: Error, Equatable, LocalizedError, Sendable {
    case missingContract
    case invalidContractLevel
    case noDeclarerCards
    case emptyQuestion
    case invalidHolding(seat: Seat, suit: Suit, value: String)
    case duplicateCard(String)
    case tooManyKnownCards(seat: Seat, count: Int)

    public var errorDescription: String? {
        switch self {
        case .missingContract:
            "请选择定约阶数和花色。"
        case .invalidContractLevel:
            "定约阶数必须是 1 到 7。"
        case .noDeclarerCards:
            "请至少录入庄家一张当时可见的牌；空白手牌会保持未知。"
        case .emptyQuestion:
            "请写下当前想复盘的问题。"
        case let .invalidHolding(seat, suit, value):
            "\(seat.chineseName)\(suit.symbol) 输入“\(value)”无法识别。请使用 A K Q J 10 及 2 到 9；“-”表示已确认缺门。"
        case let .duplicateCard(card):
            "\(card) 出现在多个可见位置，请先核对手牌。"
        case let .tooManyKnownCards(seat, count):
            "\(seat.chineseName) 已录入 \(count) 张已知牌，超过一手的 13 张。"
        }
    }
}

public enum DeclarerPlanRequestBuilder {
    public static func build(from draft: DeclarerPlanDraft) throws -> DeclarerPlanRequest {
        guard let level = draft.contractLevel, let strain = draft.contractStrain else {
            throw DeclarerPlanInputError.missingContract
        }
        guard (1...7).contains(level) else {
            throw DeclarerPlanInputError.invalidContractLevel
        }
        let question = draft.question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else {
            throw DeclarerPlanInputError.emptyQuestion
        }

        let visibleHands = try visibleHands(in: draft)
        guard let declarerHand = visibleHands.first(where: { $0.seat == draft.declarerSeat }),
              declarerHand.cardsBySuit.values.contains(where: { !$0.isEmpty }) else {
            throw DeclarerPlanInputError.noDeclarerCards
        }

        let unknownSeats = Seat.allCases.filter { seat in
            !visibleHands.contains(where: { $0.seat == seat })
        }
        let otherFacts = draft.otherDecisionTimeFacts.trimmingCharacters(in: .whitespacesAndNewlines)
        let lead = draft.openingLead.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = makePrompt(
            draft: draft,
            level: level,
            strain: strain,
            question: question,
            otherFacts: otherFacts,
            lead: lead,
            visibleHands: visibleHands
        )

        return DeclarerPlanRequest(
            declarerSeat: draft.declarerSeat,
            contractLevel: level,
            contractStrain: strain,
            openingLead: lead.isEmpty ? nil : lead,
            otherDecisionTimeFacts: otherFacts.isEmpty ? nil : otherFacts,
            question: question,
            scoring: "IMP",
            visibleHands: visibleHands,
            unknownSeats: unknownSeats,
            prompt: prompt
        )
    }

    public static func visibleHands(in draft: DeclarerPlanDraft) throws -> [VisibleHand] {
        var knownCards = Set<String>()
        var visibleHands: [VisibleHand] = []

        for seat in Seat.allCases {
            let typedHoldings = draft.hands[seat] ?? [:]
            var cardsBySuit: [Suit: [CardRank]] = [:]
            var cardCount = 0

            for suit in Suit.allCases {
                guard let rawHolding = typedHoldings[suit] else { continue }
                switch parse(rawHolding) {
                case .unknown:
                    continue
                case let .known(ranks):
                    cardsBySuit[suit] = ranks
                    cardCount += ranks.count
                    for rank in ranks {
                        let card = "\(suit.symbol)\(rank.rawValue)"
                        guard knownCards.insert(card).inserted else {
                            throw DeclarerPlanInputError.duplicateCard(card)
                        }
                    }
                case .invalid:
                    throw DeclarerPlanInputError.invalidHolding(seat: seat, suit: suit, value: rawHolding)
                }
            }

            guard cardCount <= 13 else {
                throw DeclarerPlanInputError.tooManyKnownCards(seat: seat, count: cardCount)
            }
            if !cardsBySuit.isEmpty {
                visibleHands.append(VisibleHand(seat: seat, cardsBySuit: cardsBySuit))
            }
        }
        return visibleHands
    }

    private static func makePrompt(
        draft: DeclarerPlanDraft,
        level: Int,
        strain: ContractStrain,
        question: String,
        otherFacts: String,
        lead: String,
        visibleHands: [VisibleHand]
    ) -> String {
        let handBySeat = Dictionary(uniqueKeysWithValues: visibleHands.map { ($0.seat, $0) })
        let handLines = Seat.allCases.map { seat -> String in
            guard let hand = handBySeat[seat] else {
                return "\(seat.chineseName)：未知"
            }
            let suitLines = Suit.allCases.map { suit -> String in
                guard let cards = hand.cardsBySuit[suit] else {
                    return "\(suit.symbol)未知"
                }
                if cards.isEmpty {
                    return "\(suit.symbol)缺门（已确认）"
                }
                return "\(suit.symbol)\(cards.map(\.rawValue).joined())"
            }
            return "\(seat.chineseName)：" + suitLines.joined(separator: "  ")
        }

        var sections = [
            "你是一位有经验的桥牌做庄教练。用简体中文回答，默认牌手理解基础术语，按 IMP 背景讨论成约风险与争取超墩的取舍。",
            "请基于下列决策时信息制定一份具体做庄计划。只可使用明确列出的可见牌和事实；标为未知的内容必须保持未知，不推测为已知。信息不足时请指出关键缺口并给出有条件的路线。",
            "庄家：\(draft.declarerSeat.chineseName)",
            "定约：\(level)\(strain.symbol)",
            "计分：IMP",
            "当时可见手牌：\n\(handLines.joined(separator: "\n"))",
            "问题：\(question)"
        ]
        if !lead.isEmpty {
            sections.append("首攻（用户提供）：\(lead)")
        }
        if !otherFacts.isEmpty {
            sections.append("其他决策时事实（用户提供）：\(otherFacts)")
        }
        return sections.joined(separator: "\n\n")
    }

    private enum ParsedHolding {
        case unknown
        case known([CardRank])
        case invalid
    }

    private static func parse(_ raw: String) -> ParsedHolding {
        let normalized = raw.uppercased().filter { character in
            !character.isWhitespace && character != "," && character != ";"
        }
        guard !normalized.isEmpty else { return .unknown }
        if normalized == "-" || normalized == "—" || normalized == "VOID" {
            return .known([])
        }

        let characters = Array(normalized)
        var ranks: [CardRank] = []
        var seen = Set<CardRank>()
        var index = 0

        while index < characters.count {
            let rank: CardRank
            let character = characters[index]
            if character == "1", index + 1 < characters.count, characters[index + 1] == "0" {
                rank = .ten
                index += 2
            } else {
                let symbol = String(character)
                guard let parsed = CardRank.allCases.first(where: { $0.rawValue == symbol || ($0 == .ten && symbol == "T") }) else {
                    return .invalid
                }
                rank = parsed
                index += 1
            }
            guard seen.insert(rank).inserted else { return .invalid }
            ranks.append(rank)
        }

        let rankOrder = Dictionary(uniqueKeysWithValues: CardRank.allCases.enumerated().map { ($1, $0) })
        return .known(ranks.sorted { rankOrder[$0, default: 0] < rankOrder[$1, default: 0] })
    }
}
