import Combine
import Foundation

public struct DoubleDummyCard: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let suit: Suit
    public let rank: CardRank

    public init(suit: Suit, rank: CardRank) {
        self.suit = suit
        self.rank = rank
    }

    public var description: String { "\(suit.symbol)\(rank.rawValue)" }
}

public struct DoubleDummyVerificationDraft: Codable, Equatable, Sendable {
    public var trump: ContractStrain?
    public var trickLeader: Seat = .north
    /// Cards already played to the current trick, in play order, such as "♠2 ♥K".
    public var currentTrickCards = ""
    /// Every suit must be explicitly known; use "-" to confirm a void.
    public var hands: [Seat: [Suit: String]] = [:]
    public var declarerSeat: Seat?
    public var contractLevel: Int?
    /// Declarer-side tricks won before the unfinished current trick.
    public var declarerTricksAlreadyTaken: Int?

    public init() {}
}

public struct DoubleDummyContractContext: Equatable, Sendable {
    public let declarerSeat: Seat
    public let contractLevel: Int
    public let declarerTricksAlreadyTaken: Int

    public init(declarerSeat: Seat, contractLevel: Int, declarerTricksAlreadyTaken: Int) {
        self.declarerSeat = declarerSeat
        self.contractLevel = contractLevel
        self.declarerTricksAlreadyTaken = declarerTricksAlreadyTaken
    }
}

public struct DoubleDummyVerificationPosition: Equatable, Sendable {
    public let trump: ContractStrain
    public let trickLeader: Seat
    public let currentTrick: [DoubleDummyCard]
    public let remainingHands: [Seat: [Suit: [CardRank]]]
    public let actingSeat: Seat
    public let legalCards: [DoubleDummyCard]
    /// Remaining tricks include the unfinished current trick, when present.
    public let remainingTricks: Int
    /// Contract conversion is available only when all three fields were supplied.
    public let contractContext: DoubleDummyContractContext?

    fileprivate init(
        trump: ContractStrain,
        trickLeader: Seat,
        currentTrick: [DoubleDummyCard],
        remainingHands: [Seat: [Suit: [CardRank]]],
        actingSeat: Seat,
        legalCards: [DoubleDummyCard],
        remainingTricks: Int,
        contractContext: DoubleDummyContractContext?
    ) {
        self.trump = trump
        self.trickLeader = trickLeader
        self.currentTrick = currentTrick
        self.remainingHands = remainingHands
        self.actingSeat = actingSeat
        self.legalCards = legalCards
        self.remainingTricks = remainingTricks
        self.contractContext = contractContext
    }

    /// Wire format consumed by the bundled DDS helper. Empty suit holdings stay empty between dots.
    fileprivate var solverInputLine: String {
        let trick = currentTrick.map { "\($0.suit.solverIndex):\($0.rank.solverValue)" }.joined(separator: ",")
        let hands = Seat.allCases.map { seat in
            Suit.allCases.map { suit in
                (remainingHands[seat]?[suit] ?? []).map(\.pbnRank).joined()
            }.joined(separator: ".")
        }
        return ([String(trump.solverIndex), String(trickLeader.solverIndex), trick] + hands)
            .joined(separator: "|")
    }
}

public enum DoubleDummyVerificationInputError: Error, Equatable, LocalizedError, Sendable {
    case missingTrump
    case missingHolding(seat: Seat, suit: Suit)
    case invalidHolding(seat: Seat, suit: Suit, value: String)
    case duplicateCard(DoubleDummyCard)
    case tooManyCards(seat: Seat)
    case tooManyTrickCards
    case invalidTrickCard(String)
    case duplicatePlayedCard(DoubleDummyCard)
    case playedCardStillHeld(DoubleDummyCard)
    case playerStillHasLedSuit(Seat, Suit)
    case inconsistentHandSizes
    case noCardsRemaining
    case invalidContractLevel
    case invalidTricksAlreadyTaken
    case inconsistentTricksAlreadyTaken

    public var errorDescription: String? {
        switch self {
        case .missingTrump:
            "请选择核验牌局的将牌或无将。"
        case let .missingHolding(seat, suit):
            "请确认\(seat.chineseName)\(suit.symbol)是已知牌面，缺门请填 -。"
        case let .invalidHolding(seat, suit, value):
            "\(seat.chineseName)\(suit.symbol)输入“\(value)”无法识别。请使用 A K Q J 10 及 2 到 9；“-”表示缺门。"
        case let .duplicateCard(card):
            "\(card.description)被录入到多个位置，请先修正牌面。"
        case let .tooManyCards(seat):
            "\(seat.chineseName)剩余牌张超过 13 张，当前牌面不能求解。"
        case .tooManyTrickCards:
            "本墩最多可录入 3 张已出牌；第四张打出后请把新一墩领出者设为赢家。"
        case let .invalidTrickCard(value):
            "本墩已出牌“\(value)”无法识别。请按顺序输入，例如 ♠2 ♥K。"
        case let .duplicatePlayedCard(card):
            "本墩已出牌中重复出现\(card.description)。"
        case let .playedCardStillHeld(card):
            "已出牌\(card.description)仍在某家剩余手牌中。"
        case let .playerStillHasLedSuit(seat, suit):
            "本墩\(seat.chineseName)垫出了别的花色，但其剩余手牌仍有\(suit.symbol)；请核对牌面或本墩顺序。"
        case .inconsistentHandSizes:
            "四家剩余张数与本墩已出牌数不一致；请检查是否漏记了上一墩或本墩出牌。"
        case .noCardsRemaining:
            "当前没有可供核验的剩余牌。"
        case .invalidContractLevel:
            "定约阶数必须是 1 到 7。"
        case .invalidTricksAlreadyTaken:
            "庄家方已得墩数必须是 0 到 13。"
        case .inconsistentTricksAlreadyTaken:
            "已得墩数与剩余墩数相加超过 13；请检查定约进度。"
        }
    }
}

public enum DoubleDummyVerificationPositionBuilder {
    public static func build(from draft: DoubleDummyVerificationDraft) throws -> DoubleDummyVerificationPosition {
        guard let trump = draft.trump else {
            throw DoubleDummyVerificationInputError.missingTrump
        }

        var hands: [Seat: [Suit: [CardRank]]] = [:]
        var allCards = Set<DoubleDummyCard>()
        var countBySeat: [Seat: Int] = [:]

        for seat in Seat.allCases {
            var hand: [Suit: [CardRank]] = [:]
            var count = 0
            for suit in Suit.allCases {
                guard let raw = draft.hands[seat]?[suit], !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw DoubleDummyVerificationInputError.missingHolding(seat: seat, suit: suit)
                }
                guard let ranks = parseHolding(raw) else {
                    throw DoubleDummyVerificationInputError.invalidHolding(seat: seat, suit: suit, value: raw)
                }
                hand[suit] = ranks
                count += ranks.count
                for rank in ranks {
                    let card = DoubleDummyCard(suit: suit, rank: rank)
                    guard allCards.insert(card).inserted else {
                        throw DoubleDummyVerificationInputError.duplicateCard(card)
                    }
                }
            }
            guard count <= 13 else { throw DoubleDummyVerificationInputError.tooManyCards(seat: seat) }
            hands[seat] = hand
            countBySeat[seat] = count
        }

        let currentTrick = try parseCurrentTrick(draft.currentTrickCards)
        guard currentTrick.count <= 3 else { throw DoubleDummyVerificationInputError.tooManyTrickCards }
        var playedCards = Set<DoubleDummyCard>()
        for card in currentTrick {
            guard playedCards.insert(card).inserted else {
                throw DoubleDummyVerificationInputError.duplicatePlayedCard(card)
            }
            guard !allCards.contains(card) else {
                throw DoubleDummyVerificationInputError.playedCardStillHeld(card)
            }
        }

        for (index, card) in currentTrick.enumerated().dropFirst() where card.suit != currentTrick[0].suit {
            let seat = draft.trickLeader.advanced(by: index)
            if !(hands[seat]?[currentTrick[0].suit] ?? []).isEmpty {
                throw DoubleDummyVerificationInputError.playerStillHasLedSuit(seat, currentTrick[0].suit)
            }
        }

        let adjustedCounts = Seat.allCases.map { seat in
            (countBySeat[seat] ?? 0) + currentTrick.indices.filter { draft.trickLeader.advanced(by: $0) == seat }.count
        }
        guard let remainingTricks = adjustedCounts.first, adjustedCounts.allSatisfy({ $0 == remainingTricks }) else {
            throw DoubleDummyVerificationInputError.inconsistentHandSizes
        }
        guard remainingTricks > 0 else { throw DoubleDummyVerificationInputError.noCardsRemaining }

        if let contractLevel = draft.contractLevel, !(1...7).contains(contractLevel) {
            throw DoubleDummyVerificationInputError.invalidContractLevel
        }
        if let tricks = draft.declarerTricksAlreadyTaken {
            guard (0...13).contains(tricks) else {
                throw DoubleDummyVerificationInputError.invalidTricksAlreadyTaken
            }
            guard tricks + remainingTricks <= 13 else {
                throw DoubleDummyVerificationInputError.inconsistentTricksAlreadyTaken
            }
        }

        let actingSeat = draft.trickLeader.advanced(by: currentTrick.count)
        let hand = hands[actingSeat] ?? [:]
        let ledSuit = currentTrick.first?.suit
        let suitToPlay = ledSuit.flatMap { suit in
            let holding = hand[suit] ?? []
            return holding.isEmpty ? nil : suit
        }
        let legalCards = Suit.allCases
            .filter { suitToPlay == nil || suitToPlay == $0 }
            .flatMap { suit in (hand[suit] ?? []).map { DoubleDummyCard(suit: suit, rank: $0) } }
            .sorted(by: cardOrder)
        guard !legalCards.isEmpty else { throw DoubleDummyVerificationInputError.noCardsRemaining }

        let contractContext: DoubleDummyContractContext?
        if let declarer = draft.declarerSeat,
           let level = draft.contractLevel,
           let tricks = draft.declarerTricksAlreadyTaken {
            contractContext = DoubleDummyContractContext(
                declarerSeat: declarer,
                contractLevel: level,
                declarerTricksAlreadyTaken: tricks
            )
        } else {
            contractContext = nil
        }

        return DoubleDummyVerificationPosition(
            trump: trump,
            trickLeader: draft.trickLeader,
            currentTrick: currentTrick,
            remainingHands: hands,
            actingSeat: actingSeat,
            legalCards: legalCards,
            remainingTricks: remainingTricks,
            contractContext: contractContext
        )
    }

    private static func parseHolding(_ raw: String) -> [CardRank]? {
        let normalized = raw.uppercased().filter { !$0.isWhitespace && $0 != "," && $0 != ";" }
        if normalized == "-" || normalized == "—" || normalized == "VOID" { return [] }
        var ranks: [CardRank] = []
        var seen = Set<CardRank>()
        let characters = Array(normalized)
        var index = 0
        while index < characters.count {
            let rank: CardRank
            if characters[index] == "1", index + 1 < characters.count, characters[index + 1] == "0" {
                guard let parsed = parseRank("10") else { return nil }
                rank = parsed
                index += 2
            } else {
                guard let parsed = parseRank(String(characters[index])) else {
                    return nil
                }
                rank = parsed
                index += 1
            }
            guard seen.insert(rank).inserted else { return nil }
            ranks.append(rank)
        }
        return ranks.sorted { rankOrder($0) < rankOrder($1) }
    }

    private static func parseCurrentTrick(_ raw: String) throws -> [DoubleDummyCard] {
        let tokens = raw.split { $0.isWhitespace || $0 == "," || $0 == ";" }
        return try tokens.map { token in
            let value = String(token)
            guard let suitCharacter = value.first else {
                throw DoubleDummyVerificationInputError.invalidTrickCard(value)
            }
            let suit: Suit
            switch String(suitCharacter).uppercased() {
            case "♠", "S": suit = .spades
            case "♥", "H": suit = .hearts
            case "♦", "D": suit = .diamonds
            case "♣", "C": suit = .clubs
            default: throw DoubleDummyVerificationInputError.invalidTrickCard(value)
            }
            let rankText = String(value.dropFirst()).uppercased()
            guard let rank = parseRank(rankText) else {
                throw DoubleDummyVerificationInputError.invalidTrickCard(value)
            }
            return DoubleDummyCard(suit: suit, rank: rank)
        }
    }

    private static func parseRank(_ value: String) -> CardRank? {
        let symbol = value.uppercased()
        return CardRank.allCases.first(where: { $0.rawValue == symbol || ($0 == .ten && symbol == "T") })
    }

    fileprivate static func cardOrder(_ lhs: DoubleDummyCard, _ rhs: DoubleDummyCard) -> Bool {
        if lhs.suit != rhs.suit { return lhs.suit.solverIndex < rhs.suit.solverIndex }
        return rankOrder(lhs.rank) < rankOrder(rhs.rank)
    }

    private static func rankOrder(_ rank: CardRank) -> Int { CardRank.allCases.firstIndex(of: rank) ?? 0 }
}

public struct DoubleDummyEngineMove: Equatable, Sendable {
    public let card: DoubleDummyCard
    public let equivalentCards: [DoubleDummyCard]
    /// DDS score for the partnership of the player who is to act in this position.
    public let tricksForSideToPlay: Int

    public init(card: DoubleDummyCard, equivalentCards: [DoubleDummyCard], tricksForSideToPlay: Int) {
        self.card = card
        self.equivalentCards = equivalentCards
        self.tricksForSideToPlay = tricksForSideToPlay
    }
}

public struct DoubleDummyCardComparison: Codable, Equatable, Sendable {
    public let cards: [DoubleDummyCard]
    public let tricksForSideToPlay: Int
    public let remainingTricksByDeclarer: Int?
    public let totalTricksByDeclarer: Int?
    /// Positive values are overtricks; negative values are undertricks.
    public let contractDelta: Int?
}

public struct DoubleDummyVerificationResult: Codable, Equatable, Sendable {
    public let solverVersion: String
    public let remainingTricks: Int
    public let actingSeat: Seat
    public let declarerSeat: Seat?
    public let moves: [DoubleDummyCardComparison]
}

public enum DoubleDummyResultError: Error, Equatable, LocalizedError, Sendable {
    case missingLegalMove
    case duplicateMove(DoubleDummyCard)
    case illegalMove(DoubleDummyCard)
    case missingMove(DoubleDummyCard)
    case invalidTrickCount(DoubleDummyCard)
    case invalidEquivalent(DoubleDummyCard)

    public var errorDescription: String? {
        switch self {
        case .missingLegalMove: "DDS 没有返回可显示的合法出牌结果。"
        case let .duplicateMove(card): "DDS 对\(card.description)返回了重复结果，已拒绝显示。"
        case let .illegalMove(card): "DDS 返回了当前不合法的\(card.description)，已拒绝显示。"
        case let .missingMove(card): "DDS 未返回合法出牌\(card.description)的结果，已拒绝显示不完整比较。"
        case let .invalidTrickCount(card): "DDS 对\(card.description)返回了超出剩余墩数的结果。"
        case let .invalidEquivalent(card): "DDS 将不同花色的\(card.description)标记为等价牌，已拒绝显示。"
        }
    }
}

public enum DoubleDummyVerificationResultBuilder {
    public static func build(
        from engineMoves: [DoubleDummyEngineMove],
        position: DoubleDummyVerificationPosition,
        solverVersion: String
    ) throws -> DoubleDummyVerificationResult {
        let legalCards = Set(position.legalCards)
        var seen = Set<DoubleDummyCard>()
        var comparisons: [DoubleDummyCardComparison] = []

        for engineMove in engineMoves {
            let cards = [engineMove.card] + engineMove.equivalentCards
            guard (0...position.remainingTricks).contains(engineMove.tricksForSideToPlay) else {
                throw DoubleDummyResultError.invalidTrickCount(engineMove.card)
            }
            for card in cards {
                guard card.suit == engineMove.card.suit else {
                    throw DoubleDummyResultError.invalidEquivalent(card)
                }
                guard legalCards.contains(card) else { throw DoubleDummyResultError.illegalMove(card) }
                guard seen.insert(card).inserted else { throw DoubleDummyResultError.duplicateMove(card) }
            }

            let declarerTricks: Int?
            let totalDeclarerTricks: Int?
            let contractDelta: Int?
            if let contract = position.contractContext {
                let actorPlaysDeclarerSide = position.actingSeat.partnership == contract.declarerSeat.partnership
                let remaining = actorPlaysDeclarerSide
                    ? engineMove.tricksForSideToPlay
                    : position.remainingTricks - engineMove.tricksForSideToPlay
                let total = contract.declarerTricksAlreadyTaken + remaining
                declarerTricks = remaining
                totalDeclarerTricks = total
                contractDelta = total - (contract.contractLevel + 6)
            } else {
                declarerTricks = nil
                totalDeclarerTricks = nil
                contractDelta = nil
            }

            comparisons.append(DoubleDummyCardComparison(
                cards: cards.sorted(by: DoubleDummyVerificationPositionBuilder.cardOrder),
                tricksForSideToPlay: engineMove.tricksForSideToPlay,
                remainingTricksByDeclarer: declarerTricks,
                totalTricksByDeclarer: totalDeclarerTricks,
                contractDelta: contractDelta
            ))
        }

        guard !comparisons.isEmpty else { throw DoubleDummyResultError.missingLegalMove }
        if let missing = legalCards.subtracting(seen).sorted(by: DoubleDummyVerificationPositionBuilder.cardOrder).first {
            throw DoubleDummyResultError.missingMove(missing)
        }

        return DoubleDummyVerificationResult(
            solverVersion: solverVersion,
            remainingTricks: position.remainingTricks,
            actingSeat: position.actingSeat,
            declarerSeat: position.contractContext?.declarerSeat,
            moves: comparisons.sorted { lhs, rhs in
                guard let left = lhs.cards.first, let right = rhs.cards.first else { return lhs.cards.count < rhs.cards.count }
                return DoubleDummyVerificationPositionBuilder.cardOrder(left, right)
            }
        )
    }
}

public protocol DoubleDummySolving: Sendable {
    var version: String { get }
    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove]
}

public enum BundledDDSError: Error, Equatable, LocalizedError, Sendable {
    case helperNotFound
    case failed(String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .helperNotFound:
            "没有找到随应用提供的 DDS 3.0.0 helper。请通过 Scripts/build-macos-app.sh 构建完整应用。"
        case let .failed(message): "DDS 计算失败：\(message)"
        case .invalidResponse: "DDS helper 返回了无法识别的结果；未显示猜测数字。"
        }
    }
}

public struct BundledDDSSolver: DoubleDummySolving {
    public static let solverVersion = "3.0.0"
    public var version: String { Self.solverVersion }
    public let executableURL: URL?

    public init(executableURL: URL?) {
        self.executableURL = executableURL
    }

    public func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        guard let executableURL, FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw BundledDDSError.helperNotFound
        }

        let input = Data((position.solverInputLine + "\n").utf8)
        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let standardInput = Pipe()
            let standardOutput = Pipe()
            let standardError = Pipe()
            process.executableURL = executableURL
            process.arguments = ["--bridge-teacher-dds-wire-v1"]
            process.standardInput = standardInput
            process.standardOutput = standardOutput
            process.standardError = standardError

            do {
                try process.run()
                try standardInput.fileHandleForWriting.write(contentsOf: input)
                try standardInput.fileHandleForWriting.close()
                let output = standardOutput.fileHandleForReading.readDataToEndOfFile()
                let errors = standardError.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else {
                    let message = String(decoding: errors, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                    throw BundledDDSError.failed(message.isEmpty ? "helper 退出码 \(process.terminationStatus)" : message)
                }
                guard let payload = try? JSONDecoder().decode(DDSSolverPayload.self, from: output) else {
                    throw BundledDDSError.invalidResponse
                }
                return try payload.moves.map { move in
                    guard let suit = Suit.allCases.first(where: { $0.solverIndex == move.suit }),
                          let rank = CardRank.allCases.first(where: { $0.solverValue == move.rank }) else {
                        throw BundledDDSError.invalidResponse
                    }
                    let equivalents = CardRank.allCases.compactMap { rank -> DoubleDummyCard? in
                        let mask = 1 << rank.solverValue
                        guard move.equals & mask != 0 else { return nil }
                        return DoubleDummyCard(suit: suit, rank: rank)
                    }
                    return DoubleDummyEngineMove(
                        card: DoubleDummyCard(suit: suit, rank: rank),
                        equivalentCards: equivalents,
                        tricksForSideToPlay: move.tricks
                    )
                }
            } catch let error as BundledDDSError {
                throw error
            } catch {
                throw BundledDDSError.failed(error.localizedDescription)
            }
        }.value
    }
}

private struct DDSSolverPayload: Decodable {
    let moves: [DDSSolverMove]
}

private struct DDSSolverMove: Decodable {
    let suit: Int
    let rank: Int
    let equals: Int
    let tricks: Int
}

public enum DoubleDummyVerificationState: Codable, Equatable, Sendable {
    case unverified
    case insufficient(String)
    case solving
    case failed(String)
    case verified
    case outdated
}

@MainActor
public final class DoubleDummyVerificationWorkflow: ObservableObject {
    @Published public private(set) var draft: DoubleDummyVerificationDraft
    @Published public private(set) var state: DoubleDummyVerificationState = .unverified
    @Published public private(set) var result: DoubleDummyVerificationResult?
    @Published public private(set) var hasOutdatedResult = false

    private let solver: any DoubleDummySolving
    private var revision = 0

    public func makeArchive() -> DoubleDummyVerificationWorkflowArchive {
        DoubleDummyVerificationWorkflowArchive(
            draft: draft,
            state: state,
            result: result,
            hasOutdatedResult: hasOutdatedResult
        )
    }

    public init(draft: DoubleDummyVerificationDraft = DoubleDummyVerificationDraft(), solver: any DoubleDummySolving) {
        self.draft = draft
        self.solver = solver
    }

    public func restore(from archive: DoubleDummyVerificationWorkflowArchive) {
        draft = archive.draft
        state = archive.state == .solving
            ? (archive.hasOutdatedResult ? .outdated : .failed("应用关闭前 DDS 核验尚未完成，请重新运行。"))
            : archive.state
        result = archive.result
        hasOutdatedResult = archive.hasOutdatedResult
        revision += 1
    }

    public func updateDraft(_ draft: DoubleDummyVerificationDraft) {
        guard draft != self.draft else { return }
        self.draft = draft
        invalidate()
    }

    /// A source revision can change without changing the serialized DDS position.
    public func invalidate() {
        revision += 1
        if result != nil || state == .verified || state == .outdated {
            result = nil
            hasOutdatedResult = true
            state = .outdated
        } else if state != .unverified {
            state = .unverified
        }
    }

    public func verify() async {
        let position: DoubleDummyVerificationPosition
        do {
            position = try DoubleDummyVerificationPositionBuilder.build(from: draft)
        } catch {
            state = hasOutdatedResult ? .outdated : .insufficient(error.localizedDescription)
            return
        }

        revision += 1
        let verificationRevision = revision
        state = .solving

        do {
            let engineMoves = try await solver.solve(position: position)
            guard revision == verificationRevision else { return }
            let verifiedResult = try DoubleDummyVerificationResultBuilder.build(
                from: engineMoves,
                position: position,
                solverVersion: solver.version
            )
            result = verifiedResult
            hasOutdatedResult = false
            state = .verified
        } catch {
            guard revision == verificationRevision else { return }
            result = nil
            state = .failed(error.localizedDescription)
        }
    }
}

private extension Seat {
    var solverIndex: Int { Seat.allCases.firstIndex(of: self) ?? 0 }

    var partnership: Int { self == .north || self == .south ? 0 : 1 }

    func advanced(by count: Int) -> Seat {
        let seats = Seat.allCases
        let currentIndex = solverIndex
        return seats[(currentIndex + count) % seats.count]
    }
}

private extension Suit {
    var solverIndex: Int { Suit.allCases.firstIndex(of: self) ?? 0 }
}

private extension ContractStrain {
    /// DDS strain order is spades, hearts, diamonds, clubs, then no-trump.
    var solverIndex: Int {
        switch self {
        case .spades: 0
        case .hearts: 1
        case .diamonds: 2
        case .clubs: 3
        case .noTrump: 4
        }
    }
}

private extension CardRank {
    var pbnRank: String { self == .ten ? "T" : rawValue }

    var solverValue: Int {
        switch self {
        case .ace: 14
        case .king: 13
        case .queen: 12
        case .jack: 11
        case .ten: 10
        case .nine: 9
        case .eight: 8
        case .seven: 7
        case .six: 6
        case .five: 5
        case .four: 4
        case .three: 3
        case .two: 2
        }
    }
}
