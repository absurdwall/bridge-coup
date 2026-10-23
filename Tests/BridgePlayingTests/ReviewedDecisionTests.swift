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

    func testRejectedMalformedStaleOrWrongIdentityReviewCannotAdvanceBoardOrPlan() async throws {
        let replies = [
            ReviewBoundary(output: #"{"verdict":"revise","blockingFindings":[{"claim":"Incomplete","evidence":"Main route missing","requestedChange":"Explain route"}],"advisorySuggestions":[]}"#),
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
