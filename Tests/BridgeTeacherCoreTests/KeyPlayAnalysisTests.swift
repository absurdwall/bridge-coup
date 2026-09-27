import XCTest
@testable import BridgeTeacherCore

final class KeyPlayAnalysisTests: XCTestCase {
    func testBuildsKeyPlayRequestFromConfirmedNodeAndVisibleHands() throws {
        var review = DeclarerPlanDraft()
        review.contractLevel = 3
        review.contractStrain = .noTrump
        review.vulnerability = .both
        review.auction = AuctionRecord(
            startingSeat: .south,
            entries: [
                AuctionEntry(seat: .south, call: .bid(level: 1, strain: .noTrump)),
                AuctionEntry(seat: .west, call: .pass),
                AuctionEntry(seat: .north, call: .unknown),
            ]
        )
        review.hands[.south, default: [:]][.hearts] = "A84"
        review.hands[.north, default: [:]][.hearts] = "J7"

        var node = KeyPlayAnalysisDraft()
        node.analysisPoint = "第七墩，轮到庄家处理红心"
        node.actingSeat = .south
        node.currentTrickState = .cardsRecorded
        node.currentTrickCards = "♥K, ♥3, ♥5"
        node.relevantPlayHistory = "前六墩的已知出牌：西家先兑现方块 A。"
        node.question = "比较现在拿红心 A 与忍让的目的。"

        let request = try KeyPlayAnalysisRequestBuilder.build(from: review, node: node)

        XCTAssertEqual(request.visibleHands.map(\.seat), [.north, .south])
        XCTAssertEqual(request.unknownSeats, [.east, .west])
        XCTAssertTrue(request.prompt.contains("关键出牌节点分析"))
        XCTAssertTrue(request.prompt.contains("第七墩，轮到庄家处理红心"))
        XCTAssertTrue(request.prompt.contains("当前行动座位：南家"))
        XCTAssertTrue(request.prompt.contains("♥K, ♥3, ♥5"))
        XCTAssertTrue(request.prompt.contains("西家先兑现方块 A"))
        XCTAssertTrue(request.prompt.contains("比较现在拿红心 A 与忍让的目的"))
        XCTAssertTrue(request.prompt.contains("东家：未知"))
        XCTAssertTrue(request.prompt.contains("不得把未提供的出牌过程当作事实"))
        XCTAssertEqual(request.vulnerability, .both)
        XCTAssertEqual(request.auction, review.auction)
        XCTAssertTrue(request.prompt.contains("局况：双方有局"))
        XCTAssertTrue(request.prompt.contains("第3次行动（北家）：未知叫品"))
        XCTAssertFalse(request.prompt.contains("后来"))
        XCTAssertEqual(request.scoring, "IMP")
    }

    func testKeyPlayRequestUsesCanonicalOpeningLeadAndRejectsInvalidInput() throws {
        var review = DeclarerPlanDraft()
        review.contractLevel = 3
        review.contractStrain = .noTrump
        review.openingLead = "cK"

        let request = try KeyPlayAnalysisRequestBuilder.build(from: review, node: KeyPlayAnalysisDraft())
        XCTAssertEqual(request.openingLead, "♣K")
        XCTAssertTrue(request.prompt.contains("首攻（用户提供）：♣K"))

        review.openingLead = "C1"
        XCTAssertThrowsError(try KeyPlayAnalysisRequestBuilder.build(from: review, node: KeyPlayAnalysisDraft())) { error in
            XCTAssertEqual(error as? OpeningLeadInputError, .invalidInput("C1"))
        }
    }

    func testRejectsOffSuitCandidateWhenTheActingHandMustFollowSuit() {
        var review = DeclarerPlanDraft()
        review.contractLevel = 3
        review.contractStrain = .noTrump
        review.hands[.south, default: [:]][.hearts] = "A84"
        review.hands[.south, default: [:]][.clubs] = "Q2"

        var node = KeyPlayAnalysisDraft()
        node.actingSeat = .south
        node.currentTrickState = .cardsRecorded
        node.currentTrickCards = "♥K, ♥3, ♥5"
        node.candidatePlays = "♣Q"

        XCTAssertThrowsError(try KeyPlayAnalysisRequestBuilder.build(from: review, node: node)) { error in
            XCTAssertEqual(error as? KeyPlayAnalysisInputError, .mustFollowSuit(card: "♣Q", ledSuit: "♥"))
        }
    }

    func testDoesNotAssertOffSuitCandidateIsLegalWhenLedSuitHoldingIsUnknown() {
        var review = DeclarerPlanDraft()
        review.contractLevel = 3
        review.contractStrain = .noTrump
        review.hands[.south, default: [:]][.clubs] = "Q2"

        var node = KeyPlayAnalysisDraft()
        node.actingSeat = .south
        node.currentTrickState = .cardsRecorded
        node.currentTrickCards = "♥K, ♥3, ♥5"
        node.candidatePlays = "♣Q"

        XCTAssertThrowsError(try KeyPlayAnalysisRequestBuilder.build(from: review, node: node)) { error in
            XCTAssertEqual(error as? KeyPlayAnalysisInputError, .cannotVerifyFollowSuit(card: "♣Q", ledSuit: "♥"))
        }
    }

    func testAllowsOffSuitCandidateOnlyWhenVoidIsConfirmed() throws {
        var review = DeclarerPlanDraft()
        review.contractLevel = 3
        review.contractStrain = .noTrump
        review.hands[.south, default: [:]][.hearts] = "-"
        review.hands[.south, default: [:]][.clubs] = "Q2"

        var node = KeyPlayAnalysisDraft()
        node.actingSeat = .south
        node.currentTrickState = .cardsRecorded
        node.currentTrickCards = "♥K, ♥3, ♥5"
        node.candidatePlays = "♣Q"

        let request = try KeyPlayAnalysisRequestBuilder.build(from: review, node: node)

        XCTAssertTrue(request.prompt.contains("用户要求比较的候选牌：♣Q"))
        XCTAssertTrue(request.prompt.contains("♥缺门（已确认）"))
    }

    func testRejectsCandidateThatIsNotInTheActingHand() {
        var review = DeclarerPlanDraft()
        review.contractLevel = 3
        review.contractStrain = .noTrump
        review.hands[.south, default: [:]][.hearts] = "A84"
        review.hands[.south, default: [:]][.clubs] = "Q2"

        var node = KeyPlayAnalysisDraft()
        node.actingSeat = .south
        node.currentTrickState = .noCardsPlayed
        node.candidatePlays = "♣A"

        XCTAssertThrowsError(try KeyPlayAnalysisRequestBuilder.build(from: review, node: node)) { error in
            XCTAssertEqual(error as? KeyPlayAnalysisInputError, .candidateNotInVisibleHand(card: "♣A", seat: "南家"))
        }
    }

    func testRejectsCurrentTrickCardThatIsStillListedInRemainingHand() {
        var review = DeclarerPlanDraft()
        review.contractLevel = 3
        review.contractStrain = .noTrump
        review.hands[.south, default: [:]][.hearts] = "AK4"

        var node = KeyPlayAnalysisDraft()
        node.actingSeat = .south
        node.currentTrickState = .cardsRecorded
        node.currentTrickCards = "♥A"

        XCTAssertThrowsError(try KeyPlayAnalysisRequestBuilder.build(from: review, node: node)) { error in
            XCTAssertEqual(error as? KeyPlayAnalysisInputError, .currentTrickCardStillVisible("♥A"))
        }
    }

    func testMissingNodeHistoryStaysUnknownAndRequestsClarificationWhenNeeded() throws {
        var review = DeclarerPlanDraft()
        review.contractLevel = 4
        review.contractStrain = .spades
        review.hands[.south, default: [:]][.spades] = "AKQ"

        let request = try KeyPlayAnalysisRequestBuilder.build(from: review, node: KeyPlayAnalysisDraft())

        XCTAssertTrue(request.prompt.contains("分析时点：未提供"))
        XCTAssertTrue(request.prompt.contains("当前墩状态未确认；不得假定本墩尚无人出牌"))
        XCTAssertTrue(request.prompt.contains("未提供；不得把未提供的出牌过程当作事实"))
        XCTAssertTrue(request.prompt.contains("未确认；如影响判断，请先询问轮到谁行动"))
    }

    @MainActor
    func testChangingAnalysisPointOutdatesOldResultAndUsesNewNodeOnRetry() async throws {
        var review = DeclarerPlanDraft()
        review.contractLevel = 3
        review.contractStrain = .noTrump
        review.hands[.south, default: [:]][.hearts] = "A84"
        let runtime = CapturingKeyPlayRuntime()
        let workflow = KeyPlayAnalysisWorkflow(runtime: runtime)
        workflow.updateDraft(completeNode(at: "第七墩"))

        await workflow.generate(from: review)

        XCTAssertEqual(workflow.state, .succeeded)
        XCTAssertFalse(workflow.resultIsOutdated)
        XCTAssertEqual(workflow.result?.text, "先比较拿 A 和忍让的后续交通。")

        workflow.updateDraft(completeNode(at: "第八墩"))

        XCTAssertTrue(workflow.resultIsOutdated)
        await workflow.generate(from: review)

        let requests = await runtime.requests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertTrue(requests[0].prompt.contains("第七墩"))
        XCTAssertTrue(requests[1].prompt.contains("第八墩"))
        XCTAssertFalse(workflow.resultIsOutdated)
    }

    private func completeNode(at point: String) -> KeyPlayAnalysisDraft {
        var node = KeyPlayAnalysisDraft()
        node.analysisPoint = point
        node.actingSeat = .south
        node.currentTrickState = .noCardsPlayed
        return node
    }
}

private actor CapturingKeyPlayRuntime: DeclarerTeachingRuntime {
    private var sent: [DeclarerPlanRequest] = []

    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        sent.append(request)
        return DeclarerPlanResponse(text: "先比较拿 A 和忍让的后续交通。", model: "test-model")
    }

    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "已基于同版本信息回答。", model: "test-model")
    }

    func requests() -> [DeclarerPlanRequest] { sent }
}
