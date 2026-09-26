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

        XCTAssertEqual(settings.option(for: .luna).supportedEfforts, [.low, .medium, .high, .xhigh, .max])
        XCTAssertEqual(settings.option(for: .sol).supportedEfforts, [.low, .medium, .high, .xhigh])
        XCTAssertEqual(settings.option(for: .astra).supportedEfforts, [.low, .medium, .high, .xhigh])
        XCTAssertFalse(settings.option(for: .astra).supportedEfforts.contains(.max))
        XCTAssertFalse(settings.option(for: .sol).supportedEfforts.contains(.max))
        XCTAssertFalse(settings.option(for: .astra).supportedEfforts.contains(.ultra))
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
        XCTAssertEqual(settings.selection?.effort, .xhigh)
        XCTAssertNil(settings.notice)

        XCTAssertTrue(settings.selectModel(.luna))
        XCTAssertTrue(settings.selectEffort(.max))
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

    func testAmbiguousDuplicateRuntimeIdentifiersDoNotSelectOne() {
        let settings = CodexModelSettingsState(runtimeModels: [
            model("gpt-6-luna", efforts: [.low, .medium], default: .medium),
            model("gpt-6-luna", efforts: [.low, .medium], default: .medium),
        ])

        let luna = settings.option(for: .luna)
        XCTAssertFalse(luna.isAvailable)
        XCTAssertEqual(luna.runtimeModelIdentifiers, ["gpt-6-luna", "gpt-6-luna"])
        XCTAssertNil(settings.selection)
    }

    func testOnlyCanonicalGPT6FamilyIdentifiersAreAccepted() {
        let variants: [(CodexModelFamily, String)] = [
            (.luna, "gpt-6-luna-mini"),
            (.sol, "gpt-6-sol-preview"),
            (.astra, "gpt-6-astra-thinking"),
        ]
        let settings = CodexModelSettingsState(runtimeModels: variants.map { family, identifier in
            model(identifier, efforts: [.low, .medium], default: .medium, displayName: "GPT-6 \(family.title)")
        })

        for (family, identifier) in variants {
            let option = settings.option(for: family)
            XCTAssertFalse(option.isAvailable)
            XCTAssertTrue(option.runtimeModelIdentifiers.isEmpty)
            XCTAssertEqual(option.excludedRuntimeModelIdentifiers, [identifier])
        }
        XCTAssertNil(settings.selection)
    }

    func testOnlyGPT56FamilyEntriesAreExcludedAndExplainWhyUnavailable() {
        let settings = CodexModelSettingsState(runtimeModels: [
            model("gpt-5.6-luna", efforts: [.low, .medium], default: .medium, displayName: "GPT-5.6 Luna"),
            model("gpt-5.6-sol", efforts: [.low, .medium], default: .medium, displayName: "GPT-5.6 Sol"),
            model("gpt-5.6-astra", efforts: [.low, .medium], default: .medium, displayName: "GPT-5.6 Astra"),
        ])

        for family in CodexModelFamily.allCases {
            let option = settings.option(for: family)
            XCTAssertFalse(option.isAvailable)
            XCTAssertTrue(option.runtimeModelIdentifiers.isEmpty)
            XCTAssertEqual(option.excludedRuntimeModelIdentifiers, ["gpt-5.6-\(family.rawValue)"])
            XCTAssertTrue(option.unavailableReason?.contains("未找到可接受的 GPT-6") == true)
        }
        XCTAssertNil(settings.selection)
    }

    func testGPT6SelectionIgnoresSameFamilyGPT56Entries() {
        var models = runtimeModels()
        models.append(model("gpt-6-luna-mini", efforts: [.low, .medium], default: .medium))
        let settings = CodexModelSettingsState(runtimeModels: models)

        XCTAssertEqual(settings.option(for: .luna).runtimeModelIdentifier, "gpt-6-luna")
        XCTAssertEqual(settings.option(for: .luna).excludedRuntimeModelIdentifiers, ["gpt-5.6-luna", "gpt-6-luna-mini"])
        XCTAssertEqual(settings.option(for: .sol).runtimeModelIdentifier, "gpt-6-sol")
        XCTAssertEqual(settings.option(for: .sol).excludedRuntimeModelIdentifiers, ["gpt-5.6-sol"])
        XCTAssertEqual(settings.option(for: .astra).runtimeModelIdentifier, "gpt-6-astra")
        XCTAssertEqual(settings.option(for: .astra).excludedRuntimeModelIdentifiers, ["gpt-5.6-astra"])
        XCTAssertEqual(settings.selection?.modelIdentifier, "gpt-6-luna")
        XCTAssertEqual(settings.selection?.effort, .medium)
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
            model("gpt-5.6-luna", efforts: [.low, .medium], default: .medium, displayName: "GPT-5.6 Luna"),
            model("gpt-5.6-sol", efforts: [.low, .medium], default: .medium, displayName: "GPT-5.6 Sol"),
            model("gpt-5.6-astra", efforts: [.low, .medium], default: .medium, displayName: "GPT-5.6 Astra"),
            model("gpt-6-luna", efforts: [.low, .medium, .high, .xhigh, .max, .ultra], default: .medium, modalities: [.text, .image]),
            model("gpt-6-sol", efforts: [.low, .medium, .high, .xhigh, .max, .ultra], default: .medium, modalities: [.text, .image]),
            model("gpt-6-astra", efforts: [.low, .medium, .high, .xhigh, .max, .ultra], default: .medium),
        ]
    }

    private func model(
        _ identifier: String,
        efforts: [CodexReasoningEffort],
        default defaultEffort: CodexReasoningEffort?,
        modalities: Set<CodexInputModality> = [.text],
        displayName: String? = nil
    ) -> CodexRuntimeModelCapability {
        return CodexRuntimeModelCapability(
            modelIdentifier: identifier,
            displayName: displayName ?? "GPT-6 " + identifier.split(separator: "-").last!.capitalized,
            supportedEfforts: efforts,
            defaultEffort: defaultEffort,
            inputModalities: modalities
        )
    }
}
