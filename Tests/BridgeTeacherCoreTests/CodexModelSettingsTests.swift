import XCTest
@testable import BridgeTeacherCore

final class CodexModelSettingsTests: XCTestCase {
    func testFirstRunSelectsLunaMediumWhenRuntimeAdvertisesIt() {
        let settings = CodexModelSettingsState(runtimeModels: runtimeModels())

        XCTAssertEqual(settings.selectedFamily, .luna)
        XCTAssertEqual(settings.selection, CodexModelSelection(
            family: .luna,
            modelIdentifier: "gpt-6-luna",
            effort: .medium
        ))
        XCTAssertNil(settings.notice)
    }

    func testEffortsAreFilteredByRuntimeSupportAndProductPolicy() {
        let settings = CodexModelSettingsState(runtimeModels: runtimeModels())

        XCTAssertEqual(settings.option(for: .luna).supportedEfforts, [.low, .medium, .high, .max])
        XCTAssertEqual(settings.option(for: .sol).supportedEfforts, [.low, .medium, .high])
        XCTAssertEqual(settings.option(for: .astra).supportedEfforts, [.medium, .high, .xhigh])
        XCTAssertFalse(settings.option(for: .astra).supportedEfforts.contains(.max))
        XCTAssertFalse(settings.option(for: .luna).supportedEfforts.contains(.ultra))
    }

    func testChangingModelKeepsAValidEffortAndExplainsFallbackWhenNeeded() {
        var settings = CodexModelSettingsState(runtimeModels: runtimeModels())

        XCTAssertTrue(settings.selectEffort(.high))
        XCTAssertTrue(settings.selectModel(.sol))
        XCTAssertEqual(settings.selection?.effort, .high)
        XCTAssertNil(settings.notice)

        XCTAssertTrue(settings.selectModel(.astra))
        XCTAssertEqual(settings.selection?.effort, .high)
        XCTAssertNil(settings.notice)

        XCTAssertTrue(settings.selectEffort(.xhigh))
        XCTAssertTrue(settings.selectModel(.sol))
        XCTAssertEqual(settings.selection?.effort, .medium)
        XCTAssertTrue(settings.notice?.contains("Medium") == true)
    }

    func testUnavailableInitialLunaMediumDoesNotSilentlyChooseAnotherConfiguration() {
        let settings = CodexModelSettingsState(runtimeModels: [
            model("gpt-6-luna", efforts: [.low, .high], default: .high),
            model("gpt-6-sol", efforts: [.low, .high], default: .low),
        ])

        XCTAssertNil(settings.selection)
        XCTAssertEqual(settings.selectedFamily, .luna)
        XCTAssertNotNil(settings.notice)
    }

    func testAmbiguousFamilyShowsEveryRuntimeIdentifierWithoutSelectingOne() {
        let settings = CodexModelSettingsState(runtimeModels: [
            model("gpt-6-luna-mini", efforts: [.low, .medium], default: .medium),
            model("gpt-6-luna", efforts: [.low, .medium], default: .medium),
        ])

        let luna = settings.option(for: .luna)
        XCTAssertFalse(luna.isAvailable)
        XCTAssertEqual(luna.runtimeModelIdentifiers, ["gpt-6-luna", "gpt-6-luna-mini"])
        XCTAssertNil(settings.selection)
    }

    func testModelSwitchFallsBackToRuntimeDefaultThenBlocksWhenNoLegalPairExists() {
        var settings = CodexModelSettingsState(runtimeModels: [
            model("gpt-6-luna", efforts: [.medium], default: .medium),
            model("gpt-6-sol", efforts: [.low, .high], default: .high),
            model("gpt-6-astra", efforts: [.ultra], default: .ultra),
        ])

        XCTAssertTrue(settings.selectModel(.sol))
        XCTAssertEqual(settings.selection?.effort, .high)
        XCTAssertTrue(settings.notice?.contains("运行时默认") == true)

        XCTAssertFalse(settings.option(for: .astra).isAvailable)
        XCTAssertFalse(settings.selectModel(.astra))
        XCTAssertEqual(settings.selection?.modelIdentifier, "gpt-6-sol")
    }

    func testSavedSelectionIsRestoredOnlyWhenCurrentRuntimeStillSupportsIt() {
        let saved = CodexModelSelection(family: .sol, modelIdentifier: "gpt-6-sol", effort: .high)

        let available = CodexModelSettingsState(runtimeModels: runtimeModels(), savedSelection: saved)
        XCTAssertEqual(available.selection, saved)

        let noLongerAvailable = CodexModelSettingsState(
            runtimeModels: [model("gpt-6-sol", efforts: [.low, .medium], default: .medium)],
            savedSelection: saved
        )
        XCTAssertNil(noLongerAvailable.selection)
        XCTAssertNotNil(noLongerAvailable.notice)
    }

    func testScreenshotCapabilityComesFromTheSelectedRuntimeModel() {
        var settings = CodexModelSettingsState(runtimeModels: runtimeModels())
        XCTAssertTrue(settings.canRecognizeImages)

        XCTAssertTrue(settings.selectModel(.astra))
        XCTAssertFalse(settings.canRecognizeImages)
        XCTAssertEqual(settings.option(for: .astra).runtimeModelIdentifier, "gpt-6-astra")
    }

    func testTurnStartFieldsCarryTheExactSelectedRuntimeModelAndEffort() {
        let selection = CodexModelSelection(family: .luna, modelIdentifier: "gpt-6-luna", effort: .medium)

        XCTAssertEqual(selection.turnStartFields, [
            "model": "gpt-6-luna",
            "effort": "medium",
        ])
    }

    func testOlderStoredResponsesDecodeWithoutRequestProvenanceFields() throws {
        let json = Data(#"{"text":"旧复盘中的计划","model":"gpt-5.6-luna","runtimeVersion":"codex-cli 0.156.1"}"#.utf8)

        let response = try JSONDecoder().decode(DeclarerPlanResponse.self, from: json)

        XCTAssertEqual(response.text, "旧复盘中的计划")
        XCTAssertNil(response.requestedModel)
        XCTAssertNil(response.reasoningEffort)
    }

    private func runtimeModels() -> [CodexRuntimeModelCapability] {
        [
            model("gpt-6-luna", efforts: [.low, .medium, .high, .max, .ultra], default: .medium, modalities: [.text, .image]),
            model("gpt-6-sol", efforts: [.low, .medium, .high], default: .medium, modalities: [.text, .image]),
            model("gpt-6-astra", efforts: [.medium, .high, .xhigh, .max], default: .high),
        ]
    }

    private func model(
        _ identifier: String,
        efforts: [CodexReasoningEffort],
        default defaultEffort: CodexReasoningEffort?,
        modalities: Set<CodexInputModality> = [.text]
    ) -> CodexRuntimeModelCapability {
        let displayName = "GPT-6 " + identifier.split(separator: "-").last!.capitalized
        return CodexRuntimeModelCapability(
            modelIdentifier: identifier,
            displayName: displayName,
            supportedEfforts: efforts,
            defaultEffort: defaultEffort,
            inputModalities: modalities
        )
    }
}
