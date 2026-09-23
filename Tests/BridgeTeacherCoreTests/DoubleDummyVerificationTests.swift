import XCTest
@testable import BridgeTeacherCore

@MainActor
final class DoubleDummyVerificationTests: XCTestCase {
    func testPartialTrickDeterminesActorAndFollowingSuitLegalCards() throws {
        var draft = partialTrickDraft()
        draft.hands[.east] = [.spades: "AK", .hearts: "-", .diamonds: "-", .clubs: "-"]

        let position = try DoubleDummyVerificationPositionBuilder.build(from: draft)

        XCTAssertEqual(position.trickLeader, .north)
        XCTAssertEqual(position.currentTrick, [DoubleDummyCard(suit: .spades, rank: .two)])
        XCTAssertEqual(position.actingSeat, .east)
        XCTAssertEqual(position.legalCards, [
            DoubleDummyCard(suit: .spades, rank: .ace),
            DoubleDummyCard(suit: .spades, rank: .king),
        ])
        XCTAssertEqual(position.remainingTricks, 2)
    }

    func testOffSuitCardIsRejectedWhenThatPlayerStillHasLedSuit() {
        var draft = partialTrickDraft()
        draft.currentTrickCards = "♠2 ♥3"
        draft.hands[.north] = [.spades: "-", .hearts: "-", .diamonds: "-", .clubs: "A"]
        draft.hands[.east] = [.spades: "A", .hearts: "-", .diamonds: "-", .clubs: "-"]
        draft.hands[.south] = [.spades: "-", .hearts: "Q", .diamonds: "A", .clubs: "-"]
        draft.hands[.west] = [.spades: "-", .hearts: "-", .diamonds: "K", .clubs: "2"]

        XCTAssertThrowsError(try DoubleDummyVerificationPositionBuilder.build(from: draft)) { error in
            XCTAssertEqual(error as? DoubleDummyVerificationInputError, .playerStillHasLedSuit(.east, .spades))
        }
    }

    func testDefenderToMoveResultIsConvertedToDeclarerTricksAndContractOutcome() throws {
        var draft = oneTrickDraft(leader: .west)
        draft.declarerSeat = .south
        draft.contractLevel = 1
        draft.declarerTricksAlreadyTaken = 9

        let position = try DoubleDummyVerificationPositionBuilder.build(from: draft)
        let card = try XCTUnwrap(position.legalCards.first)
        let result = try DoubleDummyVerificationResultBuilder.build(
            from: [DoubleDummyEngineMove(card: card, equivalentCards: [], tricksForSideToPlay: 1)],
            position: position,
            solverVersion: "test"
        )

        XCTAssertEqual(position.actingSeat, .west)
        XCTAssertEqual(result.moves.count, 1)
        XCTAssertEqual(result.moves[0].remainingTricksByDeclarer, 0)
        XCTAssertEqual(result.moves[0].totalTricksByDeclarer, 9)
        XCTAssertEqual(result.moves[0].contractDelta, 2)
    }

    func testEquivalentCardsAreExpandedAndEveryLegalCardMustHaveAResult() throws {
        var draft = DoubleDummyVerificationDraft()
        draft.trump = .noTrump
        draft.trickLeader = .north
        draft.hands[.north] = [.spades: "AK", .hearts: "-", .diamonds: "-", .clubs: "-"]
        draft.hands[.east] = [.spades: "-", .hearts: "AK", .diamonds: "-", .clubs: "-"]
        draft.hands[.south] = [.spades: "-", .hearts: "-", .diamonds: "AK", .clubs: "-"]
        draft.hands[.west] = [.spades: "-", .hearts: "-", .diamonds: "-", .clubs: "AK"]
        let position = try DoubleDummyVerificationPositionBuilder.build(from: draft)
        let move = DoubleDummyEngineMove(
            card: DoubleDummyCard(suit: .spades, rank: .ace),
            equivalentCards: [DoubleDummyCard(suit: .spades, rank: .king)],
            tricksForSideToPlay: 1
        )

        let result = try DoubleDummyVerificationResultBuilder.build(
            from: [move],
            position: position,
            solverVersion: "test"
        )

        XCTAssertEqual(result.moves[0].cards, [
            DoubleDummyCard(suit: .spades, rank: .ace),
            DoubleDummyCard(suit: .spades, rank: .king),
        ])
        XCTAssertThrowsError(try DoubleDummyVerificationResultBuilder.build(
            from: [],
            position: position,
            solverVersion: "test"
        ))
    }

    func testIncompletePositionNeverCallsSolverAndReportsSpecificMissingHolding() async {
        let solver = RecordingDoubleDummySolver()
        var draft = oneTrickDraft(leader: .north)
        draft.hands[.west, default: [:]][.clubs] = ""
        let workflow = DoubleDummyVerificationWorkflow(draft: draft, solver: solver)

        await workflow.verify()

        XCTAssertEqual(workflow.state, .insufficient("请确认西家♣是已知牌面，缺门请填 -。"))
        let calls = await solver.calls()
        XCTAssertEqual(calls, 0)
        XCTAssertNil(workflow.result)
    }

    func testVerifiedResultBecomesOutdatedAfterAnyCorrection() async {
        let solver = RecordingDoubleDummySolver()
        let draft = oneTrickDraft(leader: .north)
        let workflow = DoubleDummyVerificationWorkflow(draft: draft, solver: solver)

        await workflow.verify()

        XCTAssertEqual(workflow.state, .verified)
        XCTAssertNotNil(workflow.result)

        var correctedDraft = draft
        correctedDraft.hands[.north, default: [:]][.spades] = "K"
        workflow.updateDraft(correctedDraft)

        XCTAssertEqual(workflow.state, .outdated)
        XCTAssertNil(workflow.result)
        XCTAssertTrue(workflow.hasOutdatedResult)
    }

    func testSolverFailureDoesNotExposeNumericResult() async {
        let workflow = DoubleDummyVerificationWorkflow(
            draft: oneTrickDraft(leader: .north),
            solver: FailingDoubleDummySolver()
        )

        await workflow.verify()

        XCTAssertEqual(workflow.state, .failed("DDS failed"))
        XCTAssertNil(workflow.result)

        workflow.updateDraft(oneTrickDraft(leader: .east))
        XCTAssertEqual(workflow.state, .unverified)
    }

    private func partialTrickDraft() -> DoubleDummyVerificationDraft {
        var draft = DoubleDummyVerificationDraft()
        draft.trump = .spades
        draft.trickLeader = .north
        draft.currentTrickCards = "♠2"
        draft.hands[.north] = [.spades: "-", .hearts: "A", .diamonds: "-", .clubs: "-"]
        draft.hands[.east] = [.spades: "-", .hearts: "-", .diamonds: "A", .clubs: "K"]
        draft.hands[.south] = [.spades: "-", .hearts: "K", .diamonds: "Q", .clubs: "-"]
        draft.hands[.west] = [.spades: "-", .hearts: "Q", .diamonds: "-", .clubs: "A"]
        return draft
    }

    private func oneTrickDraft(leader: Seat) -> DoubleDummyVerificationDraft {
        var draft = DoubleDummyVerificationDraft()
        draft.trump = .noTrump
        draft.trickLeader = leader
        draft.hands[.north] = [.spades: "A", .hearts: "-", .diamonds: "-", .clubs: "-"]
        draft.hands[.east] = [.spades: "-", .hearts: "K", .diamonds: "-", .clubs: "-"]
        draft.hands[.south] = [.spades: "-", .hearts: "-", .diamonds: "Q", .clubs: "-"]
        draft.hands[.west] = [.spades: "-", .hearts: "-", .diamonds: "-", .clubs: "2"]
        return draft
    }
}

private actor RecordingDoubleDummySolver: DoubleDummySolving {
    private var count = 0

    nonisolated var version: String { "test" }

    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        count += 1
        return position.legalCards.map {
            DoubleDummyEngineMove(card: $0, equivalentCards: [], tricksForSideToPlay: position.remainingTricks)
        }
    }

    func calls() -> Int { count }
}

private struct FailingDoubleDummySolver: DoubleDummySolving {
    var version: String { "test" }

    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        throw TestSolverError.failed
    }
}

private enum TestSolverError: Error, LocalizedError {
    case failed

    var errorDescription: String? { "DDS failed" }
}
