import Foundation

public enum CodexModelFamily: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case luna
    case sol
    case astra

    public var title: String {
        switch self {
        case .luna: "Luna"
        case .sol: "Sol"
        case .astra: "Astra"
        }
    }
}

public enum CodexReasoningEffort: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case none
    case minimal
    case low
    case medium
    case high
    case xhigh
    case max
    case ultra

    public var title: String {
        switch self {
        case .none: "None"
        case .minimal: "Minimal"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .xhigh: "Extra High"
        case .max: "Max"
        case .ultra: "Ultra"
        }
    }
}

public enum CodexInputModality: String, Codable, Equatable, Hashable, Sendable {
    case text
    case image
    case audio
    case video
}

/// The current account-specific facts returned by the Codex runtime's model catalog.
public struct CodexRuntimeModelCapability: Equatable, Sendable {
    public let modelIdentifier: String
    public let displayName: String
    public let supportedEfforts: [CodexReasoningEffort]
    public let defaultEffort: CodexReasoningEffort?
    public let inputModalities: Set<CodexInputModality>

    public init(
        modelIdentifier: String,
        displayName: String,
        supportedEfforts: [CodexReasoningEffort],
        defaultEffort: CodexReasoningEffort?,
        inputModalities: Set<CodexInputModality>
    ) {
        self.modelIdentifier = modelIdentifier
        self.displayName = displayName
        self.supportedEfforts = supportedEfforts
        self.defaultEffort = defaultEffort
        self.inputModalities = inputModalities
    }
}

/// A durable user preference. Runtime support is always checked again before use.
public struct CodexModelSelection: Codable, Equatable, Sendable {
    public let family: CodexModelFamily
    public let modelIdentifier: String
    public let effort: CodexReasoningEffort

    public init(family: CodexModelFamily, modelIdentifier: String, effort: CodexReasoningEffort) {
        self.family = family
        self.modelIdentifier = modelIdentifier
        self.effort = effort
    }

    /// Explicit fields for the app-server `turn/start` request.
    public var turnStartFields: [String: String] {
        ["model": modelIdentifier, "effort": effort.rawValue]
    }
}

public struct CodexModelOption: Equatable, Sendable {
    public let family: CodexModelFamily
    public let runtimeModelIdentifiers: [String]
    public let excludedRuntimeModelIdentifiers: [String]
    public let runtimeDisplayName: String?
    public let supportedEfforts: [CodexReasoningEffort]
    public let defaultEffort: CodexReasoningEffort?
    public let supportsImages: Bool
    public let unavailableReason: String?

    public var runtimeModelIdentifier: String? {
        runtimeModelIdentifiers.count == 1 ? runtimeModelIdentifiers[0] : nil
    }

    public var isAvailable: Bool {
        runtimeModelIdentifier != nil && !supportedEfforts.isEmpty
    }

    fileprivate init(
        family: CodexModelFamily,
        runtimeModelIdentifiers: [String],
        excludedRuntimeModelIdentifiers: [String],
        runtimeDisplayName: String?,
        supportedEfforts: [CodexReasoningEffort],
        defaultEffort: CodexReasoningEffort?,
        supportsImages: Bool,
        unavailableReason: String?
    ) {
        self.family = family
        self.runtimeModelIdentifiers = runtimeModelIdentifiers
        self.excludedRuntimeModelIdentifiers = excludedRuntimeModelIdentifiers
        self.runtimeDisplayName = runtimeDisplayName
        self.supportedEfforts = supportedEfforts
        self.defaultEffort = defaultEffort
        self.supportsImages = supportsImages
        self.unavailableReason = unavailableReason
    }
}

/// Validates remembered choices and applies product rules to runtime-reported capabilities.
public struct CodexModelSettingsState: Equatable, Sendable {
    public let options: [CodexModelFamily: CodexModelOption]
    public private(set) var selectedFamily: CodexModelFamily?
    public private(set) var selection: CodexModelSelection?
    public private(set) var notice: String?

    public init(runtimeModels: [CodexRuntimeModelCapability], savedSelection: CodexModelSelection? = nil) {
        options = Self.makeOptions(from: runtimeModels)

        if let savedSelection {
            let option = options[savedSelection.family]!
            selectedFamily = savedSelection.family
            if option.runtimeModelIdentifier == savedSelection.modelIdentifier,
               option.supportedEfforts.contains(savedSelection.effort) {
                selection = savedSelection
                notice = nil
            } else {
                selection = nil
                if option.runtimeModelIdentifier != savedSelection.modelIdentifier {
                    selectedFamily = nil
                    notice = "上次使用的 \(savedSelection.family.title) 运行时标识已不可用。请在模型设置中重新选择。"
                } else {
                    notice = "上次使用的 \(savedSelection.family.title) · \(savedSelection.effort.title) 当前不受支持。请选择一个可用思考深度。"
                }
            }
            return
        }

        let luna = options[.luna]!
        if luna.isAvailable {
            selectedFamily = .luna
            if luna.supportedEfforts.contains(.medium), let identifier = luna.runtimeModelIdentifier {
                selection = CodexModelSelection(family: .luna, modelIdentifier: identifier, effort: .medium)
                notice = nil
            } else {
                selection = nil
                notice = "首次默认 Luna · Medium 当前不可用。请选择一个可用的思考深度。"
            }
        } else {
            selectedFamily = nil
            selection = nil
            notice = "当前 Codex runtime 未提供可用的 Luna · Medium。请选择一个已验证可用的模型与思考深度。"
        }
    }

    public func option(for family: CodexModelFamily) -> CodexModelOption {
        options[family]!
    }

    public var canRecognizeImages: Bool {
        guard let selection else { return false }
        return options[selection.family]?.supportsImages == true
    }

    @discardableResult
    public mutating func selectModel(_ family: CodexModelFamily) -> Bool {
        let option = options[family]!
        guard option.isAvailable, let identifier = option.runtimeModelIdentifier else { return false }
        if selection?.family == family { return true }

        let previousEffort = selection?.effort
        selectedFamily = family

        if let previousEffort, option.supportedEfforts.contains(previousEffort) {
            selection = CodexModelSelection(family: family, modelIdentifier: identifier, effort: previousEffort)
            notice = nil
            return true
        }
        if option.supportedEfforts.contains(.medium) {
            selection = CodexModelSelection(family: family, modelIdentifier: identifier, effort: .medium)
            notice = previousEffort.map {
                "\(family.title) 不支持 \($0.title)，已改为受支持的 Medium。"
            }
            return true
        }
        if let defaultEffort = option.defaultEffort, option.supportedEfforts.contains(defaultEffort) {
            selection = CodexModelSelection(family: family, modelIdentifier: identifier, effort: defaultEffort)
            notice = previousEffort.map {
                "\(family.title) 不支持 \($0.title)，已改为运行时默认的 \(defaultEffort.title)。"
            } ?? "\(family.title) 不支持 Medium，已选择运行时默认的 \(defaultEffort.title)。"
            return true
        }

        selection = nil
        notice = "\(family.title) 没有可自动选择的思考深度。请手动选择一个受支持的选项。"
        return true
    }

    @discardableResult
    public mutating func selectEffort(_ effort: CodexReasoningEffort) -> Bool {
        guard let family = selectedFamily else { return false }
        let option = options[family]!
        guard option.isAvailable,
              option.supportedEfforts.contains(effort),
              let identifier = option.runtimeModelIdentifier else { return false }
        selection = CodexModelSelection(family: family, modelIdentifier: identifier, effort: effort)
        notice = nil
        return true
    }

    private static func makeOptions(
        from runtimeModels: [CodexRuntimeModelCapability]
    ) -> [CodexModelFamily: CodexModelOption] {
        Dictionary(uniqueKeysWithValues: CodexModelFamily.allCases.map { family in
            let familyCandidates = runtimeModels.filter { mentionsFamily($0, family: family) }
            let matches = familyCandidates.filter { matchesGPT6Family($0, family: family) }
            let excluded = familyCandidates.filter { !matchesGPT6Family($0, family: family) }
            guard matches.count == 1, let model = matches.first else {
                let reason: String
                if matches.isEmpty, excluded.isEmpty {
                    reason = "当前 Codex runtime 未返回 GPT-6 \(family.title)。"
                } else if matches.isEmpty {
                    reason = "未找到可接受的 GPT-6 \(family.title) 标识；已排除相似目录项。"
                } else {
                    reason = "当前 Codex runtime 返回多个 GPT-6 \(family.title) 标识，无法安全选择。"
                }
                return (family, CodexModelOption(
                    family: family,
                    runtimeModelIdentifiers: matches.map(\.modelIdentifier).sorted(),
                    excludedRuntimeModelIdentifiers: Array(Set(excluded.map(\.modelIdentifier))).sorted(),
                    runtimeDisplayName: nil,
                    supportedEfforts: [],
                    defaultEffort: nil,
                    supportsImages: false,
                    unavailableReason: reason
                ))
            }

            let allowedEfforts = model.supportedEfforts.filter { effort in
                effort != .ultra && (effort != .max || family == .luna)
            }
            let reason = allowedEfforts.isEmpty ? "没有符合产品规则的运行时思考深度" : nil
            return (family, CodexModelOption(
                family: family,
                runtimeModelIdentifiers: [model.modelIdentifier],
                excludedRuntimeModelIdentifiers: Array(Set(excluded.map(\.modelIdentifier))).sorted(),
                runtimeDisplayName: model.displayName,
                supportedEfforts: allowedEfforts,
                defaultEffort: model.defaultEffort,
                supportsImages: model.inputModalities.contains(.image),
                unavailableReason: reason
            ))
        })
    }

    private static func mentionsFamily(_ model: CodexRuntimeModelCapability, family: CodexModelFamily) -> Bool {
        [model.modelIdentifier, model.displayName].contains { value in
            identifierTokens(value).contains(family.rawValue)
        }
    }

    private static func matchesGPT6Family(_ model: CodexRuntimeModelCapability, family: CodexModelFamily) -> Bool {
        model.modelIdentifier == "gpt-6-\(family.rawValue)"
    }

    private static func identifierTokens(_ value: String) -> [String] {
        value.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }
}
