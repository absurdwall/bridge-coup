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
}
