import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

@MainActor
final class ScreenshotRecognitionRetryTests: XCTestCase {
    func testManualClearThroughApplicationModelSurvivesRetryAfterRecognitionFailure() async {
        let candidate = ScreenshotRecognitionCandidate(
            hands: [:],
            declarerSeat: nil,
            contractLevel: nil,
            contractStrain: nil,
            openingLead: "♠2",
            otherDecisionTimeFacts: "",
            notes: []
        )
        let runtime = FailOnceScreenshotRecognitionRuntime(response: ScreenshotRecognitionResponse(candidate: candidate))
        let model = BridgeTeacherApplicationModel(screenshotRecognitionRuntime: runtime)

        XCTAssertTrue(model.screenshotWorkflow.planWorkflow === model.workflow)
        model.screenshotWorkflow.selectScreenshot(at: URL(fileURLWithPath: "/tmp/retry-recognition.png"))

        var draft = model.workflow.draft
        draft.openingLead = "♥5"
        model.updateReviewDraft(draft)

        await model.screenshotWorkflow.recognizeScreenshot()
        guard case .failed = model.screenshotWorkflow.state else {
            return XCTFail("The first recognition attempt should fail before the user edits the field.")
        }

        var clearedDraft = model.workflow.draft
        clearedDraft.openingLead = ""
        model.updateReviewDraft(clearedDraft)

        await model.screenshotWorkflow.recognizeScreenshot()

        XCTAssertEqual(model.workflow.draft.openingLead, "", "A user-cleared field must stay cleared when retry recognition returns a value.")
        XCTAssertTrue(model.screenshotWorkflow.makeArchive().manuallyEditedFields.contains(.openingLead))
    }
}

private actor FailOnceScreenshotRecognitionRuntime: ScreenshotRecognitionRuntime {
    private let response: ScreenshotRecognitionResponse
    private var hasFailed = false

    init(response: ScreenshotRecognitionResponse) {
        self.response = response
    }

    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse {
        guard hasFailed else {
            hasFailed = true
            throw RecognitionFailure.firstAttempt
        }
        return response
    }
}

private enum RecognitionFailure: Error {
    case firstAttempt
}
