import BridgeTeacherCore
import Foundation
import XCTest
@testable import BridgeTeacherMac

@MainActor
final class PlayWorkspaceIntegrationTests: XCTestCase {
    func testReviewedImportRealDDSHistoryArchiveAndTeachingKeepOneOriginalBoard() async throws {
        let helperPath = ProcessInfo.processInfo.environment["BRIDGE_TEACHER_DDS_HELPER"]
            ?? FileManager.default.currentDirectoryPath + "/.build/dds/bridge-dds"
        guard FileManager.default.isExecutableFile(atPath: helperPath) else {
            throw XCTSkip("Actual bundled DDS is required for integrated numerical acceptance.")
        }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let screenshot = root.appendingPathComponent("synthetic-board.png")
        try Data([0x89, 0x50, 0x4e, 0x47]).write(to: screenshot)
        let solver = CountingRealDDS(solver: BundledDDSSolver(executableURL: URL(fileURLWithPath: helperPath)))
        let recorder = IntegratedTeachingRecorder()
        let store = LocalReviewSessionStore(directoryURL: root.appendingPathComponent("reviews"))
        let model = BridgeTeacherApplicationModel(
            screenshotRecognitionRuntime: IntegratedScreenshotFixture(), teachingRuntime: recorder,
            doubleDummySolver: solver, reviewStore: store
        )
        model.selectScreenshot(at: screenshot)
        await model.screenshotWorkflow.recognizeScreenshot()
        XCTAssertFalse(model.originalHandFacts.decisionTimeConfirmed)
        XCTAssertFalse(model.startPlay())
        await model.calculateOriginalContractTable()
        guard case .unavailable = model.originalContractTableWorkflow.state else { return XCTFail("Unreviewed board cannot feed DDS") }

        var reviewed = model.workflow.draft
        reviewed.decisionTimeConfirmed = true
        reviewed.decisionTimeVisibleSeats = [.north, .south]
        model.updateReviewDraft(reviewed)
        let original = model.originalHandFacts
        await model.calculateOriginalContractTable()
        let originalTable = try readyTable(model)
        XCTAssertEqual(originalTable.cell(strain: .spades, declarer: .north)?.contract, "7S")
        XCTAssertEqual(originalTable.cell(strain: .noTrump, declarer: .south)?.contract, "—")
        XCTAssertTrue(model.startPlay())
        model.playCardResultsWorkflow.setEnabled(true)
        try await waitForCurrentLabels(model)
        XCTAssertEqual(Set(model.playCardResultsWorkflow.labels.values), [0])
        await model.workflow.generatePlan()
        XCTAssertFalse(model.workflow.resultIsOutdated)

        // Rapid card actions clear old labels immediately; collecting is explicit.
        XCTAssertTrue(model.playCard(card(.hearts, .ace), by: .east))
        XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
        XCTAssertTrue(model.playCard(card(.diamonds, .ace), by: .south))
        XCTAssertTrue(model.playCard(card(.clubs, .ace), by: .west))
        XCTAssertTrue(model.playCard(card(.spades, .ace), by: .north))
        XCTAssertEqual(model.playCardResultsWorkflow.state, .awaitingCollection)
        XCTAssertTrue(model.workflow.resultIsOutdated)
        XCTAssertTrue(model.collectPlayTrick())
        try await waitForCurrentLabels(model)
        XCTAssertEqual(model.playSession?.declarerTricks, 1)
        XCTAssertEqual(Set(model.playCardResultsWorkflow.labels.values), [0])
        XCTAssertTrue(model.undoPlay())
        XCTAssertEqual(model.playCardResultsWorkflow.state, .awaitingCollection)
        XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
        XCTAssertTrue(model.undoPlay())
        try await waitForCurrentLabels(model)
        XCTAssertEqual(model.playCardResultsWorkflow.actingSeat, .north)
        XCTAssertEqual(Set(model.playCardResultsWorkflow.labels.keys), Set(try XCTUnwrap(model.playSession).legalCards))
        XCTAssertTrue(model.redoPlay())
        XCTAssertTrue(model.redoPlay())
        try await waitForCurrentLabels(model)

        // Return across collection, branch to another legal trump, then restart.
        XCTAssertTrue(model.undoPlay())
        XCTAssertTrue(model.undoPlay())
        XCTAssertTrue(model.playCard(card(.spades, .king), by: .north))
        XCTAssertFalse(model.canRedoPlay)
        XCTAssertTrue(model.collectPlayTrick())
        XCTAssertTrue(model.restartPlay())
        try await waitForCurrentLabels(model)
        await model.calculateOriginalContractTable()
        XCTAssertEqual(try readyTable(model), originalTable)
        let cachedSolves = await solver.originalTableSolves
        XCTAssertEqual(cachedSolves, 20, "Playing and history must not recompute the original twenty cells")
        XCTAssertEqual(model.originalHandFacts, original)

        // Save only the current position, then reopen without merging derived cards into originals.
        XCTAssertTrue(model.playCard(card(.hearts, .ace), by: .east))
        XCTAssertTrue(model.playCard(card(.diamonds, .ace), by: .south))
        let savedPosition = try XCTUnwrap(model.playSession)
        model.saveReview()
        let saved = try XCTUnwrap(store.list().first)
        XCTAssertTrue(model.playCard(card(.clubs, .ace), by: .west))
        XCTAssertTrue(model.openReview(id: saved.id))
        XCTAssertEqual(model.playSession, savedPosition)
        XCTAssertFalse(model.canUndoPlay)
        XCTAssertFalse(model.canRedoPlay)
        try await waitForCurrentLabels(model)
        XCTAssertEqual(model.playCardResultsWorkflow.actingSeat, .west)
        XCTAssertEqual(model.originalHandFacts, original)
        XCTAssertEqual(model.workflow.draft.hands, original.hands)
        XCTAssertEqual(try readyTable(model), originalTable)
        XCTAssertFalse(savedPosition.remainingHands[.east]?[.hearts]?.contains(.ace) == true)
        await model.workflow.generatePlan()
        let capturedTwo = await recorder.latestRequest()
        let two = try XCTUnwrap(capturedTwo)
        XCTAssertEqual(Set(two.visibleHands.map(\.seat)), [.north, .south])
        XCTAssertEqual(Set(two.unknownSeats), [.east, .west])
        XCTAssertTrue(two.prompt.contains("东家：♥A"), "Observed plays are public even when the rest of a hand is hidden")
        XCTAssertFalse(two.prompt.contains("DDS"))
        XCTAssertFalse(two.prompt.contains("7S"))
        reviewed = model.workflow.draft
        reviewed.decisionTimeVisibleSeats = Set(Seat.allCases)
        model.updateReviewDraft(reviewed)
        XCTAssertNil(model.pendingPlayReset)
        await model.workflow.generatePlan()
        let capturedFour = await recorder.latestRequest()
        let four = try XCTUnwrap(capturedFour)
        XCTAssertEqual(four.visibleHands.count, 4)
        XCTAssertTrue(four.unknownSeats.isEmpty)
        XCTAssertEqual(try readyTable(model), originalTable)

        // A source edit is staged, cancelable, and invalidates every derived consumer only on confirmation.
        var edited = model.workflow.draft
        edited.hands[.south] = [.spades: "-", .hearts: "-", .diamonds: "AKQJT9876543", .clubs: "A"]
        edited.hands[.west] = [.spades: "-", .hearts: "-", .diamonds: "2", .clubs: "KQJT98765432"]
        model.updateReviewDraft(edited)
        XCTAssertNotNil(model.pendingPlayReset)
        XCTAssertEqual(try readyTable(model), originalTable)
        model.cancelPlayReset()
        XCTAssertEqual(model.playSession, savedPosition)
        XCTAssertEqual(model.originalHandFacts, original)
        model.updateReviewDraft(edited)
        model.confirmPlayReset()
        XCTAssertNil(model.playSession)
        XCTAssertEqual(model.playCardResultsWorkflow.state, .unavailable)
        XCTAssertTrue(model.playCardResultsWorkflow.labels.isEmpty)
        XCTAssertTrue(model.workflow.resultIsOutdated)
        XCTAssertEqual(model.originalContractTableWorkflow.state, .idle)
        await model.calculateOriginalContractTable()
        let editedTable = try readyTable(model)
        XCTAssertGreaterThan(editedTable.identity.version, originalTable.identity.version)
        XCTAssertEqual(editedTable.identity.boardID, originalTable.identity.boardID)
        XCTAssertEqual(editedTable.cell(strain: .noTrump, declarer: .south)?.contract, "7NT")
        let refreshedSolves = await solver.originalTableSolves
        XCTAssertEqual(refreshedSolves, 40)
    }

    private func readyTable(_ model: BridgeTeacherApplicationModel) throws -> OriginalContractTable {
        guard case .ready(let table) = model.originalContractTableWorkflow.state else { throw IntegrationFailure.tableNotReady }
        return table
    }

    private func waitForCurrentLabels(_ model: BridgeTeacherApplicationModel) async throws {
        let deadline = ContinuousClock().now.advanced(by: .seconds(10))
        while model.playCardResultsWorkflow.state != .ready {
            guard ContinuousClock().now < deadline else { throw IntegrationFailure.labelsNotReady }
            try await Task.sleep(for: .milliseconds(1))
        }
        XCTAssertEqual(model.playCardResultsWorkflow.positionRevision, model.playPositionRevision)
        XCTAssertEqual(Set(model.playCardResultsWorkflow.labels.keys), Set(try XCTUnwrap(model.playSession).legalCards))
    }
}

private enum IntegrationFailure: Error { case tableNotReady, labelsNotReady }

private actor CountingRealDDS: DoubleDummySolving {
    nonisolated var version: String { BundledDDSSolver.solverVersion }
    private let solver: BundledDDSSolver
    private(set) var originalTableSolves = 0
    init(solver: BundledDDSSolver) { self.solver = solver }
    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        if position.contractContext == nil { originalTableSolves += 1 }
        return try await solver.solve(position: position)
    }
}

private actor IntegratedTeachingRecorder: DeclarerTeachingRuntime {
    private var request: DeclarerPlanRequest?
    func latestRequest() -> DeclarerPlanRequest? { request }
    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        self.request = request
        return DeclarerPlanResponse(text: "Synthetic response to the captured projected request")
    }
    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "Synthetic follow-up")
    }
}

private struct IntegratedScreenshotFixture: ScreenshotRecognitionRuntime {
    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse {
        let suitBySeat: [Seat: Suit] = [.north: .spades, .east: .hearts, .south: .diamonds, .west: .clubs]
        let hands = Dictionary(uniqueKeysWithValues: Seat.allCases.map { seat in
            (seat, Dictionary(uniqueKeysWithValues: Suit.allCases.map { ($0, $0 == suitBySeat[seat] ? "AKQJT98765432" : "-") }))
        })
        return ScreenshotRecognitionResponse(candidate: ScreenshotRecognitionCandidate(
            hands: hands, declarerSeat: .north, contractLevel: 7, contractStrain: .spades,
            openingLead: nil, otherDecisionTimeFacts: "Synthetic fixture for integration tests", notes: []
        ))
    }
}

private func card(_ suit: Suit, _ rank: CardRank) -> DoubleDummyCard { DoubleDummyCard(suit: suit, rank: rank) }
