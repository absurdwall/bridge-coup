import XCTest
@testable import BridgeTeacherCore

@MainActor
final class OriginalContractTableWorkflowTests: XCTestCase {
    func testOriginalTableUsesBestDefenseAndCorrectOpeningLeaderForEachDeclarer() async {
        let solver = TableTestSolver()
        let workflow = OriginalContractTableWorkflow(originalHandFacts: completeBoard(), solver: solver)
        await workflow.calculate()
        guard case .ready(let table) = workflow.state else { return XCTFail("Expected a complete table") }
        XCTAssertEqual(table.cells.count, 20)
        XCTAssertEqual(OriginalContractTable.strains, [.spades, .hearts, .diamonds, .clubs, .noTrump])
        XCTAssertEqual(OriginalContractTable.declarers, [.north, .south, .east, .west])
        // North's opening defender East can win six; South's West can win four.
        XCTAssertEqual(table.cell(strain: .spades, declarer: .north)?.contract, "1S")
        XCTAssertEqual(table.cell(strain: .diamonds, declarer: .south)?.contract, "3D")
        XCTAssertEqual(table.cell(strain: .clubs, declarer: .east)?.contract, "2C")
        XCTAssertEqual(table.cell(strain: .noTrump, declarer: .west)?.contract, "—")
    }

    func testSameOriginalBoardReusesTableAndChangingBoardInvalidatesBeforeRecomputation() async {
        let solver = TableTestSolver()
        let original = completeBoard()
        let workflow = OriginalContractTableWorkflow(originalHandFacts: original, solver: solver)
        await workflow.calculate()
        let first = workflow.state
        await workflow.calculate()
        XCTAssertEqual(workflow.state, first)
        let cachedCalls = await solver.callCount
        XCTAssertEqual(cachedCalls, 20)
        let next = OriginalHandFacts(boardID: UUID(), version: original.version, hands: original.hands)
        workflow.updateOriginalHands(next)
        XCTAssertEqual(workflow.state, .idle)
        await workflow.calculate()
        guard case .ready(let table) = workflow.state else { return XCTFail("Expected a complete new table") }
        XCTAssertEqual(table.identity.boardID, next.boardID)
        let changedCalls = await solver.callCount
        XCTAssertEqual(changedCalls, 40)
    }

    func testIncompleteDuplicateAndUnreviewedBoardsExplainWhyWithoutSolving() async {
        let solver = TableTestSolver()
        var duplicate = completeBoard().hands
        duplicate[.east]?[.spades] = "A"
        for original in [
            OriginalHandFacts(hands: [.north: [.spades: "AK"]]),
            OriginalHandFacts(hands: duplicate),
            OriginalHandFacts(hands: completeBoard().hands, decisionTimeConfirmed: false),
        ] {
            let workflow = OriginalContractTableWorkflow(originalHandFacts: original, solver: solver)
            await workflow.calculate()
            guard case .unavailable(let reason) = workflow.state else { return XCTFail("Invalid original input must be explained") }
            XCTAssertFalse(reason.isEmpty)
        }
        let calls = await solver.callCount
        XCTAssertEqual(calls, 0)
    }

    func testOldAsyncCompletionCannotReplaceNewBoardTable() async {
        let solver = TableTestSolver(holdFirst: true)
        let original = completeBoard()
        let workflow = OriginalContractTableWorkflow(originalHandFacts: original, solver: solver)
        let obsolete = Task { await workflow.calculate() }
        await solver.waitForHeldCall()
        guard case .calculating = workflow.state else { return XCTFail("Expected calculation state") }
        let next = OriginalHandFacts(boardID: original.boardID, version: original.version + 1, hands: original.hands)
        workflow.updateOriginalHands(next)
        await workflow.calculate()
        guard case .ready(let table) = workflow.state else { return XCTFail("Expected latest table") }
        XCTAssertEqual(table.identity.version, next.version)
        await solver.releaseHeldCall()
        await obsolete.value
        XCTAssertEqual(workflow.state, .ready(table))
    }

    func testFailureHidesPartialAnswersAndRetryProducesTheCompleteTable() async {
        let solver = TableTestSolver(failFirst: true)
        let workflow = OriginalContractTableWorkflow(originalHandFacts: completeBoard(), solver: solver)
        await workflow.calculate()
        guard case .failed(let message) = workflow.state else { return XCTFail("Failure should offer a retry") }
        XCTAssertFalse(message.isEmpty)
        await workflow.calculate()
        guard case .ready(let table) = workflow.state else { return XCTFail("Retry should produce a table") }
        XCTAssertEqual(table.cells.count, 20)
    }

    private func completeBoard() -> OriginalHandFacts {
        let suitBySeat: [Seat: Suit] = [.north: .spades, .east: .hearts, .south: .diamonds, .west: .clubs]
        let hands = Dictionary(uniqueKeysWithValues: Seat.allCases.map { seat in
            (seat, Dictionary(uniqueKeysWithValues: Suit.allCases.map { ($0, $0 == suitBySeat[seat] ? "AKQJT98765432" : "-") }))
        })
        return OriginalHandFacts(hands: hands)
    }
}

private actor TableTestSolver: DoubleDummySolving {
    nonisolated let version = "test-only"
    private(set) var callCount = 0
    private let holdFirst: Bool
    private let failFirst: Bool
    private var heldContinuation: CheckedContinuation<Void, Never>?
    private var waiter: CheckedContinuation<Void, Never>?

    init(holdFirst: Bool = false, failFirst: Bool = false) {
        self.holdFirst = holdFirst
        self.failFirst = failFirst
    }

    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        callCount += 1
        if failFirst, callCount == 1 { throw BundledDDSError.failed("test retry") }
        if holdFirst, callCount == 1 {
            await withCheckedContinuation { continuation in
                heldContinuation = continuation
                waiter?.resume()
                waiter = nil
            }
        }
        let defenderTricks: Int
        switch position.trickLeader {
        case .north: defenderTricks = 7
        case .east: defenderTricks = 6
        case .south: defenderTricks = 5
        case .west: defenderTricks = 4
        }
        return position.legalCards.enumerated().map { index, card in
            DoubleDummyEngineMove(card: card, equivalentCards: [], tricksForSideToPlay: index == 0 ? 0 : defenderTricks)
        }
    }

    func waitForHeldCall() async {
        if heldContinuation != nil { return }
        await withCheckedContinuation { waiter = $0 }
    }

    func releaseHeldCall() {
        heldContinuation?.resume()
        heldContinuation = nil
    }
}
