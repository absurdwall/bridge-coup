import Foundation
import XCTest
@testable import BridgeTeacherCore

@MainActor
final class DoubleDummySolverIntegrationTests: XCTestCase {
    func testBundledDDSFindsThirteenTricksInIndependentlyKnownDeal() async throws {
        let solver = try bundledSolver()
        var draft = DoubleDummyVerificationDraft()
        draft.trump = .spades
        draft.trickLeader = .north
        draft.hands[.north] = [.spades: "AKQJT98765432", .hearts: "-", .diamonds: "-", .clubs: "-"]
        draft.hands[.east] = [.spades: "-", .hearts: "AKQJT", .diamonds: "AKQJ", .clubs: "AKQJ"]
        draft.hands[.south] = [.spades: "-", .hearts: "98765", .diamonds: "T987", .clubs: "T987"]
        draft.hands[.west] = [.spades: "-", .hearts: "432", .diamonds: "65432", .clubs: "65432"]
        let position = try DoubleDummyVerificationPositionBuilder.build(from: draft)

        let engineMoves = try await solver.solve(position: position)
        let result = try DoubleDummyVerificationResultBuilder.build(
            from: engineMoves,
            position: position,
            solverVersion: solver.version
        )

        XCTAssertEqual(position.legalCards.count, 13)
        XCTAssertEqual(result.solverVersion, "3.0.0")
        XCTAssertEqual(result.moves.flatMap(\.cards).count, 13)
        XCTAssertEqual(result.moves.count, 1)
        XCTAssertEqual(result.moves[0].tricksForSideToPlay, 13)
    }

    func testBundledDDSHandlesPartialTrickAndDefenderToAct() async throws {
        let solver = try bundledSolver()
        var draft = DoubleDummyVerificationDraft()
        draft.trump = .noTrump
        draft.trickLeader = .north
        draft.currentTrickCards = "♣2 ♣A"
        draft.declarerSeat = .east
        draft.contractLevel = 1
        draft.declarerTricksAlreadyTaken = 0
        draft.hands[.north] = [.spades: "A", .hearts: "-", .diamonds: "-", .clubs: "-"]
        draft.hands[.east] = [.spades: "-", .hearts: "A", .diamonds: "-", .clubs: "-"]
        draft.hands[.south] = [.spades: "-", .hearts: "-", .diamonds: "2", .clubs: "K"]
        draft.hands[.west] = [.spades: "-", .hearts: "-", .diamonds: "3", .clubs: "Q"]
        let position = try DoubleDummyVerificationPositionBuilder.build(from: draft)

        let engineMoves = try await solver.solve(position: position)
        let result = try DoubleDummyVerificationResultBuilder.build(
            from: engineMoves,
            position: position,
            solverVersion: solver.version
        )

        XCTAssertEqual(position.actingSeat, .south)
        XCTAssertEqual(position.currentTrick.count, 2)
        XCTAssertEqual(position.remainingTricks, 2)
        XCTAssertEqual(position.legalCards, [DoubleDummyCard(suit: .clubs, rank: .king)])
        XCTAssertEqual(result.moves.count, 1)
        XCTAssertEqual(result.moves[0].tricksForSideToPlay, 0)
        XCTAssertEqual(result.moves[0].remainingTricksByDeclarer, 2)
        XCTAssertEqual(result.moves[0].totalTricksByDeclarer, 2)
        XCTAssertEqual(result.moves[0].contractDelta, -5)
    }

    func testBundledDDSUsesEachSelectedStrain() async throws {
        let solver = try bundledSolver()

        for strain in ContractStrain.allCases {
            let leadSuit: Suit = strain == .spades ? .hearts : .spades
            let trumpSuit: Suit
            switch strain {
            case .spades: trumpSuit = .spades
            case .hearts: trumpSuit = .hearts
            case .diamonds: trumpSuit = .diamonds
            case .clubs, .noTrump: trumpSuit = .clubs
            }

            var draft = DoubleDummyVerificationDraft()
            draft.trump = strain
            draft.trickLeader = .north
            draft.hands[.north] = oneCardHand(suit: leadSuit, rank: "A")
            draft.hands[.east] = oneCardHand(suit: trumpSuit, rank: "A")
            draft.hands[.south] = oneCardHand(suit: leadSuit, rank: "K")
            draft.hands[.west] = oneCardHand(suit: leadSuit, rank: "Q")
            let position = try DoubleDummyVerificationPositionBuilder.build(from: draft)

            let engineMoves = try await solver.solve(position: position)

            XCTAssertEqual(engineMoves.count, 1, "Unexpected move count for \(strain)")
            XCTAssertEqual(engineMoves[0].tricksForSideToPlay, strain == .noTrump ? 1 : 0, "Wrong strain mapping for \(strain)")
        }
    }

    private func bundledSolver() throws -> BundledDDSSolver {
        let configuredPath = ProcessInfo.processInfo.environment["BRIDGE_TEACHER_DDS_HELPER"]
        let helperPath = configuredPath ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/dds/bridge-dds").path
        let helperURL = URL(fileURLWithPath: helperPath)
        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            throw XCTSkip("Run Scripts/build-dds-helper.sh to build the pinned DDS helper for real-solver integration tests.")
        }
        return BundledDDSSolver(executableURL: helperURL)
    }

    private func oneCardHand(suit: Suit, rank: String) -> [Suit: String] {
        Dictionary(uniqueKeysWithValues: Suit.allCases.map { ($0, $0 == suit ? rank : "-") })
    }
}
