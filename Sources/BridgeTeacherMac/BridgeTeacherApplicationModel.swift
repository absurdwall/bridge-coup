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
            "没有找到 Codex runtime。请重新安装完整的 Bridge Coup.app，或手动选择官方 codex 可执行文件。"
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
    let playCardResultsWorkflow: PlayCardResultsWorkflow
    let originalContractTableWorkflow: OriginalContractTableWorkflow

    @Published private(set) var originalHandFacts = OriginalHandFacts()
    @Published private(set) var playSession: BridgePlaySession?
    @Published private(set) var playPositionRevision = 0
    @Published private(set) var playStatus = "点击开始自主推演后可点牌。"
    @Published var pendingPlayReset: PlayResetRequest?
    private var isConfirmingPlayReset = false
    @Published private var playUndoStack: [BridgePlaySession] = []
    @Published private var playRedoStack: [BridgePlaySession] = []

    var canUndoPlay: Bool { playSession != nil && !playUndoStack.isEmpty }
    var canRedoPlay: Bool { playSession != nil && !playRedoStack.isEmpty }

    var currentTeachingDraft: DeclarerPlanDraft {
        playSession?.teachingDraft(from: workflow.draft) ?? workflow.draft
    }
    /// UI warning and submission validate the same current selected-hand projection.
    var keyPlayInputWarning: String? {
        do {
            _ = try KeyPlayAnalysisRequestBuilder.build(from: currentTeachingDraft, node: keyPlayWorkflow.draft)
            return nil
        } catch { return error.localizedDescription }
    }

    var playStartReason: String? {
        do { _ = try BridgePlaySession(original: originalHandFacts, draft: workflow.draft); return nil }
        catch { return error.localizedDescription }
    }
    @Published private(set) var hasLegacyDoubleDummyConflict = false
    @Published private(set) var doubleDummyHandSource: DoubleDummyHandSource = .sharedOriginal
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
    private var playResultsObservation: AnyCancellable?
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
        teachingRuntime: (any DeclarerTeachingRuntime)? = nil,
        doubleDummySolver: (any DoubleDummySolving)? = nil,
        reviewStore: LocalReviewSessionStore = LocalReviewSessionStore()
    ) {
        let runtimeService = CodexTeachingService()
        service = runtimeService
        modelSelectionPreferences = CodexModelSelectionPreferences()
        var initialDraft = DeclarerPlanDraft()
        initialDraft.decisionTimeVisibleSeats = [.north, .south]
        let planWorkflow = DeclarerPlanWorkflow(draft: initialDraft, runtime: teachingRuntime ?? runtimeService)
        workflow = planWorkflow
        keyPlayWorkflow = KeyPlayAnalysisWorkflow(runtime: teachingRuntime ?? runtimeService)
        screenshotWorkflow = ScreenshotReviewWorkflow(
            planWorkflow: planWorkflow,
            runtime: screenshotRecognitionRuntime ?? runtimeService
        )
        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("bridge-dds", isDirectory: false)
        let solver = doubleDummySolver ?? BundledDDSSolver(executableURL: helperURL)
        doubleDummyWorkflow = DoubleDummyVerificationWorkflow(solver: solver)
        originalContractTableWorkflow = OriginalContractTableWorkflow(solver: solver)
        playCardResultsWorkflow = PlayCardResultsWorkflow(solver: solver)
        self.reviewStore = reviewStore
        screenshotWorkflow.onRecognizedDraft = { [weak self] draft, commitRecognition in
            self?.applyReviewDraft(draft, isRecognition: true, recognitionCommit: commitRecognition) ?? false
        }
        playResultsObservation = $playPositionRevision.sink { [weak self] revision in
            guard let self else { return }
            self.playCardResultsWorkflow.updatePosition(self.playSession, revision: revision)
        }
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
                self.selectScreenshot(at: url)
            }
        }
    }

    func selectScreenshot(at url: URL) {
        if playSession != nil {
            screenshotWorkflow.invalidatePendingRecognition()
            pendingPlayReset = PlayResetRequest(draft: workflow.draft, screenshotURL: url)
            return
        }
        screenshotWorkflow.selectScreenshot(at: url)
        keyPlayWorkflow.invalidate()
        currentReviewID = nil
        reviewSessionStatus = "有尚未保存的更改"
    }

    func recognizeScreenshot() async {
        guard await prepareModelRequest(), modelSettings.canRecognizeImages else { return }
        await screenshotWorkflow.recognizeScreenshot()
        if pendingPlayReset == nil { reviewSessionStatus = "有尚未保存的更改" }
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
        applyReviewDraft(draft, isRecognition: false)
    }

    @discardableResult
    private func applyReviewDraft(_ draft: DeclarerPlanDraft, isRecognition: Bool,
                                  recognitionCommit: (() -> Void)? = nil) -> Bool {
        let draft = draft.normalizingOpeningLead()
        let previousDraft = workflow.draft
        guard draft != previousDraft else { return true }
        if isRecognition, pendingPlayReset?.isRecognition == false { return false }
        if !isRecognition, pendingPlayReset?.isRecognition == true { pendingPlayReset = nil }
        if playSession != nil, !isConfirmingPlayReset,
           draft.hands != previousDraft.hands || draft.declarerSeat != previousDraft.declarerSeat
            || draft.contractLevel != previousDraft.contractLevel || draft.contractStrain != previousDraft.contractStrain
            || draft.openingLead != previousDraft.openingLead || draft.decisionTimeConfirmed != previousDraft.decisionTimeConfirmed {
            if !isRecognition { screenshotWorkflow.invalidatePendingRecognition() }
            pendingPlayReset = PlayResetRequest(draft: draft, isRecognition: isRecognition, recognitionCommit: recognitionCommit)
            return false
        }
        if isRecognition { workflow.updateDraft(draft) }
        else { screenshotWorkflow.updateDraft(draft) }
        workflow.setTeachingProjection(playSession?.teachingDraft(from: draft))
        keyPlayWorkflow.invalidate()
        if doubleDummyHandSource == .sharedOriginal,
           previousDraft.declarerSeat != draft.declarerSeat
            || previousDraft.contractLevel != draft.contractLevel
            || previousDraft.contractStrain != draft.contractStrain {
            var doubleDummyDraft = doubleDummyWorkflow.draft
            doubleDummyDraft.declarerSeat = draft.declarerSeat
            doubleDummyDraft.contractLevel = draft.contractLevel
            doubleDummyDraft.trump = draft.contractStrain
            doubleDummyWorkflow.updateDraft(doubleDummyDraft)
        }
        reviewSessionStatus = "有尚未保存的更改"
        return true
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
        guard doubleDummyHandSource != .sharedOriginal || originalHandFacts.decisionTimeConfirmed else {
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
            await keyPlayWorkflow.generate(from: currentTeachingDraft, informationVersion: workflow.informationVersion)
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
            doubleDummyOriginalHandVersion: doubleDummyOriginalHandVersion,
            playSession: playSession,
            doubleDummyHandSource: doubleDummyHandSource
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
        clearPlayHistory()
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
        originalContractTableWorkflow.updateOriginalHands(originalHandFacts)
        doubleDummyOriginalHandVersion = snapshot.doubleDummyOriginalHandVersion
        let legacyConflict = snapshot.doubleDummyOriginalHandVersion == nil
            && !snapshot.doubleDummy.draft.hands.isEmpty
            && snapshot.doubleDummy.draft.hands != originalHandFacts.hands
        doubleDummyHandSource = snapshot.doubleDummyHandSource
            ?? (legacyConflict ? .independentNeedsReview : .sharedOriginal)
        hasLegacyDoubleDummyConflict = doubleDummyHandSource == .independentNeedsReview
        if snapshot.doubleDummy.draft.hands.isEmpty, doubleDummyHandSource == .sharedOriginal {
            resetDoubleDummyToOriginal(context: workflow.draft)
        }
        playSession = snapshot.playSession
        if let playSession, !playSession.isCompatible(with: originalHandFacts, context: workflow.draft) {
            self.playSession = nil
            workflow.markCurrentResultOutdated()
            keyPlayWorkflow.invalidate()
        }
        workflow.setTeachingProjection(self.playSession?.teachingDraft(from: workflow.draft))
        pendingPlayReset = nil
        playStatus = self.playSession == nil ? "点击开始自主推演后可点牌。" : "已恢复保存的自主推演。"
        teachingMode = snapshot.teachingMode
        currentReviewID = snapshot.id
        reviewSessionStatus = "已打开本地复盘 · \(snapshot.title)"
        playPositionRevision += 1
        reviewSessionAlert = hasLegacyDoubleDummyConflict
            ? ReviewSessionAlert(title: "旧 DDS 牌面需要核对", message: "主牌面与旧独立 DDS 输入不同；两份材料均已保留。请在双明手面板选择保留独立局面或使用主牌面。")
            : nil
        return true
    }

    @discardableResult
    func startPlay() -> Bool {
        guard playSession == nil, pendingPlayReset == nil else { return false }
        do {
            let session = try BridgePlaySession(original: originalHandFacts, draft: workflow.draft)
            clearPlayHistory()
            playSession = session
            playStatus = playSession?.suppliedOpeningLead.map { "已采用核对后的首攻 \($0.description)，不会再次出牌。" }
                ?? "自主推演已开始，请点当前行动家的合法牌。"
            playPositionChanged()
            return true
        } catch { playStatus = error.localizedDescription; return false }
    }

    @discardableResult
    func playCard(_ card: DoubleDummyCard, by seat: Seat) -> Bool {
        guard let previous = playSession else { playStatus = "请先点击开始自主推演。"; return false }
        guard pendingPlayReset == nil, previous.isCompatible(with: originalHandFacts, context: workflow.draft) else {
            playStatus = "输入修改待核对或局面已失效，请先确认或取消修改。"
            return false
        }
        var session = previous
        do {
            try session.play(card, by: seat)
            recordPlayAction(before: previous)
            playSession = session
            playStatus = session.awaitingCollection ? "四张已出齐，请手动收墩。" : "请点当前行动家的合法牌。"
            playPositionChanged()
            return true
        } catch { playStatus = error.localizedDescription; return false }
    }

    @discardableResult
    func collectPlayTrick() -> Bool {
        guard let previous = playSession else { return false }
        guard pendingPlayReset == nil, previous.isCompatible(with: originalHandFacts, context: workflow.draft) else {
            playStatus = "输入修改待核对或局面已失效，请先确认或取消修改。"
            return false
        }
        var session = previous
        do {
            try session.collectTrick()
            recordPlayAction(before: previous)
            playSession = session
            playStatus = session.isComplete ? "全副 13 墩已完成，显示的是实际推演结果。" : "由 \(session.trickLeader.chineseName) 首引下一墩。"
            playPositionChanged()
            return true
        } catch { playStatus = error.localizedDescription; return false }
    }

    func confirmPlayReset() {
        guard let request = pendingPlayReset else { return }
        pendingPlayReset = nil
        clearPlayHistory()
        playSession = nil
        playPositionChanged()
        isConfirmingPlayReset = true
        if let screenshotURL = request.screenshotURL { selectScreenshot(at: screenshotURL) }
        else {
            applyReviewDraft(request.draft, isRecognition: request.isRecognition)
            request.recognitionCommit?()
        }
        isConfirmingPlayReset = false
        playStatus = "输入已更改，旧推演已重置；请重新开始。"
    }

    func cancelPlayReset() { pendingPlayReset = nil }

    @discardableResult
    func undoPlay() -> Bool {
        guard pendingPlayReset == nil, let previous = playUndoStack.last, let current = playSession else { return false }
        guard replacePlaySession(previous) else { clearPlayHistory(); return false }
        playUndoStack.removeLast()
        playRedoStack.append(current)
        playStatus = "已撤销上一个操作，恢复完整局面。"
        return true
    }

    @discardableResult
    func redoPlay() -> Bool {
        guard pendingPlayReset == nil, let next = playRedoStack.last, let current = playSession else { return false }
        guard replacePlaySession(next) else { clearPlayHistory(); return false }
        playRedoStack.removeLast()
        playUndoStack.append(current)
        playStatus = "已恢复被撤销的完整局面。"
        return true
    }

    @discardableResult
    func restartPlay() -> Bool {
        guard let current = playSession, pendingPlayReset == nil,
              current.isCompatible(with: originalHandFacts, context: workflow.draft) else { return false }
        do {
            let start = try BridgePlaySession(original: originalHandFacts, draft: workflow.draft)
            guard replacePlaySession(start) else { return false }
            recordPlayAction(before: current)
            playStatus = start.suppliedOpeningLead.map { "已从原始牌局重走；采用首攻 \($0.description)，不会再次出牌。" }
                ?? "已回到原始牌局起点；请自行选择首攻。"
            return true
        } catch { playStatus = error.localizedDescription; return false }
    }

    private func recordPlayAction(before position: BridgePlaySession) {
        playUndoStack.append(position)
        playRedoStack = []
    }

    private func clearPlayHistory() {
        playUndoStack = []
        playRedoStack = []
    }

    /// Applies a previously captured derived position on the same original board.
    /// Every restored position follows the same analysis invalidation boundary.
    @discardableResult
    func replacePlaySession(_ session: BridgePlaySession) -> Bool {
        guard pendingPlayReset == nil,
              session.isCompatible(with: originalHandFacts, context: workflow.draft) else { return false }
        playSession = session
        playPositionChanged()
        return true
    }

    /// Shared change signal for history, per-card DDS and teaching staleness.
    func playPositionChanged(context: DeclarerPlanDraft? = nil) {
        let context = context ?? workflow.draft
        workflow.markCurrentResultOutdated()
        workflow.setTeachingProjection(playSession?.teachingDraft(from: context))
        keyPlayWorkflow.invalidate()
        if let session = playSession {
            if doubleDummyHandSource == .sharedOriginal {
                doubleDummyWorkflow.updateDraft(session.doubleDummyDraft())
            }
            var node = keyPlayWorkflow.draft
            node.actingSeat = session.actingSeat
            node.currentTrickState = session.currentTrick.isEmpty ? .noCardsPlayed : .cardsRecorded
            node.currentTrickCards = session.currentTrick.map { $0.card.description }.joined(separator: ", ")
            node.candidatePlays = ""
            keyPlayWorkflow.updateDraft(node)
        }
        else { resetDoubleDummyToOriginal(context: context) }
        reviewSessionStatus = "有尚未保存的更改"
        playPositionRevision += 1
    }

    /// Explicitly starts DDS from the original board; editing DDS remaining hands
    /// never writes back to the entered board or changes its version.
    func calculateOriginalContractTable() async {
        await originalContractTableWorkflow.calculate()
    }

    func useOriginalHandsForDoubleDummy() {
        doubleDummyHandSource = .sharedOriginal
        resetDoubleDummyToOriginal(context: workflow.draft)
    }

    private func resetDoubleDummyToOriginal(context: DeclarerPlanDraft) {
        guard doubleDummyHandSource == .sharedOriginal else { return }
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
        doubleDummyHandSource = .independentReviewed
        hasLegacyDoubleDummyConflict = false
        reviewSessionStatus = "有尚未保存的更改"
        // The persisted source records this explicit choice; nil version remains independent.
        doubleDummyOriginalHandVersion = nil
    }

    private func synchronizeOriginalHands(from draft: DeclarerPlanDraft) {
        let updated = originalHandFacts.updating(from: draft)
        guard updated != originalHandFacts else { return }
        originalHandFacts = updated
        clearPlayHistory()
        originalContractTableWorkflow.updateOriginalHands(updated)
        if let session = playSession, !session.isCompatible(with: updated, context: draft) {
            playSession = nil
            playStatus = "原始输入已改变，旧推演已失效；请核对后重新开始。"
            playPositionChanged(context: draft)
        }
        if doubleDummyHandSource == .sharedOriginal {
            doubleDummyWorkflow.invalidate()
            resetDoubleDummyToOriginal(context: draft)
        }
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

struct PlayResetRequest: Identifiable {
    let id = UUID()
    let draft: DeclarerPlanDraft
    var screenshotURL: URL? = nil
    var isRecognition = false
    var recognitionCommit: (() -> Void)? = nil
}
