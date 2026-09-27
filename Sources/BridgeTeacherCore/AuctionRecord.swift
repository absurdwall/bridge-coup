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
public struct AuctionEntry: Codable, Equatable, Identifiable, Sendable {
    /// Stable identity for this occurrence, including when the same call is
    /// entered more than once. Editing or moving an entry must preserve it.
    public let id: UUID
    public var seat: Seat?
    public var call: AuctionCall
    /// A user-supplied meaning and applicability note, not a verified system
    /// convention or a tournament Alert.
    public var meaningNote: String?

    public init(
        id: UUID = UUID(),
        seat: Seat? = nil,
        call: AuctionCall,
        meaningNote: String? = nil
    ) {
        self.id = id
        self.seat = seat
        self.call = call
        self.meaningNote = Self.normalizedMeaningNote(meaningNote)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case seat
        case call
        case meaningNote
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        seat = try container.decodeIfPresent(Seat.self, forKey: .seat)
        call = try container.decode(AuctionCall.self, forKey: .call)
        meaningNote = Self.normalizedMeaningNote(try container.decodeIfPresent(String.self, forKey: .meaningNote))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(seat, forKey: .seat)
        try container.encode(call, forKey: .call)
        try container.encodeIfPresent(Self.normalizedMeaningNote(meaningNote), forKey: .meaningNote)
    }

    public static func normalizedMeaningNote(_ note: String?) -> String? {
        guard let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
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

public enum AuctionRecordKind: String, Codable, CaseIterable, Equatable, Sendable {
    case calls
    case noAuction
}

/// Ordered, manually confirmed auction data. `nil` at the draft level means
/// no structured auction was supplied; an empty `.calls` record means no calls
/// have been entered yet; `.noAuction` is the player's explicit statement that
/// this board has no auction. None of these cases becomes a pass.
public struct AuctionRecord: Codable, Equatable, Sendable {
    public var kind: AuctionRecordKind
    /// The first position to act, not the seat making the first non-pass bid.
    public var startingSeat: Seat?
    public var entries: [AuctionEntry]

    public init(
        kind: AuctionRecordKind = .calls,
        startingSeat: Seat? = nil,
        entries: [AuctionEntry] = []
    ) {
        self.kind = kind
        self.startingSeat = startingSeat
        self.entries = entries
    }

    /// Inserts one occurrence without changing the identity of existing calls.
    @discardableResult
    public mutating func insertEntry(_ entry: AuctionEntry, at index: Int) -> Bool {
        guard (0...entries.count).contains(index),
              !entries.contains(where: { $0.id == entry.id }) else { return false }
        entries.insert(entry, at: index)
        return true
    }

    /// Corrects the call at its stable occurrence identity, preserving its note.
    @discardableResult
    public mutating func updateCall(forEntryID id: UUID, to call: AuctionCall) -> Bool {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return false }
        entries[index].call = call
        return true
    }

    /// Replaces or clears a note at its stable occurrence identity.
    @discardableResult
    public mutating func setMeaningNote(_ note: String?, forEntryID id: UUID) -> Bool {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return false }
        entries[index].meaningNote = AuctionEntry.normalizedMeaningNote(note)
        return true
    }

    /// Removes only the selected occurrence; equal calls and their notes remain.
    @discardableResult
    public mutating func removeEntry(id: UUID) -> Bool {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return false }
        entries.remove(at: index)
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case startingSeat
        case entries
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decodeIfPresent(AuctionRecordKind.self, forKey: .kind) ?? .calls
        startingSeat = try container.decodeIfPresent(Seat.self, forKey: .startingSeat)
        entries = try container.decodeIfPresent([AuctionEntry].self, forKey: .entries) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(startingSeat, forKey: .startingSeat)
        try container.encode(entries, forKey: .entries)
    }

    public var promptDescription: String {
        if kind == .noAuction, entries.isEmpty {
            return "叫牌状态：用户已确认本局无叫牌。"
        }
        let start = startingSeat?.chineseName ?? "未知；不得默认北家"
        guard !entries.isEmpty else {
            return "首个行动位置：\(start)\n当前没有已确认叫品；空记录不代表无叫牌。"
        }
        let lines = entries.enumerated().map { index, entry in
            let seat = entry.seat?.chineseName ?? "位置未知"
            var line = "第\(index + 1)次行动（\(seat)）：\(entry.call.displayText)"
            if let note = AuctionEntry.normalizedMeaningNote(entry.meaningNote) {
                line += "\n  用户提供的叫品含义与适用条件备注（未核实，不得表述为已确认的约定；仅在备注所述条件明确成立时作为线索，条件不明时先询问）：<user-call-meaning-note>\n\(note)\n</user-call-meaning-note>"
            }
            return line
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
        if kind == .noAuction {
            return entries.isEmpty ? [] : nil
        }
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
