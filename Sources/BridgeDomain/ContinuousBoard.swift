import Foundation

public enum BoardPhase: String, Codable, Sendable { case bidding, openingLead, declarer, defense, finished }

/// A canonical actual call, distinct from a request to inspect its meaning.
public struct AuctionCall: Hashable, Codable, Sendable, CustomStringConvertible {
    public let description: String
    public init(_ value: String) throws {
        guard ["P", "X", "XX"].contains(value) || Self.bids.contains(value) else {
            throw ContinuousBoardError.invalidCall
        }
        description = value
    }
    public static let bids: [String] = (1...7).flatMap { level in ["C", "D", "H", "S", "NT"].map { "\(level)\($0)" } }
    public var bidIndex: Int? { Self.bids.firstIndex(of: description) }
    public var level: Int? { bidIndex.map { $0 / 5 + 1 } }
    public var strain: Strain? { bidIndex.map { [Strain.clubs, .diamonds, .hearts, .spades, .noTrump][$0 % 5] } }
    public init(from decoder: Decoder) throws { try self.init(decoder.singleValueContainer().decode(String.self)) }
    public func encode(to encoder: Encoder) throws { var c = encoder.singleValueContainer(); try c.encode(description) }
}

public struct AuctionEvent: Codable, Equatable, Sendable {
    public let sequence: Int
    public let seat: Seat
    public let call: AuctionCall
    public init(sequence: Int, seat: Seat, call: AuctionCall) { self.sequence = sequence; self.seat = seat; self.call = call }
}

public enum ContinuousBoardError: Error, Equatable {
    case invalidCall, illegalCall, auctionComplete, contractNotConfirmed, contractMismatch, invalidExposure, missingVisibleHand
}

/// Immutable authorized facts. The model cannot add calls, exposures, or a final contract.
public struct ContinuousSnapshot: Codable, Equatable, Sendable {
    public let boardID: UUID
    public let revision: Int
    public let phase: BoardPhase
    public let userSeat: Seat
    public let controller: Seat
    public let actingSeat: Seat?
    public let contract: Contract?
    public let contractConfirmed: Bool
    public let dealer: Seat
    public let vulnerability: String
    public let scoring: String
    public let objective: String
    public let agreements: String
    public let auction: [AuctionEvent]
    public let hands: [Hand]
    public let events: [PlayEvent]
    public let currentTrick: [PlayEvent]
    public let completedTricks: [CompletedTrick]
    public let currentWinningPlay: PlayEvent?
    public let legalCalls: [AuctionCall]
    public let legalCards: [Card]
    public let declarerTricks: Int
    public let defenderTricks: Int
    public var id: String { "\(boardID.uuidString):\(revision):\(phase.rawValue):\(controller.rawValue)" }

    public init(boardID: UUID, revision: Int, phase: BoardPhase, userSeat: Seat, controller: Seat, actingSeat: Seat?, contract: Contract?, contractConfirmed: Bool, dealer: Seat, vulnerability: String, scoring: String, objective: String, agreements: String, auction: [AuctionEvent], hands: [Hand], events: [PlayEvent], currentTrick: [PlayEvent], completedTricks: [CompletedTrick], currentWinningPlay: PlayEvent?, legalCalls: [AuctionCall], legalCards: [Card], declarerTricks: Int, defenderTricks: Int) {
        self.boardID = boardID; self.revision = revision; self.phase = phase; self.userSeat = userSeat
        self.controller = controller; self.actingSeat = actingSeat; self.contract = contract; self.contractConfirmed = contractConfirmed
        self.dealer = dealer; self.vulnerability = vulnerability; self.scoring = scoring; self.objective = objective
        self.agreements = agreements; self.auction = auction; self.hands = hands; self.events = events
        self.currentTrick = currentTrick; self.completedTricks = completedTricks; self.currentWinningPlay = currentWinningPlay
        self.legalCalls = legalCalls; self.legalCards = legalCards; self.declarerTricks = declarerTricks; self.defenderTricks = defenderTricks
    }
}
