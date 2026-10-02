import Foundation
import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

@MainActor
final class PlayHistoryWorkflowTests: XCTestCase {
    func testUndoRedoRestoreCompletePositionAndRevisionWithoutTouchingOriginal() throws {
        let model = startedModel()
        let source = model.originalHandFacts
        let start = try XCTUnwrap(model.playSession)
        XCTAssertFalse(model.canUndoPlay)
        XCTAssertFalse(model.canRedoPlay)
        XCTAssertFalse(model.undoPlay())
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        let played = model.playSession
        let revision = model.playPositionRevision
        XCTAssertTrue(model.canUndoPlay)
        XCTAssertTrue(model.undoPlay())
        XCTAssertEqual(model.playSession, start)
        XCTAssertGreaterThan(model.playPositionRevision, revision)
        XCTAssertFalse(model.canUndoPlay)
        XCTAssertTrue(model.canRedoPlay)
        XCTAssertTrue(model.redoPlay())
        XCTAssertEqual(model.playSession, played)
        XCTAssertFalse(model.canRedoPlay)
        XCTAssertEqual(model.originalHandFacts, source)
    }

    func testUndoAcrossCollectBoundaryRestoresFullTrickScoresLeaderAndCards() throws {
        let model = startedModel()
        playFirstTrick(model)
        let beforeCollect = try XCTUnwrap(model.playSession)
        XCTAssertTrue(model.collectPlayTrick())
        let afterCollect = try XCTUnwrap(model.playSession)
        XCTAssertEqual(afterCollect.northSouthTricks, 1)
        XCTAssertEqual(afterCollect.actingSeat, .north)
        XCTAssertTrue(model.undoPlay())
        XCTAssertEqual(model.playSession, beforeCollect)
        XCTAssertTrue(model.playSession?.awaitingCollection == true)
        XCTAssertEqual(model.playSession?.currentTrick.count, 4)
        XCTAssertEqual(model.playSession?.northSouthTricks, 0)
        XCTAssertTrue(model.undoPlay())
        XCTAssertEqual(model.playSession?.currentTrick.count, 3)
        XCTAssertEqual(model.playSession?.actingSeat, .south)
        XCTAssertTrue(model.playSession?.remainingHands[.south]?[.hearts]?.contains(.nine) == true)
        XCTAssertTrue(model.redoPlay())
        XCTAssertEqual(model.playSession, beforeCollect)
        XCTAssertTrue(model.redoPlay())
        XCTAssertEqual(model.playSession, afterCollect)
    }

    func testNewLegalBranchClearsRedoWhileRejectedMovePreservesIt() throws {
        let model = startedModel()
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        XCTAssertTrue(model.undoPlay())
        let start = model.playSession
        XCTAssertFalse(model.playCard(card(.spades, .ace), by: .north))
        XCTAssertTrue(model.canRedoPlay)
        XCTAssertEqual(model.playSession, start)
        XCTAssertTrue(model.playCard(card(.hearts, .three), by: .west))
        XCTAssertFalse(model.canRedoPlay)
        XCTAssertFalse(model.redoPlay())
        XCTAssertEqual(model.playSession?.currentTrick.first?.card, card(.hearts, .three))
        XCTAssertTrue(model.undoPlay())
        XCTAssertEqual(model.playSession, start)
    }

    func testCompletionCanBeRewoundThroughCollectionAndLastCard() throws {
        let model = startedModel()
        for _ in 0..<13 {
            for _ in 0..<4 {
                let session = try XCTUnwrap(model.playSession)
                XCTAssertTrue(model.playCard(try XCTUnwrap(session.legalCards.first), by: try XCTUnwrap(session.actingSeat)))
            }
            XCTAssertTrue(model.collectPlayTrick())
        }
        let complete = try XCTUnwrap(model.playSession)
        XCTAssertTrue(complete.isComplete)
        XCTAssertTrue(model.undoPlay())
        XCTAssertFalse(model.playSession?.isComplete == true)
        XCTAssertEqual(model.playSession?.completedTricks.count, 12)
        XCTAssertTrue(model.playSession?.awaitingCollection == true)
        XCTAssertTrue(model.undoPlay())
        XCTAssertEqual(model.playSession?.currentTrick.count, 3)
        XCTAssertEqual(model.playSession?.legalCards.count, 1)
        XCTAssertTrue(model.redoPlay())
        XCTAssertTrue(model.redoPlay())
        XCTAssertEqual(model.playSession, complete)
    }

    func testRestartPreservesSameSourceVisibilityAndSuppliedLeadAndCanBeUndone() throws {
        let model = startedModel(openingLead: "H4")
        let start = try XCTUnwrap(model.playSession)
        let source = model.originalHandFacts
        XCTAssertEqual(start.currentTrick.count, 1)
        XCTAssertTrue(model.playCard(card(.spades, .ace), by: .north))
        let previous = model.playSession
        var visibility = model.workflow.draft
        visibility.decisionTimeVisibleSeats = [.north, .south, .west]
        model.updateReviewDraft(visibility)
        let revision = model.playPositionRevision
        XCTAssertTrue(model.restartPlay())
        XCTAssertEqual(model.playSession, start)
        XCTAssertGreaterThan(model.playPositionRevision, revision)
        XCTAssertEqual(model.originalHandFacts, source)
        XCTAssertEqual(model.workflow.draft.decisionTimeVisibleSeats, [.north, .south, .west])
        XCTAssertEqual(model.playSession?.currentTrick.first?.card, card(.hearts, .four))
        XCTAssertEqual(model.playSession?.actingSeat, .north)
        XCTAssertTrue(model.undoPlay())
        XCTAssertEqual(model.playSession, previous)
        XCTAssertTrue(model.redoPlay())
        XCTAssertEqual(model.playSession, start)
    }

    func testHistoryTravelInvalidatesTeachingAndKeepsCurrentProjection() async throws {
        let model = startedModel(teachingRuntime: ImmediateTeachingRuntime())
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        await model.workflow.generatePlan()
        XCTAssertFalse(model.workflow.resultIsOutdated)
        XCTAssertTrue(model.undoPlay())
        XCTAssertTrue(model.workflow.resultIsOutdated)
        XCTAssertEqual(model.currentTeachingDraft.observedPlays, [])
        await model.workflow.generatePlan()
        XCTAssertFalse(model.workflow.resultIsOutdated)
        XCTAssertTrue(model.redoPlay())
        XCTAssertTrue(model.workflow.resultIsOutdated)
        XCTAssertEqual(model.currentTeachingDraft.observedPlays?.first?.card, card(.hearts, .four))
        await model.workflow.generatePlan()
        XCTAssertFalse(model.workflow.resultIsOutdated)
        XCTAssertTrue(model.restartPlay())
        XCTAssertTrue(model.workflow.resultIsOutdated)
        XCTAssertEqual(model.currentTeachingDraft.observedPlays, [])
    }

    func testConfirmedSourceChangeClearsHistoryWhileCancelKeepsIt() throws {
        let model = startedModel()
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        XCTAssertTrue(model.undoPlay())
        XCTAssertTrue(model.canRedoPlay)
        var changed = model.workflow.draft
        changed.contractStrain = .noTrump
        model.updateReviewDraft(changed)
        model.cancelPlayReset()
        XCTAssertTrue(model.canRedoPlay)
        model.updateReviewDraft(changed)
        model.confirmPlayReset()
        XCTAssertFalse(model.canUndoPlay)
        XCTAssertFalse(model.canRedoPlay)
        XCTAssertFalse(model.redoPlay())
        XCTAssertTrue(model.startPlay())
        XCTAssertFalse(model.undoPlay())
    }

    func testOpenRestoresOnlySavedPositionAndClearsInMemoryHistory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalReviewSessionStore(directoryURL: root)
        let model = startedModel(reviewStore: store)
        XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
        model.saveReview()
        let saved = try XCTUnwrap(store.list().first)
        let savedPosition = model.playSession
        XCTAssertTrue(model.playCard(card(.spades, .ace), by: .north))
        XCTAssertTrue(model.canUndoPlay)
        XCTAssertTrue(model.openReview(id: saved.id))
        XCTAssertEqual(model.playSession, savedPosition)
        XCTAssertFalse(model.canUndoPlay)
        XCTAssertFalse(model.canRedoPlay)
        XCTAssertFalse(model.undoPlay())
        XCTAssertTrue(model.playCard(card(.spades, .king), by: .north))
        XCTAssertTrue(model.undoPlay())
        XCTAssertEqual(model.playSession, savedPosition)
    }
}

@MainActor
private func startedModel(openingLead: String = "", teachingRuntime: (any DeclarerTeachingRuntime)? = nil,
                          reviewStore: LocalReviewSessionStore = LocalReviewSessionStore()) -> BridgeTeacherApplicationModel {
    let model = BridgeTeacherApplicationModel(teachingRuntime: teachingRuntime, reviewStore: reviewStore)
    var draft = DeclarerPlanDraft()
    draft.declarerSeat = .south
    draft.contractLevel = 1
    draft.contractStrain = .spades
    draft.openingLead = openingLead
    draft.decisionTimeVisibleSeats = [.north, .south]
    draft.hands[.north] = [.spades: "AKQJT98765432", .hearts: "-", .diamonds: "-", .clubs: "-"]
    draft.hands[.east] = [.spades: "-", .hearts: "AKQJT", .diamonds: "AKQJ", .clubs: "AKQJ"]
    draft.hands[.south] = [.spades: "-", .hearts: "98765", .diamonds: "T987", .clubs: "T987"]
    draft.hands[.west] = [.spades: "-", .hearts: "432", .diamonds: "65432", .clubs: "65432"]
    model.updateReviewDraft(draft)
    XCTAssertTrue(model.startPlay())
    return model
}
@MainActor
private func playFirstTrick(_ model: BridgeTeacherApplicationModel) {
    XCTAssertTrue(model.playCard(card(.hearts, .four), by: .west))
    XCTAssertTrue(model.playCard(card(.spades, .ace), by: .north))
    XCTAssertTrue(model.playCard(card(.hearts, .king), by: .east))
    XCTAssertTrue(model.playCard(card(.hearts, .nine), by: .south))
}
private func card(_ suit: Suit, _ rank: CardRank) -> DoubleDummyCard { DoubleDummyCard(suit: suit, rank: rank) }
private struct ImmediateTeachingRuntime: DeclarerTeachingRuntime {
    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "teaching for this position")
    }
    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "follow up")
    }
}
