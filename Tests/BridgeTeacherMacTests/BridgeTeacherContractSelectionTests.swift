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
        model.handleContractSelectionAction(.select(ContractChoice(level: 4, strain: .spades)))

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

    func testClearingContractPreservesOtherReviewContextAndInvalidatesContract() {
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
        model.handleContractSelectionAction(.select(ContractChoice(level: 3, strain: .noTrump)))

        let versionBeforeClearing = model.workflow.informationVersion
        model.handleContractSelectionAction(.clear)

        XCTAssertEqual(model.workflow.informationVersion, versionBeforeClearing + 1)
        XCTAssertNil(model.workflow.draft.contractLevel)
        XCTAssertNil(model.workflow.draft.contractStrain)
        XCTAssertEqual(model.workflow.draft.declarerSeat, .west)
        XCTAssertEqual(model.workflow.draft.openingLead, "♥5")
        XCTAssertEqual(model.workflow.draft.otherDecisionTimeFacts, "首攻来自当前复盘。")

        XCTAssertNil(model.doubleDummyWorkflow.draft.contractLevel)
        XCTAssertNil(model.doubleDummyWorkflow.draft.trump)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.declarerSeat, .west)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.trickLeader, .east)
        XCTAssertEqual(model.doubleDummyWorkflow.draft.declarerTricksAlreadyTaken, 5)
    }

    func testCancellingContractSelectionPreservesExistingDraftAndVersion() {
        let model = BridgeTeacherApplicationModel()
        var draft = model.workflow.draft
        draft.declarerSeat = .east
        draft.openingLead = "♣A"
        model.updateReviewDraft(draft)
        model.handleContractSelectionAction(.select(ContractChoice(level: 4, strain: .spades)))

        let draftBeforeCancel = model.workflow.draft
        let versionBeforeCancel = model.workflow.informationVersion
        model.handleContractSelectionAction(.cancel)

        XCTAssertEqual(model.workflow.draft, draftBeforeCancel)
        XCTAssertEqual(model.workflow.informationVersion, versionBeforeCancel)
        XCTAssertEqual(model.workflow.draft.contractLevel, 4)
        XCTAssertEqual(model.workflow.draft.contractStrain, .spades)
        XCTAssertEqual(model.workflow.draft.declarerSeat, .east)
        XCTAssertEqual(model.workflow.draft.openingLead, "♣A")
    }

    func testOpeningLeadShortcutsNormalizeInEditableReviewDraft() {
        let model = BridgeTeacherApplicationModel()

        for (input, expected) in [("s2", "♠2"), ("H3", "♥3"), ("D10", "♦10"), ("cT", "♣10")] {
            var draft = model.workflow.draft
            draft.openingLead = input
            model.updateReviewDraft(draft)
            XCTAssertEqual(model.workflow.draft.openingLead, expected, "Input: \(input)")
        }

        var invalidDraft = model.workflow.draft
        invalidDraft.openingLead = "S1"
        model.updateReviewDraft(invalidDraft)
        XCTAssertEqual(model.workflow.draft.openingLead, "S1")
    }

    func testCallMeaningNoteChangeInvalidatesSharedDeclarerAndKeyPlayAnalyses() {
        let model = BridgeTeacherApplicationModel()
        let entry = AuctionEntry(seat: .west, call: .pass)
        var draft = model.workflow.draft
        draft.auction = AuctionRecord(startingSeat: .west, entries: [entry])
        model.updateReviewDraft(draft)

        model.keyPlayWorkflow.restore(
            from: KeyPlayAnalysisWorkflowArchive(
                draft: KeyPlayAnalysisDraft(),
                state: .succeeded,
                result: DeclarerPlanResponse(text: "旧版关键出牌分析。"),
                resultIsOutdated: false,
                resultInformationVersion: model.workflow.informationVersion
            ),
            currentInformationVersion: model.workflow.informationVersion
        )

        var revisedDraft = model.workflow.draft
        XCTAssertTrue(revisedDraft.auction?.setMeaningNote("仅当双方采用该约定时。", forEntryID: entry.id) == true)
        let previousVersion = model.workflow.informationVersion
        model.updateReviewDraft(revisedDraft)

        XCTAssertEqual(model.workflow.informationVersion, previousVersion + 1)
        XCTAssertTrue(model.keyPlayWorkflow.resultIsOutdated)
        XCTAssertEqual(model.keyPlayWorkflow.result?.text, "旧版关键出牌分析。")
    }
}
