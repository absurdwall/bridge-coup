import Foundation
import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

@MainActor
final class PlayCardResultsWorkflowTests: XCTestCase {
    func testVisibleTeachingRequestExcludesHiddenHandsAndDDSLabelsAfterResultsAreReady() async throws {
        let runtime = CardResultsTeachingRecorder()
        let model = BridgeTeacherApplicationModel(teachingRuntime: runtime, doubleDummySolver: ImmediatePlaySolver())
        model.updateReviewDraft(cardResultsBoard())
        XCTAssertTrue(model.startPlay())
        model.playCardResultsWorkflow.setEnabled(true)
        try await waitUntil { model.playCardResultsWorkflow.state == .ready }
        await model.workflow.generatePlan()
        let recorded = await runtime.request
        let request = try XCTUnwrap(recorded)
        XCTAssertEqual(Set(request.visibleHands.map(\.seat)), [.north, .south])
        XCTAssertEqual(Set(request.unknownSeats), [.east, .west])
        XCTAssertFalse(request.prompt.contains("DDS"))
        XCTAssertFalse(request.prompt.contains("逐牌结果"))
        XCTAssertFalse(model.playCardResultsWorkflow.labels.isEmpty)
    }

    func testToggleHidesResultsWithoutBlockingLegalPlayAndNeverUsesEditableLegacyDDS() async throws {
        let model = BridgeTeacherApplicationModel(doubleDummySolver: ImmediatePlaySolver())
        model.playCardResultsWorkflow.setEnabled(true)
        XCTAssertEqual(model.playCardResultsWorkflow.state, .unavailable)
        model.updateReviewDraft(cardResultsBoard())
        XCTAssertTrue(model.startPlay())
        try await waitUntil { model.playCardResultsWorkflow.state == .ready }
        let initial = try XCTUnwrap(model.playSession)
        let card = try XCTUnwrap(initial.legalCards.first)
        XCTAssertNotNil(model.playCardResultsWorkflow.label(for: card, by: .east))
        XCTAssertNil(model.playCardResultsWorkflow.label(for: card, by: .north))
        var unrelated = DoubleDummyVerificationDraft()
        unrelated.trump = .clubs
        model.doubleDummyWorkflow.updateDraft(unrelated)
        XCTAssertEqual(model.playCardResultsWorkflow.state, .ready)
        model.playCardResultsWorkflow.setEnabled(false)
        XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
        XCTAssertNil(model.playCardResultsWorkflow.label(for: card, by: .east))
        XCTAssertTrue(model.playCard(card, by: .east))
        XCTAssertEqual(model.playCardResultsWorkflow.state, .hidden)
        model.playCardResultsWorkflow.setEnabled(true)
        try await waitUntil { model.playCardResultsWorkflow.state == .ready }
        XCTAssertEqual(model.playCardResultsWorkflow.actingSeat, .south)
        XCTAssertEqual(model.playCardResultsWorkflow.positionRevision, model.playPositionRevision)
        XCTAssertEqual(Set(model.playCardResultsWorkflow.labels.keys), Set(try XCTUnwrap(model.playSession).legalCards))
    }

    func testLateResultCannotOverwriteExternalRestoredPositionOrToggleOff() async throws {
        let solver = DelayedPlaySolver()
        let model = BridgeTeacherApplicationModel(doubleDummySolver: solver)
        model.updateReviewDraft(cardResultsBoard())
        XCTAssertTrue(model.startPlay())
        let initial = try XCTUnwrap(model.playSession)
        model.playCardResultsWorkflow.setEnabled(true)
        try await waitUntil { await solver.count >= 1 }
        XCTAssertTrue(model.playCard(try XCTUnwrap(initial.legalCards.first), by: .east))
        XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
        try await waitUntil { await solver.count >= 2 }
        XCTAssertTrue(model.replacePlaySession(initial))
        try await waitUntil { await solver.count >= 3 }
        await solver.finish(2, score: 2)
        try await waitUntil { model.playCardResultsWorkflow.state == .ready }
        let restoredLabels = model.playCardResultsWorkflow.labels
        await solver.finish(0, score: 0)
        await solver.finish(1, score: 1)
        try await Task.sleep(nanoseconds: 5_000_000)
        XCTAssertEqual(model.playCardResultsWorkflow.labels, restoredLabels)
        XCTAssertEqual(model.playCardResultsWorkflow.actingSeat, .east)
        model.playCardResultsWorkflow.retry()
        try await waitUntil { await solver.count >= 4 }
        model.playCardResultsWorkflow.setEnabled(false)
        await solver.finish(3, score: 3)
        try await Task.sleep(nanoseconds: 5_000_000)
        XCTAssertEqual(model.playCardResultsWorkflow.state, .hidden)
        XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
    }

    func testFailureClearsLabelsAndRetryComputesCurrentPosition() async throws {
        let solver = DelayedPlaySolver()
        let model = BridgeTeacherApplicationModel(doubleDummySolver: solver)
        model.updateReviewDraft(cardResultsBoard())
        XCTAssertTrue(model.startPlay())
        model.playCardResultsWorkflow.setEnabled(true)
        try await waitUntil { await solver.count >= 1 }
        await solver.fail(0)
        try await waitUntil { if case .failed = model.playCardResultsWorkflow.state { return true }; return false }
        XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
        model.playCardResultsWorkflow.retry()
        XCTAssertEqual(model.playCardResultsWorkflow.state, .calculating)
        try await waitUntil { await solver.count >= 2 }
        await solver.finish(1, score: 0)
        try await waitUntil { model.playCardResultsWorkflow.state == .ready }
        XCTAssertEqual(Set(model.playCardResultsWorkflow.labels.keys), Set(try XCTUnwrap(model.playSession).legalCards))
    }

    func testWaitingCollectionAndCompleteClearLabelsAndDoNotShowDDSAsActualResult() async throws {
        let model = BridgeTeacherApplicationModel(doubleDummySolver: ImmediatePlaySolver())
        model.updateReviewDraft(cardResultsBoard())
        XCTAssertTrue(model.startPlay())
        model.playCardResultsWorkflow.setEnabled(true)
        try await waitUntil { model.playCardResultsWorkflow.state == .ready }
        for trick in 0..<13 {
            for _ in 0..<4 {
                let session = try XCTUnwrap(model.playSession)
                XCTAssertTrue(model.playCard(try XCTUnwrap(session.legalCards.first), by: try XCTUnwrap(session.actingSeat)))
            }
            XCTAssertEqual(model.playCardResultsWorkflow.state, .awaitingCollection)
            XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
            XCTAssertNil(model.playCardResultsWorkflow.actingSeat)
            XCTAssertTrue(model.collectPlayTrick())
            if trick == 12 {
                XCTAssertEqual(model.playCardResultsWorkflow.state, .complete)
                XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
                XCTAssertNotNil(model.playSession?.actualContractDelta)
            }
        }
    }

    func testRealDDSLabelsAllEquivalentCardsAcrossFiveStrainsFromDeclarerPerspective() async throws {
        let solver = try realPlaySolver()
        for strain in ContractStrain.allCases {
            let model = BridgeTeacherApplicationModel(doubleDummySolver: solver)
            model.updateReviewDraft(cardResultsBoard(strain: strain))
            XCTAssertTrue(model.startPlay())
            model.playCardResultsWorkflow.setEnabled(true)
            try await waitUntil(timeout: 10) { model.playCardResultsWorkflow.state == .ready }
            let session = try XCTUnwrap(model.playSession)
            let position = try DoubleDummyVerificationPositionBuilder.build(from: session.doubleDummyDraft())
            let actualMoves = try await solver.solve(position: position)
            XCTAssertEqual(actualMoves.count, 1, "Pure-suit opening cards are equivalent")
            XCTAssertEqual(actualMoves[0].equivalentCards.count, 12)
            XCTAssertEqual(model.playCardResultsWorkflow.labels.count, 13)
            let expected = strain == .spades || strain == .diamonds ? "=" : "-13"
            for card in session.legalCards {
                XCTAssertEqual(model.playCardResultsWorkflow.label(for: card, by: .east), expected, "Wrong declarer-side label for \(strain)")
                XCTAssertNil(model.playCardResultsWorkflow.label(for: card, by: .north))
            }
        }
    }

    func testRealDDSPartialTrickDefenderAndCollectedDeclarerTricksStayInTotal() async throws {
        let model = BridgeTeacherApplicationModel(doubleDummySolver: try realPlaySolver())
        model.updateReviewDraft(cardResultsBoard())
        XCTAssertTrue(model.startPlay())
        model.playCardResultsWorkflow.setEnabled(true)
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .hearts, rank: .ace), by: .east))
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .diamonds, rank: .ace), by: .south))
        try await waitUntil(timeout: 10) { model.playCardResultsWorkflow.state == .ready }
        XCTAssertEqual(model.playCardResultsWorkflow.actingSeat, .west, "West is a defender")
        XCTAssertEqual(Set(model.playCardResultsWorkflow.labels.values), [0])
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .clubs, rank: .ace), by: .west))
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .spades, rank: .ace), by: .north))
        XCTAssertTrue(model.collectPlayTrick())
        XCTAssertEqual(model.playSession?.declarerTricks, 1)
        XCTAssertTrue(model.playCard(DoubleDummyCard(suit: .spades, rank: .king), by: .north))
        try await waitUntil(timeout: 10) { model.playCardResultsWorkflow.state == .ready }
        XCTAssertEqual(model.playCardResultsWorkflow.actingSeat, .east)
        XCTAssertEqual(Set(model.playCardResultsWorkflow.labels.values), [0], "Already won trick plus remaining twelve exactly make 7S")
    }

    private func waitUntil(timeout: TimeInterval = 2, _ condition: () async -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !(await condition()) {
            guard Date() < deadline else { throw TestFailure.timeout }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}

private enum TestFailure: Error { case timeout, solverFailure }
private actor CardResultsTeachingRecorder: DeclarerTeachingRuntime {
    private(set) var request: DeclarerPlanRequest?
    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        self.request = request
        return DeclarerPlanResponse(text: "controlled response")
    }
    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "controlled follow-up")
    }
}
private struct ImmediatePlaySolver: DoubleDummySolving {
    var version: String { "controlled-workflow" }
    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        position.legalCards.map { DoubleDummyEngineMove(card: $0, equivalentCards: [], tricksForSideToPlay: 0) }
    }
}
private actor DelayedPlaySolver: DoubleDummySolving {
    nonisolated var version: String { "controlled-race" }
    private var requests: [(DoubleDummyVerificationPosition, CheckedContinuation<[DoubleDummyEngineMove], Error>?)] = []
    var count: Int { requests.count }
    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        try await withCheckedThrowingContinuation { requests.append((position, $0)) }
    }
    func finish(_ index: Int, score: Int) {
        let request = requests[index]
        requests[index].1 = nil
        request.1?.resume(returning: request.0.legalCards.map { DoubleDummyEngineMove(card: $0, equivalentCards: [], tricksForSideToPlay: min(score, request.0.remainingTricks)) })
    }
    func fail(_ index: Int) {
        let continuation = requests[index].1
        requests[index].1 = nil
        continuation?.resume(throwing: TestFailure.solverFailure)
    }
}
private func cardResultsBoard(strain: ContractStrain = .spades) -> DeclarerPlanDraft {
    var draft = DeclarerPlanDraft()
    draft.declarerSeat = .north
    draft.contractLevel = 7
    draft.contractStrain = strain
    draft.decisionTimeVisibleSeats = [.north, .south]
    let suitBySeat: [Seat: Suit] = [.north: .spades, .east: .hearts, .south: .diamonds, .west: .clubs]
    draft.hands = Dictionary(uniqueKeysWithValues: Seat.allCases.map { seat in
        (seat, Dictionary(uniqueKeysWithValues: Suit.allCases.map { ($0, $0 == suitBySeat[seat] ? "AKQJT98765432" : "-") }))
    })
    return draft
}
private func realPlaySolver() throws -> BundledDDSSolver {
    let path = ProcessInfo.processInfo.environment["BRIDGE_TEACHER_DDS_HELPER"]
        ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build/dds/bridge-dds").path
    guard FileManager.default.isExecutableFile(atPath: path) else { throw XCTSkip("Real bundled DDS helper required; build it or set BRIDGE_TEACHER_DDS_HELPER.") }
    return BundledDDSSolver(executableURL: URL(fileURLWithPath: path))
}
