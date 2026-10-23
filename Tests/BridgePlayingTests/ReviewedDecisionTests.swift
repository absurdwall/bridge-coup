import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeDriver

final class ReviewedDecisionTests: XCTestCase {
    func testApprovedFirstDecisionCommitsOneMatchingPlanAndCard() async throws {
        let board = try reviewedBoard()
        let reviewer = InspectingReviewer()
        let expert = ExpertSession(transport: RecordedPlayTransport(output: firstCandidate), reviewer: reviewer)
        let driver = BoardDriver(board: board, expert: expert)
        let step = try await driver.advance()
        let decision = try XCTUnwrap(step.decision)
        XCTAssertEqual(step.actualEvents.count, 2)
        XCTAssertEqual(step.execution.event.card, try Card("D3"))
        XCTAssertEqual(decision.review!.result.verdict, .approve)
        XCTAssertEqual(decision.pending!.candidate, decision.advice)
        XCTAssertEqual(decision.pending!.proposedEffectivePlan, "Preserve entries; establish clubs.")
        let input = try JSONSerialization.jsonObject(with: Data(decision.review!.input.utf8)) as! [String:Any]
        XCTAssertEqual(Set(((input["latestSnapshot"] as! [String:Any])["hands"] as! [String:Any]).keys), ["N", "S"])
        XCTAssertEqual(input["legalCurrentCards"] as? [String], ["D8", "D6", "D5", "D3"])
        XCTAssertEqual((input["candidate"] as? [String:Any])?["selectedCard"] as? String, "D3")
        let plan = await expert.activePlan()
        let pending = await expert.pendingDecision()
        XCTAssertEqual(plan, decision.planAssociation)
        XCTAssertNil(pending)
    }
    func testRevisionKeepsPositionAndPriorPlanUntilFinalApprovedCandidateExecutes() async throws {
        let player = ReviewLoopBoundary(outputs: [firstCandidate, revisedCandidate], role: "player")
        let reviewer = ReviewLoopBoundary(outputs: [revisionVerdict, approvalVerdict], role: "reviewer")
        let expert = ExpertSession(transport: player, reviewer: reviewer)
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
        let step = try await driver.advance()
        let decision = try XCTUnwrap(step.decision)
        XCTAssertEqual(step.execution.event.card, try Card("D5"))
        XCTAssertEqual(step.actualEvents.count, 2)
        XCTAssertEqual(decision.reviewRounds?.count, 2)
        XCTAssertEqual(decision.executionDisposition, .reviewApproved)
        let requests = await player.inputs
        XCTAssertEqual(requests.count, 2)
        let original = try JSONSerialization.jsonObject(with: Data(requests[0].utf8)) as! [String:Any]
        let feedback = try JSONSerialization.jsonObject(with: Data(requests[1].utf8)) as! [String:Any]
        XCTAssertEqual(feedback["type"] as? String, "revision")
        XCTAssertEqual(feedback["rawReview"] as? String, revisionVerdict)
        XCTAssertEqual(feedback["rawCandidate"] as? String, firstCandidate)
        XCTAssertEqual(feedback["latestSnapshot"] as? NSDictionary, original as NSDictionary)
        XCTAssertTrue(original["effectivePlan"] is NSNull)
        XCTAssertEqual(decision.effectivePlan, "Final approved route, verbatim.")
        XCTAssertEqual(decision.input, requests[1])
        XCTAssertEqual(decision.canonicalInput, requests[0])
        let plan = await expert.activePlan()
        XCTAssertEqual(plan?.text, "Final approved route, verbatim.")
    }

    func testFiveSemanticReviewsReleaseOnlyLatestCandidateAsContested() async throws {
        let player = ReviewLoopBoundary(outputs: [firstCandidate, firstCandidate, firstCandidate, firstCandidate, revisedCandidate], role: "player")
        let reviewer = ReviewLoopBoundary(outputs: Array(repeating: revisionVerdict, count: 5), role: "reviewer")
        let expert = ExpertSession(transport: player, reviewer: reviewer)
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
        let step = try await driver.advance()
        let decision = try XCTUnwrap(step.decision)
        XCTAssertEqual(decision.reviewRounds?.map(\.number), [1,2,3,4,5])
        XCTAssertEqual(decision.review!.result.verdict, .revise)
        XCTAssertEqual(decision.executionDisposition, .contested)
        XCTAssertEqual(decision.advice.currentCard, try Card("D5"))
        XCTAssertEqual(decision.pending?.candidate, decision.advice)
        XCTAssertEqual(decision.review?.candidateID, decision.pending?.candidateID)
        XCTAssertEqual(step.actualEvents.count, 2)
        let inputs = await player.inputs
        let reviews = await reviewer.inputs
        XCTAssertEqual(inputs.count, 5)
        XCTAssertEqual(reviews.count, 5)
        let activePlan = await expert.activePlan()
        XCTAssertEqual(activePlan?.text, "Final approved route, verbatim.")
    }

    func testMissingAuthorizedHandIsNeedsInputBeforeAnyReviewOrContestedRelease() async throws {
        let snapshot = try reviewedBoard().snapshot(controller: .south)
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as! [String:Any]
        object["hands"] = []
        let incomplete = try JSONDecoder().decode(DecisionSnapshot.self, from: JSONSerialization.data(withJSONObject: object))
        let player = ReviewLoopBoundary(outputs: [firstCandidate], role: "player")
        let reviewer = ReviewLoopBoundary(outputs: [approvalVerdict], role: "reviewer")
        let expert = ExpertSession(transport: player, reviewer: reviewer)
        do { _ = try await expert.decide(incomplete); XCTFail("Missing public hand requires input") }
        catch let failure as ExpertFailure {
            XCTAssertEqual(failure.category, .needsInput)
            XCTAssertTrue(failure.reviewRounds.isEmpty)
        }
        let playerCalls = await player.inputs
        let reviewerCalls = await reviewer.inputs
        XCTAssertTrue(playerCalls.isEmpty)
        XCTAssertTrue(reviewerCalls.isEmpty)
        let activePlan = await expert.activePlan()
        XCTAssertNil(activePlan)
    }

    func testUncertaintyRestatesPublicFactsAndConsumesTheSameFiveRoundBudget() async throws {
        let uncertain = #"{"verdict":"uncertain","blockingFindings":[],"advisorySuggestions":["Clarify the authorized remaining hands; unknown defenders stay unknown."]}"#
        let player = ReviewLoopBoundary(outputs: Array(repeating: firstCandidate, count: 5), role: "player")
        let reviewer = ReviewLoopBoundary(outputs: Array(repeating: uncertain, count: 5), role: "reviewer")
        let driver = BoardDriver(board: try reviewedBoard(), expert: ExpertSession(transport: player, reviewer: reviewer))
        let step = try await driver.advance()
        let decision = try XCTUnwrap(step.decision)
        XCTAssertEqual(decision.executionDisposition, .contested)
        XCTAssertEqual(decision.review!.result.verdict, .uncertain)
        XCTAssertEqual(decision.reviewRounds?.count, 5)
        let inputs = await player.inputs
        let canonical = try JSONSerialization.jsonObject(with: Data(inputs[0].utf8)) as! NSDictionary
        for input in inputs.dropFirst() {
            let feedback = try JSONSerialization.jsonObject(with: Data(input.utf8)) as! [String:Any]
            XCTAssertEqual(feedback["type"] as? String, "clarification")
            XCTAssertEqual(feedback["rawReview"] as? String, uncertain)
            XCTAssertEqual(feedback["latestSnapshot"] as? NSDictionary, canonical)
            let hands = (feedback["latestSnapshot"] as! [String:Any])["hands"] as! [String:Any]
            XCTAssertEqual(Set(hands.keys), ["N", "S"])
        }
        XCTAssertEqual(step.actualEvents.count, 2)
    }

    func testContestedOperationsCarryOnlyFinalPlanIntoTheNextRealSnapshot() async throws {
        for operation in ["keep", "replace", "withdraw"] {
            let text: Any = operation == "replace" ? "Contested replacement, exact text." : NSNull()
            let draft = String(decoding: try JSONSerialization.data(withJSONObject: ["plan": ["update": operation, "text": text], "selectedCard": "DA", "publicReason": "Win the current diamond trick."]), as: UTF8.self)
            let final = #"{"plan":{"update":"keep","text":null},"selectedCard":"CA","publicReason":"Start clubs from South."}"#
            let player = ReviewLoopBoundary(outputs: [firstCandidate] + Array(repeating: draft, count: 5) + [final], role: "player")
            let reviewer = ReviewLoopBoundary(outputs: [approvalVerdict] + Array(repeating: revisionVerdict, count: 5) + [approvalVerdict], role: "reviewer")
            let expert = ExpertSession(transport: player, reviewer: reviewer)
            let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
            var decisions: [DecisionRecord] = []
            while decisions.count < 3 {
                if let decision = try await driver.advance().decision { decisions.append(decision) }
            }
            XCTAssertEqual(decisions[1].executionDisposition, .contested)
            XCTAssertEqual(decisions[1].reviewRounds?.count, 5)
            XCTAssertTrue(decisions[1].reviewRounds!.allSatisfy { $0.pending.priorPlan?.text == "Preserve entries; establish clubs." })
            let expected = operation == "keep" ? "Preserve entries; establish clubs." : operation == "replace" ? "Contested replacement, exact text." : nil
            XCTAssertEqual(decisions[1].effectivePlan, expected)
            XCTAssertEqual(decisions[2].effectivePlan, expected)
            let next = try JSONSerialization.jsonObject(with: Data(decisions[2].input.utf8)) as! [String:Any]
            if let expected { XCTAssertEqual(next["effectivePlan"] as? String, expected) }
            else { XCTAssertTrue(next["effectivePlan"] is NSNull) }
            let trace = await driver.trace()
            XCTAssertEqual(trace.modelActions, 3)
        }
    }

    func testTechnicalFailureAfterFourReviewsNeverBecomesContestedExecution() async throws {
        let player = ReviewLoopBoundary(outputs: Array(repeating: firstCandidate, count: 5), role: "player")
        let reviewer = ReviewLoopBoundary(outputs: Array(repeating: revisionVerdict, count: 4), role: "reviewer")
        let expert = ExpertSession(transport: player, reviewer: reviewer)
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
        do { _ = try await driver.advance(); XCTFail("Absent fifth judgment is not contested authorization") }
        catch let failure as ExpertFailure {
            XCTAssertEqual(failure.category, .runtime)
            XCTAssertEqual(failure.reviewRounds.count, 4)
        }
        let trace = await driver.trace()
        XCTAssertEqual(trace.modelActions, 0)
        XCTAssertEqual(trace.steps.count, 0)
        let plan = await expert.activePlan()
        XCTAssertNil(plan)
    }

    func testInvalidFifthCandidateCannotUseEarlierLegalCandidateForContestedRelease() async throws {
        let invalid = revisedCandidate.replacingOccurrences(of: "D5", with: "DQ")
        let player = ReviewLoopBoundary(outputs: Array(repeating: firstCandidate, count: 4) + [invalid], role: "player")
        let reviewer = ReviewLoopBoundary(outputs: Array(repeating: revisionVerdict, count: 4), role: "reviewer")
        let driver = BoardDriver(board: try reviewedBoard(), expert: ExpertSession(transport: player, reviewer: reviewer))
        do { _ = try await driver.advance(); XCTFail("An invalid fifth candidate cannot be executed") }
        catch let failure as ExpertFailure {
            XCTAssertEqual(failure.category, .invalidOutput)
            XCTAssertEqual(failure.reviewRounds.count, 4)
            XCTAssertEqual(failure.rawOutput, invalid)
        }
        let trace = await driver.trace()
        XCTAssertEqual(trace.modelActions, 0)
        let reviews = await reviewer.inputs
        XCTAssertEqual(reviews.count, 4)
    }

    func testKeepAndWithdrawPreserveExplicitNullInReviewedAndFeedbackCandidates() async throws {
        for operation in ["keep", "withdraw"] {
            let candidate = "{\"plan\":{\"update\":\"\(operation)\",\"text\":null},\"selectedCard\":\"DA\",\"publicReason\":\"Win the diamond trick.\"}"
            let player = ReviewLoopBoundary(outputs: [firstCandidate, candidate, candidate], role: "player")
            let reviewer = ReviewLoopBoundary(outputs: [approvalVerdict, revisionVerdict, approvalVerdict], role: "reviewer")
            let driver = BoardDriver(board: try reviewedBoard(), expert: ExpertSession(transport: player, reviewer: reviewer))
            var count = 0
            while count < 2 { if try await driver.advance().decision != nil { count += 1 } }
            let reviewInputs = await reviewer.inputs
            for input in reviewInputs.dropFirst() {
                let value = try JSONSerialization.jsonObject(with: Data(input.utf8)) as! [String:Any]
                let proposal = value["candidate"] as! [String:Any]
                XCTAssertTrue((proposal["plan"] as! [String:Any])["text"] is NSNull)
                XCTAssertEqual(proposal as NSDictionary, try JSONSerialization.jsonObject(with: Data(candidate.utf8)) as! NSDictionary)
            }
            let playerInputs = await player.inputs
            let feedback = try JSONSerialization.jsonObject(with: Data(playerInputs[2].utf8)) as! [String:Any]
            XCTAssertTrue(((feedback["candidate"] as! [String:Any])["plan"] as! [String:Any])["text"] is NSNull)
        }
    }

    func testApprovalDoesNotAdoptPlanUntilExactActualExecutionAndCannotCommitTwice() async throws {
        var board = try reviewedBoard()
        let expert = ExpertSession(transport: RecordedPlayTransport(output: firstCandidate), reviewer: InspectingReviewer())
        let decision = try await expert.decide(board.snapshot(controller: .south))
        let activeBeforeExecution = await expert.activePlan()
        let pending = await expert.pendingDecision()
        XCTAssertNil(activeBeforeExecution)
        XCTAssertEqual(pending?.candidate, decision.advice)
        do {
            try await expert.commit(decision, execution: ActualExecution(event: .init(sequence: 1, seat: .north, card: try Card("D5")), source: .model))
            XCTFail("Approval of D3 cannot authorize D5 or its plan")
        } catch { XCTAssertEqual(error as? ExpertSessionError, .invalidExecutionEvidence) }
        let stillPending = await expert.pendingDecision()
        XCTAssertEqual(stillPending, pending)
        try board.apply(decision.action)
        let execution = ActualExecution(event: board.events.last!, source: .model)
        try await expert.commit(decision, execution: execution)
        do { try await expert.commit(decision, execution: execution); XCTFail("Commit is single use") }
        catch { XCTAssertEqual(error as? ExpertSessionError, .invalidExecutionEvidence) }
        XCTAssertEqual(board.events.count, 2)
    }

    func testStalePlayerReplyCannotCreateAnExecutableCandidate() async throws {
        let expert = ExpertSession(transport: ReviewBoundary(output: firstCandidate, stale: true), reviewer: InspectingReviewer())
        let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
        do { _ = try await driver.advance(); XCTFail("A reply to a superseded player request must fail") }
        catch let failure as ExpertFailure { XCTAssertEqual(failure.category, .identity) }
        let trace = await driver.trace()
        XCTAssertEqual(trace.modelActions, 0)
    }

    func testMalformedStaleOrWrongIdentityReviewCannotAdvanceBoardOrPlan() async throws {
        let replies = [
            ReviewBoundary(output: #"{"verdict":"approve","blockingFindings":[{"claim":"Defect","evidence":"Facts","requestedChange":"Repair"}],"advisorySuggestions":[]}"#),
            ReviewBoundary(output: #"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#, stale: true),
            ReviewBoundary(output: #"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#, model: "gpt-6-luna")
        ]
        for reviewer in replies {
            let expert = ExpertSession(transport: RecordedPlayTransport(output: firstCandidate), reviewer: reviewer)
            let driver = BoardDriver(board: try reviewedBoard(), expert: expert)
            do { _ = try await driver.advance(); XCTFail("Invalid review cannot execute") } catch {}
            let trace = await driver.trace()
            let plan = await expert.activePlan()
            XCTAssertEqual(trace.steps.count, 0)
            XCTAssertEqual(trace.modelActions, 0)
            XCTAssertNil(plan)
        }
    }

}

let firstCandidate = #"{"plan":{"update":"replace","text":"Preserve entries; establish clubs."},"selectedCard":"D3","publicReason":"Follow low from dummy."}"#
func reviewedBoard() throws -> BoardState {
    var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
    try board.play(Card("DQ"), by: .west)
    return board
}
actor InspectingReviewer: PlayingTransport {
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        PlayingReply(rawOutput: #"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#,
                     identity: .init(requestedModel: "gpt-6.1-sol", requestedEffort: "medium", runtimeVersion: "scripted review", observedModel: "gpt-6.1-sol", observedEffort: "medium", threadID: "review-\(UUID())", turnID: "turn-\(UUID())"), requestID: request.id)
    }
}

extension ExpertSession {
    init(transport: any PlayingTransport) { self.init(transport: transport, reviewer: InspectingReviewer()) }
}

struct ReviewBoundary: PlayingTransport {
    let output: String
    var stale = false
    var model = "gpt-6.1-sol"
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        PlayingReply(rawOutput: output, identity: .init(requestedModel: model, requestedEffort: "medium", runtimeVersion: "boundary", observedModel: model, observedEffort: "medium", threadID: "independent-review", turnID: "review"), requestID: stale ? UUID() : request.id)
    }
}

let approvalVerdict = #"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#
let revisionVerdict = #"{"verdict":"revise","blockingFindings":[{"claim":"Incomplete line","evidence":"Missing entry transition","requestedChange":"Trace the route"}],"advisorySuggestions":[]}"#
let revisedCandidate = #"{"plan":{"update":"replace","text":"Final approved route, verbatim."},"selectedCard":"D5","publicReason":"Follow from dummy with the revised route."}"#
actor ReviewLoopBoundary: PlayingTransport {
    let outputs: [String]
    let role: String
    var inputs: [String] = []
    init(outputs: [String], role: String) { self.outputs = outputs; self.role = role }
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        inputs.append(request.input)
        guard inputs.count <= outputs.count else { throw ReviewLoopFailure.exhausted }
        return PlayingReply(rawOutput: outputs[inputs.count - 1], identity: .init(requestedModel: "gpt-6.1-sol", requestedEffort: "medium", runtimeVersion: "offline synthetic", observedModel: "gpt-6.1-sol", observedEffort: "medium", threadID: role, turnID: "turn-\(inputs.count)"), requestID: request.id)
    }
}
private enum ReviewLoopFailure: Error { case exhausted }
