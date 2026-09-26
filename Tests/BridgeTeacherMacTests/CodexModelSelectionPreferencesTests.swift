import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

final class CodexModelSelectionPreferencesTests: XCTestCase {
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
