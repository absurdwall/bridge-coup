import XCTest
import BridgeDomain
import BridgeExpert
import BridgeDriver
import BridgeKnowledge

final class ExplanationRoundtripTests: XCTestCase {
    func testProductionSessionSuspendsForChinesePreviewThenReviewsSameEvidenceAndSavesIt() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try ExplanationStore(url: directory.appendingPathComponent("test.sqlite"), testData: true)
        let player = ContinuousBoundary(outputs: [
            #"{"selectedAction":"REQUEST_EXPLANATIONS","publicReason":"Check the intended response and compare an alternative.","plan":{"update":"keep","text":null},"requestExplanations":["2C","2NT"]}"#,
            #"{"selectedAction":"2C","publicReason":"The observed game-forcing meaning fits this hand, subject to the supplied system.","plan":{"update":"replace","text":"Show clubs and game values, then reassess partner's continuation."}}"#
        ], role: "player")
        let reviewer = ContinuousBoundary(outputs: [#"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#], role: "review")
        let session = try ExternalBoardSession(continuous: try configuration(), transport: player, reviewer: reviewer, explanationStore: store)
        let request: ExplanationRequest
        do { _ = try await session.decideContinuous(); XCTFail("Expected non-authorizing information request"); return }
        catch let needed as ExplanationRequestNeeded { request = needed.request }
        XCTAssertEqual(request.candidates.map(\.description), ["2C", "2NT"])
        XCTAssertTrue(request.localResults.allSatisfy { $0.status == .noMatch })
        let status = try await session.continuousStatus()
        XCTAssertNil(status.pendingAuthorization)
        XCTAssertEqual(status.snapshot.auction.count, 2)
        let observation = ExplanationObservation(context: request.context, candidate: try AuctionCall("2C"), text: "13大牌点以上，通常4张以上梅花，进局逼叫。", source: "synthetic preview fixture", observedAt: "2026-10-25T12:00:00Z", sourceVersion: "unknown", evidence: ["synthetic:test-preview"], notes: "TEST DATA", isTestData: true)
        let results = [ExplanationResult(candidate: try AuctionCall("2C"), provider: .environment, status: .found,
                references: [ExplanationMatch(observation: observation, status: .exact, differences: [])], detail: "test fixture"),
            ExplanationResult(candidate: try AuctionCall("2NT"), provider: .environment, status: .unavailable, references: [], detail: "preview unavailable")]
        try await session.provideExplanations(requestID: request.id, snapshotID: request.snapshotID, results: results)
        let awaitingFinalReview = try await session.continuousCheckpoint()
        XCTAssertFalse(awaitingFinalReview.safeToResume, "Information return cannot reset the pending decision's review/query budget")
        let advice = try await session.decideContinuous()
        XCTAssertEqual(advice.selectedAction, "2C")
        XCTAssertEqual(advice.decision?.rounds.count, 1)
        let inputs = await player.requests
        let reviews = await reviewer.requests
        let playerEnvelope = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(inputs[1].input.utf8)) as? [String: Any])
        let reviewerEnvelope = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(reviews[0].input.utf8)) as? [String: Any])
        XCTAssertEqual(try JSONSerialization.data(withJSONObject: playerEnvelope["explanationEvidence"]!, options: .sortedKeys), try JSONSerialization.data(withJSONObject: reviewerEnvelope["explanationEvidence"]!, options: .sortedKeys))
        XCTAssertTrue(inputs[1].input.contains("13大牌点以上"))
        let saved = try await store.lookup(context: request.context, candidate: AuctionCall("2C"))
        XCTAssertEqual(saved.first?.observation.text, observation.text)
        let checkpoint = try await session.continuousCheckpoint()
        XCTAssertFalse(checkpoint.safeToResume)
    }

    func testPreSubmitInspectionInvalidatesOldAuthorizationAndPreservesReviewBudget() async throws {
        let output = #"{"selectedAction":"2C","publicReason":"Show clubs and game strength.","plan":{"update":"replace","text":"Continue toward game after showing clubs."}}"#
        let player = ContinuousBoundary(outputs: [output, output], role: "player")
        let reviewer = ContinuousBoundary(outputs: Array(repeating: #"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#, count: 2), role: "review")
        let session = try ExternalBoardSession(continuous: try configuration(), transport: player, reviewer: reviewer)
        let first = try await session.decideContinuous()
        let deadline = try await session.continuousCheckpoint().automaticDeadline
        let request = try await session.inspectCalls(candidates: [AuctionCall("2C")], reason: "Verify intended call before submission")
        do {
            _ = try await session.observeCall(.init(sequence: 2, seat: .south, call: AuctionCall("2C")), authorization: first.authorization)
            XCTFail("Inspection revoked the old authorization")
        } catch {}
        do { try await session.provideExplanations(requestID: UUID(), snapshotID: request.snapshotID, results: unavailable(request)); XCTFail("Reject wrong request") } catch {}
        do { try await session.provideExplanations(requestID: request.id, snapshotID: "stale", results: unavailable(request)); XCTFail("Reject wrong position") } catch {}
        try await session.provideExplanations(requestID: request.id, snapshotID: request.snapshotID, results: unavailable(request))
        let second = try await session.decideContinuous()
        XCTAssertNotEqual(first.authorization, second.authorization)
        XCTAssertEqual(second.decision?.id, first.decision?.id)
        XCTAssertEqual(second.decision?.rounds.count, 2)
        let after = try await session.continuousCheckpoint()
        XCTAssertEqual(after.automaticDeadline, deadline)
        do {
            _ = try await session.observeCall(.init(sequence: 2, seat: .south, call: AuctionCall("2C")), authorization: first.authorization)
            XCTFail("Old candidate authorization cannot confirm new same-call proposal")
        } catch {}
        _ = try await session.observeCall(.init(sequence: 2, seat: .south, call: AuctionCall("2C")), authorization: second.authorization)
        let committed = try await session.continuousCheckpoint()
        XCTAssertTrue(committed.safeToResume)
        XCTAssertEqual(committed.explanationEvidence?.count, 2)
    }

    func testExplanationReferencesSurviveRoleHandoffAndSafeResumeForFreshReviewers() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try ExplanationStore(url: directory.appendingPathComponent("test.sqlite"), testData: true)
        let pass = #"{"selectedAction":"P","publicReason":"Pass this synthetic hand.","plan":{"update":"replace","text":"Wait for the final contract."}}"#
        let lead = #"{"selectedAction":"S2","publicReason":"Develop spades.","plan":{"update":"replace","text":"Develop the spade suit conditionally."}}"#
        let approve = #"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#
        let player = ContinuousBoundary(outputs: [pass, lead], role: "player")
        let reviewer = ContinuousBoundary(outputs: [approve, approve], role: "review")
        let config = ContinuousBoardConfiguration(boardID: UUID(), userSeat: .north, dealer: .west, vulnerability: "neither", scoring: "MP", objective: "Best MP result", agreements: "Synthetic natural test",
            initialHand: Hand(seat: .north, cards: try ["2","3","4","5","6","7","8","9","T","J","Q","K","A"].map { try Card("S" + $0) }),
            auction: [.init(sequence: 0, seat: .west, call: try AuctionCall("1NT"))],
            explanationSettings: .init(nsSystem: "Test NS", ewSystem: "Test EW", conditions: "synthetic"))
        let session = try ExternalBoardSession(continuous: config, transport: player, reviewer: reviewer, explanationStore: store)
        let request = try await session.inspectCalls(candidates: [AuctionCall("P")], reason: "Check synthetic pass meaning")
        let observation = ExplanationObservation(context: request.context, candidate: try AuctionCall("P"), text: "测试资料：不叫，暂不参与竞叫。", source: "synthetic provider", observedAt: "2026-10-25T12:00:00Z", evidence: ["synthetic:pass"], isTestData: true)
        try await session.provideExplanations(requestID: request.id, snapshotID: request.snapshotID, results: [.init(candidate: AuctionCall("P"), provider: .environment, status: .found, references: [.init(observation: observation, status: .exact, differences: [])], detail: "TEST DATA")])
        let advised = try await session.decideContinuous()
        _ = try await session.observeCall(.init(sequence: 1, seat: .north, call: AuctionCall("P")), authorization: advised.authorization)
        _ = try await session.observeCall(.init(sequence: 2, seat: .east, call: AuctionCall("P")))
        _ = try await session.observeCall(.init(sequence: 3, seat: .south, call: AuctionCall("P")))
        let checkpoint = try await session.continuousCheckpoint()
        XCTAssertTrue(checkpoint.safeToResume)
        let contract = try Contract(level: 1, strain: .noTrump, declarer: .west)
        try await session.confirmContract(contract)
        _ = try await session.decideContinuous()
        let reviews = await reviewer.requests
        XCTAssertTrue(reviews[1].input.contains(observation.text))
        XCTAssertTrue(reviews[1].instructions.contains("DEFENSE REVIEW"))
        let resumedReviewer = ContinuousBoundary(outputs: [approve], role: "review")
        let resumed = try await ExternalBoardSession.resume(checkpoint, reconciled: checkpoint.configuration,
            transport: ContinuousBoundary(outputs: [lead], role: "player"), reviewer: resumedReviewer, explanationStore: store)
        try await resumed.confirmContract(contract)
        _ = try await resumed.decideContinuous()
        let resumedReviews = await resumedReviewer.requests
        XCTAssertTrue(resumedReviews[0].input.contains(observation.text))
        let restored = try await resumed.continuousCheckpoint()
        XCTAssertEqual(restored.explanationEvidence, checkpoint.explanationEvidence)
        XCTAssertEqual(restored.automaticDeadline, checkpoint.automaticDeadline)
    }

    func testInformationAfterRevisionRetainsFiveRoundSemanticLimit() async throws {
        let advice = #"{"selectedAction":"2C","publicReason":"Show clubs.","plan":{"update":"replace","text":"Continue toward game."}}"#
        let query = #"{"selectedAction":"REQUEST_EXPLANATIONS","publicReason":"Check meaning after feedback.","plan":{"update":"keep","text":null},"requestExplanations":["2C"]}"#
        let revise = #"{"verdict":"revise","blockingFindings":[{"claim":"Clarify plan","evidence":"Synthetic objection","requestedChange":"Clarify continuation"}],"advisorySuggestions":[]}"#
        let player = ContinuousBoundary(outputs: [advice, query, advice, advice, advice, advice], role: "player")
        let reviewer = ContinuousBoundary(outputs: Array(repeating: revise, count: 5), role: "review")
        let session = try ExternalBoardSession(continuous: try configuration(), transport: player, reviewer: reviewer)
        let request: ExplanationRequest
        do { _ = try await session.decideContinuous(); XCTFail("Expected request"); return }
        catch let needed as ExplanationRequestNeeded { request = needed.request }
        try await session.provideExplanations(requestID: request.id, snapshotID: request.snapshotID, results: unavailable(request))
        let result = try await session.decideContinuous()
        XCTAssertEqual(result.decision?.rounds.count, 5)
        XCTAssertEqual(result.decision?.executionDisposition, .contested)
        XCTAssertEqual(result.decision?.rounds.last?.review.result.verdict, .revise)
        let requests = await reviewer.requests
        XCTAssertEqual(requests.count, 5)
    }

    private func unavailable(_ request: ExplanationRequest) -> [ExplanationResult] {
        request.candidates.map { .init(candidate: $0, provider: .environment, status: .unavailable, references: [], detail: "No current environment provider") }
    }

    private func configuration() throws -> ContinuousBoardConfiguration {
        .init(boardID: UUID(), userSeat: .south, dealer: .north, vulnerability: "neither", scoring: "MP", objective: "Best MP result", agreements: "NS simplified 2/1; EW CCBA; synthetic test position",
            initialHand: Hand(seat: .south, cards: try ["S7","S3","HQ","H8","H2","DK","D6","D3","D2","CA","CK","CJ","C7"].map(Card.init)),
            auction: [.init(sequence: 0, seat: .north, call: try AuctionCall("1S")), .init(sequence: 1, seat: .east, call: try AuctionCall("P"))],
            explanationSettings: .init(nsSystem: "simplified 2/1", ewSystem: "CCBA", conditions: "synthetic fixture"))
    }
}
