import XCTest
@testable import BridgeTeacherCore

@MainActor
final class ScreenshotReviewWorkflowTests: XCTestCase {
    func testRecognitionCandidateCodableMatchesObjectShapedRuntimeSchema() throws {
        let json = """
        {
          "hands": {
            "north": {"spades":"AK", "hearts":"", "diamonds":"-", "clubs":""},
            "east": {"spades":"", "hearts":"", "diamonds":"", "clubs":""},
            "south": {"spades":"Q", "hearts":"J10", "diamonds":"", "clubs":"A"},
            "west": {"spades":"", "hearts":"", "diamonds":"", "clubs":""}
          },
          "vulnerability": "eastWest",
          "auction": {
            "startingSeat": "west",
            "entries": [
              {"seat":"west", "action":"bid", "level":1, "strain":"clubs"},
              {"seat":"north", "action":"unknown", "level":null, "strain":null}
            ]
          },
          "declarerSeat": "south",
          "contractLevel": 4,
          "contractStrain": "hearts",
          "openingLead": null,
          "otherDecisionTimeFacts": "",
          "notes": []
        }
        """.data(using: .utf8)!

        let candidate = try JSONDecoder().decode(ScreenshotRecognitionCandidate.self, from: json)
        XCTAssertEqual(candidate.hands[.north]?[.spades], "AK")
        XCTAssertEqual(candidate.hands[.north]?[.diamonds], "-")
        XCTAssertNil(candidate.openingLead)
        XCTAssertEqual(candidate.vulnerability, .eastWest)
        XCTAssertEqual(candidate.auction?.entries.map(\.auctionCall), [
            .bid(level: 1, strain: .clubs), .unknown,
        ])
        XCTAssertEqual(candidate.auction?.entries.map(\.seat), [.west, .north])

        let encoded = try JSONEncoder().encode(candidate)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let hands = try XCTUnwrap(object["hands"] as? [String: [String: String]])
        XCTAssertEqual(hands["north"]?["spades"], "AK")
        XCTAssertEqual(hands["south"]?["clubs"], "A")
        XCTAssertEqual(try JSONDecoder().decode(ScreenshotRecognitionCandidate.self, from: encoded), candidate)

        var legacyObject = object
        legacyObject.removeValue(forKey: "vulnerability")
        legacyObject.removeValue(forKey: "auction")
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)
        let legacyCandidate = try JSONDecoder().decode(ScreenshotRecognitionCandidate.self, from: legacyData)
        XCTAssertNil(legacyCandidate.vulnerability)
        XCTAssertNil(legacyCandidate.auction)
    }

    func testScreenshotAuctionCandidateCanBeCorrectedAndIsGatedUntilExplicitReview() async {
        let recognition = Self.candidateResponse.candidate
        let planRuntime = CapturingPlanRuntime()
        let planWorkflow = DeclarerPlanWorkflow(runtime: planRuntime)
        let review = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: FixedScreenshotRecognitionRuntime(recognition)
        )
        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/partial-auction.jpg"))

        await review.recognizeScreenshot()

        XCTAssertEqual(planWorkflow.draft.auction?.entries.map(\.call), [
            .bid(level: 1, strain: .clubs), .unknown,
        ])
        XCTAssertEqual(review.candidate?.auction?.entries.map(\.seat), [.west, nil])
        XCTAssertEqual(planWorkflow.draft.auction?.entries.map(\.seat), [.west, .north])
        XCTAssertEqual(planWorkflow.draft.vulnerability, .eastWest)
        XCTAssertFalse(planWorkflow.draft.decisionTimeConfirmed)
        XCTAssertThrowsError(try DeclarerPlanRequestBuilder.build(from: planWorkflow.draft)) { error in
            XCTAssertEqual(error as? DeclarerPlanInputError, .decisionTimeNotConfirmed)
        }

        var reviewedDraft = planWorkflow.draft
        reviewedDraft.auction?.entries[1].call = .pass
        reviewedDraft.vulnerability = .both
        reviewedDraft.decisionTimeVisibleSeats = [.south]
        reviewedDraft.decisionTimeConfirmed = true
        review.updateDraft(reviewedDraft)
        await review.generatePlan()

        let requests = await planRuntime.requests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].auction?.entries.map(\.call), [
            .bid(level: 1, strain: .clubs), .pass,
        ])
        XCTAssertEqual(requests[0].auction?.entries.map(\.seat), [.west, .north])
        XCTAssertTrue(requests[0].auction?.promptDescription.contains("第2次行动（北家）") == true)
        XCTAssertNotNil(requests[0].auction?.layoutRows)
        XCTAssertEqual(requests[0].vulnerability, .both)
        XCTAssertEqual(requests[0].informationVersion, planWorkflow.informationVersion)
    }

    func testRecognitionPreservesExistingManualAuctionAndVulnerability() async {
        let planWorkflow = DeclarerPlanWorkflow(runtime: CapturingPlanRuntime())
        let review = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: FixedScreenshotRecognitionRuntime(Self.candidateResponse.candidate)
        )
        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/manual-auction.jpg"))
        var manualDraft = planWorkflow.draft
        manualDraft.vulnerability = .northSouth
        manualDraft.auction = AuctionRecord(
            startingSeat: .east,
            entries: [AuctionEntry(seat: .east, call: .pass)]
        )
        review.updateDraft(manualDraft)

        await review.recognizeScreenshot()

        XCTAssertEqual(planWorkflow.draft.vulnerability, .northSouth)
        XCTAssertEqual(planWorkflow.draft.auction, manualDraft.auction)
        XCTAssertFalse(planWorkflow.draft.decisionTimeConfirmed)
    }

    func testEmptyAuctionCandidateCreatesNoCallsAndNeverInventsPassOrNoAuction() async {
        var candidate = Self.candidateResponse.candidate
        candidate.auction = ScreenshotAuctionCandidate(startingSeat: .north, entries: [])
        let planRuntime = CapturingPlanRuntime()
        let planWorkflow = DeclarerPlanWorkflow(runtime: planRuntime)
        let review = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: FixedScreenshotRecognitionRuntime(candidate)
        )
        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/no-visible-calls.jpg"))

        await review.recognizeScreenshot()

        XCTAssertEqual(planWorkflow.draft.auction, AuctionRecord(startingSeat: .north, entries: []))
        XCTAssertEqual(planWorkflow.draft.auction?.kind, .calls)
        XCTAssertTrue(planWorkflow.draft.auction?.entries.isEmpty == true)
        XCTAssertFalse(planWorkflow.draft.decisionTimeConfirmed)
    }

    func testCroppedAuctionKeepsOnlyVisibleCallsWithoutInsertingOmittedTurns() async {
        var candidate = Self.candidateResponse.candidate
        candidate.auction = ScreenshotAuctionCandidate(
            startingSeat: nil,
            entries: [
                ScreenshotAuctionEntryCandidate(seat: .south, action: .bid, level: 1, strain: .clubs),
                ScreenshotAuctionEntryCandidate(seat: .north, action: .bid, level: 2, strain: .hearts),
            ]
        )
        let planWorkflow = DeclarerPlanWorkflow(runtime: CapturingPlanRuntime())
        let review = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: FixedScreenshotRecognitionRuntime(candidate)
        )
        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/cropped-auction.jpg"))

        await review.recognizeScreenshot()

        XCTAssertEqual(planWorkflow.draft.auction?.entries.map(\.call), [
            .bid(level: 1, strain: .clubs), .bid(level: 2, strain: .hearts),
        ])
        XCTAssertEqual(planWorkflow.draft.auction?.entries.map(\.seat), [.south, .north])
        XCTAssertNil(planWorkflow.draft.auction?.startingSeat)
        XCTAssertFalse(planWorkflow.draft.decisionTimeConfirmed)
    }

    func testReapplyingRecognitionCannotRestoreManuallyClearedAuctionOrVulnerability() async {
        let candidate = Self.candidateResponse.candidate
        let planWorkflow = DeclarerPlanWorkflow(runtime: CapturingPlanRuntime())
        let review = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: FixedScreenshotRecognitionRuntime(candidate)
        )
        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/cleared-auction.jpg"))

        await review.recognizeScreenshot()
        var correctedDraft = planWorkflow.draft
        correctedDraft.auction = nil
        correctedDraft.vulnerability = nil
        correctedDraft.hands[.south, default: [:]][.spades] = ""
        review.updateDraft(correctedDraft)
        XCTAssertTrue(review.makeArchive().manuallyEditedFields.contains(.auction))
        XCTAssertTrue(review.makeArchive().manuallyEditedFields.contains(.vulnerability))
        XCTAssertTrue(review.makeArchive().manuallyEditedFields.contains(.hand(seat: .south, suit: .spades)))

        await review.recognizeScreenshot()

        XCTAssertNil(planWorkflow.draft.auction)
        XCTAssertNil(planWorkflow.draft.vulnerability)
        XCTAssertEqual(planWorkflow.draft.hands[.south]?[.spades], "")
        XCTAssertTrue(review.makeArchive().manuallyEditedFields.contains(.auction))
        XCTAssertTrue(review.makeArchive().manuallyEditedFields.contains(.vulnerability))
        XCTAssertTrue(review.makeArchive().manuallyEditedFields.contains(.hand(seat: .south, suit: .spades)))
        XCTAssertFalse(planWorkflow.draft.decisionTimeConfirmed)
    }

    func testContradictoryVisibleScreenshotCandidatesAreRejectedBeforeTeaching() async {
        var contradictoryCandidate = Self.candidateResponse.candidate
        contradictoryCandidate.hands[.north, default: [:]][.spades] = "6"
        contradictoryCandidate.hands[.south, default: [:]][.spades] = "62"

        let planRuntime = CapturingPlanRuntime()
        let workflow = DeclarerPlanWorkflow(runtime: planRuntime)
        let review = ScreenshotReviewWorkflow(
            planWorkflow: workflow,
            runtime: FixedScreenshotRecognitionRuntime(contradictoryCandidate)
        )
        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/contradictory-board.jpg"))
        await review.recognizeScreenshot()

        var confirmedDraft = workflow.draft
        confirmedDraft.decisionTimeVisibleSeats = [.north, .south]
        confirmedDraft.decisionTimeConfirmed = true
        review.updateDraft(confirmedDraft)
        await review.generatePlan()

        XCTAssertEqual(workflow.state, .invalid(DeclarerPlanInputError.duplicateCard("♠6").localizedDescription))
        let requests = await planRuntime.requests()
        XCTAssertTrue(requests.isEmpty)
    }

    func testRecognitionIsOnlyACandidateAndPlanUsesOnlyCorrectedConfirmedHands() async throws {
        let recognition = ScreenshotRecognitionCandidate(
            hands: Self.recognizedHands,
            declarerSeat: .south,
            contractLevel: 4,
            contractStrain: .hearts,
            openingLead: "♠2",
            otherDecisionTimeFacts: "西家开叫后东家加叫。",
            notes: [
                ScreenshotRecognitionNote(
                    field: "叫牌解释",
                    kind: .visibleButUnclear,
                    message: "文字部分被遮挡，请核对。"
                )
            ]
        )
        let recognitionRuntime = FixedScreenshotRecognitionRuntime(recognition)
        let planRuntime = CapturingPlanRuntime()
        let planWorkflow = DeclarerPlanWorkflow(runtime: planRuntime)
        let review = ScreenshotReviewWorkflow(planWorkflow: planWorkflow, runtime: recognitionRuntime)

        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/bridge-review.jpg"))
        await review.recognizeScreenshot()

        XCTAssertEqual(review.state, .succeeded)
        XCTAssertEqual(review.candidate, recognition)
        XCTAssertEqual(planWorkflow.draft.decisionTimeVisibleSeats, [])
        XCTAssertFalse(planWorkflow.draft.decisionTimeConfirmed)
        XCTAssertEqual(planWorkflow.draft.hands[.south]?[.spades], "KQ")

        await review.generatePlan()

        XCTAssertEqual(planWorkflow.state, .invalid(DeclarerPlanInputError.decisionTimeNotConfirmed.localizedDescription))
        let requestsBeforeConfirmation = await planRuntime.requests()
        XCTAssertEqual(requestsBeforeConfirmation.count, 0)

        var correctedDraft = planWorkflow.draft
        correctedDraft.hands[.south, default: [:]][.spades] = "AKQ"
        correctedDraft.hands[.south, default: [:]][.diamonds] = "AQ"
        correctedDraft.decisionTimeVisibleSeats = [.south]
        correctedDraft.decisionTimeConfirmed = true
        review.updateDraft(correctedDraft)
        await review.generatePlan()

        XCTAssertEqual(planWorkflow.state, .succeeded)
        let requests = await planRuntime.requests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].visibleHands.map(\.seat), [.south])
        XCTAssertEqual(requests[0].visibleHands[0].cardsBySuit[.spades], [.ace, .king, .queen])
        XCTAssertEqual(requests[0].visibleHands[0].cardsBySuit[.diamonds], [.ace, .queen])
        XCTAssertEqual(requests[0].unknownSeats, [.north, .east, .west])
        XCTAssertTrue(requests[0].prompt.contains("北家：未知"))
        XCTAssertFalse(requests[0].prompt.contains("♠J8"))
        XCTAssertFalse(requests[0].prompt.contains("叫牌解释"))
        XCTAssertTrue(requests[0].prompt.contains("西家开叫后东家加叫。"))

        let requestedImage = await recognitionRuntime.requestedImages()
        XCTAssertEqual(requestedImage, [URL(fileURLWithPath: "/tmp/bridge-review.jpg")])
    }

    func testUnknownScreenshotDeclarerStaysUnknownUntilPlayerSelectsOne() async {
        var candidate = Self.candidateResponse.candidate
        candidate.declarerSeat = nil
        let planRuntime = CapturingPlanRuntime()
        let planWorkflow = DeclarerPlanWorkflow(runtime: planRuntime)
        let review = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: FixedScreenshotRecognitionRuntime(candidate)
        )

        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/declarer-not-shown.jpg"))
        await review.recognizeScreenshot()

        XCTAssertNil(planWorkflow.draft.declarerSeat)
        XCTAssertEqual(planWorkflow.draft.contractLevel, 4)
        XCTAssertEqual(planWorkflow.draft.contractStrain, .hearts)

        var confirmedDraft = planWorkflow.draft
        confirmedDraft.decisionTimeVisibleSeats = [.south]
        confirmedDraft.decisionTimeConfirmed = true
        review.updateDraft(confirmedDraft)
        await review.generatePlan()

        XCTAssertEqual(planWorkflow.state, .invalid(DeclarerPlanInputError.missingDeclarerSeat.localizedDescription))
        let requests = await planRuntime.requests()
        XCTAssertTrue(requests.isEmpty)
    }

    func testKeyPlayModeCannotUseUnconfirmedScreenshotOrUnselectedHands() async throws {
        let planWorkflow = DeclarerPlanWorkflow(runtime: CapturingPlanRuntime())
        let review = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: FixedScreenshotRecognitionRuntime(Self.candidateResponse.candidate)
        )
        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/key-play-board.jpg"))
        await review.recognizeScreenshot()

        var node = KeyPlayAnalysisDraft()
        node.analysisPoint = "第七墩"
        node.actingSeat = .south
        node.currentTrickState = .noCardsPlayed
        XCTAssertThrowsError(try KeyPlayAnalysisRequestBuilder.build(from: planWorkflow.draft, node: node)) { error in
            XCTAssertEqual(error as? DeclarerPlanInputError, .decisionTimeNotConfirmed)
        }

        var confirmedDraft = planWorkflow.draft
        confirmedDraft.decisionTimeVisibleSeats = [.south]
        confirmedDraft.decisionTimeConfirmed = true
        review.updateDraft(confirmedDraft)

        let request = try KeyPlayAnalysisRequestBuilder.build(from: planWorkflow.draft, node: node)
        XCTAssertEqual(request.visibleHands.map(\.seat), [.south])
        XCTAssertEqual(request.unknownSeats, [.north, .east, .west])
        XCTAssertFalse(request.prompt.contains("♠J8"))
    }

    func testLateRecognitionFromPreviousScreenshotCannotReplaceNewScreenshotOrEdits() async {
        let runtime = DeferredScreenshotRecognitionRuntime()
        let planWorkflow = DeclarerPlanWorkflow(runtime: CapturingPlanRuntime())
        let review = ScreenshotReviewWorkflow(planWorkflow: planWorkflow, runtime: runtime)
        let firstImage = URL(fileURLWithPath: "/tmp/first-board.jpg")
        let secondImage = URL(fileURLWithPath: "/tmp/second-board.jpg")
        review.selectScreenshot(at: firstImage)

        let recognitionTask = Task { await review.recognizeScreenshot() }
        await runtime.waitUntilRequested()

        review.selectScreenshot(at: secondImage)
        var editedDraft = planWorkflow.draft
        editedDraft.otherDecisionTimeFacts = "新截图：已确认是开叫后局面。"
        review.updateDraft(editedDraft)
        await runtime.finish(with: Self.candidateResponse)
        await recognitionTask.value

        XCTAssertEqual(review.screenshotURL, secondImage)
        XCTAssertNil(review.candidate)
        XCTAssertEqual(review.state, .idle)
        XCTAssertEqual(planWorkflow.draft, editedDraft)
    }

    func testLateRecognitionCannotOverwriteCorrectionOnCurrentScreenshot() async {
        let runtime = DeferredScreenshotRecognitionRuntime()
        let planWorkflow = DeclarerPlanWorkflow(runtime: CapturingPlanRuntime())
        let review = ScreenshotReviewWorkflow(planWorkflow: planWorkflow, runtime: runtime)
        let image = URL(fileURLWithPath: "/tmp/corrected-current-board.jpg")
        review.selectScreenshot(at: image)

        let recognitionTask = Task { await review.recognizeScreenshot() }
        await runtime.waitUntilRequested()

        var correctedDraft = planWorkflow.draft
        correctedDraft.hands[.south, default: [:]][.spades] = "AKQ"
        correctedDraft.vulnerability = .neither
        correctedDraft.auction = AuctionRecord(
            startingSeat: .east,
            entries: [AuctionEntry(seat: .east, call: .unknown)]
        )
        correctedDraft.otherDecisionTimeFacts = "牌手在识别期间确认：南家黑桃为 AKQ。"
        review.updateDraft(correctedDraft)
        await runtime.finish(with: Self.candidateResponse)
        await recognitionTask.value

        XCTAssertEqual(review.screenshotURL, image)
        XCTAssertNil(review.candidate)
        XCTAssertEqual(review.state, .stale)
        XCTAssertEqual(planWorkflow.draft, correctedDraft)
        XCTAssertEqual(planWorkflow.draft.vulnerability, .neither)
        XCTAssertEqual(planWorkflow.draft.auction?.entries.map(\.call), [.unknown])
    }

    func testRecognitionFailureKeepsImageAndManualFactsAndRetryFillsOnlyMissingFields() async {
        let runtime = RetryScreenshotRecognitionRuntime(Self.candidateResponse)
        let planWorkflow = DeclarerPlanWorkflow(runtime: CapturingPlanRuntime())
        let review = ScreenshotReviewWorkflow(planWorkflow: planWorkflow, runtime: runtime)
        let image = URL(fileURLWithPath: "/tmp/retry-board.jpg")
        review.selectScreenshot(at: image)
        var draft = planWorkflow.draft
        draft.otherDecisionTimeFacts = "我确认当前墩是黑桃 2、明手已摊牌。"
        draft.vulnerability = .neither
        draft.auction = AuctionRecord(
            startingSeat: .south,
            entries: [AuctionEntry(seat: .south, call: .unknown)]
        )
        review.updateDraft(draft)

        await review.recognizeScreenshot()

        XCTAssertEqual(review.state, .failed(PlanRuntimeError.temporarilyUnavailable.localizedDescription))
        XCTAssertEqual(review.screenshotURL, image)
        XCTAssertEqual(planWorkflow.draft, draft)
        XCTAssertNil(review.candidate)

        await review.recognizeScreenshot()

        XCTAssertEqual(review.state, .succeeded)
        XCTAssertEqual(review.screenshotURL, image)
        XCTAssertEqual(planWorkflow.draft.otherDecisionTimeFacts, draft.otherDecisionTimeFacts)
        XCTAssertEqual(planWorkflow.draft.vulnerability, .neither)
        XCTAssertEqual(planWorkflow.draft.auction, draft.auction)
        XCTAssertEqual(planWorkflow.draft.hands[.south]?[.spades], "KQ")
        XCTAssertFalse(planWorkflow.draft.decisionTimeConfirmed)
        let attempts = await runtime.callCount()
        XCTAssertEqual(attempts, 2)
    }

    func testFailureRetryPreservesIndividuallyClearedRecognitionFields() async {
        let runtime = RetryScreenshotRecognitionRuntime(Self.candidateResponse)
        let planWorkflow = DeclarerPlanWorkflow(runtime: CapturingPlanRuntime())
        let review = ScreenshotReviewWorkflow(planWorkflow: planWorkflow, runtime: runtime)
        review.selectScreenshot(at: URL(fileURLWithPath: "/tmp/field-edits-after-failure.jpg"))

        var manuallyEnteredDraft = planWorkflow.draft
        manuallyEnteredDraft.auction = AuctionRecord(
            startingSeat: .east,
            entries: [AuctionEntry(seat: .east, call: .pass)]
        )
        manuallyEnteredDraft.vulnerability = .neither
        manuallyEnteredDraft.declarerSeat = .east
        manuallyEnteredDraft.contractLevel = 2
        manuallyEnteredDraft.contractStrain = .clubs
        manuallyEnteredDraft.openingLead = "♥3"
        manuallyEnteredDraft.otherDecisionTimeFacts = "人工输入的事实"
        manuallyEnteredDraft.hands[.south, default: [:]][.spades] = "A"
        review.updateDraft(manuallyEnteredDraft)

        await review.recognizeScreenshot()
        XCTAssertEqual(review.state, .failed(PlanRuntimeError.temporarilyUnavailable.localizedDescription))

        var clearedDraft = planWorkflow.draft
        clearedDraft.auction = nil
        clearedDraft.vulnerability = nil
        clearedDraft.declarerSeat = nil
        clearedDraft.contractLevel = nil
        clearedDraft.contractStrain = nil
        clearedDraft.openingLead = ""
        clearedDraft.otherDecisionTimeFacts = ""
        clearedDraft.hands[.south, default: [:]][.spades] = ""
        review.updateDraft(clearedDraft)

        let editedFields = review.makeArchive().manuallyEditedFields
        XCTAssertTrue(editedFields.contains(.auction))
        XCTAssertTrue(editedFields.contains(.vulnerability))
        XCTAssertTrue(editedFields.contains(.declarerSeat))
        XCTAssertTrue(editedFields.contains(.contractLevel))
        XCTAssertTrue(editedFields.contains(.contractStrain))
        XCTAssertTrue(editedFields.contains(.openingLead))
        XCTAssertTrue(editedFields.contains(.otherDecisionTimeFacts))
        XCTAssertTrue(editedFields.contains(.hand(seat: .south, suit: .spades)))

        await review.recognizeScreenshot()

        XCTAssertEqual(review.state, .succeeded)
        XCTAssertNil(planWorkflow.draft.auction)
        XCTAssertNil(planWorkflow.draft.vulnerability)
        XCTAssertNil(planWorkflow.draft.declarerSeat)
        XCTAssertNil(planWorkflow.draft.contractLevel)
        XCTAssertNil(planWorkflow.draft.contractStrain)
        XCTAssertEqual(planWorkflow.draft.openingLead, "")
        XCTAssertEqual(planWorkflow.draft.otherDecisionTimeFacts, "")
        XCTAssertEqual(planWorkflow.draft.hands[.south]?[.spades], "")
        XCTAssertEqual(planWorkflow.draft.hands[.north]?[.spades], "J8")
    }

    private static let recognizedHands: [Seat: [Suit: String]] = [
        .north: [.spades: "J8", .hearts: "A", .diamonds: "7", .clubs: "6"],
        .east: [.spades: "10", .hearts: "K", .diamonds: "Q", .clubs: "J"],
        .south: [.spades: "KQ", .hearts: "QJ", .diamonds: "AK", .clubs: "A"],
        .west: [.spades: "92", .hearts: "109", .diamonds: "543", .clubs: "987"],
    ]

    private static let candidateResponse = ScreenshotRecognitionResponse(
        candidate: ScreenshotRecognitionCandidate(
            hands: recognizedHands,
            declarerSeat: .south,
            contractLevel: 4,
            contractStrain: .hearts,
            openingLead: "♠2",
            otherDecisionTimeFacts: "西家开叫后东家加叫。",
            notes: [],
            vulnerability: .eastWest,
            auction: ScreenshotAuctionCandidate(
                startingSeat: .west,
                entries: [
                    ScreenshotAuctionEntryCandidate(
                        seat: .west,
                        action: .bid,
                        level: 1,
                        strain: .clubs
                    ),
                    ScreenshotAuctionEntryCandidate(seat: nil, action: .unknown),
                ]
            )
        ),
        model: "test-model",
        runtimeVersion: "test-runtime"
    )
}

private actor FixedScreenshotRecognitionRuntime: ScreenshotRecognitionRuntime {
    private let response: ScreenshotRecognitionResponse
    private var images: [URL] = []

    init(_ candidate: ScreenshotRecognitionCandidate) {
        response = ScreenshotRecognitionResponse(candidate: candidate, model: "test-model", runtimeVersion: "test-runtime")
    }

    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse {
        images.append(imageURL)
        return response
    }

    func requestedImages() -> [URL] { images }
}

private actor CapturingPlanRuntime: DeclarerTeachingRuntime {
    private var sent: [DeclarerPlanRequest] = []

    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse {
        sent.append(request)
        return DeclarerPlanResponse(text: "按已确认的庄家手牌安排路线。", model: "test-model")
    }

    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse {
        DeclarerPlanResponse(text: "已基于同版本的已确认信息回答。", model: "test-model")
    }

    func requests() -> [DeclarerPlanRequest] { sent }
}

private actor DeferredScreenshotRecognitionRuntime: ScreenshotRecognitionRuntime {
    private var continuation: CheckedContinuation<ScreenshotRecognitionResponse, Never>?
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var hasStarted = false

    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            hasStarted = true
            startedContinuation?.resume()
            startedContinuation = nil
        }
    }

    func waitUntilRequested() async {
        guard !hasStarted else { return }
        await withCheckedContinuation { startedContinuation = $0 }
    }

    func finish(with response: ScreenshotRecognitionResponse) {
        continuation?.resume(returning: response)
        continuation = nil
    }
}

private actor RetryScreenshotRecognitionRuntime: ScreenshotRecognitionRuntime {
    private let response: ScreenshotRecognitionResponse
    private var attempts = 0

    init(_ response: ScreenshotRecognitionResponse) {
        self.response = response
    }

    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse {
        attempts += 1
        if attempts == 1 {
            throw PlanRuntimeError.temporarilyUnavailable
        }
        return response
    }

    func callCount() -> Int { attempts }
}
