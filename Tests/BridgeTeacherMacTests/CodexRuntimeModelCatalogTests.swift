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
}
