import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeDriver

final class ReviewRecoveryTests: XCTestCase {
    func testThreeReviewerFailuresThenApprovalKeepOneCandidateAndOneSemanticRound() async throws {
        let reviewer = RecoveringReviewer(failures: 3)
        let expert = ExpertSession(transport: RecordedPlayTransport(output: firstCandidate), reviewer: reviewer)
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
        let step = try await driver.advance()
        let decision = try XCTUnwrap(step.decision)
        let inputs = await reviewer.inputs
        XCTAssertEqual(inputs.count, 4)
        XCTAssertEqual(Set(inputs).count, 1)
        XCTAssertEqual(decision.reviewRounds?.count, 1)
        XCTAssertEqual(step.actualEvents.count, 2)
        let evidence = await expert.requestEvidence()
        XCTAssertEqual(evidence.filter { $0.role == .reviewer }.map(\.technicalAttempt), [1, 2, 3, 4])
        XCTAssertEqual(evidence.filter { $0.role == .reviewer }.map(\.semanticRound), [1, 1, 1, 1])
    }
    func testTimeoutReturnsBeforeIgnoringCancellationRepliesAndRetainsThemAsLate() async throws {
        let expert = ExpertSession(transport: RecordedPlayTransport(output: firstCandidate), reviewer: LateReviewer())
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert, requestTimeoutSeconds: 0.015)
        let started = Date()
        do { _ = try await driver.advance(); XCTFail("All timed-out attempts must stop") } catch {}
        XCTAssertLessThan(Date().timeIntervalSince(started), 0.20)
        let trace = await driver.trace()
        XCTAssertEqual(trace.modelActions, 0)
        try await Task.sleep(for: .milliseconds(300))
        let evidence = await expert.requestEvidence()
        XCTAssertEqual(evidence.filter { $0.role == .reviewer && $0.outcome == .timeout }.count, 4)
        XCTAssertEqual(evidence.filter { $0.role == .reviewer && $0.outcome == .late }.count, 4)
        let active = await expert.activePlan()
        XCTAssertNil(active)
    }

    func testBoardBudgetCoversBothRolesAndLaterRetries() async throws {
        let reviewer = DelayedFailingReviewer()
        let expert = ExpertSession(transport: RecordedPlayTransport(output: firstCandidate), reviewer: reviewer)
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert, requestTimeoutSeconds: 1, runTimeoutSeconds: 0.045)
        let started = Date()
        do { _ = try await driver.advance(); XCTFail("Board protection expires before four whole requests") } catch {}
        XCTAssertLessThan(Date().timeIntervalSince(started), 0.15)
        let evidence = await expert.requestEvidence()
        XCTAssertLessThanOrEqual(evidence.filter { $0.role == .reviewer && $0.outcome != .late }.count, 2)
        let trace = await driver.trace()
        XCTAssertEqual(trace.modelActions, 0)
    }

    func testMissingPublicFactsResumeInProcessWithoutLosingPriorPlayerSession() async throws {
        var board = try reviewedBoard()
        let player = SequencePlayTransport(outputs: [firstCandidate, #"{"plan":{"update":"keep","text":null},"selectedCard":"DA","publicReason":"Win the current diamond."}"#])
        let expert = ExpertSession(transport: player, reviewer: InspectingReviewer())
        let first = try await expert.decide(board.snapshot(controller: .south))
        try board.apply(first.action)
        try await expert.commit(first, execution: .init(event: board.events.last!, source: .model))
        try board.play(Card("D4"), by: .east)
        let complete = try board.snapshot(controller: .south)
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(complete)) as! [String:Any]
        object["hands"] = (object["hands"] as! [[String:Any]]).filter { $0["seat"] as? String == "south" }
        let incomplete = try JSONDecoder().decode(DecisionSnapshot.self, from: JSONSerialization.data(withJSONObject: object))
        do { _ = try await expert.decide(incomplete); XCTFail("Missing dummy must suspend") }
        catch let failure as ExpertFailure { XCTAssertEqual(failure.category, .needsInput) }
        let waiting = await expert.needsInputState()
        let suspended = try XCTUnwrap(waiting)
        try await Task.sleep(for: .milliseconds(30))
        let resumed = try await expert.decide(complete)
        XCTAssertEqual(resumed.identity.threadID, first.identity.threadID)
        XCTAssertEqual(resumed.effectivePlan, first.effectivePlan)
        XCTAssertEqual(resumed.reviewRounds?.count, 1)
        XCTAssertEqual(resumed.session, suspended.session)
        XCTAssertGreaterThan(resumed.humanWaitingSeconds ?? 0, 0.02)
    }

    func testValidRevisionEndsTechnicalRecoveryAndNextCandidateGetsOwnFourAttempts() async throws {
        let reviewer = RevisionAfterFailuresReviewer()
        let player = SequencePlayTransport(outputs: [firstCandidate, firstCandidate])
        let expert = ExpertSession(transport: player, reviewer: reviewer)
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
        let step = try await driver.advance()
        let decision = try XCTUnwrap(step.decision)
        XCTAssertEqual(decision.reviewRounds?.map(\.review.result.verdict), [.revise, .approve])
        let evidence = await expert.requestEvidence()
        let reviews = evidence.filter { $0.role == .reviewer }
        XCTAssertEqual(reviews.map(\.technicalAttempt), [1,2,3,4,1,2,3,4])
        XCTAssertEqual(reviews.map(\.semanticRound), [1,1,1,1,2,2,2,2])
        XCTAssertEqual(Set(reviews.prefix(4).compactMap(\.candidateID)).count, 1)
        XCTAssertNotEqual(reviews[0].candidateID, reviews[4].candidateID)
        let trace = await driver.trace()
        XCTAssertEqual(trace.playerRequests, 2)
        XCTAssertEqual(trace.reviewerRequests, 8)
        XCTAssertEqual(trace.semanticReviews, 2)
        XCTAssertEqual(trace.retries, 6)
        XCTAssertEqual(trace.modelActions, 1)
    }

    func testFourMalformedReviewerAttemptsStopWithAllRawEvidenceAndNoContestedRelease() async throws {
        let reviewer = ReviewBoundary(output: "malformed JSON")
        let expert = ExpertSession(transport: RecordedPlayTransport(output: firstCandidate), reviewer: reviewer)
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
        do { _ = try await driver.advance(); XCTFail("Malformed review is never semantic exhaustion") }
        catch let failure as ExpertFailure {
            XCTAssertEqual(failure.category, .invalidOutput)
            XCTAssertTrue(failure.reviewRounds.isEmpty)
            XCTAssertEqual(failure.requestEvidence.filter { $0.role == .reviewer }.count, 4)
            XCTAssertTrue(failure.requestEvidence.filter { $0.role == .reviewer }.allSatisfy { $0.rawOutput == "malformed JSON" && $0.outcome == .protocolFailure })
        }
        let trace = await driver.trace()
        XCTAssertEqual(trace.modelActions, 0)
        XCTAssertEqual(trace.semanticReviews, 0)
        XCTAssertEqual(trace.retries, 3)
    }

    func testIdentityFailureIsFatalWithoutReviewerRetryAndPlayerContractFailureSkipsReview() async throws {
        for (player, reviewer, expectedReviews) in [
            (firstCandidate, ReviewBoundary(output: approvalVerdict, stale: true), 1),
            ("{}", ReviewBoundary(output: approvalVerdict), 0)
        ] {
            let expert = ExpertSession(transport: RecordedPlayTransport(output: player), reviewer: reviewer)
            let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
            do { _ = try await driver.advance(); XCTFail("Fatal failure cannot execute") } catch {}
            let trace = await driver.trace()
            XCTAssertEqual(trace.reviewerRequests, expectedReviews)
            XCTAssertEqual(trace.modelActions, 0)
            XCTAssertEqual(trace.retries, 0)
        }
    }

    func testAuthorizationCannotCommitAfterAutomaticDeadline() async throws {
        let board = try reviewedBoard()
        let expert = ExpertSession(transport: RecordedPlayTransport(output: firstCandidate), reviewer: InspectingReviewer())
        let decision = try await expert.decide(board.snapshot(controller: .south), automaticDeadline: Date().addingTimeInterval(0.1))
        try await Task.sleep(for: .milliseconds(120))
        do {
            try await expert.commit(decision, execution: .init(event: .init(sequence: 1, seat: .north, card: try Card("D3")), source: .model))
            XCTFail("Expired authorization cannot commit its plan")
        } catch {}
        let plan = await expert.activePlan()
        XCTAssertNil(plan)
    }

}
actor RecoveringReviewer: PlayingTransport {
    var failures: Int
    var inputs: [String] = []
    init(failures: Int) { self.failures = failures }
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        inputs.append(request.input)
        if failures > 0 { failures -= 1; throw RecoveryBoundaryError.network }
        return try await InspectingReviewer().respond(to: request)
    }
}
enum RecoveryBoundaryError: Error { case network }

struct LateReviewer: PlayingTransport {
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.25) {
                continuation.resume(returning: PlayingReply(rawOutput: approvalVerdict, identity: .init(requestedModel: "gpt-6.1-sol", requestedEffort: "medium", runtimeVersion: "late-boundary", observedModel: "gpt-6.1-sol", observedEffort: "medium", threadID: "late-review", turnID: UUID().uuidString), requestID: request.id))
            }
        }
    }
}

struct DelayedFailingReviewer: PlayingTransport {
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        try await Task.sleep(for: .milliseconds(30))
        throw RecoveryBoundaryError.network
    }
}

actor RevisionAfterFailuresReviewer: PlayingTransport {
    var count = 0
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        count += 1
        if count % 4 != 0 { throw RecoveryBoundaryError.network }
        let output = count == 4 ? revisionVerdict : approvalVerdict
        return PlayingReply(rawOutput: output, identity: .init(requestedModel: "gpt-6.1-sol", requestedEffort: "medium", runtimeVersion: "scripted", observedModel: "gpt-6.1-sol", observedEffort: "medium", threadID: "review-\(count)", turnID: "turn-\(count)"), requestID: request.id)
    }
}
