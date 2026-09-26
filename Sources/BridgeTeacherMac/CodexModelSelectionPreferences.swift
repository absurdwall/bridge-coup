import BridgeTeacherCore
import Foundation

struct CodexModelSelectionPreferences {
    private static let storageKey = "bridgeTeacher.modelSelection"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> CodexModelSelection? {
        guard let data = userDefaults.data(forKey: Self.storageKey) else { return nil }
        return try? JSONDecoder().decode(CodexModelSelection.self, from: data)
    }

    func save(_ selection: CodexModelSelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }
}
