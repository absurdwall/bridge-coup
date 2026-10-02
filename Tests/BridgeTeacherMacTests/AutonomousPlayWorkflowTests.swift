import Foundation
import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

@MainActor
final class AutonomousPlayWorkflowTests: XCTestCase {
    func testStartRequiresCompleteValidKnownHandsContractAndReviewedScreenshot() {
        let model = BridgeTeacherApplicationModel()
        XCTAssertFalse(model.startPlay())
        var draft = board()
        draft.hands[.east]?[.clubs] = ""
        model.updateReviewDraft(draft)
        XCTAssertFalse(model.startPlay())
        XCTAssertNotNil(model.playStartReason)
        draft = board()
        draft.hands[.east]?[.spades] = "A"
        model.updateReviewDraft(draft)
        XCTAssertFalse(model.startPlay())
        draft = board()
        draft.decisionTimeConfirmed = false
        model.updateReviewDraft(draft)
        XCTAssertFalse(model.startPlay())
        draft = board()
        draft.contractLevel = nil
        model.updateReviewDraft(draft)
        XCTAssertFalse(model.startPlay())
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        XCTAssertFalse(model.startPlay(), "Starting twice must not discard progress")
    }

    func testExplicitSuppliedLeadIsValidatedPlayedOnceAndOriginalRemainsIntact() throws {
        let model = BridgeTeacherApplicationModel()
        var draft = board()
        draft.openingLead = "SA" // South declarer -> west first lead; west has no spades.
        model.updateReviewDraft(draft)
        XCTAssertFalse(model.startPlay())
        draft.openingLead = "H4"
        model.updateReviewDraft(draft)
        let original = model.originalHandFacts
        XCTAssertTrue(model.startPlay())
        let session = try XCTUnwrap(model.playSession)
        XCTAssertEqual(session.currentTrick, [BridgePlayedCard(seat: .west, card: card(.hearts, .four))])
        XCTAssertEqual(session.actingSeat, .north)
        XCTAssertFalse(session.remainingHands[.west]?[.hearts]?.contains(.four) == true)
        XCTAssertFalse(model.playCard(card(.hearts, .four), by: .west))
        XCTAssertEqual(model.originalHandFacts, original)
        XCTAssertEqual(model.workflow.draft.openingLead, "♥4")
        XCTAssertTrue(model.playStatus.contains("只能"))
    }

    func testTurnFollowingSuitAndManualCollectionUseTrumpAndNoTrumpWinners() throws {
        for strain: ContractStrain in [.spades, .noTrump] {
            let model = BridgeTeacherApplicationModel()
            var draft = board()
            draft.contractStrain = strain
            model.updateReviewDraft(draft)
            XCTAssertTrue(model.startPlay())
            let original = model.originalHandFacts
            XCTAssertFalse(model.collectPlayTrick())
            XCTAssertFalse(model.playCard(card(.hearts, .king), by: .east))
            XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
            XCTAssertTrue(model.playCard(card(.spades, .ace), by: .north))
            XCTAssertFalse(model.playCard(card(.diamonds, .ace), by: .east), "East must follow hearts")
            XCTAssertTrue(model.playCard(card(.hearts, .king), by: .east))
            XCTAssertTrue(model.playCard(card(.hearts, .nine), by: .south))
            let completed = try XCTUnwrap(model.playSession)
            XCTAssertEqual(completed.currentTrick.count, 4)
            XCTAssertTrue(completed.awaitingCollection)
            XCTAssertNil(completed.actingSeat)
            XCTAssertFalse(model.playCard(card(.hearts, .three), by: .west))
            XCTAssertTrue(model.collectPlayTrick())
            XCTAssertEqual(model.playSession?.actingSeat, strain == .spades ? .north : .east)
            XCTAssertEqual(model.playSession?.northSouthTricks, strain == .spades ? 1 : 0)
            XCTAssertEqual(model.playSession?.eastWestTricks, strain == .spades ? 0 : 1)
            XCTAssertEqual(model.originalHandFacts, original)
        }
    }

    func testAllThirteenTricksFinishAndEveryOriginalCardIsPlayedExactlyOnce() throws {
        let model = BridgeTeacherApplicationModel()
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        let original = model.originalHandFacts
        for _ in 0..<13 {
            for _ in 0..<4 {
                let session = try XCTUnwrap(model.playSession)
                let seat = try XCTUnwrap(session.actingSeat)
                XCTAssertTrue(model.playCard(try XCTUnwrap(session.legalCards.first), by: seat))
            }
            XCTAssertTrue(model.collectPlayTrick())
        }
        let session = try XCTUnwrap(model.playSession)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.completedTricks.count, 13)
        XCTAssertEqual(Set(session.completedTricks.flatMap { $0.map(\.card) }).count, 52)
        XCTAssertEqual(session.northSouthTricks + session.eastWestTricks, 13)
        XCTAssertNil(session.actingSeat)
        XCTAssertTrue(session.legalCards.isEmpty)
        XCTAssertEqual(session.actualContractDelta, session.declarerTricks - 7)
        XCTAssertFalse(model.playCard(card(.spades, .ace), by: .north))
        XCTAssertEqual(model.originalHandFacts, original)
        XCTAssertEqual(model.workflow.draft.hands, original.hands)
        XCTAssertNoThrow(try DeclarerPlanRequestBuilder.build(from: model.currentTeachingDraft))
    }

    func testTeachingRequestsUseSelectedRemainingHandsPublicHistoryAndBecomeOutdated() async throws {
        let runtime = RecordingTeachingRuntime()
        let model = BridgeTeacherApplicationModel(teachingRuntime: runtime)
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        await model.workflow.generatePlan()
        XCTAssertFalse(model.workflow.resultIsOutdated)
        let oldRevision = model.playPositionRevision
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        XCTAssertGreaterThan(model.playPositionRevision, oldRevision)
        XCTAssertTrue(model.workflow.resultIsOutdated)
        await model.workflow.generatePlan()
        let latest = await runtime.latest()
        let request = try XCTUnwrap(latest)
        XCTAssertEqual(Set(request.visibleHands.map(\.seat)), [.north, .south])
        XCTAssertEqual(Set(request.unknownSeats), [.east, .west])
        XCTAssertTrue(request.prompt.contains("西家：♥4"), "Played cards are public even when seat hand remains hidden")
        XCTAssertFalse(request.prompt.contains("DDS"))
        var visible = model.workflow.draft
        visible.decisionTimeVisibleSeats = Set(Seat.allCases)
        model.updateReviewDraft(visible)
        XCTAssertNil(model.pendingPlayReset)
        await model.workflow.generatePlan()
        let latestFour = await runtime.latest()
        let fourHandRequest = try XCTUnwrap(latestFour)
        XCTAssertEqual(fourHandRequest.visibleHands.count, 4)
        XCTAssertFalse(try XCTUnwrap(fourHandRequest.visibleHands.first { $0.seat == .west }).cardsBySuit[.hearts]?.contains(.four) == true)
        XCTAssertEqual(model.workflow.draft.hands[.west]?[.hearts], "432")
    }

    func testLateTeachingResponseCannotBecomeCurrentAfterPlayChanges() async {
        let runtime = SuspendedTeachingRuntime()
        let model = BridgeTeacherApplicationModel(teachingRuntime: runtime)
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        let task = Task { await model.workflow.generatePlan() }
        while !(await runtime.isWaiting()) { await Task.yield() }
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        await runtime.finish()
        await task.value
        XCTAssertNil(model.workflow.result)
        XCTAssertEqual(model.workflow.state, .idle)
    }

    func testReplacingScreenshotWithPlayProgressCanBeCancelledBeforeChangingSource() {
        let model = BridgeTeacherApplicationModel()
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        let source = model.originalHandFacts
        let position = model.playSession
        model.selectScreenshot(at: URL(fileURLWithPath: "/tmp/new-board.png"))
        XCTAssertNotNil(model.pendingPlayReset)
        XCTAssertNil(model.screenshotWorkflow.screenshotURL)
        model.cancelPlayReset()
        XCTAssertEqual(model.originalHandFacts, source)
        XCTAssertEqual(model.playSession, position)
    }

    func testUIWarningAndSubmissionUseRemainingHandsForVisibleCardInPartialTrick() async throws {
        let runtime = RecordingTeachingRuntime()
        let model = BridgeTeacherApplicationModel(teachingRuntime: runtime)
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        XCTAssertTrue(model.playCard(card(.spades, .ace), by: .north))
        XCTAssertTrue(model.workflow.draft.hands[.north]?[.spades]?.contains("A") == true)
        XCTAssertNil(model.keyPlayInputWarning)
        await model.keyPlayWorkflow.generate(from: model.currentTeachingDraft, informationVersion: model.workflow.informationVersion)
        XCTAssertEqual(model.keyPlayWorkflow.state, .succeeded)
        let latest = await runtime.latest()
        let request = try XCTUnwrap(latest)
        XCTAssertFalse(try XCTUnwrap(request.visibleHands.first { $0.seat == .north }).cardsBySuit[.spades]?.contains(.ace) == true)
        XCTAssertTrue(request.prompt.contains("♠A"), "The removed card remains public current-trick history")
        XCTAssertEqual(Set(request.unknownSeats), [.east, .west])
    }

    func testReplacedOpeningLeadRejectsOldPositionAndArchiveRestorationUsesSameGuard() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalReviewSessionStore(directoryURL: root)
        let model = BridgeTeacherApplicationModel(reviewStore: store)
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        let oldPosition = try XCTUnwrap(model.playSession)
        var changed = model.workflow.draft
        changed.openingLead = "H4"
        model.updateReviewDraft(changed)
        model.confirmPlayReset()
        XCTAssertFalse(model.replacePlaySession(oldPosition), "Source version is unchanged but opening-lead dependency changed")
        XCTAssertTrue(model.startPlay())
        model.saveReview()
        let saved = try XCTUnwrap(store.list().first)
        var snapshot = try store.open(id: saved.id).snapshot
        snapshot.playSession = oldPosition
        _ = try store.save(snapshot, screenshotURL: nil)
        let reopened = BridgeTeacherApplicationModel(reviewStore: store)
        XCTAssertTrue(reopened.openReview(id: saved.id))
        XCTAssertNil(reopened.playSession, "Archive restoration rejects the same incompatible supplied-lead position")
        XCTAssertEqual(reopened.workflow.draft.openingLead, "♥4")
    }

    func testOriginalOrContractEditRequiresExplicitResetAndCancellationPreservesEverything() throws {
        let model = BridgeTeacherApplicationModel()
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        let session = model.playSession
        let original = model.originalHandFacts
        let oldDraft = model.workflow.draft
        var changed = oldDraft
        changed.hands[.north]?[.spades] = "KQJT98765432"
        model.updateReviewDraft(changed)
        XCTAssertNotNil(model.pendingPlayReset)
        XCTAssertEqual(model.workflow.draft, oldDraft)
        XCTAssertEqual(model.playSession, session)
        model.cancelPlayReset()
        XCTAssertEqual(model.originalHandFacts, original)
        XCTAssertEqual(model.playSession, session)
        model.handleContractSelectionAction(.select(ContractChoice(level: 3, strain: .noTrump)))
        XCTAssertNotNil(model.pendingPlayReset)
        model.confirmPlayReset()
        XCTAssertNil(model.playSession)
        XCTAssertEqual(model.workflow.draft.contractLevel, 3)
        XCTAssertEqual(model.workflow.draft.contractStrain, .noTrump)
        XCTAssertEqual(model.originalHandFacts, original)
        XCTAssertTrue(model.startPlay())
    }

    func testPlayArchiveKeepsOriginalAndRemainingSeparateAndRestoresTeachingProjection() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalReviewSessionStore(directoryURL: root)
        let model = BridgeTeacherApplicationModel(reviewStore: store)
        model.updateReviewDraft(board())
        XCTAssertTrue(model.startPlay())
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        model.saveReview()
        let saved = try XCTUnwrap(store.list().first)
        let restored = BridgeTeacherApplicationModel(reviewStore: store)
        XCTAssertTrue(restored.openReview(id: saved.id))
        XCTAssertEqual(restored.playSession, model.playSession)
        XCTAssertEqual(restored.originalHandFacts, model.originalHandFacts)
        XCTAssertEqual(restored.workflow.draft.hands, board().hands)
        XCTAssertEqual(restored.currentTeachingDraft.observedPlays, model.currentTeachingDraft.observedPlays)
        XCTAssertTrue(restored.playCard(card(.spades, .ace), by: .north))
    }
}

private func board() -> DeclarerPlanDraft {
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
private func card(_ suit: Suit, _ rank: CardRank) -> DoubleDummyCard { DoubleDummyCard(suit: suit, rank: rank) }
private actor RecordingTeachingRuntime: DeclarerTeachingRuntime {
    private var request: DeclarerPlanRequest?
    func latest() -> DeclarerPlanRequest? { request }
    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        self.request = request
        return DeclarerPlanResponse(text: "workflow teaching response")
    }
    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "follow-up")
    }
}

private actor SuspendedTeachingRuntime: DeclarerTeachingRuntime {
    private var continuation: CheckedContinuation<DeclarerPlanResponse, Never>?
    func isWaiting() -> Bool { continuation != nil }
    func finish() {
        continuation?.resume(returning: DeclarerPlanResponse(text: "旧局面响应"))
        continuation = nil
    }
    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        await withCheckedContinuation { continuation = $0 }
    }
    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "follow-up")
    }
}
