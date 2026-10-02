import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

final class CodexRuntimeModelCatalogTests: XCTestCase {
    func testRuntimeCatalogPreservesActualModelIDEffortsDefaultsAndInputModalities() throws {
        let page = try CodexRuntimeModelCatalogParser.parsePage([
            "data": [[
                "id": "gpt-6-luna-picker-id",
                "model": "gpt-6-luna",
                "displayName": "GPT-6 Luna",
                "supportedReasoningEfforts": [
                    ["reasoningEffort": "low", "description": "Fast"],
                    ["reasoningEffort": "medium", "description": "Balanced"],
                    ["reasoningEffort": "ultra", "description": "Deep"],
                ],
                "defaultReasoningEffort": "medium",
                "inputModalities": ["text", "image"],
            ]],
            "nextCursor": "next-page",
        ])

        XCTAssertEqual(page.models.count, 1)
        XCTAssertEqual(page.models[0].modelIdentifier, "gpt-6-luna")
        XCTAssertEqual(page.models[0].displayName, "GPT-6 Luna")
        XCTAssertEqual(page.models[0].supportedEfforts, [.low, .medium, .ultra])
        XCTAssertEqual(page.models[0].defaultEffort, .medium)
        XCTAssertEqual(page.models[0].inputModalities, [.text, .image])
        XCTAssertEqual(page.nextCursor, "next-page")
    }

    func testMissingImageCapabilityIsNotInferredFromModelName() throws {
        let page = try CodexRuntimeModelCatalogParser.parsePage([
            "data": [[
                "model": "gpt-6-luna",
                "displayName": "GPT-6 Luna",
                "supportedReasoningEfforts": [["reasoningEffort": "medium"]],
                "defaultReasoningEffort": "medium",
            ]],
        ])

        XCTAssertTrue(page.models[0].inputModalities.isEmpty)
    }

    func testGPT56CatalogEntriesStayOutOfGPT6FamilyChoices() throws {
        let page = try CodexRuntimeModelCatalogParser.parsePage([
            "data": [
                catalogEntry("gpt-6-luna", displayName: "GPT-6-Luna"),
                catalogEntry("gpt-5.6-luna", displayName: "GPT-5.6-Luna"),
                catalogEntry("gpt-6.1-sol", displayName: "GPT-6-Sol"),
                catalogEntry("gpt-5.6-sol", displayName: "GPT-5.6-Sol"),
                catalogEntry("gpt-6-sol", displayName: "GPT-6 Sol"),
                catalogEntry("gpt-6-astra", displayName: "GPT-6-Astra"),
                catalogEntry("gpt-5.6-terra", displayName: "GPT-5.6-Terra"),
            ],
        ])

        let settings = CodexModelSettingsState(runtimeModels: page.models)

        XCTAssertEqual(settings.option(for: .luna).runtimeModelIdentifier, "gpt-6-luna")
        XCTAssertEqual(settings.option(for: .luna).excludedRuntimeModelIdentifiers, ["gpt-5.6-luna"])
        XCTAssertEqual(settings.option(for: .sol).runtimeModelIdentifier, "gpt-6.1-sol")
        XCTAssertEqual(settings.option(for: .sol).excludedRuntimeModelIdentifiers, ["gpt-5.6-sol", "gpt-6-sol"])
        XCTAssertEqual(settings.option(for: .astra).runtimeModelIdentifier, "gpt-6-astra")
        XCTAssertEqual(settings.option(for: .astra).excludedRuntimeModelIdentifiers, [])
        XCTAssertEqual(settings.selection?.modelIdentifier, "gpt-6-luna")
        XCTAssertEqual(settings.selection?.effort, .medium)
    }

    private func catalogEntry(_ model: String, displayName: String) -> [String: Any] {
        [
            "model": model,
            "displayName": displayName,
            "supportedReasoningEfforts": [
                ["reasoningEffort": "low"],
                ["reasoningEffort": "medium"],
                ["reasoningEffort": "ultra"],
            ],
            "defaultReasoningEffort": "medium",
            "inputModalities": ["text"],
        ]
    }
}
