import Foundation

public enum Seat: String, Codable, CaseIterable, Sendable {
    case north, east, south, west
    public var next: Seat { Self.allCases[(Self.allCases.firstIndex(of: self)! + 1) % 4] }
    public var partner: Seat { next.next }
}

public enum Suit: String, Codable, CaseIterable, Sendable {
    case spades, hearts, diamonds, clubs
    public var code: String { String(rawValue.prefix(1)).uppercased() }
}

public enum Strain: String, Codable, Sendable {
    case spades, hearts, diamonds, clubs, noTrump
    public var trump: Suit? { Suit(rawValue: rawValue) }
}

public struct Card: Hashable, Codable, Sendable, CustomStringConvertible {
    public let suit: Suit
    public let rank: Int
    public init(_ code: String) throws {
        guard let suit = Suit.allCases.first(where: { $0.code == String(code.prefix(1)) }),
              let rank = Self.ranks.firstIndex(of: String(code.dropFirst())) else { throw DomainError.invalidCard(code) }
        self.suit = suit
        self.rank = rank + 2
    }
    private static let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
    public var description: String { suit.code + Self.ranks[rank - 2] }
    public init(from decoder: Decoder) throws { try self.init(decoder.singleValueContainer().decode(String.self)) }
    public func encode(to encoder: Encoder) throws { var value = encoder.singleValueContainer(); try value.encode(description) }
}

public struct Contract: Codable, Equatable, Sendable {
    public let level: Int
    public let strain: Strain
    public let declarer: Seat
    public init(level: Int, strain: Strain, declarer: Seat) throws {
        guard (1...7).contains(level) else { throw DomainError.invalidContract }
        self.level = level; self.strain = strain; self.declarer = declarer
    }
}

public struct Hand: Codable, Equatable, Sendable {
    public let seat: Seat
    public let cards: [Card]
    public init(seat: Seat, cards: [Card]) { self.seat = seat; self.cards = cards }
}

public struct PlayEvent: Codable, Equatable, Sendable {
    public let sequence: Int
    public let seat: Seat
    public let card: Card
    public init(sequence: Int, seat: Seat, card: Card) { self.sequence = sequence; self.seat = seat; self.card = card }
}

/// Decision-time facts only. Suggested cards and public plans never enter this record.
public struct DecisionSnapshot: Codable, Equatable, Sendable {
    public let boardID: UUID
    public let revision: Int
    public let controller: Seat
    public let actingSeat: Seat
    public let contract: Contract
    public let vulnerability: String
    public let scoring: String
    public let objective: String
    public let publicBackground: String?
    public let hands: [Hand]
    public let events: [PlayEvent]
    public let currentTrick: [PlayEvent]
    public let declarerTricks: Int
    public let defenderTricks: Int
    public var id: String { "\(boardID.uuidString):\(revision):\(controller.rawValue)" }

    public init(boardID: UUID, revision: Int, controller: Seat, actingSeat: Seat, contract: Contract,
                vulnerability: String, scoring: String, objective: String, publicBackground: String?, hands: [Hand],
                events: [PlayEvent], currentTrick: [PlayEvent], declarerTricks: Int, defenderTricks: Int) {
        self.boardID = boardID; self.revision = revision; self.controller = controller; self.actingSeat = actingSeat
        self.contract = contract; self.vulnerability = vulnerability; self.scoring = scoring; self.objective = objective
        self.publicBackground = publicBackground; self.hands = hands; self.events = events
        self.currentTrick = currentTrick; self.declarerTricks = declarerTricks; self.defenderTricks = defenderTricks
    }
}

/// Association is program-owned; the model supplies only the card.
public struct CurrentAction: Codable, Equatable, Sendable {
    public let snapshotID: String
    public let boardID: UUID
    public let revision: Int
    public let controller: Seat
    public let actingSeat: Seat
    public let card: Card
    public init(snapshot: DecisionSnapshot, card: Card) {
        snapshotID = snapshot.id; boardID = snapshot.boardID; revision = snapshot.revision
        controller = snapshot.controller; actingSeat = snapshot.actingSeat; self.card = card
    }
}

public enum DomainError: Error, Equatable {
    case invalidCard(String), invalidContract, invalidDeal, finished, wrongTurn, cardNotHeld, mustFollowSuit, staleSnapshot, invalidController
}
