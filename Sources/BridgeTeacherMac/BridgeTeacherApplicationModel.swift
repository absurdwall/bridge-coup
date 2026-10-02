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

    @Published private(set) var originalHandFacts = OriginalHandFacts()
    @Published private(set) var playSession: BridgePlaySession?
    @Published private(set) var playPositionRevision = 0
    @Published private(set) var playStatus = "点击开始自主推演后可点牌。"
    @Published var pendingPlayReset: PlayResetRequest?
    private var isConfirmingPlayReset = false

    var currentTeachingDraft: DeclarerPlanDraft {
        playSession?.teachingDraft(from: workflow.draft) ?? workflow.draft
    }
    var playStartReason: String? {
        do { _ = try BridgePlaySession(original: originalHandFacts, draft: workflow.draft); return nil }
        catch { return error.localizedDescription }
    }
    @Published private(set) var hasLegacyDoubleDummyConflict = false
    private var doubleDummyOriginalHandVersion: Int? = 0

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
                self.selectScreenshot(at: url)
            }
        }
    }

    func selectScreenshot(at url: URL) {
        if playSession != nil {
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
        if playSession != nil, !isConfirmingPlayReset,
           draft.hands != previousDraft.hands || draft.declarerSeat != previousDraft.declarerSeat
            || draft.contractLevel != previousDraft.contractLevel || draft.contractStrain != previousDraft.contractStrain
            || draft.openingLead != previousDraft.openingLead || draft.decisionTimeConfirmed != previousDraft.decisionTimeConfirmed {
            pendingPlayReset = PlayResetRequest(draft: draft)
            return
        }
        screenshotWorkflow.updateDraft(draft)
        workflow.setTeachingProjection(playSession?.teachingDraft(from: draft))
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
            playSession: playSession
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
        playSession = snapshot.playSession
        if let playSession,
           playSession.originalBoardID != originalHandFacts.boardID || playSession.originalVersion != originalHandFacts.version
            || playSession.declarerSeat != workflow.draft.declarerSeat || playSession.contractLevel != workflow.draft.contractLevel
            || playSession.strain != workflow.draft.contractStrain {
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
        guard playSession == nil else { return false }
        do {
            playSession = try BridgePlaySession(original: originalHandFacts, draft: workflow.draft)
            playStatus = playSession?.suppliedOpeningLead.map { "已采用核对后的首攻 \($0.description)，不会再次出牌。" }
                ?? "自主推演已开始，请点当前行动家的合法牌。"
            playPositionChanged()
            return true
        } catch { playStatus = error.localizedDescription; return false }
    }

    @discardableResult
    func playCard(_ card: DoubleDummyCard, by seat: Seat) -> Bool {
        guard var session = playSession else { playStatus = "请先点击开始自主推演。"; return false }
        do {
            try session.play(card, by: seat)
            playSession = session
            playStatus = session.awaitingCollection ? "四张已出齐，请手动收墩。" : "请点当前行动家的合法牌。"
            playPositionChanged()
            return true
        } catch { playStatus = error.localizedDescription; return false }
    }

    @discardableResult
    func collectPlayTrick() -> Bool {
        guard var session = playSession else { return false }
        do {
            try session.collectTrick()
            playSession = session
            playStatus = session.isComplete ? "全副 13 墩已完成，显示的是实际推演结果。" : "由 \(session.trickLeader.chineseName) 首引下一墩。"
            playPositionChanged()
            return true
        } catch { playStatus = error.localizedDescription; return false }
    }

    func confirmPlayReset() {
        guard let request = pendingPlayReset else { return }
        pendingPlayReset = nil
        playSession = nil
        playPositionChanged()
        isConfirmingPlayReset = true
        if let screenshotURL = request.screenshotURL { selectScreenshot(at: screenshotURL) }
        else { updateReviewDraft(request.draft) }
        isConfirmingPlayReset = false
        playStatus = "输入已更改，旧推演已重置；请重新开始。"
    }

    func cancelPlayReset() { pendingPlayReset = nil }

    /// Applies a previously captured derived position on the same original board.
    /// Every restored position follows the same analysis invalidation boundary.
    @discardableResult
    func replacePlaySession(_ session: BridgePlaySession) -> Bool {
        guard session.originalBoardID == originalHandFacts.boardID,
              session.originalVersion == originalHandFacts.version,
              session.declarerSeat == workflow.draft.declarerSeat,
              session.contractLevel == workflow.draft.contractLevel,
              session.strain == workflow.draft.contractStrain else { return false }
        playSession = session
        playPositionChanged()
        return true
    }

    /// Shared change signal for history, per-card DDS and teaching staleness.
    func playPositionChanged() {
        workflow.markCurrentResultOutdated()
        workflow.setTeachingProjection(playSession?.teachingDraft(from: workflow.draft))
        keyPlayWorkflow.invalidate()
        if let session = playSession {
            doubleDummyWorkflow.updateDraft(session.doubleDummyDraft())
            var node = keyPlayWorkflow.draft
            node.actingSeat = session.actingSeat
            node.currentTrickState = session.currentTrick.isEmpty ? .noCardsPlayed : .cardsRecorded
            node.currentTrickCards = session.currentTrick.map { $0.card.description }.joined(separator: ", ")
            node.candidatePlays = ""
            keyPlayWorkflow.updateDraft(node)
        }
        else { useOriginalHandsForDoubleDummy() }
        reviewSessionStatus = "有尚未保存的更改"
        playPositionRevision += 1
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

struct PlayResetRequest: Identifiable {
    let id = UUID()
    let draft: DeclarerPlanDraft
    var screenshotURL: URL? = nil
}
