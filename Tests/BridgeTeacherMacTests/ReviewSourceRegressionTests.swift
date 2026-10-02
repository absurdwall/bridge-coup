import Foundation
import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

@MainActor
final class ReviewSourceRegressionTests: XCTestCase {
    func testFirstRecognitionDuringPlayStagesResetAndCancelPreservesSourcePositionAndHistory() async throws {
        let model = BridgeTeacherApplicationModel(screenshotRecognitionRuntime: RegressionRecognition())
        model.selectScreenshot(at: URL(fileURLWithPath: "/tmp/recognition-board.png"))
        model.updateReviewDraft(regressionBoard())
        XCTAssertTrue(model.startPlay())
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .hearts, rank: .ace), by: .east))
        let source = model.originalHandFacts
        let position = model.playSession
        let draft = model.workflow.draft
        await model.screenshotWorkflow.recognizeScreenshot()
        XCTAssertNotNil(model.pendingPlayReset)
        XCTAssertNil(model.screenshotWorkflow.candidate)
        XCTAssertNil(model.screenshotWorkflow.recognitionResponse)
        XCTAssertEqual(model.screenshotWorkflow.state, .idle)
        XCTAssertEqual(model.originalHandFacts, source)
        XCTAssertEqual(model.workflow.draft, draft)
        XCTAssertEqual(model.playSession, position)
        XCTAssertTrue(model.canUndoPlay)
        XCTAssertFalse(model.playCard(DoubleDummyCard(suit: .diamonds, rank: .ace), by: .south))
        model.cancelPlayReset()
        XCTAssertEqual(model.originalHandFacts, source)
        XCTAssertEqual(model.playSession, position)
        await model.screenshotWorkflow.recognizeScreenshot()
        XCTAssertNotNil(model.pendingPlayReset, "Cancelled first recognition remains available to retry")
        model.cancelPlayReset()
        XCTAssertTrue(model.undoPlay())
        XCTAssertTrue(model.redoPlay())
        XCTAssertEqual(model.playSession, position)
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .diamonds, rank: .ace), by: .south))
    }

    func testIndependentDDSChoiceSurvivesAllPlayAndInputTransitionsAndReopen() throws {
        for chooseIndependent in [false, true] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let store = LocalReviewSessionStore(directoryURL: directory)
            let (id, independent) = try saveLegacy(store: store)
            let model = BridgeTeacherApplicationModel(reviewStore: store)
            XCTAssertTrue(model.openReview(id: id))
            if chooseIndependent { model.keepLegacyDoubleDummyPosition() }
            XCTAssertTrue(model.startPlay())
            XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .hearts, rank: .ace), by: .east))
            XCTAssertTrue(model.undoPlay())
            XCTAssertTrue(model.redoPlay())
            XCTAssertTrue(model.restartPlay())
            XCTAssertEqual(model.doubleDummyWorkflow.draft, independent)
            var draft = model.workflow.draft
            draft.decisionTimeConfirmed = false
            model.updateReviewDraft(draft)
            model.confirmPlayReset()
            XCTAssertEqual(model.doubleDummyWorkflow.draft, independent)
            draft.decisionTimeConfirmed = true
            model.updateReviewDraft(draft)
            draft.hands[.north]?[.spades] = "KQJT98765432"
            model.updateReviewDraft(draft)
            model.saveReview()
            let restored = BridgeTeacherApplicationModel(reviewStore: store)
            XCTAssertTrue(restored.openReview(id: id))
            XCTAssertEqual(restored.doubleDummyWorkflow.draft, independent)
            XCTAssertEqual(restored.hasLegacyDoubleDummyConflict, !chooseIndependent)
            restored.useOriginalHandsForDoubleDummy()
            XCTAssertFalse(restored.hasLegacyDoubleDummyConflict)
            XCTAssertEqual(restored.doubleDummyWorkflow.draft.hands, draft.hands)
            restored.saveReview()
            let linked = BridgeTeacherApplicationModel(reviewStore: store)
            XCTAssertTrue(linked.openReview(id: id))
            XCTAssertFalse(linked.hasLegacyDoubleDummyConflict)
            XCTAssertEqual(linked.doubleDummyWorkflow.draft.hands, draft.hands)
        }
    }

    func testConfirmedRecognitionClearsOldPlayAndHistoryAndRequiresReviewBeforeStarting() async throws {
        let model = BridgeTeacherApplicationModel(screenshotRecognitionRuntime: RegressionRecognition())
        model.selectScreenshot(at: URL(fileURLWithPath: "/tmp/recognized-board.png"))
        model.updateReviewDraft(regressionBoard())
        XCTAssertTrue(model.startPlay())
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .hearts, rank: .ace), by: .east))
        await model.screenshotWorkflow.recognizeScreenshot()
        XCTAssertNotNil(model.pendingPlayReset)
        model.confirmPlayReset()
        XCTAssertNil(model.playSession)
        XCTAssertNotNil(model.screenshotWorkflow.candidate)
        XCTAssertNotNil(model.screenshotWorkflow.recognitionResponse)
        XCTAssertEqual(model.screenshotWorkflow.state, .succeeded)
        XCTAssertFalse(model.canUndoPlay)
        XCTAssertFalse(model.canRedoPlay)
        XCTAssertFalse(model.originalHandFacts.decisionTimeConfirmed)
        XCTAssertFalse(model.startPlay())
        var reviewed = model.workflow.draft
        reviewed.decisionTimeConfirmed = true
        model.updateReviewDraft(reviewed)
        XCTAssertTrue(model.startPlay())
        XCTAssertEqual(model.playSession?.currentTrick, [])
    }

    func testRecognitionStartedBeforePlayStillStagesWhenResponseArrives() async throws {
        let runtime = SuspendedRegressionRecognition()
        let model = BridgeTeacherApplicationModel(screenshotRecognitionRuntime: runtime)
        model.selectScreenshot(at: URL(fileURLWithPath: "/tmp/inflight-board.png"))
        model.updateReviewDraft(regressionBoard())
        let task = Task { await model.screenshotWorkflow.recognizeScreenshot() }
        while !(await runtime.isWaiting()) { await Task.yield() }
        XCTAssertTrue(model.startPlay())
        let source = model.originalHandFacts
        await runtime.finish()
        await task.value
        XCTAssertNotNil(model.pendingPlayReset)
        XCTAssertEqual(model.originalHandFacts, source)
        XCTAssertEqual(model.playSession?.originalVersion, source.version)
        model.cancelPlayReset()
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .hearts, rank: .ace), by: .east))
    }

    func testLateRecognitionCannotChangeReopenedRecordOrManualCorrections() async throws {
        for restoreSaved in [false, true] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let store = LocalReviewSessionStore(directoryURL: directory)
            let runtime = SuspendedRegressionRecognition()
            let model = BridgeTeacherApplicationModel(screenshotRecognitionRuntime: runtime, reviewStore: store)
            model.selectScreenshot(at: URL(fileURLWithPath: "/tmp/inflight-board.png"))
            model.updateReviewDraft(regressionBoard())
            let (id, _) = try saveLegacy(store: store)
            let task = Task { await model.screenshotWorkflow.recognizeScreenshot() }
            while !(await runtime.isWaiting()) { await Task.yield() }
            if restoreSaved { XCTAssertTrue(model.openReview(id: id)) }
            else {
                var corrected = model.workflow.draft
                corrected.question = "保留这次人工修正"
                model.updateReviewDraft(corrected)
            }
            let source = model.originalHandFacts
            let draft = model.workflow.draft
            await runtime.finish()
            await task.value
            XCTAssertNil(model.pendingPlayReset)
            XCTAssertEqual(model.originalHandFacts, source)
            XCTAssertEqual(model.workflow.draft, draft)
            XCTAssertTrue(model.originalHandFacts.decisionTimeConfirmed)
        }
    }

    func testStalePositionCannotAcceptCardsOrCollectAfterDirectSourceChange() throws {
        let model = BridgeTeacherApplicationModel()
        model.updateReviewDraft(regressionBoard())
        XCTAssertTrue(model.startPlay())
        for (seat, suit) in [(Seat.east, Suit.hearts), (.south, .diamonds), (.west, .clubs), (.north, .spades)] {
            XCTAssertTrue(model.playCard(DoubleDummyCard(suit: suit, rank: .ace), by: seat))
        }
        var invalidated = model.workflow.draft
        invalidated.decisionTimeConfirmed = false
        model.workflow.updateDraft(invalidated)
        XCTAssertNil(model.playSession)
        XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
        let unchanged = model.playSession
        XCTAssertFalse(model.collectPlayTrick())
        XCTAssertFalse(model.playCard(DoubleDummyCard(suit: .hearts, rank: .king), by: .east))
        XCTAssertEqual(model.playSession, unchanged)
    }

    func testUnresolvedLegacyDDSIsPreservedWhenPlayStartsAndReviewIsSaved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LocalReviewSessionStore(directoryURL: directory)
        let (id, independent) = try saveLegacy(store: store)
        let model = BridgeTeacherApplicationModel(reviewStore: store)
        XCTAssertTrue(model.openReview(id: id))
        XCTAssertTrue(model.hasLegacyDoubleDummyConflict)
        XCTAssertEqual(model.doubleDummyWorkflow.draft, independent)
        XCTAssertTrue(model.startPlay())
        model.saveReview()
        XCTAssertTrue(model.hasLegacyDoubleDummyConflict)
        XCTAssertEqual(model.doubleDummyWorkflow.draft, independent)
        XCTAssertEqual(try store.open(id: id).snapshot.doubleDummy.draft, independent)
    }
}

@MainActor
private func saveLegacy(store: LocalReviewSessionStore) throws -> (UUID, DoubleDummyVerificationDraft) {
    let writer = BridgeTeacherApplicationModel(reviewStore: store)
    writer.updateReviewDraft(regressionBoard())
    var independent = DoubleDummyVerificationDraft()
    independent.hands = [.north: [.spades: "A"]]
    independent.trump = .noTrump
    independent.trickLeader = .west
    let snapshot = ReviewSessionSnapshot(title: "独立旧 DDS", teachingMode: .declarerPlan,
        declarerPlan: writer.workflow.makeArchive(), screenshot: writer.screenshotWorkflow.makeArchive(),
        keyPlay: writer.keyPlayWorkflow.makeArchive(),
        doubleDummy: DoubleDummyVerificationWorkflowArchive(draft: independent, state: .unverified, result: nil, hasOutdatedResult: false))
    _ = try store.save(snapshot, screenshotURL: nil)
    return (snapshot.id, independent)
}
private func regressionBoard() -> DeclarerPlanDraft {
    var draft = DeclarerPlanDraft()
    draft.declarerSeat = .north
    draft.contractLevel = 7
    draft.contractStrain = .spades
    draft.decisionTimeVisibleSeats = [.north, .south]
    let suitBySeat: [Seat: Suit] = [.north: .spades, .east: .hearts, .south: .diamonds, .west: .clubs]
    for seat in Seat.allCases {
        for suit in Suit.allCases {
            draft.hands[seat, default: [:]][suit] = suitBySeat[seat] == suit ? "AKQJT98765432" : "-"
        }
    }
    return draft
}

private struct RegressionRecognition: ScreenshotRecognitionRuntime {
    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse {
        ScreenshotRecognitionResponse(candidate: ScreenshotRecognitionCandidate(hands: regressionBoard().hands,
            declarerSeat: .north, contractLevel: 7, contractStrain: .spades, openingLead: nil,
            otherDecisionTimeFacts: "", notes: []))
    }
}

private actor SuspendedRegressionRecognition: ScreenshotRecognitionRuntime {
    private var continuation: CheckedContinuation<ScreenshotRecognitionResponse, Never>?
    func isWaiting() -> Bool { continuation != nil }
    func finish() async {
        let response = try! await RegressionRecognition().recognizeScreenshot(at: URL(fileURLWithPath: "/tmp/board.png"))
        continuation?.resume(returning: response)
        continuation = nil
    }
    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse {
        await withCheckedContinuation { continuation = $0 }
    }
}
