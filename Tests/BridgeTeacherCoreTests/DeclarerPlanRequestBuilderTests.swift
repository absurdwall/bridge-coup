import XCTest
@testable import BridgeTeacherCore

final class DeclarerPlanRequestBuilderTests: XCTestCase {
    func testUnenteredHandsRemainUnknownInDecisionTimeRequest() throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 4
        draft.contractStrain = .hearts
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        draft.hands[.south, default: [:]][.hearts] = "KQJ8"

        let request = try DeclarerPlanRequestBuilder.build(from: draft)

        XCTAssertEqual(request.visibleHands.map(\.seat), [.south])
        XCTAssertEqual(request.visibleHands[0].cardsBySuit[.spades], [.ace, .king, .queen, .two])
        XCTAssertEqual(request.visibleHands[0].cardsBySuit[.diamonds], nil)
        XCTAssertEqual(request.unknownSeats, [.north, .east, .west])
        XCTAssertTrue(request.prompt.contains("北家：未知"))
        XCTAssertTrue(request.prompt.contains("西家：未知"))
        XCTAssertFalse(request.prompt.contains("西家：♠"))
    }

    func testDuplicateKnownCardsAreRejectedBeforeRequestCreation() {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 4
        draft.contractStrain = .hearts
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        draft.hands[.north, default: [:]][.spades] = "A7"

        XCTAssertThrowsError(try DeclarerPlanRequestBuilder.build(from: draft)) { error in
            XCTAssertEqual(error as? DeclarerPlanInputError, .duplicateCard("♠A"))
        }
    }

    func testMoreThanThirteenKnownCardsInOneHandIsRejected() {
        var draft = DeclarerPlanDraft()
        draft.hands[.south, default: [:]][.spades] = "AKQJ1098765432"
        draft.hands[.south, default: [:]][.hearts] = "A"

        XCTAssertThrowsError(try DeclarerPlanRequestBuilder.visibleHands(in: draft)) { error in
            XCTAssertEqual(error as? DeclarerPlanInputError, .tooManyKnownCards(seat: .south, count: 14))
        }
    }

    func testBlankHoldingStaysUnknownWhileDashRecordsKnownVoid() throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 4
        draft.contractStrain = .hearts
        draft.hands[.south, default: [:]][.spades] = "-"
        draft.hands[.south, default: [:]][.hearts] = "AKQ"

        let hands = try DeclarerPlanRequestBuilder.visibleHands(in: draft)
        let request = try DeclarerPlanRequestBuilder.build(from: draft)

        XCTAssertEqual(hands[0].cardsBySuit[.spades], [])
        XCTAssertNil(hands[0].cardsBySuit[.diamonds])
        XCTAssertTrue(request.prompt.contains("♠缺门（已确认）"))
        XCTAssertTrue(request.prompt.contains("♦未知"))
    }

    func testFollowUpKeepsCurrentPlanAndSeparatesHypothesesFromConfirmedInformation() throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 4
        draft.contractStrain = .hearts
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        draft.question = "请为这副牌制定做庄计划。"
        let context = try DeclarerPlanRequestBuilder.build(from: draft, informationVersion: 7)
        let plan = DeclarerPlanAnalysis(
            id: UUID(),
            requestID: UUID(),
            informationVersion: 7,
            response: DeclarerPlanResponse(text: "先兑现黑桃顶张，再保留进手。")
        )
        let priorAnswer = DeclarerFollowUpExchange(
            id: UUID(),
            informationVersion: 7,
            planID: plan.id,
            question: "为什么先处理黑桃？",
            assumptions: nil,
            status: .answered(DeclarerPlanResponse(text: "这样可以先检查黑桃分布。"))
        )
        let staleAnswer = DeclarerFollowUpExchange(
            informationVersion: 6,
            planID: UUID(),
            question: "已经不相关的旧问题。",
            assumptions: nil,
            status: .answered(DeclarerPlanResponse(text: "已失效的旧回答。"))
        )
        let unansweredExchange = DeclarerFollowUpExchange(
            informationVersion: 7,
            planID: plan.id,
            question: "尚未完成的追问。",
            assumptions: nil,
            status: .sending
        )

        let followUp = try DeclarerFollowUpRequestBuilder.build(
            context: context,
            currentPlan: plan,
            priorExchanges: [priorAnswer, staleAnswer, unansweredExchange],
            question: "如果东家有四张黑桃呢？",
            assumptions: "假设东家有四张黑桃（尚未确认）",
            requestID: UUID()
        )

        XCTAssertEqual(followUp.informationVersion, 7)
        XCTAssertEqual(followUp.context.visibleHands.map(\.seat), [.south])
        XCTAssertEqual(followUp.context.unknownSeats, [.north, .east, .west])
        XCTAssertFalse(context.prompt.contains("假设东家有四张黑桃"))
        XCTAssertTrue(followUp.prompt.contains("先兑现黑桃顶张，再保留进手。"))
        XCTAssertTrue(followUp.prompt.contains("为什么先处理黑桃？"))
        XCTAssertTrue(followUp.prompt.contains("这样可以先检查黑桃分布。"))
        XCTAssertFalse(followUp.prompt.contains("已失效的旧回答。"))
        XCTAssertFalse(followUp.prompt.contains("尚未完成的追问。"))
        XCTAssertTrue(followUp.prompt.contains("本次条件假设（不是已确认事实）"))
        XCTAssertTrue(followUp.prompt.contains("假设东家有四张黑桃（尚未确认）"))
        XCTAssertTrue(followUp.prompt.contains("东家：未知"))
    }
}
