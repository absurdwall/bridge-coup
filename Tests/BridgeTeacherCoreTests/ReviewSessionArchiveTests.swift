import Foundation
import XCTest
@testable import BridgeTeacherCore

final class ReviewSessionArchiveTests: XCTestCase {
    func testLegacyArchiveWithoutManualAuctionFieldsKeepsThemUnknown() throws {
        var draft = DeclarerPlanDraft()
        draft.otherDecisionTimeFacts = "旧备注：叫牌 1♣—Pass—3NT；尚未结构化录入。"
        let archive = DeclarerPlanWorkflowArchive(
            draft: draft,
            state: .idle,
            informationVersion: 0,
            planAnalyses: [],
            currentPlanID: nil,
            followUpExchanges: [],
            followUpQuestion: "",
            followUpAssumptions: ""
        )
        let encoded = try JSONEncoder().encode(archive)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var storedDraft = try XCTUnwrap(object["draft"] as? [String: Any])
        storedDraft.removeValue(forKey: "auction")
        storedDraft.removeValue(forKey: "vulnerability")
        object["draft"] = storedDraft
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let reopened = try JSONDecoder().decode(DeclarerPlanWorkflowArchive.self, from: legacyData)

        XCTAssertNil(reopened.draft.auction)
        XCTAssertNil(reopened.draft.vulnerability)
        XCTAssertTrue(reopened.draft.otherDecisionTimeFacts.contains("叫牌 1♣—Pass—3NT"))
    }

    func testNormalizedOpeningLeadSurvivesSaveReopenAndTeachingRequest() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.openingLead = "s2"
        draft.hands[.south, default: [:]][.spades] = "A2"
        draft = draft.normalizingOpeningLead()

        let snapshot = ReviewSessionSnapshot(
            title: "Lead round-trip",
            teachingMode: .declarerPlan,
            declarerPlan: DeclarerPlanWorkflowArchive(
                draft: draft,
                state: .idle,
                informationVersion: 0,
                planAnalyses: [],
                currentPlanID: nil,
                followUpExchanges: [],
                followUpQuestion: "",
                followUpAssumptions: ""
            ),
            screenshot: ScreenshotReviewWorkflowArchive(state: .idle, candidate: nil, response: nil),
            keyPlay: KeyPlayAnalysisWorkflowArchive(
                draft: KeyPlayAnalysisDraft(),
                state: .idle,
                result: nil,
                resultIsOutdated: false,
                resultInformationVersion: nil
            ),
            doubleDummy: DoubleDummyVerificationWorkflowArchive(
                draft: DoubleDummyVerificationDraft(),
                state: .unverified,
                result: nil,
                hasOutdatedResult: false
            )
        )

        let store = LocalReviewSessionStore(directoryURL: temporaryRoot.appendingPathComponent("reviews", isDirectory: true))
        let saved = try store.save(snapshot, screenshotURL: nil)
        let reopened = try store.open(id: saved.id)

        XCTAssertEqual(reopened.snapshot.declarerPlan.draft.openingLead, "♠2")
        let request = try DeclarerPlanRequestBuilder.build(from: reopened.snapshot.declarerPlan.draft)
        XCTAssertEqual(request.openingLead, "♠2")
        XCTAssertTrue(request.prompt.contains("首攻（用户提供）：♠2"))
    }

    func testArchiveWithPreKindAuctionRecordDefaultsToCallsAndKeepsConfirmedOwners() throws {
        var draft = DeclarerPlanDraft()
        draft.auction = AuctionRecord(
            startingSeat: .west,
            entries: [
                AuctionEntry(seat: .west, call: .pass),
                AuctionEntry(seat: .north, call: .bid(level: 1, strain: .clubs)),
            ]
        )
        let encoded = try JSONEncoder().encode(workflowArchive(draft: draft))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var storedDraft = try XCTUnwrap(object["draft"] as? [String: Any])
        var storedAuction = try XCTUnwrap(storedDraft["auction"] as? [String: Any])
        storedAuction.removeValue(forKey: "kind")
        storedDraft["auction"] = storedAuction
        object["draft"] = storedDraft
        let previousSchemaData = try JSONSerialization.data(withJSONObject: object)

        let reopened = try JSONDecoder().decode(DeclarerPlanWorkflowArchive.self, from: previousSchemaData)

        XCTAssertEqual(reopened.draft.auction?.kind, .calls)
        XCTAssertEqual(reopened.draft.auction?.startingSeat, .west)
        XCTAssertEqual(reopened.draft.auction?.entries.map(\.seat), [.west, .north])
        XCTAssertEqual(reopened.draft.auction?.entries.map(\.call), [.pass, .bid(level: 1, strain: .clubs)])
    }

    func testConfirmedNoAuctionStateSurvivesArchiveRoundTrip() throws {
        var draft = DeclarerPlanDraft()
        draft.auction = AuctionRecord(kind: .noAuction)

        let encoded = try JSONEncoder().encode(workflowArchive(draft: draft))
        let reopened = try JSONDecoder().decode(DeclarerPlanWorkflowArchive.self, from: encoded)

        XCTAssertEqual(reopened.draft.auction, AuctionRecord(kind: .noAuction))
        XCTAssertEqual(reopened.draft.auction?.layoutRows, [])
    }

    private func workflowArchive(draft: DeclarerPlanDraft) -> DeclarerPlanWorkflowArchive {
        DeclarerPlanWorkflowArchive(
            draft: draft,
            state: .idle,
            informationVersion: 0,
            planAnalyses: [],
            currentPlanID: nil,
            followUpExchanges: [],
            followUpQuestion: "",
            followUpAssumptions: ""
        )
    }

    @MainActor
    func testReopenedInFlightPlanAndFollowUpReturnToRetryableState() throws {
        var draft = DeclarerPlanDraft()
        draft.declarerSeat = .south
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.hands[.south, default: [:]][.spades] = "AKQ2"
        let plan = DeclarerPlanAnalysis(
            requestID: UUID(),
            informationVersion: 4,
            response: DeclarerPlanResponse(text: "先规划进手。")
        )
        let pending = DeclarerFollowUpExchange(
            informationVersion: 4,
            planID: plan.id,
            question: "如果西家有五张黑桃呢？",
            assumptions: nil,
            status: .sending
        )
        let archive = DeclarerPlanWorkflowArchive(
            draft: draft,
            state: .generating,
            informationVersion: 4,
            planAnalyses: [plan],
            currentPlanID: plan.id,
            followUpExchanges: [pending],
            followUpQuestion: "",
            followUpAssumptions: ""
        )

        let workflow = DeclarerPlanWorkflow(runtime: ReopenedFollowUpRuntime())
        workflow.restore(from: archive)

        XCTAssertEqual(workflow.state, .idle)
        XCTAssertEqual(workflow.followUpExchanges.first?.status, .failed("应用关闭前这次追问尚未完成，可以重新发送。"))
        XCTAssertTrue(workflow.canFollowUp)
        XCTAssertTrue(workflow.canRetry(try XCTUnwrap(workflow.followUpExchanges.first)))
    }

    @MainActor
    func testSavedReviewReopensWithScreenshotDecisionContextConversationAndAnalysisStates() async throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let screenshotSource = temporaryRoot.appendingPathComponent("original-board.jpg")
        let imageBytes = Data([0xFF, 0xD8, 0xFF, 0xD9])
        try fileManager.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        try imageBytes.write(to: screenshotSource)

        let planID = UUID()
        var draft = DeclarerPlanDraft()
        draft.declarerSeat = .north
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.vulnerability = .eastWest
        draft.auction = AuctionRecord(
            startingSeat: .west,
            entries: [
                AuctionEntry(seat: .west, call: .pass),
                AuctionEntry(seat: .north, call: .unknown),
                AuctionEntry(seat: .east, call: .bid(level: 1, strain: .noTrump)),
            ]
        )
        draft.openingLead = "♠2"
        draft.otherDecisionTimeFacts = "叫牌：1NT—3NT；首攻后等待庄家决定。"
        draft.question = "如何安排前两轮？"
        draft.decisionTimeVisibleSeats = [.north, .south]
        draft.decisionTimeConfirmed = true
        draft.hands[.north, default: [:]][.spades] = "A84"
        draft.hands[.south, default: [:]][.hearts] = "K73"
        draft.hands[.east, default: [:]][.diamonds] = "QJ9"

        let oldPlan = DeclarerPlanAnalysis(
            id: UUID(),
            requestID: UUID(),
            informationVersion: 2,
            response: DeclarerPlanResponse(text: "旧信息版本的计划。", model: "model-a", runtimeVersion: "0.156.1")
        )
        let currentPlan = DeclarerPlanAnalysis(
            id: planID,
            requestID: UUID(),
            informationVersion: 3,
            response: DeclarerPlanResponse(text: "按可见手牌安排路线。", model: "model-b", runtimeVersion: "0.156.1")
        )
        let oldExchange = DeclarerFollowUpExchange(
            informationVersion: 2,
            planID: oldPlan.id,
            question: "旧问题",
            assumptions: "条件假设",
            status: .answered(DeclarerPlanResponse(text: "旧回答。"))
        )
        let currentExchange = DeclarerFollowUpExchange(
            informationVersion: 3,
            planID: planID,
            question: "如果首攻方有五张黑桃呢？",
            assumptions: "假设西家有五张黑桃",
            status: .answered(DeclarerPlanResponse(text: "只在该假设成立时改变路线。"))
        )

        let candidate = ScreenshotRecognitionCandidate(
            hands: [
                .north: [.spades: "A84"],
                .east: [.diamonds: "QJ9"],
                .south: [.hearts: "K73"],
                .west: [.clubs: "T62"],
            ],
            declarerSeat: nil,
            contractLevel: 3,
            contractStrain: .noTrump,
            openingLead: nil,
            otherDecisionTimeFacts: "",
            notes: [ScreenshotRecognitionNote(field: "declarerSeat", kind: .notShown, message: "截图未标注庄家。")]
        )
        let response = ScreenshotRecognitionResponse(candidate: candidate, model: "vision-model", runtimeVersion: "0.156.1")

        let session = ReviewSessionSnapshot(
            id: UUID(),
            title: "North 3NT",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            teachingMode: .keyPlayAnalysis,
            declarerPlan: DeclarerPlanWorkflowArchive(
                draft: draft,
                state: .succeeded,
                informationVersion: 3,
                planAnalyses: [oldPlan, currentPlan],
                currentPlanID: planID,
                followUpExchanges: [oldExchange, currentExchange],
                followUpQuestion: "",
                followUpAssumptions: ""
            ),
            screenshot: ScreenshotReviewWorkflowArchive(
                state: .succeeded,
                candidate: candidate,
                response: response,
                sourceFilename: screenshotSource.lastPathComponent
            ),
            keyPlay: KeyPlayAnalysisWorkflowArchive(
                draft: KeyPlayAnalysisDraft(),
                state: .succeeded,
                result: DeclarerPlanResponse(text: "关键节点分析。", model: "key-play-model", runtimeVersion: "0.156.1"),
                resultIsOutdated: true,
                resultInformationVersion: 2
            ),
            doubleDummy: DoubleDummyVerificationWorkflowArchive(
                draft: DoubleDummyVerificationDraft(),
                state: .outdated,
                result: nil,
                hasOutdatedResult: true
            )
        )

        let store = LocalReviewSessionStore(directoryURL: temporaryRoot.appendingPathComponent("reviews", isDirectory: true))
        let saved = try store.save(session, screenshotURL: screenshotSource)
        let missingScreenshot = temporaryRoot.appendingPathComponent("missing-image.jpg")
        XCTAssertThrowsError(try store.save(session, screenshotURL: missingScreenshot))
        let reopened = try store.open(id: session.id)

        XCTAssertEqual(reopened.snapshot.id, session.id)
        XCTAssertEqual(reopened.snapshot.title, "North 3NT")
        XCTAssertEqual(reopened.snapshot.teachingMode, .keyPlayAnalysis)
        XCTAssertEqual(reopened.snapshot.declarerPlan.informationVersion, 3)
        XCTAssertEqual(reopened.snapshot.declarerPlan.planAnalyses.map(\.informationVersion), [2, 3])
        XCTAssertEqual(reopened.snapshot.declarerPlan.followUpExchanges, [oldExchange, currentExchange])
        XCTAssertEqual(reopened.snapshot.declarerPlan.draft.decisionTimeVisibleSeats, [.north, .south])
        XCTAssertEqual(reopened.snapshot.declarerPlan.draft.vulnerability, .eastWest)
        XCTAssertEqual(reopened.snapshot.declarerPlan.draft.auction, draft.auction)
        XCTAssertEqual(reopened.snapshot.declarerPlan.draft.hands[.east]?[.diamonds], "QJ9")
        XCTAssertEqual(reopened.snapshot.screenshot.candidate, candidate)
        XCTAssertEqual(reopened.snapshot.screenshot.response, response)
        XCTAssertEqual(reopened.snapshot.screenshot.sourceFilename, "original-board.jpg")
        XCTAssertEqual(reopened.snapshot.keyPlay.result, session.keyPlay.result)
        XCTAssertTrue(reopened.snapshot.keyPlay.resultIsOutdated)
        XCTAssertEqual(reopened.snapshot.keyPlay.resultInformationVersion, 2)
        XCTAssertEqual(reopened.snapshot.doubleDummy.state, .outdated)
        XCTAssertTrue(reopened.snapshot.doubleDummy.hasOutdatedResult)
        XCTAssertNotEqual(reopened.screenshotURL?.standardizedFileURL, screenshotSource.standardizedFileURL)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(reopened.screenshotURL)), imageBytes)
        XCTAssertEqual(try store.list().map(\.id), [saved.id])

        let runtime = ReopenedFollowUpRuntime()
        let workflow = DeclarerPlanWorkflow(runtime: runtime)
        workflow.restore(from: reopened.snapshot.declarerPlan)
        XCTAssertTrue(workflow.canFollowUp)
        workflow.setFollowUpQuestion("重新打开后，为什么仍把西家留作未知？")
        workflow.setFollowUpAssumptions("假设西家持有五张黑桃")
        await workflow.sendFollowUp()

        let capturedRequest = await runtime.lastFollowUpRequest()
        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.informationVersion, 3)
        XCTAssertEqual(request.context.visibleHands.map(\.seat), [.north, .south])
        XCTAssertEqual(request.context.unknownSeats, [.east, .west])
        XCTAssertEqual(request.context.vulnerability, .eastWest)
        XCTAssertEqual(request.context.auction, draft.auction)
        XCTAssertFalse(request.context.prompt.contains("QJ9"))
        XCTAssertTrue(request.prompt.contains("假设西家持有五张黑桃"))
        XCTAssertEqual(workflow.followUpExchanges.last?.status, .answered(DeclarerPlanResponse(text: "只按当前确认信息分析。")))
    }
}

private actor ReopenedFollowUpRuntime: DeclarerTeachingRuntime {
    private var followUpRequest: DeclarerFollowUpRequest?

    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        throw PlanRuntimeError.requestFailed("unexpected plan generation")
    }

    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        followUpRequest = request
        return DeclarerPlanResponse(text: "只按当前确认信息分析。")
    }

    func lastFollowUpRequest() -> DeclarerFollowUpRequest? { followUpRequest }
}
