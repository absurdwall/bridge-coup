import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeDriver

final class ExternalBoardTests: XCTestCase {
    func testInitialAutomaticSoleLegalPlayPrecedesFirstReviewedChoiceAndPreservesManualForcedPath() async throws {
        let player = ReviewLoopBoundary(outputs: [
            #"{"plan":{"update":"replace","text":"Win diamonds, then establish clubs."},"selectedCard":"DA","publicReason":"Win the diamond trick."}"#,
            #"{"plan":{"update":"keep","text":null},"selectedCard":"CA","publicReason":"Start clubs."}"#
        ], role: "player")
        let session = try ExternalBoardSession(configuration: automaticConfiguration(), transport: player, reviewer: InspectingReviewer())
        let event = PlayEvent(sequence: 1, seat: .north, card: try Card("D3"))
        let automatic = try await session.observe(event, automatic: true)
        XCTAssertEqual(automatic.source, .forced)
        let beforeChoice = try await session.status()
        XCTAssertNil(beforeChoice.activePlan)
        XCTAssertNil(beforeChoice.pendingAuthorization)
        let noRequests = await player.inputs
        XCTAssertTrue(noRequests.isEmpty)
        do { _ = try await session.observe(event, automatic: true); XCTFail("Automatic observation is single use") } catch {}
        _ = try await session.observe(.init(sequence: 2, seat: .east, card: Card("D4")))
        let first = try await session.decide()
        XCTAssertEqual(first.source, .model)
        XCTAssertEqual(first.decision?.advice.plan.update, .replace)
        XCTAssertEqual(first.decision?.snapshot.events.count, 3)
        _ = try await session.observe(.init(sequence: 3, seat: .south, card: Card("DA")), authorization: first.authorization)
        let next = try await session.decide()
        _ = try await session.observe(.init(sequence: 4, seat: .south, card: Card("CA")), authorization: next.authorization)
        _ = try await session.observe(.init(sequence: 5, seat: .west, card: Card("C2")))
        let manual = try await session.decide()
        XCTAssertEqual(manual.source, .forced)
        XCTAssertNil(manual.decision)
        _ = try await session.observe(.init(sequence: 6, seat: .north, card: Card("CQ")), authorization: manual.authorization)
        let requests = await player.inputs
        XCTAssertEqual(requests.count, 2)
    }

    func testAutomaticObservationCannotReplaceAChoiceOrPendingReviewedAdvice() async throws {
        let choices = try ExternalBoardSession(configuration: externalConfiguration(), transport: RecordedPlayTransport(output: firstCandidate), reviewer: InspectingReviewer())
        do { _ = try await choices.observe(.init(sequence: 1, seat: .north, card: Card("D3")), automatic: true); XCTFail("Multiple choices require Expert") } catch {}
        let unchanged = try await choices.status()
        XCTAssertEqual(unchanged.events.count, 1)
        let pending = try ExternalBoardSession(configuration: automaticConfiguration(), transport: RecordedPlayTransport(output: firstCandidate), reviewer: InspectingReviewer())
        let advice = try await pending.decide()
        do { _ = try await pending.observe(.init(sequence: 1, seat: .north, card: Card("D3")), automatic: true); XCTFail("A pending model decision cannot be relabeled forced") } catch {}
        let stillPending = try await pending.status()
        XCTAssertEqual(stillPending.pendingAuthorization, advice.authorization)
        XCTAssertNil(stillPending.activePlan)
        _ = try await pending.observe(.init(sequence: 1, seat: .north, card: Card("D3")), authorization: advice.authorization)
    }

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

private func automaticConfiguration() throws -> ExternalBoardConfiguration {
    let base = try externalConfiguration()
    let north = try "S8 S6 S2 S3 S5 S7 HK H7 H4 H2 H5 D3 CQ".split(separator: " ").map { try Card(String($0)) }
    return ExternalBoardConfiguration(boardID: base.boardID, contract: base.contract, vulnerability: base.vulnerability,
        scoring: base.scoring, objective: base.objective, publicBackground: base.publicBackground,
        initialHands: [.init(seat: .north, cards: north), base.initialHands.first { $0.seat == .south }!], events: base.events)
}
