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
    case runtimeCannotRun(String)
    case runtimeProtocolUnavailable(String)
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
        case let .runtimeCannotRun(message):
            "Codex runtime 不可运行：\(message)"
        case let .runtimeProtocolUnavailable(message):
            "Codex runtime 协议不可用：\(message)"
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
        case .checking, .runtimeMissing, .runtimeCannotRun, .runtimeProtocolUnavailable, .failed: nil
        }
    }
}

@MainActor
final class BridgeTeacherApplicationModel: ObservableObject {
    let workflow: DeclarerPlanWorkflow
    let keyPlayWorkflow: KeyPlayAnalysisWorkflow
    let screenshotWorkflow: ScreenshotReviewWorkflow
    let doubleDummyWorkflow: DoubleDummyVerificationWorkflow

    @Published private(set) var originalHandFacts = OriginalHandFacts()
    @Published private(set) var hasLegacyDoubleDummyConflict = false
    private var doubleDummyOriginalHandVersion: Int? = 0

    @Published private(set) var connectionStatus: CodexConnectionStatus = .checking
    @Published private(set) var isConnecting = false
    @Published private(set) var isStartingLogin = false
    @Published private(set) var runtimePathHints: [CodexRuntimePathHint] = []
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
    private var draftObservation: AnyCancellable?
    private var isRestoringReview = false

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

    init(
        screenshotRecognitionRuntime: (any ScreenshotRecognitionRuntime)? = nil,
        doubleDummySolver: (any DoubleDummySolving)? = nil,
        reviewStore: LocalReviewSessionStore = LocalReviewSessionStore()
    ) {
        let runtimeService = CodexTeachingService()
        service = runtimeService
        modelSelectionPreferences = CodexModelSelectionPreferences()
        var initialDraft = DeclarerPlanDraft()
        initialDraft.decisionTimeVisibleSeats = [.north, .south]
        let planWorkflow = DeclarerPlanWorkflow(draft: initialDraft, runtime: runtimeService)
        workflow = planWorkflow
        keyPlayWorkflow = KeyPlayAnalysisWorkflow(runtime: runtimeService)
        screenshotWorkflow = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: screenshotRecognitionRuntime ?? runtimeService
        )
        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("bridge-dds", isDirectory: false)
        doubleDummyWorkflow = DoubleDummyVerificationWorkflow(solver: doubleDummySolver ?? BundledDDSSolver(executableURL: helperURL))
        self.reviewStore = reviewStore
        draftObservation = planWorkflow.$draft.dropFirst().sink { [weak self] draft in
            guard let self, !self.isRestoringReview else { return }
            self.synchronizeOriginalHands(from: draft)
        }
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        await searchRuntime()
    }

    func searchRuntime() async {
        guard !isConnecting, !isStartingLogin else { return }
        let candidates = CodexRuntimeDiscovery.candidateURLs(
            savedPath: UserDefaults.standard.string(forKey: CodexRuntimeDiscovery.preferenceKey)
        )
        await discoverRuntime(candidates: candidates, saveManualSelection: false)
    }

    func copyRuntimePath(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
    }

    func revealRuntimePath(_ url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return
        }
        var directory = url.deletingLastPathComponent()
        while directory.path != "/", !FileManager.default.fileExists(atPath: directory.path) {
            directory.deleteLastPathComponent()
        }
        NSWorkspace.shared.open(directory)
    }

    func chooseRuntime() {
        let panel = NSOpenPanel()
        panel.title = "选择 Codex CLI 可执行文件"
        panel.message = "选择官方 Codex 的 codex 可执行文件。建议位置见连接状态中的候选路径；这些位置不保证已安装。"
        panel.directoryURL = runtimePathHints.first(where: { $0.failure == nil })?.url.deletingLastPathComponent()
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
        let draft = draft.normalizingOpeningLead()
        let previousDraft = workflow.draft
        guard draft != previousDraft else { return }
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
        guard !hasLegacyDoubleDummyConflict else { return }
        guard originalHandFacts.decisionTimeConfirmed else {
            reviewSessionAlert = ReviewSessionAlert(title: "请先核对截图", message: "截图候选尚未确认，不能用于 DDS。")
            return
        }
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
        saveExplicitModelSelection(updated.selection)
    }

    func selectEffort(_ effort: CodexReasoningEffort) {
        var updated = modelSettings
        guard updated.selectEffort(effort) else { return }
        modelSettings = updated
        saveExplicitModelSelection(updated.selection)
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
            if savedSelection?.modelIdentifier == "gpt-6-sol", let migrated = modelSettings.selection {
                modelSelectionPreferences.save(migrated)
            }
            try await service.setRequestSelection(modelSettings.selection)
            modelCatalogStatus = "模型标识、effort 与输入能力来自当前 Codex runtime。"
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
            doubleDummy: doubleDummyWorkflow.makeArchive(),
            originalHandFacts: originalHandFacts,
            doubleDummyOriginalHandVersion: doubleDummyOriginalHandVersion
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
        isRestoringReview = true
        defer { isRestoringReview = false }
        workflow.restore(from: snapshot.declarerPlan)
        screenshotWorkflow.restore(from: snapshot.screenshot, screenshotURL: opened.screenshotURL)
        keyPlayWorkflow.restore(
            from: snapshot.keyPlay,
            currentInformationVersion: snapshot.declarerPlan.informationVersion
        )
        doubleDummyWorkflow.restore(from: snapshot.doubleDummy)
        originalHandFacts = snapshot.originalHandFacts ?? OriginalHandFacts(
            version: snapshot.declarerPlan.informationVersion,
            hands: workflow.draft.hands,
            decisionTimeConfirmed: workflow.draft.decisionTimeConfirmed
        )
        doubleDummyOriginalHandVersion = snapshot.doubleDummyOriginalHandVersion
        hasLegacyDoubleDummyConflict = snapshot.doubleDummyOriginalHandVersion == nil
            && !snapshot.doubleDummy.draft.hands.isEmpty
            && snapshot.doubleDummy.draft.hands != originalHandFacts.hands
        if snapshot.doubleDummy.draft.hands.isEmpty { useOriginalHandsForDoubleDummy() }
        teachingMode = snapshot.teachingMode
        currentReviewID = snapshot.id
        reviewSessionStatus = "已打开本地复盘 · \(snapshot.title)"
        reviewSessionAlert = hasLegacyDoubleDummyConflict
            ? ReviewSessionAlert(title: "旧 DDS 牌面需要核对", message: "主牌面与旧独立 DDS 输入不同；两份材料均已保留。请在双明手面板选择保留独立局面或使用主牌面。")
            : nil
        return true
    }

    /// Explicitly starts DDS from the original board; editing DDS remaining hands
    /// never writes back to the entered board or changes its version.
    func useOriginalHandsForDoubleDummy() {
        resetDoubleDummyToOriginal(context: workflow.draft)
    }

    private func resetDoubleDummyToOriginal(context: DeclarerPlanDraft) {
        var draft = doubleDummyWorkflow.draft
        draft.hands = originalHandFacts.hands
        draft.currentTrickCards = ""
        draft.declarerTricksAlreadyTaken = 0
        draft.declarerSeat = context.declarerSeat
        draft.contractLevel = context.contractLevel
        draft.trump = context.contractStrain
        if let declarer = context.declarerSeat,
           let index = Seat.allCases.firstIndex(of: declarer) {
            draft.trickLeader = Seat.allCases[(index + 1) % Seat.allCases.count]
        }
        doubleDummyWorkflow.updateDraft(draft)
        doubleDummyOriginalHandVersion = originalHandFacts.version
        hasLegacyDoubleDummyConflict = false
        reviewSessionStatus = "有尚未保存的更改"
    }

    func keepLegacyDoubleDummyPosition() {
        hasLegacyDoubleDummyConflict = false
        // A nil source keeps the independent origin explicit in future archives.
        doubleDummyOriginalHandVersion = nil
    }

    private func synchronizeOriginalHands(from draft: DeclarerPlanDraft) {
        let updated = originalHandFacts.updating(from: draft)
        guard updated != originalHandFacts else { return }
        originalHandFacts = updated
        doubleDummyWorkflow.invalidate()
        resetDoubleDummyToOriginal(context: draft)
    }

    private func reviewTitle(for draft: DeclarerPlanDraft) -> String {
        let seat = draft.declarerSeat?.chineseName ?? "桥牌复盘"
        guard let level = draft.contractLevel, let strain = draft.contractStrain else { return seat }
        return "\(seat) \(level)\(strain.symbol)"
    }

    private func useRuntime(_ url: URL, saveSelection: Bool) async {
        await discoverRuntime(candidates: [url], saveManualSelection: saveSelection)
    }

    private func discoverRuntime(candidates: [URL], saveManualSelection: Bool) async {
        guard !isConnecting else { return }
        isConnecting = true
        connectionStatus = .checking
        defer { isConnecting = false }
        let discovery = CodexRuntimeDiscovery(candidates: candidates) { [service] url in
            let info = try await service.configure(executableURL: url)
            let signedIn = try await service.isChatGPTSignedIn()
            return CodexRuntimeConnection(info: info, isSignedIn: signedIn)
        }
        let result = await discovery.search()
        runtimePathHints = result.hints
        guard let connection = result.connection else {
            switch result.failure {
            case let .protocolUnavailable(message): connectionStatus = .runtimeProtocolUnavailable(message)
            case let .cannotRun(message): connectionStatus = .runtimeCannotRun(message)
            case .notExecutable: connectionStatus = .runtimeCannotRun("找到的文件不可执行。请重新搜索或手动选择。")
            case .missing, nil: connectionStatus = .runtimeMissing
            }
            await clearRuntimeModelSettings(message: "重新搜索或选择 Codex runtime 后连接 ChatGPT。")
            return
        }
        runtimePath = connection.info.executableURL.path
        connectionStatus = connection.isSignedIn
            ? .signedIn(version: connection.info.version)
            : .needsLogin(version: connection.info.version)
        if saveManualSelection {
            UserDefaults.standard.set(connection.info.executableURL.path, forKey: CodexRuntimeDiscovery.preferenceKey)
        }
        if connection.isSignedIn {
            await refreshModelSettings()
        } else {
            await clearRuntimeModelSettings(message: "连接 ChatGPT 后读取当前账号可用的模型能力。")
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

    private func clearRuntimeModelSettings(message: String) async {
        modelSettings = CodexModelSettingsState(runtimeModels: [])
        modelCatalogStatus = message
        try? await service.setRequestSelection(nil)
    }

    private func loadSavedModelSelection() -> CodexModelSelection? {
        modelSelectionPreferences.load()
    }

    private func saveExplicitModelSelection(_ selection: CodexModelSelection?) {
        guard let selection else { return }
        modelSelectionPreferences.save(selection)
    }
}

struct ReviewSessionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
