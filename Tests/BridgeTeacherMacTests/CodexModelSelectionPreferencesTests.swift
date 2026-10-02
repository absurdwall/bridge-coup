import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

final class CodexModelSelectionPreferencesTests: XCTestCase {
    func testMigratedOldSolPreferenceCanBeSavedAndRestoredForNextLaunch() throws {
        let suiteName = "BridgeTeacherModelMigration-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = CodexModelSelectionPreferences(userDefaults: defaults)
        preferences.save(CodexModelSelection(family: .sol, modelIdentifier: "gpt-6-sol", effort: .high))
        let catalog = [CodexRuntimeModelCapability(
            modelIdentifier: "gpt-6.1-sol", displayName: "GPT-6.1 Sol",
            supportedEfforts: [.high, .ultra], defaultEffort: .high, inputModalities: [.text, .image]
        )]
        let migrated = CodexModelSettingsState(runtimeModels: catalog, savedSelection: preferences.load())
        XCTAssertTrue(migrated.notice?.contains("迁移") == true)
        preferences.save(try XCTUnwrap(migrated.selection))
        let restored = CodexModelSettingsState(runtimeModels: catalog, savedSelection: preferences.load())
        XCTAssertEqual(restored.selection?.modelIdentifier, "gpt-6.1-sol")
        XCTAssertEqual(restored.selection?.effort, .high)
        XCTAssertNil(restored.notice)
    }

    func testSelectionAndEffortSurviveCreatingPreferencesForTheNextLaunch() throws {
        let suiteName = "BridgeTeacherModelSelection-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let selected = CodexModelSelection(
            family: .astra,
            modelIdentifier: "gpt-6-astra",
            effort: .xhigh
        )
        CodexModelSelectionPreferences(userDefaults: defaults).save(selected)

        let reopenedPreferences = CodexModelSelectionPreferences(userDefaults: defaults)
        XCTAssertEqual(reopenedPreferences.load(), selected)
    }
}
