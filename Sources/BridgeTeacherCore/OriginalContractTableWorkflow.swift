import Combine
import Foundation

public struct OriginalBoardIdentity: Equatable, Hashable, Sendable {
    public let boardID: UUID
    public let version: Int

    public init(_ facts: OriginalHandFacts) {
        boardID = facts.boardID
        version = facts.version
    }
}

public struct OriginalContractTableCell: Equatable, Sendable {
    public let strain: ContractStrain
    public let declarer: Seat
    public let tricks: Int

    public var contract: String {
        guard tricks >= 7 else { return "—" }
        let denomination: String
        switch strain {
        case .spades: denomination = "S"
        case .hearts: denomination = "H"
        case .diamonds: denomination = "D"
        case .clubs: denomination = "C"
        case .noTrump: denomination = "NT"
        }
        return "\(tricks - 6)\(denomination)"
    }
}

public struct OriginalContractTable: Equatable, Sendable {
    public static let strains: [ContractStrain] = [.spades, .hearts, .diamonds, .clubs, .noTrump]
    public static let declarers: [Seat] = [.north, .south, .east, .west]
    public let identity: OriginalBoardIdentity
    public let solverVersion: String
    public let cells: [OriginalContractTableCell]

    public func cell(strain: ContractStrain, declarer: Seat) -> OriginalContractTableCell? {
        cells.first { $0.strain == strain && $0.declarer == declarer }
    }
}

public enum OriginalContractTableState: Equatable, Sendable {
    case unavailable(String)
    case idle
    case calculating(completedCells: Int)
    case ready(OriginalContractTable)
    case failed(String)
}

public enum OriginalContractTableInputError: Error, LocalizedError {
    case incompleteBoard

    public var errorDescription: String? {
        "原始四手定约表需要每家 13 张、合计 52 张已确认且不重复的牌。请先补齐并核对原始牌面。"
    }
}

/// Solves the original board independently of selected contracts, teaching visibility,
/// and derived play positions. A stale calculation never publishes into another board.
@MainActor
public final class OriginalContractTableWorkflow: ObservableObject {
    @Published public private(set) var originalHandFacts: OriginalHandFacts
    @Published public private(set) var state: OriginalContractTableState
    private let solver: any DoubleDummySolving
    private var generation = UUID()
    private var cachedTable: OriginalContractTable?

    public var identity: OriginalBoardIdentity { OriginalBoardIdentity(originalHandFacts) }

    public init(originalHandFacts: OriginalHandFacts = OriginalHandFacts(), solver: any DoubleDummySolving) {
        self.originalHandFacts = originalHandFacts
        self.solver = solver
        self.state = Self.initialState(for: originalHandFacts)
    }

    public func updateOriginalHands(_ facts: OriginalHandFacts) {
        guard facts != originalHandFacts else { return }
        generation = UUID()
        originalHandFacts = facts
        cachedTable = nil
        state = Self.initialState(for: facts)
    }

    public func calculate() async {
        if let cachedTable, cachedTable.identity == identity {
            state = .ready(cachedTable)
            return
        }
        if case .calculating = state { return }
        let source = originalHandFacts
        let request = UUID()
        generation = request
        do {
            _ = try Self.position(facts: source, strain: .spades, declarer: .north)
            state = .calculating(completedCells: 0)
            var cells: [OriginalContractTableCell] = []
            for strain in OriginalContractTable.strains {
                for declarer in OriginalContractTable.declarers {
                    let position = try Self.position(facts: source, strain: strain, declarer: declarer)
                    let moves = try await solver.solve(position: position)
                    guard generation == request, identity == OriginalBoardIdentity(source) else { return }
                    let validated = try DoubleDummyVerificationResultBuilder.build(
                        from: moves, position: position, solverVersion: solver.version
                    )
                    // Opening leader is a defender. Best defense chooses the lead
                    // maximizing its own tricks, leaving 13 - that score to declarer.
                    guard let defensiveTricks = validated.moves.map(\.tricksForSideToPlay).max() else {
                        throw DoubleDummyResultError.missingLegalMove
                    }
                    cells.append(OriginalContractTableCell(
                        strain: strain, declarer: declarer, tricks: 13 - defensiveTricks
                    ))
                    state = .calculating(completedCells: cells.count)
                }
            }
            guard generation == request, identity == OriginalBoardIdentity(source) else { return }
            let table = OriginalContractTable(
                identity: OriginalBoardIdentity(source), solverVersion: solver.version, cells: cells
            )
            cachedTable = table
            state = .ready(table)
        } catch {
            guard generation == request, identity == OriginalBoardIdentity(source) else { return }
            if case .calculating = state {
                state = .failed(error.localizedDescription)
            } else {
                state = .unavailable(error.localizedDescription)
            }
        }
    }

    private static func initialState(for facts: OriginalHandFacts) -> OriginalContractTableState {
        do {
            _ = try position(facts: facts, strain: .spades, declarer: .north)
            return .idle
        } catch {
            return .unavailable(error.localizedDescription)
        }
    }

    private static func position(
        facts: OriginalHandFacts, strain: ContractStrain, declarer: Seat
    ) throws -> DoubleDummyVerificationPosition {
        _ = try facts.validatedHands()
        var draft = DoubleDummyVerificationDraft()
        draft.hands = facts.hands
        draft.trump = strain
        let seats = Seat.allCases
        let declarerIndex = seats.firstIndex(of: declarer)!
        draft.trickLeader = seats[(declarerIndex + 1) % seats.count]
        let position = try DoubleDummyVerificationPositionBuilder.build(from: draft)
        guard position.remainingTricks == 13 else { throw OriginalContractTableInputError.incompleteBoard }
        return position
    }
}
