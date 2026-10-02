import BridgeTeacherCore
import XCTest
@testable import BridgeTeacherMac

@MainActor
final class OriginalContractTableApplicationTests: XCTestCase {
    func testCompleteSharedOriginalHandsAllowTableWithoutContractAndOtherWorkflowsDoNotInvalidateIt() async throws {
        let solver = ApplicationTableSolver()
        let model = BridgeTeacherApplicationModel(doubleDummySolver: solver)
        var draft = model.workflow.draft
        draft.hands = completeHands()
        draft.contractLevel = nil
        draft.contractStrain = nil
        draft.declarerSeat = nil
        model.updateReviewDraft(draft)
        await model.calculateOriginalContractTable()
        guard case .ready(let originalTable) = model.originalContractTableWorkflow.state else {
            return XCTFail("Original table should work with no selected contract")
        }
        draft.contractLevel = 4
        draft.contractStrain = .hearts
        draft.declarerSeat = .south
        draft.decisionTimeVisibleSeats = [.north, .south]
        model.updateReviewDraft(draft)
        let teachingBefore = try DeclarerPlanRequestBuilder.build(from: model.workflow.draft).prompt
        var derivedDraft = model.doubleDummyWorkflow.draft
        derivedDraft.hands[.north]?[.spades] = "AK"
        model.updateDoubleDummyDraft(derivedDraft)
        await model.calculateOriginalContractTable()
        XCTAssertEqual(model.originalContractTableWorkflow.state, .ready(originalTable))
        XCTAssertEqual(try DeclarerPlanRequestBuilder.build(from: model.workflow.draft).prompt, teachingBefore)
        XCTAssertFalse(teachingBefore.contains("DDS"))
        let calls = await solver.callCount
        XCTAssertEqual(calls, 20)
    }

    func testOriginalInputChangeImmediatelyInvalidatesTheTableAndRecomputesForTheNewVersion() async {
        let solver = ApplicationTableSolver()
        let model = BridgeTeacherApplicationModel(doubleDummySolver: solver)
        var draft = model.workflow.draft
        draft.hands = completeHands()
        model.updateReviewDraft(draft)
        await model.calculateOriginalContractTable()
        guard case .ready(let first) = model.originalContractTableWorkflow.state else { return XCTFail("Expected table") }
        draft.hands[.south] = [.spades: "-", .hearts: "-", .diamonds: "AKQJT9876543", .clubs: "A"]
        draft.hands[.west] = [.spades: "-", .hearts: "-", .diamonds: "2", .clubs: "KQJT98765432"]
        model.updateReviewDraft(draft)
        XCTAssertEqual(model.originalContractTableWorkflow.state, .idle)
        await model.calculateOriginalContractTable()
        guard case .ready(let next) = model.originalContractTableWorkflow.state else { return XCTFail("Expected new table") }
        XCTAssertEqual(next.identity.boardID, first.identity.boardID)
        XCTAssertGreaterThan(next.identity.version, first.identity.version)
        let calls = await solver.callCount
        XCTAssertEqual(calls, 40)
    }

    private func completeHands() -> [Seat: [Suit: String]] {
        let suitBySeat: [Seat: Suit] = [.north: .spades, .east: .hearts, .south: .diamonds, .west: .clubs]
        return Dictionary(uniqueKeysWithValues: Seat.allCases.map { seat in
            (seat, Dictionary(uniqueKeysWithValues: Suit.allCases.map { ($0, $0 == suitBySeat[seat] ? "AKQJT98765432" : "-") }))
        })
    }
}

private actor ApplicationTableSolver: DoubleDummySolving {
    nonisolated let version = "test-only"
    private(set) var callCount = 0

    func solve(position: DoubleDummyVerificationPosition) async throws -> [DoubleDummyEngineMove] {
        callCount += 1
        return position.legalCards.map {
            DoubleDummyEngineMove(card: $0, equivalentCards: [], tricksForSideToPlay: 6)
        }
    }
}
