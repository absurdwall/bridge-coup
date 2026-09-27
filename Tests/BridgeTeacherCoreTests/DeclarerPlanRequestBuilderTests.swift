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

    func testManualAuctionAndVulnerabilityReachRequestWithUnknownPassAndLayoutDistinct() throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.vulnerability = .eastWest
        draft.auction = AuctionRecord(
            startingSeat: .east,
            entries: [
                AuctionEntry(seat: .east, call: .pass),
                AuctionEntry(seat: .south, call: .unknown),
                AuctionEntry(seat: .west, call: .bid(level: 1, strain: .hearts)),
            ]
        )
        draft.hands[.south, default: [:]][.spades] = "AKQ2"

        let request = try DeclarerPlanRequestBuilder.build(from: draft, informationVersion: 8)

        XCTAssertEqual(request.informationVersion, 8)
        XCTAssertEqual(request.vulnerability, .eastWest)
        XCTAssertEqual(request.auction, draft.auction)
        XCTAssertTrue(request.prompt.contains("局况：东西有局"))
        XCTAssertTrue(request.prompt.contains("首个行动位置：东家"))
        XCTAssertTrue(request.prompt.contains("第1次行动（东家）：Pass"))
        XCTAssertTrue(request.prompt.contains("第2次行动（南家）：未知叫品"))
        XCTAssertTrue(request.prompt.contains("第3次行动（西家）：1♥"))
        XCTAssertTrue(request.prompt.contains("Pass 只表示明确录入的 Pass"))

        let rows = try XCTUnwrap(draft.auction?.layoutRows)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0][.north], .layoutBlank)
        XCTAssertEqual(rows[0][.east], .entry(try XCTUnwrap(draft.auction?.entries[0])))
        XCTAssertEqual(rows[0][.south], .entry(try XCTUnwrap(draft.auction?.entries[1])))
        XCTAssertEqual(rows[0][.west], .entry(try XCTUnwrap(draft.auction?.entries[2])))
    }

    func testAllFourStartingSeatsAlignColumnsAndUnknownSeatIsNeverDefaultedToNorth() throws {
        for startingSeat in Seat.allCases {
            let entries = [
                AuctionEntry(seat: startingSeat, call: .pass),
                AuctionEntry(seat: Seat.allCases[(Seat.allCases.firstIndex(of: startingSeat)! + 1) % 4], call: .unknown),
            ]
            let record = AuctionRecord(startingSeat: startingSeat, entries: entries)
            let rows = try XCTUnwrap(record.layoutRows)
            let startIndex = try XCTUnwrap(Seat.allCases.firstIndex(of: startingSeat))

            for (rowIndex, row) in rows.enumerated() {
                for (columnIndex, seat) in Seat.allCases.enumerated() {
                    let position = rowIndex * Seat.allCases.count + columnIndex
                    if position < startIndex || position >= startIndex + entries.count {
                        XCTAssertEqual(row[seat], .layoutBlank, "alignment at row \(rowIndex), seat \(seat)")
                    } else {
                        XCTAssertEqual(row[seat], .entry(entries[position - startIndex]))
                    }
                }
            }
        }

        let unassigned = AuctionRecord(entries: [AuctionEntry(call: .pass), AuctionEntry(call: .unknown)])
        XCTAssertNil(unassigned.layoutRows)
        XCTAssertTrue(unassigned.promptDescription.contains("未知；不得默认北家"))
        XCTAssertEqual(unassigned.entries.map(\.call), [.pass, .unknown])

        let correctedButUnreconciled = AuctionRecord(
            startingSeat: .east,
            entries: [AuctionEntry(seat: .north, call: .pass)]
        )
        XCTAssertNil(correctedButUnreconciled.layoutRows, "a correction must not silently move a confirmed call to a different seat")
    }

    func testOmittedAuctionAndVulnerabilityStayUnknownWithoutBlockingPlanRequest() throws {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .clubs
        draft.hands[.south, default: [:]][.clubs] = "A2"

        let request = try DeclarerPlanRequestBuilder.build(from: draft)

        XCTAssertNil(request.auction)
        XCTAssertNil(request.vulnerability)
        XCTAssertTrue(request.prompt.contains("局况：未提供；保持未知"))
        XCTAssertTrue(request.prompt.contains("叫牌记录：未提供；这不代表无叫牌"))
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
