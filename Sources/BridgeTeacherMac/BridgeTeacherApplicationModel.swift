import AppKit
import BridgeTeacherCore
import Combine
import Foundation

struct ContractChoice: Equatable {
    let level: Int
    let strain: ContractStrain
}

enum ContractSelectionAction {
    case select(ContractChoice)
    case clear
    case cancel
}

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
    let screenshotWorkflow: ScreenshotReviewWorkflow
    let doubleDummyWorkflow: DoubleDummyVerificationWorkflow

    @Published private(set) var connectionStatus: CodexConnectionStatus = .checking
    @Published private(set) var isConnecting = false
    @Published private(set) var isStartingLogin = false
    @Published private(set) var runtimePath: String?
    @Published private(set) var modelSettings = CodexModelSettingsState(runtimeModels: [])
    @Published private(set) var modelCatalogStatus = "连接 ChatGPT 后读取当前账号可用的模型能力。"
    @Published private(set) var teachingMode: TeachingMode = .declarerPlan
    @Published private(set) var savedReviewSessions: [ReviewSessionListItem] = []
    @Published private(set) var reviewSessionStatus = ""
    @Published var reviewSessionAlert: ReviewSessionAlert?

    private let service: CodexTeachingService
    private let modelSelectionPreferences: CodexModelSelectionPreferences
    private let reviewStore: LocalReviewSessionStore
    private var currentReviewID: UUID?
    private var hasBootstrapped = false

    var canSendModelRequests: Bool {
        connectionStatus.isSignedIn && modelSettings.selection != nil
    }

    var modelSelectionSummary: String {
        guard let selection = modelSettings.selection else { return "模型设置" }
        return "\(selection.family.title) · \(selection.effort.title)"
    }

    var screenshotCapabilityMessage: String? {
        guard connectionStatus.isSignedIn else { return "连接 ChatGPT 后才能读取截图识别能力。" }
        guard let selection = modelSettings.selection else { return "请先在模型设置中选择经 runtime 验证的模型与思考深度。" }
        guard modelSettings.canRecognizeImages else {
            return "\(selection.modelIdentifier) 未报告图像输入能力。请选择支持图像的模型后再识别截图。"
        }
        return nil
    }

    init() {
        let runtimeService = CodexTeachingService()
        service = runtimeService
        modelSelectionPreferences = CodexModelSelectionPreferences()
        let planWorkflow = DeclarerPlanWorkflow(runtime: runtimeService)
        workflow = planWorkflow
        keyPlayWorkflow = KeyPlayAnalysisWorkflow(runtime: runtimeService)
        screenshotWorkflow = ScreenshotReviewWorkflow(planWorkflow: planWorkflow, runtime: runtimeService)
        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("bridge-dds", isDirectory: false)
        doubleDummyWorkflow = DoubleDummyVerificationWorkflow(solver: BundledDDSSolver(executableURL: helperURL))
        reviewStore = LocalReviewSessionStore()
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        guard let candidate = CodexExecutableDiscovery.find() else {
            connectionStatus = .runtimeMissing
            modelCatalogStatus = "选择 Codex runtime 并连接 ChatGPT 后，才能读取模型能力。"
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

    func chooseScreenshot() {
        let panel = NSOpenPanel()
        panel.title = "导入桥牌截图"
        panel.message = "选择牌局界面截图。原图仅用于本次识别，不会作为做庄计划的输入。"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                guard let self else { return }
                self.screenshotWorkflow.selectScreenshot(at: url)
                self.keyPlayWorkflow.invalidate()
                self.currentReviewID = nil
                self.reviewSessionStatus = "有尚未保存的更改"
            }
        }
    }

    func recognizeScreenshot() async {
        guard await prepareModelRequest(), modelSettings.canRecognizeImages else { return }
        await screenshotWorkflow.recognizeScreenshot()
        keyPlayWorkflow.invalidate()
        reviewSessionStatus = "有尚未保存的更改"
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
            if signedIn {
                await refreshModelSettings()
            } else {
                await clearRuntimeModelSettings(message: "连接 ChatGPT 后读取当前账号可用的模型能力。")
            }
        } catch {
            connectionStatus = .failed(error.localizedDescription)
        }
    }

    func generatePlan() async {
        guard await prepareModelRequest() else { return }
        await workflow.generatePlan()
        reviewSessionStatus = "有尚未保存的更改"
    }

    func updateReviewDraft(_ draft: DeclarerPlanDraft) {
        let previousDraft = workflow.draft
        guard draft != previousDraft else { return }
        workflow.updateDraft(draft)
        screenshotWorkflow.updateDraft(draft)
        keyPlayWorkflow.invalidate()
        if previousDraft.declarerSeat != draft.declarerSeat
            || previousDraft.contractLevel != draft.contractLevel
            || previousDraft.contractStrain != draft.contractStrain {
            var doubleDummyDraft = doubleDummyWorkflow.draft
            doubleDummyDraft.declarerSeat = draft.declarerSeat
            doubleDummyDraft.contractLevel = draft.contractLevel
            doubleDummyDraft.trump = draft.contractStrain
            doubleDummyWorkflow.updateDraft(doubleDummyDraft)
        }
        reviewSessionStatus = "有尚未保存的更改"
    }

    func handleContractSelectionAction(_ action: ContractSelectionAction) {
        switch action {
        case let .select(contract):
            var draft = workflow.draft
            draft.contractLevel = contract.level
            draft.contractStrain = contract.strain
            updateReviewDraft(draft)
        case .clear:
            var draft = workflow.draft
            draft.contractLevel = nil
            draft.contractStrain = nil
            updateReviewDraft(draft)
        case .cancel:
            break
        }
    }

    func updateKeyPlayDraft(_ draft: KeyPlayAnalysisDraft) {
        keyPlayWorkflow.updateDraft(draft)
        reviewSessionStatus = "有尚未保存的更改"
    }

    func updateDoubleDummyDraft(_ draft: DoubleDummyVerificationDraft) {
        doubleDummyWorkflow.updateDraft(draft)
        reviewSessionStatus = "有尚未保存的更改"
    }

    func setFollowUpQuestion(_ question: String) {
        workflow.setFollowUpQuestion(question)
        reviewSessionStatus = "有尚未保存的更改"
    }

    func setFollowUpAssumptions(_ assumptions: String) {
        workflow.setFollowUpAssumptions(assumptions)
        reviewSessionStatus = "有尚未保存的更改"
    }

    func sendFollowUp() async {
        guard await prepareModelRequest() else { return }
        await workflow.sendFollowUp()
        reviewSessionStatus = "有尚未保存的更改"
    }

    func retryFollowUp(_ exchangeID: UUID) async {
        guard await prepareModelRequest() else { return }
        await workflow.retryFollowUp(exchangeID)
        reviewSessionStatus = "有尚未保存的更改"
    }

    func verifyDoubleDummy() async {
        await doubleDummyWorkflow.verify()
        reviewSessionStatus = "有尚未保存的更改"
    }

    func setTeachingMode(_ mode: TeachingMode) {
        guard teachingMode != mode else { return }
        teachingMode = mode
        reviewSessionStatus = "有尚未保存的更改"
    }

    func generate(mode: TeachingMode) async {
        guard await prepareModelRequest() else { return }
        switch mode {
        case .declarerPlan:
            await workflow.generatePlan()
        case .keyPlayAnalysis:
            await keyPlayWorkflow.generate(from: workflow.draft, informationVersion: workflow.informationVersion)
        }
        reviewSessionStatus = "有尚未保存的更改"
    }

    func selectModel(_ family: CodexModelFamily) {
        var updated = modelSettings
        guard updated.selectModel(family) else { return }
        modelSettings = updated
        saveValidModelSelection(updated.selection)
        Task { await applyServiceSelection(updated.selection) }
    }

    func selectEffort(_ effort: CodexReasoningEffort) {
        var updated = modelSettings
        guard updated.selectEffort(effort) else { return }
        modelSettings = updated
        saveValidModelSelection(updated.selection)
        Task { await applyServiceSelection(updated.selection) }
    }

    func refreshModelSettings() async {
        guard connectionStatus.isSignedIn else {
            await clearRuntimeModelSettings(message: "连接 ChatGPT 后读取当前账号可用的模型能力。")
            return
        }
        modelCatalogStatus = "正在读取 Codex runtime 返回的模型能力…"
        do {
            let runtimeModels = try await service.listRuntimeModels()
            let savedSelection = loadSavedModelSelection()
            modelSettings = CodexModelSettingsState(runtimeModels: runtimeModels, savedSelection: savedSelection)
            try await service.setRequestSelection(modelSettings.selection)
            modelCatalogStatus = "模型标识、effort 与输入能力来自当前 Codex runtime。"
            if savedSelection == nil, let selection = modelSettings.selection {
                saveValidModelSelection(selection)
            }
        } catch {
            modelSettings = CodexModelSettingsState(runtimeModels: [])
            try? await service.setRequestSelection(nil)
            modelCatalogStatus = "无法读取当前账号的模型能力：\(error.localizedDescription)"
        }
    }

    func saveReview() {
        let snapshot = ReviewSessionSnapshot(
            id: currentReviewID ?? UUID(),
            title: reviewTitle(for: workflow.draft),
            teachingMode: teachingMode,
            declarerPlan: workflow.makeArchive(),
            screenshot: screenshotWorkflow.makeArchive(),
            keyPlay: keyPlayWorkflow.makeArchive(),
            doubleDummy: doubleDummyWorkflow.makeArchive()
        )
        do {
            let saved = try reviewStore.save(snapshot, screenshotURL: screenshotWorkflow.screenshotURL)
            currentReviewID = saved.id
            reviewSessionStatus = "已保存在本机 · \(saved.title)"
            reviewSessionAlert = nil
        } catch {
            reviewSessionAlert = ReviewSessionAlert(title: "复盘未能保存", message: error.localizedDescription)
        }
    }

    func refreshSavedReviewSessions() -> Bool {
        do {
            savedReviewSessions = try reviewStore.list()
            return true
        } catch {
            reviewSessionAlert = ReviewSessionAlert(title: "本地复盘列表读取失败", message: error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func openReview(id: UUID) -> Bool {
        let opened: OpenedReviewSession
        do {
            opened = try reviewStore.open(id: id)
        } catch {
            reviewSessionAlert = ReviewSessionAlert(title: "复盘未能打开", message: error.localizedDescription)
            return false
        }

        let snapshot = opened.snapshot
        workflow.restore(from: snapshot.declarerPlan)
        screenshotWorkflow.restore(from: snapshot.screenshot, screenshotURL: opened.screenshotURL)
        keyPlayWorkflow.restore(
            from: snapshot.keyPlay,
            currentInformationVersion: snapshot.declarerPlan.informationVersion
        )
        doubleDummyWorkflow.restore(from: snapshot.doubleDummy)
        teachingMode = snapshot.teachingMode
        currentReviewID = snapshot.id
        reviewSessionStatus = "已打开本地复盘 · \(snapshot.title)"
        reviewSessionAlert = nil
        return true
    }

    private func reviewTitle(for draft: DeclarerPlanDraft) -> String {
        let seat = draft.declarerSeat?.chineseName ?? "桥牌复盘"
        guard let level = draft.contractLevel, let strain = draft.contractStrain else { return seat }
        return "\(seat) \(level)\(strain.symbol)"
    }

    private func useRuntime(_ url: URL, saveSelection: Bool) async {
        connectionStatus = .checking
        runtimePath = url.path
        do {
            let info = try await service.configure(executableURL: url)
            let signedIn = try await service.isChatGPTSignedIn()
            connectionStatus = signedIn ? .signedIn(version: info.version) : .needsLogin(version: info.version)
            if signedIn {
                await refreshModelSettings()
            } else {
                await clearRuntimeModelSettings(message: "连接 ChatGPT 后读取当前账号可用的模型能力。")
            }
            if saveSelection {
                UserDefaults.standard.set(url.path, forKey: "bridgeTeacher.codexExecutablePath")
            }
        } catch {
            connectionStatus = .failed(error.localizedDescription)
            await clearRuntimeModelSettings(message: "模型能力不可用：\(error.localizedDescription)")
        }
    }

    private func prepareModelRequest() async -> Bool {
        guard connectionStatus.isSignedIn, let selection = modelSettings.selection else { return false }
        do {
            try await service.setRequestSelection(selection)
            return true
        } catch {
            modelCatalogStatus = "模型设置已不可用：\(error.localizedDescription) 请刷新模型能力。"
            modelSettings = CodexModelSettingsState(runtimeModels: [])
            return false
        }
    }

    private func applyServiceSelection(_ selection: CodexModelSelection?) async {
        do {
            try await service.setRequestSelection(selection)
        } catch {
            modelCatalogStatus = "无法应用模型设置：\(error.localizedDescription)"
        }
    }

    private func clearRuntimeModelSettings(message: String) async {
        modelSettings = CodexModelSettingsState(runtimeModels: [])
        modelCatalogStatus = message
        try? await service.setRequestSelection(nil)
    }

    private func loadSavedModelSelection() -> CodexModelSelection? {
        modelSelectionPreferences.load()
    }

    private func saveValidModelSelection(_ selection: CodexModelSelection?) {
        guard let selection else { return }
        modelSelectionPreferences.save(selection)
    }
}

struct ReviewSessionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
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
