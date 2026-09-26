import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

@MainActor
final class BridgeTeacherContractSelectionTests: XCTestCase {
    func testSelectingContractUpdatesReviewAndDoubleDummyContextAtomically() {
        let model = BridgeTeacherApplicationModel()
        var doubleDummyDraft = model.doubleDummyWorkflow.draft
        doubleDummyDraft.trickLeader = .east
        doubleDummyDraft.declarerTricksAlreadyTaken = 5
        model.updateDoubleDummyDraft(doubleDummyDraft)

        var draft = model.workflow.draft
        draft.declarerSeat = .west
        draft.openingLead = "♥5"
        draft.otherDecisionTimeFacts = "首攻来自当前复盘。"
        model.updateReviewDraft(draft)

        let versionBeforeSelection = model.workflow.informationVersion
        model.selectContract(level: 4, strain: .spades)

        XCTAssertEqual(model.workflow.informationVersion, versionBeforeSelection + 1)
        XCTAssertEqual(model.workflow.draft.contractLevel, 4)
        XCTAssertEqual(model.workflow.draft.contractStrain, .spades)
        XCTAssertEqual(model.workflow.draft.declarerSeat, .west)
        XCTAssertEqual(model.workflow.draft.openingLead, "♥5")
        XCTAssertEqual(model.workflow.draft.otherDecisionTimeFacts, "首攻来自当前复盘。")

        XCTAssertEqual(model.doubleDummyWorkflow.draft.contractLevel, 4)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.trump, .spades)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.declarerSeat, .west)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.trickLeader, .east)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.declarerTricksAlreadyTaken, 5)
    }
}
