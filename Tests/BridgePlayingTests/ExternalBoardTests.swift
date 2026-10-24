import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeDriver

final class ExternalBoardTests: XCTestCase {
    func testAdviceRequiresMatchingObservedExecutionBeforeNextDecision() async throws {
        let player = ReviewLoopBoundary(outputs: [firstCandidate, #"{"plan":{"update":"keep","text":null},"selectedCard":"DA","publicReason":"Win the diamond trick."}"#], role: "player")
        let session = try ExternalBoardSession(configuration: externalConfiguration(), transport: player, reviewer: InspectingReviewer())
        let initial = try await session.status()
        XCTAssertEqual(initial.snapshot?.hands.count, 2)
        XCTAssertEqual(initial.snapshot?.actingSeat, .north)
        let first = try await session.decide()
        XCTAssertEqual(first.decision?.action.card, try Card("D3"))
        let before = try await session.status()
        XCTAssertEqual(before.events.count, 1)
        XCTAssertNil(before.activePlan)
        do {
            _ = try await session.observe(.init(sequence: 1, seat: .north, card: Card("D5")), authorization: first.authorization)
            XCTFail("A proposed D3 never authorizes D5")
        } catch {}
        let event = PlayEvent(sequence: 1, seat: .north, card: try Card("D3"))
        let execution = try await session.observe(event, authorization: first.authorization)
        XCTAssertEqual(execution.source, .model)
        do { _ = try await session.observe(event, authorization: first.authorization); XCTFail("Duplicate cannot advance") } catch {}
        _ = try await session.observe(.init(sequence: 2, seat: .east, card: Card("D4")))
        let next = try await session.decide()
        XCTAssertEqual(next.decision?.snapshot.actingSeat, .south)
        XCTAssertEqual(next.decision?.snapshot.controller, .south)
        XCTAssertEqual(next.decision?.effectivePlan, "Preserve entries; establish clubs.")
        XCTAssertEqual(next.decision?.snapshot.scoring, "MP")
        XCTAssertEqual(next.decision?.snapshot.events.count, 3)
        XCTAssertEqual(next.decision?.identity.threadID, first.decision?.identity.threadID)
    }
    func testContinuationCannotResetAnExpiredAutomaticBudget() async throws {
        let original = try ExternalBoardSession(configuration: externalConfiguration(), transport: RecordedPlayTransport(output: firstCandidate),
            reviewer: InspectingReviewer(), started: Date(timeIntervalSinceNow: -1801))
        let checkpoint = try await original.checkpoint()
        do {
            _ = try await ExternalBoardSession.resume(checkpoint, reconciled: checkpoint.configuration,
                transport: RecordedPlayTransport(output: firstCandidate), reviewer: InspectingReviewer())
            XCTFail("Reconstruction must preserve the original automatic budget")
        } catch {}
        do { _ = try await original.decide(); XCTFail("Expired budget cannot authorize a new decision") } catch {}
        let stopped = try await original.checkpoint()
        XCTAssertFalse(stopped.safeToResume)
    }

    func testSavedPublicHistoryResumesNewThreadWithPlanButNoOldAuthorization() async throws {
        let original = try ExternalBoardSession(configuration: externalConfiguration(), transport: RecordedPlayTransport(output: firstCandidate), reviewer: InspectingReviewer())
        let first = try await original.decide()
        let unsafe = try await original.checkpoint()
        do {
            _ = try await ExternalBoardSession.resume(unsafe, reconciled: unsafe.configuration, transport: RecordedPlayTransport(output: firstCandidate), reviewer: InspectingReviewer())
            XCTFail("Pending review authorization cannot be restored")
        } catch {}
        _ = try await original.observe(.init(sequence: 1, seat: .north, card: Card("D3")), authorization: first.authorization)
        _ = try await original.observe(.init(sequence: 2, seat: .east, card: Card("D4")))
        let saved = try await original.checkpoint()
        let readBack = try JSONDecoder().decode(ExternalBoardCheckpoint.self, from: JSONEncoder().encode(saved))
        let player = ReviewLoopBoundary(outputs: [#"{"plan":{"update":"keep","text":null},"selectedCard":"DA","publicReason":"Win the diamond trick."}"#], role: "reconstructed-player")
        let resumed = try await ExternalBoardSession.resume(readBack, reconciled: readBack.configuration, transport: player, reviewer: InspectingReviewer())
        let status = try await resumed.status()
        XCTAssertTrue(status.reconstructed)
        XCTAssertNil(status.pendingAuthorization)
        XCTAssertEqual(status.events.count, 3)
        let next = try await resumed.decide()
        XCTAssertEqual(next.decision?.effectivePlan, "Preserve entries; establish clubs.")
        XCTAssertEqual(next.decision?.snapshot.events, readBack.configuration.events)
        XCTAssertNotEqual(next.decision?.identity.threadID, first.decision?.identity.threadID)
        XCTAssertNotEqual(next.authorization, first.authorization)
    }
}

private func externalConfiguration() throws -> ExternalBoardConfiguration {
    let deal = try syntheticDeal()
    return ExternalBoardConfiguration(boardID: UUID(), contract: try .init(level: 3, strain: .noTrump, declarer: .south),
        vulnerability: "both", scoring: "MP", objective: "Best expected matchpoint result, including overtricks.",
        publicBackground: "South 1NT – North 3NT; no displayed explanations.",
        initialHands: [.init(seat: .south, cards: deal[.south]!), .init(seat: .north, cards: deal[.north]!)],
        events: [.init(sequence: 0, seat: .west, card: try Card("DQ"))])
}
