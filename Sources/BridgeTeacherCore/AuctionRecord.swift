import Foundation

/// A board's vulnerability as explicitly supplied by the player.
/// `nil` in a draft means it was not provided; `.neither` is an explicit value.
public enum Vulnerability: String, CaseIterable, Codable, Equatable, Sendable {
    case neither
    case northSouth
    case eastWest
    case both

    public var chineseDescription: String {
        switch self {
        case .neither: "双方无局"
        case .northSouth: "南北有局"
        case .eastWest: "东西有局"
        case .both: "双方有局"
        }
    }
}

/// One action in the auction. An unknown action is different from a pass and
/// from a blank cell used only to align the auction's four seat columns.
public enum AuctionCall: Codable, Equatable, Sendable {
    case bid(level: Int, strain: ContractStrain)
    case pass
    case double
    case redouble
    case unknown

    public var displayText: String {
        switch self {
        case let .bid(level, strain): "\(level)\(strain.symbol)"
        case .pass: "Pass"
        case .double: "X"
        case .redouble: "XX"
        case .unknown: "未知叫品"
        }
    }
}

/// A confirmed action and the seat assigned to it, when the player knows it.
/// Keeping the seat on each entry means changing the selected opening seat
/// cannot silently relabel calls that were already confirmed.
public struct AuctionEntry: Codable, Equatable, Sendable {
    public var seat: Seat?
    public var call: AuctionCall

    public init(seat: Seat? = nil, call: AuctionCall) {
        self.seat = seat
        self.call = call
    }
}

public enum AuctionLayoutCell: Equatable, Sendable {
    case layoutBlank
    case entry(AuctionEntry)
}

public struct AuctionLayoutRow: Equatable, Sendable {
    public let cells: [Seat: AuctionLayoutCell]

    public init(cells: [Seat: AuctionLayoutCell]) {
        self.cells = cells
    }

    public subscript(seat: Seat) -> AuctionLayoutCell {
        cells[seat] ?? .layoutBlank
    }
}

/// Ordered, manually confirmed auction data. `nil` at the draft level means
/// no structured auction was supplied; an empty record means no calls were
/// entered. Neither case is converted to a pass or to an unknown call.
public struct AuctionRecord: Codable, Equatable, Sendable {
    /// The first position to act, not the seat making the first non-pass bid.
    public var startingSeat: Seat?
    public var entries: [AuctionEntry]

    public init(startingSeat: Seat? = nil, entries: [AuctionEntry] = []) {
        self.startingSeat = startingSeat
        self.entries = entries
    }

    public var promptDescription: String {
        let start = startingSeat?.chineseName ?? "未知；不得默认北家"
        guard !entries.isEmpty else {
            return "首个行动位置：\(start)\n当前没有已确认叫品；空记录不代表无叫牌。"
        }
        let lines = entries.enumerated().map { index, entry in
            let seat = entry.seat?.chineseName ?? "位置未知"
            return "第\(index + 1)次行动（\(seat)）：\(entry.call.displayText)"
        }
        return "首个行动位置：\(start)\n已确认叫牌序列：\n\(lines.joined(separator: "\n"))"
    }

    /// Returns the expected turn position for an entry in this sequence. Passes
    /// and unknown calls each consume a turn. A missing starting position and
    /// missing first-entry seat remain unknown.
    public func sequenceSeat(at entryIndex: Int) -> Seat? {
        guard entryIndex >= 0,
              let firstSeat = entries.first?.seat ?? startingSeat,
              let firstIndex = Seat.allCases.firstIndex(of: firstSeat) else {
            return nil
        }
        return Seat.allCases[(firstIndex + entryIndex) % Seat.allCases.count]
    }

    /// Four-column rows in fixed N/E/S/W order. Leading and trailing cells are
    /// layout blanks. If no opening position or first entry seat is known, the
    /// calls remain an ordered transcript and no seat is guessed.
    public var layoutRows: [AuctionLayoutRow]? {
        guard !entries.isEmpty else { return [] }
        guard let firstSeat = entries.first?.seat ?? startingSeat,
              let firstColumn = Seat.allCases.firstIndex(of: firstSeat) else {
            return nil
        }
        if let startingSeat, let firstEntrySeat = entries.first?.seat,
           firstEntrySeat != startingSeat {
            return nil
        }
        for (index, entry) in entries.enumerated() {
            if let confirmedSeat = entry.seat,
               confirmedSeat != sequenceSeat(at: index) {
                return nil
            }
        }

        let occupiedLength = firstColumn + entries.count
        let rowCount = (occupiedLength + Seat.allCases.count - 1) / Seat.allCases.count
        var rows = (0..<rowCount).map { _ in
            AuctionLayoutRow(cells: Dictionary(uniqueKeysWithValues: Seat.allCases.map { ($0, .layoutBlank) }))
        }

        for (entryIndex, entry) in entries.enumerated() {
            let position = firstColumn + entryIndex
            let rowIndex = position / Seat.allCases.count
            let column = Seat.allCases[position % Seat.allCases.count]
            var cells = rows[rowIndex].cells
            cells[column] = .entry(entry)
            rows[rowIndex] = AuctionLayoutRow(cells: cells)
        }
        return rows
    }
}
