import Foundation

public enum TeachingMode: String, CaseIterable, Hashable, Sendable {
    case declarerPlan
    case keyPlayAnalysis

    public var title: String {
        switch self {
        case .declarerPlan: "做庄计划"
        case .keyPlayAnalysis: "分析这一步"
        }
    }
}

public enum CurrentTrickState: String, CaseIterable, Hashable, Sendable {
    case unknown
    case noCardsPlayed
    case cardsRecorded

    public var title: String {
        switch self {
        case .unknown: "尚未确认"
        case .noCardsPlayed: "尚无人出牌"
        case .cardsRecorded: "本墩已有出牌"
        }
    }
}

public struct KeyPlayCard: Equatable, Hashable, Sendable, CustomStringConvertible {
    public let suit: Suit
    public let rank: CardRank

    public init(suit: Suit, rank: CardRank) {
        self.suit = suit
        self.rank = rank
    }

    public var description: String { "\(suit.symbol)\(rank.rawValue)" }
}

public struct KeyPlayAnalysisDraft: Equatable, Sendable {
    public var analysisPoint = ""
    public var actingSeat: Seat? = nil
    public var currentTrickState: CurrentTrickState = .unknown
    /// Enter current-trick cards in play order, separated by commas, such as “♥K, ♥3, ♥5”.
    public var currentTrickCards = ""
    public var relevantPlayHistory = ""
    /// Optional cards the user wants compared, such as “♥A, ♥4, ♥8”.
    public var candidatePlays = ""
    public var question = "请分析当前这一出牌节点。"

    public init() {}
}

public enum KeyPlayAnalysisInputError: Error, Equatable, LocalizedError, Sendable {
    case emptyQuestion
    case invalidCurrentTrick(String)
    case trickCardsEnteredWithoutRecordingState
    case duplicateCurrentTrickCard(String)
    case currentTrickCardStillVisible(String)
    case invalidCandidate(String)
    case duplicateCandidate(String)
    case candidateActionSeatUnconfirmed
    case candidateHandNotVisible(String)
    case candidateNotInVisibleHand(card: String, seat: String)
    case candidateTrickStateUnknown
    case cannotVerifyFollowSuit(card: String, ledSuit: String)
    case mustFollowSuit(card: String, ledSuit: String)

    public var errorDescription: String? {
        switch self {
        case .emptyQuestion:
            "请写下当前想比较的关键出牌问题。"
        case let .invalidCurrentTrick(value):
            "当前墩输入“\(value)”无法识别。请按出牌先后，用逗号分隔，例如 ♥K, ♥3, ♥5。"
        case .trickCardsEnteredWithoutRecordingState:
            "你已录入当前墩牌张，请将当前墩状态设为“本墩已有出牌”后再分析。"
        case let .duplicateCurrentTrickCard(card):
            "当前墩中重复录入了 \(card)，请核对出牌顺序。"
        case let .currentTrickCardStillVisible(card):
            "当前墩已出的 \(card) 仍录在剩余可见手牌中，请先修正牌面。"
        case let .invalidCandidate(value):
            "候选出牌“\(value)”无法识别。请按花色和牌点录入，例如 ♠A 或 ♥10。"
        case let .duplicateCandidate(card):
            "候选出牌中重复录入了 \(card)。"
        case .candidateActionSeatUnconfirmed:
            "请先确认轮到谁行动，再核对候选牌是否合法。"
        case let .candidateHandNotVisible(seat):
            "尚未录入\(seat)当时可见的剩余手牌，无法核对候选牌。"
        case let .candidateNotInVisibleHand(card, seat):
            "候选牌 \(card) 不在已录入的\(seat)剩余可见手牌中。"
        case .candidateTrickStateUnknown:
            "当前墩状态尚未确认，暂时无法验证候选牌是否合法。"
        case let .cannotVerifyFollowSuit(card, ledSuit):
            "已知首引花色为 \(ledSuit)，但行动者的该花色手牌未知，无法确认 \(card) 是否可以垫出。"
        case let .mustFollowSuit(card, ledSuit):
            "当前墩首引 \(ledSuit)，行动者仍有该花色，不能把 \(card) 作为合法候选。"
        }
    }
}

public enum KeyPlayAnalysisRequestBuilder {
    public static func build(
        from review: DeclarerPlanDraft,
        node: KeyPlayAnalysisDraft
    ) throws -> DeclarerPlanRequest {
        guard let level = review.contractLevel, let strain = review.contractStrain else {
            throw DeclarerPlanInputError.missingContract
        }
        guard (1...7).contains(level) else {
            throw DeclarerPlanInputError.invalidContractLevel
        }
        let question = node.question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else {
            throw KeyPlayAnalysisInputError.emptyQuestion
        }

        let visibleHands = try DeclarerPlanRequestBuilder.visibleHands(in: review)
        let unknownSeats = Seat.allCases.filter { seat in
            !visibleHands.contains(where: { $0.seat == seat })
        }
        let currentTrick = try parseCurrentTrick(node)
        for card in currentTrick where visibleHands.contains(where: { $0.cardsBySuit[card.suit]?.contains(card.rank) == true }) {
            throw KeyPlayAnalysisInputError.currentTrickCardStillVisible(card.description)
        }
        let candidates = try parseCandidates(node.candidatePlays)
        try validateCandidates(
            candidates,
            node: node,
            currentTrick: currentTrick,
            visibleHands: visibleHands
        )
        let lead = review.openingLead.trimmingCharacters(in: .whitespacesAndNewlines)
        let otherFacts = review.otherDecisionTimeFacts.trimmingCharacters(in: .whitespacesAndNewlines)
        let history = node.relevantPlayHistory.trimmingCharacters(in: .whitespacesAndNewlines)
        let point = node.analysisPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = makePrompt(
            review: review,
            node: node,
            level: level,
            strain: strain,
            question: question,
            point: point,
            lead: lead,
            otherFacts: otherFacts,
            history: history,
            currentTrick: currentTrick,
            candidates: candidates,
            visibleHands: visibleHands,
            unknownSeats: unknownSeats
        )

        return DeclarerPlanRequest(
            declarerSeat: review.declarerSeat,
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

    private static func parseCurrentTrick(_ node: KeyPlayAnalysisDraft) throws -> [KeyPlayCard] {
        let rawCards = node.currentTrickCards.trimmingCharacters(in: .whitespacesAndNewlines)
        guard node.currentTrickState == .cardsRecorded else {
            guard rawCards.isEmpty else {
                throw KeyPlayAnalysisInputError.trickCardsEnteredWithoutRecordingState
            }
            return []
        }

        let values = rawCards
            .components(separatedBy: CharacterSet(charactersIn: ",，、;；\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard (1...3).contains(values.count) else {
            throw KeyPlayAnalysisInputError.invalidCurrentTrick(node.currentTrickCards)
        }

        var cards: [KeyPlayCard] = []
        var seen = Set<KeyPlayCard>()
        for value in values {
            guard let card = parseCard(value) else {
                throw KeyPlayAnalysisInputError.invalidCurrentTrick(value)
            }
            guard seen.insert(card).inserted else {
                throw KeyPlayAnalysisInputError.duplicateCurrentTrickCard(card.description)
            }
            cards.append(card)
        }

        return cards
    }

    private static func parseCard(_ rawValue: String) -> KeyPlayCard? {
        let value = rawValue.filter { !$0.isWhitespace }
        guard let suit = Suit.allCases.first(where: { value.hasPrefix($0.symbol) }) else { return nil }
        let rankValue = String(value.dropFirst(suit.symbol.count)).uppercased()
        guard let rank = CardRank.allCases.first(where: { $0.rawValue == rankValue || ($0 == .ten && rankValue == "T") }) else {
            return nil
        }
        return KeyPlayCard(suit: suit, rank: rank)
    }

    private static func parseCandidates(_ rawValue: String) throws -> [KeyPlayCard] {
        let values = rawValue
            .components(separatedBy: CharacterSet(charactersIn: ",，、;；\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var candidates: [KeyPlayCard] = []
        var seen = Set<KeyPlayCard>()
        for value in values {
            guard let card = parseCard(value) else {
                throw KeyPlayAnalysisInputError.invalidCandidate(value)
            }
            guard seen.insert(card).inserted else {
                throw KeyPlayAnalysisInputError.duplicateCandidate(card.description)
            }
            candidates.append(card)
        }
        return candidates
    }

    private static func validateCandidates(
        _ candidates: [KeyPlayCard],
        node: KeyPlayAnalysisDraft,
        currentTrick: [KeyPlayCard],
        visibleHands: [VisibleHand]
    ) throws {
        guard !candidates.isEmpty else { return }
        guard let actingSeat = node.actingSeat else {
            throw KeyPlayAnalysisInputError.candidateActionSeatUnconfirmed
        }
        guard let actingHand = visibleHands.first(where: { $0.seat == actingSeat }) else {
            throw KeyPlayAnalysisInputError.candidateHandNotVisible(actingSeat.chineseName)
        }

        let ledSuit: Suit?
        switch node.currentTrickState {
        case .unknown:
            throw KeyPlayAnalysisInputError.candidateTrickStateUnknown
        case .noCardsPlayed:
            ledSuit = nil
        case .cardsRecorded:
            ledSuit = currentTrick.first?.suit
        }

        for card in candidates {
            guard actingHand.cardsBySuit[card.suit]?.contains(card.rank) == true else {
                throw KeyPlayAnalysisInputError.candidateNotInVisibleHand(
                    card: card.description,
                    seat: actingSeat.chineseName
                )
            }
            guard let ledSuit, card.suit != ledSuit else { continue }
            guard let ledSuitHolding = actingHand.cardsBySuit[ledSuit] else {
                throw KeyPlayAnalysisInputError.cannotVerifyFollowSuit(
                    card: card.description,
                    ledSuit: ledSuit.symbol
                )
            }
            guard ledSuitHolding.isEmpty else {
                throw KeyPlayAnalysisInputError.mustFollowSuit(
                    card: card.description,
                    ledSuit: ledSuit.symbol
                )
            }
        }
    }

    private static func makePrompt(
        review: DeclarerPlanDraft,
        node: KeyPlayAnalysisDraft,
        level: Int,
        strain: ContractStrain,
        question: String,
        point: String,
        lead: String,
        otherFacts: String,
        history: String,
        currentTrick: [KeyPlayCard],
        candidates: [KeyPlayCard],
        visibleHands: [VisibleHand],
        unknownSeats: [Seat]
    ) -> String {
        let handBySeat = Dictionary(uniqueKeysWithValues: visibleHands.map { ($0.seat, $0) })
        let handLines = Seat.allCases.map { seat -> String in
            guard let hand = handBySeat[seat] else { return "\(seat.chineseName)：未知" }
            let suitLines = Suit.allCases.map { suit -> String in
                guard let cards = hand.cardsBySuit[suit] else { return "\(suit.symbol)未知" }
                if cards.isEmpty { return "\(suit.symbol)缺门（已确认）" }
                return "\(suit.symbol)\(cards.map(\.rawValue).joined())"
            }
            return "\(seat.chineseName)：" + suitLines.joined(separator: "  ")
        }

        let pointText = point.isEmpty ? "未提供；如影响比较，请先询问分析时点。" : point
        let actorText = node.actingSeat?.chineseName ?? "未确认；如影响判断，请先询问轮到谁行动。"
        let trickSection: String
        switch node.currentTrickState {
        case .unknown:
            trickSection = "当前墩状态未确认；不得假定本墩尚无人出牌。"
        case .noCardsPlayed:
            trickSection = "已确认当前墩尚无人出牌。"
        case .cardsRecorded:
            let cards = currentTrick.map(\.description).joined(separator: ", ")
            trickSection = "本墩已出牌（按先后）：\(cards)"
        }
        let historyText = history.isEmpty
            ? "未提供；不得把未提供的出牌过程当作事实。"
            : history
        let candidateText = candidates.isEmpty
            ? "用户未列出候选牌；不得臆造行动者手中未确认的牌。"
            : candidates.map(\.description).joined(separator: "、")
        let unknownText = unknownSeats.isEmpty ? "无" : unknownSeats.map(\.chineseName).joined(separator: "、")

        var sections = [
            "你是一位有经验的桥牌牌手教练。用简体中文、按 IMP 背景分析一个具体关键出牌节点。",
            "模式：关键出牌节点分析；只比较当前这一步的推荐与有意义的替代路线，不要给整副牌泛泛的做庄计划。只使用下列决策时可见手牌、已确认节点信息和用户提供的历史。未知保持未知；不得把未提供的出牌过程当作事实。",
            "分析时点：\(pointText)",
            "定约：\(level)\(strain.symbol)，庄家：\(review.declarerSeat.chineseName)",
            "当前行动座位：\(actorText)",
            "计分背景：IMP",
            "决策时剩余可见手牌：\n\(handLines.joined(separator: "\n"))",
            "未确认的座位：\(unknownText)",
            "当前墩：\(trickSection)",
            "用户要求比较的候选牌：\(candidateText)",
            "问题：\(question)",
            "分析要求：围绕本节点实际可选的牌，逐项解释推荐路线和重要替代路线的目的、风险与后续交通影响；只有在本局确实相关时才解释忍让、进手或顺序控制。候选牌必须来自行动者已确认的剩余手牌；若手牌、当前墩或历史不足以确认合法性，先明确说明并提出具体补充问题。若缺少会改变选择的信息，不能代替用户补写历史。分布推断需说明假设和依据；未经计算不得声称已验证的精确成功率。当前请求是教学推理，没有 DDS 核验，不声称已验证墩数。"
        ]
        if !lead.isEmpty { sections.append("已知首攻（用户提供）：\(lead)") }
        if !otherFacts.isEmpty { sections.append("其他确认的决策时事实（用户提供）：\(otherFacts)") }
        sections.append("此前相关出牌历史（用户提供）：\(historyText)")
        return sections.joined(separator: "\n\n")
    }
}
