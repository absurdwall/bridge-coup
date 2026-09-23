import XCTest
@testable import BridgeTeacherCore

@MainActor
final class DeclarerPlanWorkflowTests: XCTestCase {
    func testRuntimeFailurePreservesInputAndAllowsRetry() async throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        let runtime = RetryRuntime()
        let workflow = DeclarerPlanWorkflow(draft: draft, runtime: runtime)

        await workflow.generatePlan()

        XCTAssertEqual(workflow.draft, draft)
        XCTAssertEqual(workflow.state, .failed(PlanRuntimeError.temporarilyUnavailable.localizedDescription))
        XCTAssertNil(workflow.result)

        await workflow.generatePlan()

        XCTAssertEqual(workflow.draft, draft)
        XCTAssertEqual(workflow.state, .succeeded)
        XCTAssertEqual(workflow.result?.text, "基于目前可见的牌，先安排进手再处理黑桃。")
        let sentRequests = await runtime.requests()
        XCTAssertEqual(sentRequests.count, 2)
        XCTAssertEqual(sentRequests[0], sentRequests[1])
        XCTAssertEqual(sentRequests[0].unknownSeats, [.north, .east, .west])
        XCTAssertEqual(sentRequests[0].visibleHands.map(\.seat), [.south])
        XCTAssertTrue(sentRequests[0].prompt.contains("北家：未知"))
        XCTAssertTrue(sentRequests[0].prompt.contains("东家：未知"))
        XCTAssertTrue(sentRequests[0].prompt.contains("西家：未知"))
    }
}

private actor RetryRuntime: DeclarerTeachingRuntime {
    private var attempt = 0
    private var sent: [DeclarerPlanRequest] = []

    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        attempt += 1
        sent.append(request)
        if attempt == 1 {
            throw PlanRuntimeError.temporarilyUnavailable
        }
        return DeclarerPlanResponse(text: "基于目前可见的牌，先安排进手再处理黑桃。", model: "test-model")
    }

    func requests() -> [DeclarerPlanRequest] { sent }
}
