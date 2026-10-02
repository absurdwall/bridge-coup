import Foundation

struct CodexRuntimeConnection: Equatable {
    let info: CodexRuntimeInfo
    let isSignedIn: Bool
}

enum CodexRuntimeCandidateFailure: Equatable {
    case missing
    case notExecutable
    case cannotRun(String)
    case protocolUnavailable(String)

    var message: String {
        switch self {
        case .missing: "未找到文件"
        case .notExecutable: "文件不可执行；请选 codex 可执行文件"
        case let .cannotRun(message): "无法运行：\(message)"
        case let .protocolUnavailable(message): "协议不可用：\(message)"
        }
    }
}

struct CodexRuntimePathHint: Equatable, Identifiable {
    let url: URL
    let failure: CodexRuntimeCandidateFailure?
    var id: String { url.path }
}

struct CodexRuntimeSearchResult {
    let connection: CodexRuntimeConnection?
    let hints: [CodexRuntimePathHint]

    var failure: CodexRuntimeCandidateFailure? {
        hints.compactMap(\.failure).first(where: {
            if case .protocolUnavailable = $0 { return true }
            return false
        }) ?? hints.compactMap(\.failure).first(where: { $0 != .missing })
    }
}

/// One boundary owns candidate discovery, filesystem checks and runtime probing.
/// A failed saved/manual candidate never prevents later candidates from being tried.
struct CodexRuntimeDiscovery {
    static let preferenceKey = "bridgeTeacher.codexExecutablePath"
    let candidates: [URL]
    private let fileState: (URL) -> CodexRuntimeCandidateFailure?
    private let probe: (URL) async throws -> CodexRuntimeConnection

    init(
        candidates: [URL],
        fileState: @escaping (URL) -> CodexRuntimeCandidateFailure? = Self.checkFile,
        probe: @escaping (URL) async throws -> CodexRuntimeConnection
    ) {
        var seen = Set<String>()
        self.candidates = candidates.filter { seen.insert($0.standardizedFileURL.path).inserted }
        self.fileState = fileState
        self.probe = probe
    }

    func search() async -> CodexRuntimeSearchResult {
        var hints: [CodexRuntimePathHint] = []
        for candidate in candidates {
            if let failure = fileState(candidate) {
                hints.append(CodexRuntimePathHint(url: candidate, failure: failure))
                continue
            }
            do {
                let connection = try await probe(candidate)
                hints.append(CodexRuntimePathHint(url: candidate, failure: nil))
                return CodexRuntimeSearchResult(connection: connection, hints: hints)
            } catch {
                hints.append(CodexRuntimePathHint(url: candidate, failure: Self.failure(for: error)))
            }
        }
        return CodexRuntimeSearchResult(connection: nil, hints: hints)
    }

    static func checkFile(_ url: URL) -> CodexRuntimeCandidateFailure? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return .missing }
        guard !isDirectory.boolValue, FileManager.default.isExecutableFile(atPath: url.path) else { return .notExecutable }
        return nil
    }

    static func failure(for error: Error) -> CodexRuntimeCandidateFailure {
        if let setup = error as? CodexRuntimeSetupError {
            switch setup {
            case .runtimeNotFound: return .missing
            case let .runtimeNotExecutable(message): return .cannotRun(message)
            case let .protocolUnavailable(message): return .protocolUnavailable(message)
            case .invalidVersion, .unsupportedVersion, .transport: return .cannotRun(setup.localizedDescription)
            default: return .protocolUnavailable(setup.localizedDescription)
            }
        }
        return .protocolUnavailable(error.localizedDescription)
    }

    static func candidateURLs(
        savedPath: String?,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        bundle: URL = Bundle.main.bundleURL,
        directoryContents: (URL) -> [URL] = { (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? [] }
    ) -> [URL] {
        var urls: [URL] = []
        // Keep an explicit working choice ahead of automatically discovered installations.
        if let savedPath { urls.append(URL(fileURLWithPath: savedPath)) }
        urls.append(bundle.appendingPathComponent("Contents/Resources/codex"))
        urls.append(bundle.appendingPathComponent("Contents/Resources/codex-cli/bin/codex"))
        urls += (environment["PATH"] ?? "").split(separator: ":").map {
            URL(fileURLWithPath: String($0)).appendingPathComponent("codex")
        }
        urls += ["/opt/homebrew/bin/codex", "/usr/local/bin/codex"].map(URL.init(fileURLWithPath:))
        for applications in [URL(fileURLWithPath: "/Applications"), home.appendingPathComponent("Applications")] {
            for app in ["Codex.app", "ChatGPT.app"] {
                for relative in ["Contents/Resources/codex", "Contents/Resources/codex-cli/bin/codex", "Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"] {
                    urls.append(applications.appendingPathComponent(app).appendingPathComponent(relative))
                }
            }
        }
        let nodeRoot = home.appendingPathComponent(".nvm/versions/node")
        urls += directoryContents(nodeRoot).sorted(by: { $0.path > $1.path }).map { $0.appendingPathComponent("bin/codex") }
        return urls
    }
}
