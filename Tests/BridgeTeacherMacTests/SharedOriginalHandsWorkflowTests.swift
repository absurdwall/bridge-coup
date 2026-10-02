import Foundation
import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

@MainActor
final class SharedOriginalHandsWorkflowTests: XCTestCase {
    func testSharedImportedBoardRunsRealDDSWithoutIndependentInput() async throws {
        let helperPath = ProcessInfo.processInfo.environment["BRIDGE_TEACHER_DDS_HELPER"]
            ?? FileManager.default.currentDirectoryPath + "/.build/dds/bridge-dds"
        guard FileManager.default.isExecutableFile(atPath: helperPath) else {
            throw XCTSkip("Build the real DDS helper before accepting this integration check.")
        }
        let model = BridgeTeacherApplicationModel(doubleDummySolver: BundledDDSSolver(executableURL: URL(fileURLWithPath: helperPath)))
        var board = fullBoard()
        board.declarerSeat = .north
        model.updateReviewDraft(board)
        await model.verifyDoubleDummy()
        XCTAssertEqual(model.doubleDummyWorkflow.state, .verified)
        let result = try XCTUnwrap(model.doubleDummyWorkflow.result)
        XCTAssertEqual(result.solverVersion, "3.0.0")
        XCTAssertTrue(result.moves.allSatisfy { $0.totalTricksByDeclarer == 13 && $0.contractDelta == 6 })
        XCTAssertEqual(model.doubleDummyWorkflow.draft.hands, board.hands)
    }

    func testEnteredBoardFeedsDDSWithoutRepeatedEntryAndVisibilityDoesNotInvalidateSource() async throws {
        let model = BridgeTeacherApplicationModel(doubleDummySolver: KnownMovesSolver())
        model.updateReviewDraft(fullBoard())
        let version = model.originalHandFacts.version
        XCTAssertEqual(model.doubleDummyWorkflow.draft.hands, model.workflow.draft.hands)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.trickLeader, .west)
        await model.verifyDoubleDummy()
        XCTAssertEqual(model.doubleDummyWorkflow.state, .verified)

        let twoHands = try DeclarerPlanRequestBuilder.build(from: model.workflow.draft)
        XCTAssertEqual(Set(twoHands.visibleHands.map(\.seat)), [.north, .south])
        XCTAssertEqual(Set(twoHands.unknownSeats), [.east, .west])
        XCTAssertFalse(twoHands.prompt.contains("东家：♠缺门"))
        XCTAssertFalse(twoHands.prompt.contains("DDS"))
        var allVisible = model.workflow.draft
        allVisible.decisionTimeVisibleSeats = Set(Seat.allCases)
        model.updateReviewDraft(allVisible)
        let fourHands = try DeclarerPlanRequestBuilder.build(from: model.workflow.draft)
        XCTAssertEqual(fourHands.visibleHands.count, 4)
        XCTAssertTrue(fourHands.unknownSeats.isEmpty)
        XCTAssertEqual(model.originalHandFacts.version, version)
        XCTAssertEqual(model.doubleDummyWorkflow.state, .verified)
    }

    func testDerivedRemainingHandsNeverOverwriteOriginalAndOriginalEditStalesDDSAndTeaching() async throws {
        let model = BridgeTeacherApplicationModel(doubleDummySolver: KnownMovesSolver())
        model.updateReviewDraft(fullBoard())
        await model.verifyDoubleDummy()
        let source = model.originalHandFacts
        var remaining = model.doubleDummyWorkflow.draft
        remaining.hands[.north]?[.spades] = "KQJT98765432"
        remaining.currentTrickCards = "♠A"
        model.updateDoubleDummyDraft(remaining)
        XCTAssertEqual(model.originalHandFacts, source)
        XCTAssertEqual(model.workflow.draft.hands, source.hands)

        model.workflow.restore(from: DeclarerPlanWorkflowArchive(
            draft: model.workflow.draft, state: .succeeded,
            informationVersion: model.workflow.informationVersion,
            planAnalyses: [DeclarerPlanAnalysis(requestID: UUID(), informationVersion: model.workflow.informationVersion,
                response: DeclarerPlanResponse(text: "旧教学"))],
            currentPlanID: nil, followUpExchanges: [], followUpQuestion: "", followUpAssumptions: ""
        ))
        var changed = model.workflow.draft
        changed.hands[.north]?[.spades] = "KQJT98765432"
        model.updateReviewDraft(changed)
        XCTAssertGreaterThan(model.originalHandFacts.version, source.version)
        XCTAssertNil(model.doubleDummyWorkflow.result)
        XCTAssertEqual(model.doubleDummyWorkflow.state, .outdated)
        XCTAssertTrue(model.workflow.resultIsOutdated)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.currentTrickCards, "")
    }

    func testRevokingConfirmationClearsPreviousDDSResultEvenWhenHandsAreUnchanged() async {
        let model = BridgeTeacherApplicationModel(doubleDummySolver: KnownMovesSolver())
        model.updateReviewDraft(fullBoard())
        await model.verifyDoubleDummy()
        XCTAssertEqual(model.doubleDummyWorkflow.state, .verified)
        var unconfirmed = model.workflow.draft
        unconfirmed.decisionTimeConfirmed = false
        model.updateReviewDraft(unconfirmed)
        XCTAssertNil(model.doubleDummyWorkflow.result)
        XCTAssertEqual(model.doubleDummyWorkflow.state, .outdated)
        await model.verifyDoubleDummy()
        XCTAssertNil(model.doubleDummyWorkflow.result)
    }

    func testPartialTeachingKeepsUnknownDistinctFromVoidAndDDSDoesNotFillMissingCards() async throws {
        let model = BridgeTeacherApplicationModel(doubleDummySolver: KnownMovesSolver())
        var draft = fullBoard()
        draft.hands = [.south: [.hearts: "A2", .spades: "-", .clubs: ""]]
        model.updateReviewDraft(draft)
        let request = try DeclarerPlanRequestBuilder.build(from: model.workflow.draft)
        let hand = try XCTUnwrap(request.visibleHands.first)
        XCTAssertEqual(hand.cardsBySuit[.spades], [])
        XCTAssertNil(hand.cardsBySuit[.clubs])
        XCTAssertNil(hand.cardsBySuit[.diamonds])
        await model.verifyDoubleDummy()
        guard case .insufficient = model.doubleDummyWorkflow.state else { return XCTFail("Incomplete board must remain insufficient") }
        XCTAssertEqual(model.originalHandFacts.hands, draft.hands)
        draft.hands[.north] = [.hearts: "A"]
        model.updateReviewDraft(draft)
        XCTAssertThrowsError(try model.originalHandFacts.validatedHands())
    }

    func testScreenshotRecognitionSharesCandidateButRequiresConfirmationBeforeDDS() async throws {
        let model = BridgeTeacherApplicationModel(screenshotRecognitionRuntime: BoardScreenshotRuntime(), doubleDummySolver: KnownMovesSolver())
        model.screenshotWorkflow.selectScreenshot(at: URL(fileURLWithPath: "/tmp/board.png"))
        await model.screenshotWorkflow.recognizeScreenshot()
        XCTAssertEqual(model.originalHandFacts.hands, fullBoard().hands)
        XCTAssertFalse(model.originalHandFacts.decisionTimeConfirmed)
        await model.verifyDoubleDummy()
        XCTAssertNil(model.doubleDummyWorkflow.result)
        var reviewed = model.workflow.draft
        reviewed.decisionTimeConfirmed = true
        reviewed.decisionTimeVisibleSeats = [.north, .south]
        model.updateReviewDraft(reviewed)
        await model.verifyDoubleDummy()
        XCTAssertEqual(model.doubleDummyWorkflow.state, .verified)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.hands, fullBoard().hands)
    }

    func testLegacyConflictPreservesBothInputsUntilExplicitChoiceAndNewDerivedArchiveRoundTrips() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LocalReviewSessionStore(directoryURL: directory)
        let writer = BridgeTeacherApplicationModel(reviewStore: store)
        writer.updateReviewDraft(fullBoard())
        var independent = writer.doubleDummyWorkflow.draft
        independent.hands = [.north: [.spades: "A"]]
        let legacy = ReviewSessionSnapshot(title: "旧复盘", teachingMode: .declarerPlan,
            declarerPlan: writer.workflow.makeArchive(), screenshot: writer.screenshotWorkflow.makeArchive(),
            keyPlay: writer.keyPlayWorkflow.makeArchive(),
            doubleDummy: DoubleDummyVerificationWorkflowArchive(draft: independent, state: .unverified, result: nil, hasOutdatedResult: false))
        _ = try store.save(legacy, screenshotURL: nil)
        let model = BridgeTeacherApplicationModel(reviewStore: store)
        XCTAssertTrue(model.openReview(id: legacy.id))
        XCTAssertTrue(model.hasLegacyDoubleDummyConflict)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.hands, independent.hands)
        XCTAssertEqual(model.workflow.draft.hands, fullBoard().hands)
        model.useOriginalHandsForDoubleDummy()
        XCTAssertFalse(model.hasLegacyDoubleDummyConflict)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.hands, fullBoard().hands)
        var derived = model.doubleDummyWorkflow.draft
        derived.hands[.north]?[.spades] = "KQJT98765432"
        derived.currentTrickCards = "♠A"
        model.updateDoubleDummyDraft(derived)
        model.saveReview()
        let reopened = BridgeTeacherApplicationModel(reviewStore: store)
        XCTAssertTrue(reopened.openReview(id: legacy.id))
        XCTAssertFalse(reopened.hasLegacyDoubleDummyConflict)
        XCTAssertEqual(reopened.originalHandFacts, model.originalHandFacts)
        XCTAssertEqual(reopened.doubleDummyWorkflow.draft.hands, derived.hands)
        XCTAssertEqual(reopened.workflow.draft.hands, fullBoard().hands)
    }
}

private func fullBoard() -> DeclarerPlanDraft {
    var draft = DeclarerPlanDraft()
    draft.declarerSeat = .south
    draft.contractLevel = 1
    draft.contractStrain = .spades
    draft.decisionTimeVisibleSeats = [.north, .south]
    draft.hands[.north] = [.spades: "AKQJT98765432", .hearts: "-", .diamonds: "-", .clubs: "-"]
    draft.hands[.east] = [.spades: "-", .hearts: "AKQJT", .diamonds: "AKQJ", .clubs: "AKQJ"]
    draft.hands[.south] = [.spades: "-", .hearts: "98765", .diamonds: "T987", .clubs: "T987"]
    draft.hands[.west] = [.spades: "-", .hearts: "432", .diamonds: "65432", .clubs: "65432"]
    return draft
}

private struct KnownMovesSolver: DoubleDummySolving {
    let version = "workflow-test"
    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        position.legalCards.map { DoubleDummyEngineMove(card: $0, equivalentCards: [], tricksForSideToPlay: position.remainingTricks) }
    }
}

private struct BoardScreenshotRuntime: ScreenshotRecognitionRuntime {
    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse {
        ScreenshotRecognitionResponse(candidate: ScreenshotRecognitionCandidate(hands: fullBoard().hands,
            declarerSeat: .south, contractLevel: 1, contractStrain: .spades, openingLead: nil,
            otherDecisionTimeFacts: "", notes: []))
    }
}
