import Foundation
import CSQLite
import BridgeDomain

public enum ExplanationStoreError: Error, Equatable {
    case database(String), unsupportedFormat, dataKindMismatch, invalidObservation, invalidContext, conflictingObservation
}

/// A local, indexed collection of observed prefixes. New observations never replace an older source.
public actor ExplanationStore {
    private let database: SQLiteDatabase
    private let testData: Bool
    private let encoder: JSONEncoder = {
        let value = JSONEncoder(); value.outputFormatting = [.sortedKeys]; return value
    }()

    public init(url: URL, testData: Bool = false) throws {
        guard url.isFileURL else { throw ExplanationStoreError.unsupportedFormat }
        self.testData = testData
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        database = try SQLiteDatabase(url: url)
        try database.execute("PRAGMA foreign_keys = ON")
        let version = try database.rows("PRAGMA user_version").first?.first ?? "0"
        if version == "0" {
            guard try database.rows("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").isEmpty else {
                throw ExplanationStoreError.unsupportedFormat
            }
            try database.transaction {
                try database.execute("CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
                try database.execute("INSERT INTO metadata VALUES ('format', 'bridge-explanations'), ('testData', ?)", [testData ? "1" : "0"])
                try database.execute("CREATE TABLE prefixes (id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES prefixes(id), call TEXT NOT NULL, UNIQUE(parent_id, call))")
                try database.execute("INSERT INTO prefixes (id, parent_id, call) VALUES (1, NULL, '')")
                try database.execute("CREATE TABLE observations (id TEXT PRIMARY KEY, prefix_id INTEGER NOT NULL REFERENCES prefixes(id), candidate TEXT NOT NULL, context_key TEXT NOT NULL, body TEXT NOT NULL)")
                try database.execute("CREATE INDEX observations_lookup ON observations(prefix_id, candidate, context_key)")
                try database.execute("PRAGMA user_version = 1")
            }
        } else if version != "1" { throw ExplanationStoreError.unsupportedFormat }
        guard try database.rows("SELECT value FROM metadata WHERE key='format'").first?.first == "bridge-explanations" else {
            throw ExplanationStoreError.unsupportedFormat
        }
        guard try database.rows("SELECT value FROM metadata WHERE key='testData'").first?.first == (testData ? "1" : "0") else {
            throw ExplanationStoreError.dataKindMismatch
        }
    }

    public func save(_ observation: ExplanationObservation) throws {
        guard observation.isTestData == testData else { throw ExplanationStoreError.dataKindMismatch }
        guard [observation.text, observation.source, observation.observedAt, observation.sourceVersion].allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              !observation.evidence.isEmpty, observation.evidence.allSatisfy({ !$0.isEmpty }) else {
            throw ExplanationStoreError.invalidObservation
        }
        let context = try NormalizedContext(observation.context)
        let body = String(decoding: try encoder.encode(observation), as: UTF8.self)
        if let existing = try database.rows("SELECT body FROM observations WHERE id=?", [observation.id.uuidString]).first?.first {
            guard try JSONDecoder().decode(ExplanationObservation.self, from: Data(existing.utf8)) == observation else {
                throw ExplanationStoreError.conflictingObservation
            }
            return
        }
        try database.transaction {
            let prefix = try prefixID(observation.context.auction, create: true)!
            try database.execute("INSERT INTO observations (id, prefix_id, candidate, context_key, body) VALUES (?, ?, ?, ?, ?)",
                [observation.id.uuidString, prefix, observation.candidate.description, try key(context), body])
        }
    }

    /// Exact paths are preferred. Same-path condition differences are explicitly related references.
    /// An unobserved or different auction path is a normal empty result.
    public func lookup(context: ExplanationContext, candidate: AuctionCall, limit: Int = 5) throws -> [ExplanationMatch] {
        let normalized = try NormalizedContext(context)
        let count = max(0, min(limit, 20))
        guard count > 0, let prefix = try prefixID(context.auction, create: false) else { return [] }
        let rows = try database.rows("SELECT body FROM observations WHERE prefix_id=? AND candidate=? ORDER BY CASE WHEN context_key=? THEN 0 ELSE 1 END, rowid DESC LIMIT ?",
            [prefix, candidate.description, try key(normalized), String(count)])
        return try rows.map { row in
            let observation = try JSONDecoder().decode(ExplanationObservation.self, from: Data(row[0].utf8))
            let differences = normalized.differences(from: try NormalizedContext(observation.context))
            return ExplanationMatch(observation: observation, status: differences.isEmpty ? .exact : .related, differences: differences)
        }
    }

    private func key(_ context: NormalizedContext) throws -> String { String(decoding: try encoder.encode(context), as: UTF8.self) }

    private func prefixID(_ auction: [AuctionEvent], create: Bool) throws -> String? {
        var parent = "1"
        for event in auction {
            if create { try database.execute("INSERT OR IGNORE INTO prefixes (parent_id, call) VALUES (?, ?)", [parent, event.call.description]) }
            guard let next = try database.rows("SELECT id FROM prefixes WHERE parent_id=? AND call=?", [parent, event.call.description]).first?.first else { return nil }
            parent = next
        }
        return parent
    }
}

private struct NormalizedContext: Codable {
    let actorPosition: Int
    let dealerSideSystem: String
    let otherSideSystem: String
    let dealerSideVulnerability: String
    let otherSideVulnerability: String
    let conditions: String

    init(_ context: ExplanationContext) throws {
        var seat = context.dealer
        for (index, event) in context.auction.enumerated() {
            guard event.sequence == index, event.seat == seat else { throw ExplanationStoreError.invalidContext }
            seat = seat.next
        }
        guard seat == context.actingSeat, !context.nsSystem.isEmpty, !context.ewSystem.isEmpty,
              !context.vulnerability.isEmpty else { throw ExplanationStoreError.invalidContext }
        actorPosition = context.auction.count % 4
        let dealerIsNS = context.dealer == .north || context.dealer == .south
        dealerSideSystem = dealerIsNS ? context.nsSystem : context.ewSystem
        otherSideSystem = dealerIsNS ? context.ewSystem : context.nsSystem
        let ns: String; let ew: String
        switch context.vulnerability.lowercased().replacingOccurrences(of: " ", with: "") {
        case "neither", "none", "love", "-": ns = "no"; ew = "no"
        case "ns", "n/s", "northsouth": ns = "yes"; ew = "no"
        case "ew", "e/w", "eastwest": ns = "no"; ew = "yes"
        case "both", "all": ns = "yes"; ew = "yes"
        default:
            // An unknown label is not normalized across differing compass orientation.
            ns = "unmapped:\(context.vulnerability):\(context.dealer.rawValue)"; ew = ns
        }
        dealerSideVulnerability = dealerIsNS ? ns : ew
        otherSideVulnerability = dealerIsNS ? ew : ns
        conditions = context.conditions
    }

    func differences(from other: NormalizedContext) -> [String] {
        var result: [String] = []
        if actorPosition != other.actorPosition { result.append("acting position differs") }
        if dealerSideSystem != other.dealerSideSystem || otherSideSystem != other.otherSideSystem { result.append("partnership systems differ") }
        if dealerSideVulnerability != other.dealerSideVulnerability || otherSideVulnerability != other.otherSideVulnerability { result.append("vulnerability differs") }
        if conditions != other.conditions { result.append("table conditions differ") }
        let unknownSystem = [dealerSideSystem, otherSideSystem, other.dealerSideSystem, other.otherSideSystem].contains {
            ["unknown", "unspecified", "未知", "未确认"].contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        }
        if unknownSystem { result.append("partnership system is unknown") }
        if dealerSideVulnerability.hasPrefix("unmapped:") || other.dealerSideVulnerability.hasPrefix("unmapped:") {
            result.append("vulnerability is not normalized")
        }
        return result
    }
}

private final class SQLiteDatabase: @unchecked Sendable {
    private var connection: OpaquePointer?
    init(url: URL) throws {
        guard sqlite3_open_v2(url.path, &connection, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            let detail = connection.map { String(cString: sqlite3_errmsg($0)) } ?? "Cannot open database"
            if let connection { sqlite3_close(connection) }; connection = nil
            throw ExplanationStoreError.database(detail)
        }
        sqlite3_busy_timeout(connection, 2000)
    }
    deinit { if let connection { sqlite3_close(connection) } }

    func execute(_ sql: String, _ values: [String] = []) throws {
        _ = try rows(sql, values)
    }
    func rows(_ sql: String, _ values: [String] = []) throws -> [[String]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, sql, -1, &statement, nil) == SQLITE_OK else { throw error() }
        defer { sqlite3_finalize(statement) }
        for (index, value) in values.enumerated() {
            guard sqlite3_bind_text(statement, Int32(index + 1), value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) == SQLITE_OK else { throw error() }
        }
        var result: [[String]] = []
        while true {
            let status = sqlite3_step(statement)
            if status == SQLITE_DONE { return result }
            guard status == SQLITE_ROW else { throw error() }
            result.append((0..<sqlite3_column_count(statement)).map { column in
                sqlite3_column_text(statement, column).map { String(cString: $0) } ?? ""
            })
        }
    }
    func transaction(_ body: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE")
        do { try body(); try execute("COMMIT") }
        catch { try? execute("ROLLBACK"); throw error }
    }
    private func error() -> ExplanationStoreError { .database(String(cString: sqlite3_errmsg(connection))) }
}
