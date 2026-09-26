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

    func testFollowUpFailureCanBeRetriedWithoutDuplicatingTheExchange() async throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        let runtime = FollowUpRetryRuntime()
        let workflow = DeclarerPlanWorkflow(draft: draft, runtime: runtime)

        await workflow.generatePlan()
        let plan = try XCTUnwrap(workflow.planAnalyses.last)
        workflow.setFollowUpQuestion("如果黑桃 4-1 呢？")
        workflow.setFollowUpAssumptions("假设西家有四张黑桃（未确认）")

        await workflow.sendFollowUp()

        XCTAssertEqual(workflow.followUpExchanges.count, 1)
        let failedExchange = try XCTUnwrap(workflow.followUpExchanges.first)
        XCTAssertEqual(failedExchange.status, .failed(PlanRuntimeError.temporarilyUnavailable.localizedDescription))
        XCTAssertEqual(workflow.followUpQuestion, "如果黑桃 4-1 呢？")
        XCTAssertEqual(workflow.followUpAssumptions, "假设西家有四张黑桃（未确认）")

        await workflow.sendFollowUp()
        var requests = await runtime.followUpRequests()
        XCTAssertEqual(requests.count, 1, "sending the same failed message again must not silently create a second exchange")

        await workflow.retryFollowUp(failedExchange.id)

        requests = await runtime.followUpRequests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].requestID, requests[1].requestID)
        XCTAssertEqual(requests[1].planID, plan.id)
        XCTAssertEqual(requests[1].informationVersion, plan.informationVersion)
        XCTAssertTrue(requests[1].prompt.contains("先安排黑桃进手。"))
        XCTAssertTrue(requests[1].prompt.contains("假设西家有四张黑桃（未确认）"))
        XCTAssertEqual(workflow.followUpExchanges.count, 1)
        XCTAssertEqual(workflow.followUpExchanges[0].status, .answered(DeclarerPlanResponse(text: "先核对已知的黑桃牌张。", model: "test-model")))
        XCTAssertEqual(workflow.followUpQuestion, "")
        XCTAssertEqual(workflow.followUpAssumptions, "")
    }

    func testCorrectionExpiresPlanAndIgnoresLateFollowUpBeforeCleanReanalysis() async throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        let runtime = DelayedFollowUpRuntime()
        let workflow = DeclarerPlanWorkflow(draft: draft, runtime: runtime)
        await workflow.generatePlan()
        let oldPlan = try XCTUnwrap(workflow.planAnalyses.last)

        workflow.setFollowUpQuestion("为什么保留西家的牌型为未知？")
        let requestTask = Task { await workflow.sendFollowUp() }
        await runtime.waitForFirstFollowUp()

        var correctedDraft = workflow.draft
        correctedDraft.contractLevel = 4
        correctedDraft.contractStrain = .spades
        correctedDraft.otherDecisionTimeFacts = "修正：首攻实际是 ♥5。"
        workflow.updateDraft(correctedDraft)

        XCTAssertTrue(workflow.resultIsOutdated)
        XCTAssertTrue(workflow.isOutdated(oldPlan))
        XCTAssertEqual(workflow.followUpExchanges.first?.status, .outdated)
        XCTAssertFalse(workflow.canFollowUp)

        await runtime.completeFirstFollowUp()
        await requestTask.value

        XCTAssertEqual(workflow.followUpExchanges.first?.status, .outdated)
        XCTAssertTrue(workflow.resultIsOutdated)

        await workflow.generatePlan()
        let newPlan = try XCTUnwrap(workflow.planAnalyses.last)
        XCTAssertNotEqual(newPlan.id, oldPlan.id)
        XCTAssertEqual(newPlan.informationVersion, oldPlan.informationVersion + 1)
        XCTAssertFalse(workflow.resultIsOutdated)

        workflow.setFollowUpQuestion("请结合修正后的首攻重新解释。")
        await workflow.sendFollowUp()
        let requests = await runtime.followUpRequests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[1].informationVersion, newPlan.informationVersion)
        XCTAssertEqual(requests[1].context.contractLevel, 4)
        XCTAssertEqual(requests[1].context.contractStrain, .spades)
        XCTAssertEqual(requests[1].priorExchanges, [])
        XCTAssertTrue(requests[1].context.prompt.contains("修正：首攻实际是 ♥5。"))
        XCTAssertFalse(requests[1].prompt.contains("为什么保留西家的牌型为未知？"))
    }

    func testReplacementPlanExpiresInFlightFollowUpAndAllowsNextQuestion() async throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        let runtime = DelayedFollowUpRuntime()
        let workflow = DeclarerPlanWorkflow(draft: draft, runtime: runtime)

        await workflow.generatePlan()
        let firstPlan = try XCTUnwrap(workflow.planAnalyses.last)
        workflow.setFollowUpQuestion("为什么保留西家的牌型为未知？")
        let followUpTask = Task { await workflow.sendFollowUp() }
        await runtime.waitForFirstFollowUp()

        await workflow.generatePlan()
        let replacementPlan = try XCTUnwrap(workflow.planAnalyses.last)
        XCTAssertNotEqual(replacementPlan.id, firstPlan.id)

        await runtime.completeFirstFollowUp()
        await followUpTask.value

        XCTAssertEqual(workflow.followUpExchanges.first?.status, .outdated)
        XCTAssertFalse(workflow.isSendingFollowUp)
        XCTAssertTrue(workflow.canFollowUp)

        workflow.setFollowUpQuestion("请结合新计划继续解释。")
        await workflow.sendFollowUp()

        let requests = await runtime.followUpRequests()
        XCTAssertEqual(requests.count, 2)
        if requests.count > 1 {
            XCTAssertEqual(requests[1].planID, replacementPlan.id)
        }
        XCTAssertEqual(workflow.followUpExchanges.count, 2)
    }

    func testLatePlanResponseCannotReplaceAnalysisForCorrectedInformation() async throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 4
        draft.contractStrain = .hearts
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        let runtime = DelayedPlanRuntime()
        let workflow = DeclarerPlanWorkflow(draft: draft, runtime: runtime)
        let oldRequest = Task { await workflow.generatePlan() }
        await runtime.waitForFirstPlan()

        var correctedDraft = workflow.draft
        correctedDraft.contractLevel = 3
        correctedDraft.contractStrain = .noTrump
        correctedDraft.otherDecisionTimeFacts = "修正：明手是北家。"
        workflow.updateDraft(correctedDraft)
        await workflow.generatePlan()

        XCTAssertEqual(workflow.result?.text, "新信息版本的计划。")
        XCTAssertEqual(workflow.planAnalyses.last?.informationVersion, 1)
        await runtime.completeFirstPlan()
        await oldRequest.value

        XCTAssertEqual(workflow.result?.text, "新信息版本的计划。")
        XCTAssertEqual(workflow.planAnalyses.count, 1)
        XCTAssertEqual(workflow.planAnalyses.last?.informationVersion, workflow.informationVersion)
        let requests = await runtime.planRequests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[1].contractLevel, 3)
        XCTAssertEqual(requests[1].contractStrain, .noTrump)
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

    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        throw PlanRuntimeError.requestFailed("test runtime does not handle follow-ups")
    }
}

private actor FollowUpRetryRuntime: DeclarerTeachingRuntime {
    private var followUps: [DeclarerFollowUpRequest] = []

    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "先安排黑桃进手。", model: "test-model")
    }

    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        followUps.append(request)
        if followUps.count == 1 {
            throw PlanRuntimeError.temporarilyUnavailable
        }
        return DeclarerPlanResponse(text: "先核对已知的黑桃牌张。", model: "test-model")
    }

    func followUpRequests() -> [DeclarerFollowUpRequest] { followUps }
}

private actor DelayedFollowUpRuntime: DeclarerTeachingRuntime {
    private var followUps: [DeclarerFollowUpRequest] = []
    private var firstFollowUpContinuation: CheckedContinuation<DeclarerPlanResponse, Error>?
    private var firstFollowUpStarted = false
    private var firstFollowUpWaiter: CheckedContinuation<Void, Never>?

    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "信息版本 \(request.informationVersion) 的做庄计划。", model: "test-model")
    }

    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        followUps.append(request)
        guard followUps.count == 1 else {
            return DeclarerPlanResponse(text: "根据修正信息的回答。", model: "test-model")
        }
        firstFollowUpStarted = true
        firstFollowUpWaiter?.resume()
        firstFollowUpWaiter = nil
        return try await withCheckedThrowingContinuation { firstFollowUpContinuation = $0 }
    }

    func waitForFirstFollowUp() async {
        guard !firstFollowUpStarted else { return }
        await withCheckedContinuation { firstFollowUpWaiter = $0 }
    }

    func completeFirstFollowUp() {
        firstFollowUpContinuation?.resume(returning: DeclarerPlanResponse(text: "迟到的旧版本回答。", model: "test-model"))
        firstFollowUpContinuation = nil
    }

    func followUpRequests() -> [DeclarerFollowUpRequest] { followUps }
}

private actor DelayedPlanRuntime: DeclarerTeachingRuntime {
    private var sentPlanRequests: [DeclarerPlanRequest] = []
    private var firstPlanContinuation: CheckedContinuation<DeclarerPlanResponse, Error>?
    private var firstPlanStarted = false
    private var firstPlanWaiter: CheckedContinuation<Void, Never>?

    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        sentPlanRequests.append(request)
        guard sentPlanRequests.count == 1 else {
            return DeclarerPlanResponse(text: "新信息版本的计划。", model: "test-model")
        }
        firstPlanStarted = true
        firstPlanWaiter?.resume()
        firstPlanWaiter = nil
        return try await withCheckedThrowingContinuation { firstPlanContinuation = $0 }
    }

    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "未使用的追问响应。")
    }

    func waitForFirstPlan() async {
        guard !firstPlanStarted else { return }
        await withCheckedContinuation { firstPlanWaiter = $0 }
    }

    func planRequests() -> [DeclarerPlanRequest] { sentPlanRequests }

    func completeFirstPlan() {
        firstPlanContinuation?.resume(returning: DeclarerPlanResponse(text: "迟到的旧版本计划。", model: "test-model"))
        firstPlanContinuation = nil
    }
}
