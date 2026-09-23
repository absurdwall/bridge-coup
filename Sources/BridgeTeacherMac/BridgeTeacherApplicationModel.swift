import AppKit
import BridgeTeacherCore
import Combine
import Foundation

enum CodexConnectionStatus: Equatable {
    case checking
    case runtimeMissing
    case needsLogin(version: String)
    case awaitingLogin(version: String)
    case signedIn(version: String)
    case failed(String)

    var message: String {
        switch self {
        case .checking:
            "正在检查 Codex runtime…"
        case .runtimeMissing:
            "没有找到 Codex runtime"
        case let .needsLogin(version):
            "Codex \(version) · 需要 ChatGPT 登录"
        case let .awaitingLogin(version):
            "Codex \(version) · 请在浏览器完成登录，再检查连接"
        case let .signedIn(version):
            "ChatGPT 已连接 · Codex \(version)"
        case let .failed(message):
            message
        }
    }

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }

    var runtimeVersion: String? {
        switch self {
        case let .needsLogin(version), let .awaitingLogin(version), let .signedIn(version): version
        case .checking, .runtimeMissing, .failed: nil
        }
    }
}

@MainActor
final class BridgeTeacherApplicationModel: ObservableObject {
    let workflow: DeclarerPlanWorkflow
    let keyPlayWorkflow: KeyPlayAnalysisWorkflow

    @Published private(set) var connectionStatus: CodexConnectionStatus = .checking
    @Published private(set) var isConnecting = false
    @Published private(set) var isStartingLogin = false
    @Published private(set) var runtimePath: String?

    private let service: CodexTeachingService
    private var hasBootstrapped = false

    init() {
        let runtimeService = CodexTeachingService()
        service = runtimeService
        workflow = DeclarerPlanWorkflow(runtime: runtimeService)
        keyPlayWorkflow = KeyPlayAnalysisWorkflow(runtime: runtimeService)
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        guard let candidate = CodexExecutableDiscovery.find() else {
            connectionStatus = .runtimeMissing
            return
        }
        await useRuntime(candidate, saveSelection: false)
    }

    func chooseRuntime() {
        let panel = NSOpenPanel()
        panel.title = "选择 Codex CLI 可执行文件"
        panel.message = "选择官方 Codex CLI 或 app-server 可执行文件。"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                await self?.useRuntime(url, saveSelection: true)
            }
        }
    }

    func connectToChatGPT() async {
        guard !isStartingLogin else { return }
        isStartingLogin = true
        defer { isStartingLogin = false }
        do {
            let url = try await service.beginChatGPTLogin()
            guard NSWorkspace.shared.open(url) else {
                connectionStatus = .failed("无法打开系统浏览器。请重试连接 ChatGPT。")
                return
            }
            connectionStatus = .awaitingLogin(version: connectionStatus.runtimeVersion ?? CodexTeachingService.minimumVersion)
        } catch {
            connectionStatus = .failed(error.localizedDescription)
        }
    }

    func checkLogin() async {
        guard !isConnecting else { return }
        isConnecting = true
        defer { isConnecting = false }
        do {
            let signedIn = try await service.isChatGPTSignedIn()
            let version = connectionStatus.runtimeVersion ?? CodexTeachingService.minimumVersion
            connectionStatus = signedIn ? .signedIn(version: version) : .needsLogin(version: version)
        } catch {
            connectionStatus = .failed(error.localizedDescription)
        }
    }

    func generatePlan() async {
        await workflow.generatePlan()
    }

    func updateReviewDraft(_ draft: DeclarerPlanDraft) {
        guard draft != workflow.draft else { return }
        workflow.updateDraft(draft)
        keyPlayWorkflow.invalidate()
    }

    func updateKeyPlayDraft(_ draft: KeyPlayAnalysisDraft) {
        keyPlayWorkflow.updateDraft(draft)
    }

    func generate(mode: TeachingMode) async {
        switch mode {
        case .declarerPlan:
            await workflow.generatePlan()
        case .keyPlayAnalysis:
            await keyPlayWorkflow.generate(from: workflow.draft)
        }
    }

    private func useRuntime(_ url: URL, saveSelection: Bool) async {
        connectionStatus = .checking
        runtimePath = url.path
        do {
            let info = try await service.configure(executableURL: url)
            let signedIn = try await service.isChatGPTSignedIn()
            connectionStatus = signedIn ? .signedIn(version: info.version) : .needsLogin(version: info.version)
            if saveSelection {
                UserDefaults.standard.set(url.path, forKey: "bridgeTeacher.codexExecutablePath")
            }
        } catch {
            connectionStatus = .failed(error.localizedDescription)
        }
    }
}

private enum CodexExecutableDiscovery {
    static func find() -> URL? {
        let fileManager = FileManager.default
        var candidates: [URL] = []

        if let bundled = Bundle.main.url(forResource: "codex", withExtension: nil) {
            candidates.append(bundled)
        }
        if let storedPath = UserDefaults.standard.string(forKey: "bridgeTeacher.codexExecutablePath") {
            candidates.append(URL(fileURLWithPath: storedPath))
        }

        let environment = ProcessInfo.processInfo.environment
        let pathDirectories = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
        candidates.append(contentsOf: pathDirectories.map { URL(fileURLWithPath: $0).appendingPathComponent("codex") })
        candidates.append(contentsOf: ["/opt/homebrew/bin/codex", "/usr/local/bin/codex"].map(URL.init(fileURLWithPath:)))

        let nvmRoot = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".nvm/versions/node", isDirectory: true)
        if let versions = try? fileManager.contentsOfDirectory(at: nvmRoot, includingPropertiesForKeys: nil) {
            candidates.append(contentsOf: versions.map { $0.appendingPathComponent("bin/codex") })
        }

        return candidates.first(where: { fileManager.isExecutableFile(atPath: $0.path) })
    }
}
