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

    func testOriginalTwentyCellTableMatchesIndependentPureSuitDeal() async throws {
        let solver = try bundledSolver()
        let hands = pureSuitOriginalHands()
        let workflow = OriginalContractTableWorkflow(originalHandFacts: OriginalHandFacts(hands: hands), solver: solver)
        await workflow.calculate()
        guard case .ready(let table) = workflow.state else { return XCTFail("Real DDS table failed: \(workflow.state)") }
        XCTAssertEqual(table.cells.count, 20)
        XCTAssertEqual(table.solverVersion, "3.0.0")
        // Each seat holds one entire suit. Trump owners can take all thirteen;
        // in NT the defender on opening lead cashes their entire suit.
        for strain in OriginalContractTable.strains {
            for declarer in OriginalContractTable.declarers {
                let northSouth = declarer == .north || declarer == .south
                let ownsTrump = (northSouth && (strain == .spades || strain == .diamonds))
                    || (!northSouth && (strain == .hearts || strain == .clubs))
                let expectedTricks = ownsTrump ? 13 : 0
                let cell = try XCTUnwrap(table.cell(strain: strain, declarer: declarer))
                XCTAssertEqual(cell.tricks, expectedTricks, "Wrong real DDS value for \(strain), \(declarer)")
                XCTAssertEqual(cell.contract, ownsTrump ? "7" + strainContractLetter(strain) : "—")
            }
        }
    }

    func testOriginalTableDistinguishesDeclarersByActualOpeningLeaderAndFullContractNotation() async throws {
        let solver = try bundledSolver()
        var hands = pureSuitOriginalHands()
        // Exchange South's diamond two and West's club ace. In NT, East
        // cashes thirteen hearts against North. Against South, West cannot
        // reach East: either opening suit loses to South, who cashes twelve
        // diamonds plus the club ace. In clubs, defense gets the club ace
        // and one diamond while West must follow with diamond two: 11 tricks.
        hands[.south] = [.spades: "-", .hearts: "-", .diamonds: "AKQJT9876543", .clubs: "A"]
        hands[.west] = [.spades: "-", .hearts: "-", .diamonds: "2", .clubs: "KQJT98765432"]
        let workflow = OriginalContractTableWorkflow(originalHandFacts: OriginalHandFacts(hands: hands), solver: solver)
        await workflow.calculate()
        guard case .ready(let table) = workflow.state else { return XCTFail("Real DDS table failed: \(workflow.state)") }
        XCTAssertEqual(table.cell(strain: .noTrump, declarer: .north)?.tricks, 0)
        XCTAssertEqual(table.cell(strain: .noTrump, declarer: .north)?.contract, "—")
        XCTAssertEqual(table.cell(strain: .noTrump, declarer: .south)?.tricks, 13)
        XCTAssertEqual(table.cell(strain: .noTrump, declarer: .south)?.contract, "7NT")
        XCTAssertEqual(table.cell(strain: .clubs, declarer: .west)?.contract, "5C")
        XCTAssertEqual(table.cell(strain: .diamonds, declarer: .south)?.contract, "7D")
    }

    func testOriginalTableShowsSmallSlamAtTwelveTricks() async throws {
        let solver = try bundledSolver()
        var hands = pureSuitOriginalHands()
        // East owns the trump ace. North has all twelve other trumps and a
        // diamond; South has the other twelve diamonds and heart two. East
        // takes one trump trick, then North ruffs and NS wins the remainder.
        hands[.north] = [.spades: "KQJT98765432", .hearts: "-", .diamonds: "2", .clubs: "-"]
        hands[.east] = [.spades: "A", .hearts: "AKQJT9876543", .diamonds: "-", .clubs: "-"]
        hands[.south] = [.spades: "-", .hearts: "2", .diamonds: "AKQJT9876543", .clubs: "-"]
        let workflow = OriginalContractTableWorkflow(originalHandFacts: OriginalHandFacts(hands: hands), solver: solver)
        await workflow.calculate()
        guard case .ready(let table) = workflow.state else { return XCTFail("Real DDS table failed: \(workflow.state)") }
        XCTAssertEqual(table.cell(strain: .spades, declarer: .north)?.tricks, 12)
        XCTAssertEqual(table.cell(strain: .spades, declarer: .north)?.contract, "6S")
        XCTAssertEqual(table.cell(strain: .spades, declarer: .south)?.contract, "6S")
    }

    private func pureSuitOriginalHands() -> [Seat: [Suit: String]] {
        let suitBySeat: [Seat: Suit] = [.north: .spades, .east: .hearts, .south: .diamonds, .west: .clubs]
        return Dictionary(uniqueKeysWithValues: Seat.allCases.map { seat in
            (seat, Dictionary(uniqueKeysWithValues: Suit.allCases.map { ($0, $0 == suitBySeat[seat] ? "AKQJT98765432" : "-") }))
        })
    }

    private func strainContractLetter(_ strain: ContractStrain) -> String {
        switch strain {
        case .spades: "S"
        case .hearts: "H"
        case .diamonds: "D"
        case .clubs: "C"
        case .noTrump: "NT"
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
