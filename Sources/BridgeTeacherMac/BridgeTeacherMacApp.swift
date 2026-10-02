import AppKit
import SwiftUI
import BridgeTeacherCore

@main
struct BridgeTeacherMacApp: App {
    var body: some Scene {
        WindowGroup("Bridge Coup") {
            BridgeTeacherWorkspaceShell()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1320, height: 900)
    }
}

struct BridgeTeacherWorkspaceView: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @State private var isShowingSavedReviews = false
    @State private var isShowingModelSettings = false

    init(model: BridgeTeacherApplicationModel) {
        self.model = model
    }

    var body: some View {
        GeometryReader { geometry in
            let panelHeight = max(320, geometry.size.height - 160)
            VStack(spacing: 18) {
                header

                HStack(alignment: .top, spacing: 18) {
                    ScrollView(.vertical) {
                        DeclarerEntryPanel(
                            model: model,
                            workflow: model.workflow,
                            keyPlayWorkflow: model.keyPlayWorkflow,
                            screenshotWorkflow: model.screenshotWorkflow,
                            mode: teachingModeBinding
                        )
                        .frame(minWidth: 560, maxWidth: 600)
                    }
                    if model.teachingMode == .declarerPlan {
                        TeachingPanel(model: model, workflow: model.workflow)
                            .frame(minWidth: 500, maxWidth: .infinity)
                    } else {
                        KeyPlayTeachingPanel(model: model, workflow: model.keyPlayWorkflow)
                            .frame(minWidth: 500, maxWidth: .infinity)
                    }
                }
                .frame(height: panelHeight, alignment: .top)
            }
            .padding(24)
            .frame(minWidth: 1180, minHeight: 650, alignment: .top)
            .accessibilityIdentifier("bridge-coup-workspace")
        }
        .background(BridgePalette.canvas.ignoresSafeArea())
        .preferredColorScheme(.light)
        .task { await model.bootstrap() }
        .sheet(isPresented: $isShowingSavedReviews) {
            SavedReviewSessionsView(model: model)
                .frame(minWidth: 540, minHeight: 420)
        }
        .alert(item: $model.reviewSessionAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("好"))
            )
        }
    }

    private var teachingModeBinding: Binding<TeachingMode> {
        Binding(
            get: { model.teachingMode },
            set: { model.setTeachingMode($0) }
        )
    }

    private var header: some View {
        HStack(spacing: 14) {
            brandLockup

            VStack(alignment: .leading, spacing: 3) {
                Text("\(model.teachingMode.title) · 决策时信息 · IMP")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BridgePalette.muted)
                    .lineLimit(1)
                if !model.reviewSessionStatus.isEmpty {
                    Text(model.reviewSessionStatus)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BridgePalette.green)
                        .lineLimit(1)
                        .accessibilityIdentifier("review-session-status")
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 7) {
                Button {
                    model.saveReview()
                } label: {
                    Label("保存", systemImage: "square.and.arrow.down")
                }
                .controlSize(.small)
                .buttonStyle(.borderless)
                .accessibilityIdentifier("save-review-session")

                Button {
                    if model.refreshSavedReviewSessions() {
                        isShowingSavedReviews = true
                    }
                } label: {
                    Label("打开", systemImage: "folder")
                }
                .controlSize(.small)
                .buttonStyle(.borderless)
                .accessibilityIdentifier("open-review-session")

                Button {
                    isShowingModelSettings = true
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(model.connectionStatus.isSignedIn ? BridgePalette.green : BridgePalette.amber)
                            .frame(width: 7, height: 7)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(model.modelSelectionSummary)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(BridgePalette.ink)
                            Text("模型与连接")
                                .font(.system(size: 9))
                                .foregroundStyle(BridgePalette.muted)
                        }
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BridgePalette.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(BridgePalette.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("model-effort-settings")
                .accessibilityLabel("\(model.modelSelectionSummary) · \(model.connectionStatus.message)")
                .popover(isPresented: $isShowingModelSettings, arrowEdge: .top) {
                    CodexModelSettingsPopover(model: model)
                }
                .padding(.trailing, 80)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(BridgePalette.border, lineWidth: 1))
    }

    @ViewBuilder
    private var brandLockup: some View {
        let resources = Bundle.main.resourceURL
        HStack(spacing: 9) {
            if let logoURL = resources?.appendingPathComponent("BridgeCoupLogo.png"),
               let logo = NSImage(contentsOf: logoURL) {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 43, height: 43)
                    .accessibilityLabel("Bridge Coup stacked-card logo")
            }
            if let wordmarkURL = resources?.appendingPathComponent("BridgeCoupWordmark.png"),
               let wordmark = NSImage(contentsOf: wordmarkURL) {
                Image(nsImage: wordmark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 136, height: 31, alignment: .leading)
                    .accessibilityLabel("Bridge Coup wordmark")
            } else {
                Text("Bridge Coup")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(BridgePalette.ink)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("bridge-coup-brand-lockup")
    }
}

private struct CodexModelSettingsPopover: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @Environment(\.dismiss) private var dismiss
    @State private var isConnectionExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("模型与思考深度")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(BridgePalette.ink)
                        Text("选项以当前 Codex runtime 能力为准")
                            .font(.system(size: 10))
                            .foregroundStyle(BridgePalette.muted)
                    }
                    Spacer(minLength: 6)
                    Button("完成") { dismiss() }
                        .controlSize(.small)
                        .accessibilityIdentifier("close-model-settings")
                }

                Text(model.modelCatalogStatus)
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 4) {
                    ForEach(CodexModelFamily.allCases, id: \.self) { family in
                        let option = model.modelSettings.option(for: family)
                        Button {
                            model.selectModel(family)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: model.modelSettings.selectedFamily == family ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(model.modelSettings.selectedFamily == family ? BridgePalette.green : BridgePalette.muted)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(family.title)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(BridgePalette.ink)
                                    Text(modelIdentifierLabel(for: option))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(option.isAvailable ? BridgePalette.muted : BridgePalette.warning)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    if let reason = option.unavailableReason {
                                        Text(reason)
                                            .font(.system(size: 8))
                                            .foregroundStyle(BridgePalette.warning)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    } else if !option.excludedRuntimeModelIdentifiers.isEmpty {
                                        Text("已过滤相似目录项：\(option.excludedRuntimeModelIdentifiers.joined(separator: "、"))")
                                            .font(.system(size: 8))
                                            .foregroundStyle(BridgePalette.muted)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                Spacer(minLength: 3)
                                Text(option.isAvailable ? "可用" : "不可用")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(option.isAvailable ? BridgePalette.green : BridgePalette.warning)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                model.modelSettings.selectedFamily == family ? BridgePalette.green.opacity(0.07) : .clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!option.isAvailable)
                        .accessibilityIdentifier("model-choice-\(family.rawValue)")
                    }
                }

                if let family = model.modelSettings.selectedFamily {
                    let option = model.modelSettings.option(for: family)
                    Divider().overlay(BridgePalette.border)
                    Text("Thinking effort · \(option.runtimeModelIdentifier ?? family.title)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BridgePalette.ink)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 61), alignment: .leading)], alignment: .leading, spacing: 5) {
                        ForEach(option.supportedEfforts, id: \.self) { effort in
                            Button {
                                model.selectEffort(effort)
                            } label: {
                                Text(effort.title)
                                    .font(.system(size: 9, weight: .medium))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(
                                        model.modelSettings.selection?.effort == effort ? BridgePalette.green.opacity(0.12) : BridgePalette.soft,
                                        in: Capsule()
                                    )
                                    .foregroundStyle(model.modelSettings.selection?.effort == effort ? BridgePalette.green : BridgePalette.ink)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("effort-choice-\(effort.rawValue)")
                        }
                    }
                    if option.supportedEfforts.isEmpty {
                        Text(option.unavailableReason ?? "该模型没有可选择的思考深度。")
                            .font(.system(size: 9))
                            .foregroundStyle(BridgePalette.warning)
                    }
                }

                if let notice = model.modelSettings.notice {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(BridgePalette.warning)
                            .padding(.top, 1)
                        Text(notice)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(BridgePalette.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let screenshotMessage = model.screenshotCapabilityMessage {
                    Text(screenshotMessage)
                        .font(.system(size: 9))
                        .foregroundStyle(BridgePalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                connectionDisclosure
            }
            .padding(12)
        }
        .frame(width: 326, height: 354)
        .background(BridgePalette.canvas)
    }

    private var connectionDisclosure: some View {
        DisclosureGroup(isExpanded: $isConnectionExpanded) {
            VStack(alignment: .leading, spacing: 7) {
                Text(model.connectionStatus.message)
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if let runtimePath = model.runtimePath {
                    Text(URL(fileURLWithPath: runtimePath).lastPathComponent)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(BridgePalette.muted)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Button("选择 Codex runtime") { model.chooseRuntime() }
                        .controlSize(.small)
                    if model.connectionStatus.isSignedIn {
                        Button("检查连接") { Task { await model.checkLogin() } }
                            .controlSize(.small)
                            .disabled(model.isConnecting)
                        Button("重新登录") { Task { await model.connectToChatGPT() } }
                            .controlSize(.small)
                            .disabled(model.isStartingLogin)
                    } else if case .awaitingLogin = model.connectionStatus {
                        Button("检查连接") { Task { await model.checkLogin() } }
                            .controlSize(.small)
                            .disabled(model.isConnecting)
                        Button("重开登录") { Task { await model.connectToChatGPT() } }
                            .controlSize(.small)
                            .disabled(model.isStartingLogin)
                    } else if model.connectionStatus.runtimeVersion != nil {
                        Button("连接 ChatGPT") { Task { await model.connectToChatGPT() } }
                            .controlSize(.small)
                            .disabled(model.isStartingLogin)
                    }
                }

                Button("刷新模型能力") { Task { await model.refreshModelSettings() } }
                    .font(.system(size: 10))
                    .disabled(!model.connectionStatus.isSignedIn)
                    .accessibilityIdentifier("refresh-model-capabilities")
            }
            .padding(.top, 6)
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(model.connectionStatus.isSignedIn ? BridgePalette.green : BridgePalette.amber)
                    .frame(width: 7, height: 7)
                Text("连接状态")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BridgePalette.ink)
                Spacer(minLength: 2)
                Text(model.connectionStatus.message)
                    .font(.system(size: 9))
                    .foregroundStyle(BridgePalette.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .accessibilityIdentifier("codex-connection-details")
    }

    private func modelIdentifierLabel(for option: CodexModelOption) -> String {
        if !option.runtimeModelIdentifiers.isEmpty {
            return option.runtimeModelIdentifiers.joined(separator: " · ")
        }
        if !option.excludedRuntimeModelIdentifiers.isEmpty {
            return option.excludedRuntimeModelIdentifiers.joined(separator: " · ")
        }
        return option.unavailableReason ?? "尚未验证"
    }
}

private struct CodexRequestProvenanceLine: View {
    let model: String?
    let requestedModel: String?
    let effort: String?

    private var summary: String? {
        let requested = requestedModel ?? model
        guard let requested, !requested.isEmpty else { return nil }
        let effective = model.map { $0 == requested ? requested : "\(requested) → \($0)" } ?? "\(requested)（runtime 未回报模型）"
        guard let effort, !effort.isEmpty else { return effective }
        let effortTitle = CodexReasoningEffort(rawValue: effort)?.title ?? effort
        return "\(effective) · \(effortTitle)"
    }

    var body: some View {
        if let summary {
            Text("本次请求：\(summary)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(BridgePalette.muted)
                .textSelection(.enabled)
                .accessibilityIdentifier("request-model-effort-provenance")
        }
    }
}

private struct SavedReviewSessionsView: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("本机复盘")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("记录与原始截图只保存在这台 Mac。")
                        .font(.system(size: 12))
                        .foregroundStyle(BridgePalette.muted)
                }
                Spacer()
                Button("完成") { dismiss() }
            }

            if let alert = model.reviewSessionAlert {
                Label(alert.message, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(BridgePalette.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if model.savedReviewSessions.isEmpty {
                ContentUnavailableView(
                    "还没有保存的复盘",
                    systemImage: "tray",
                    description: Text("完成一次牌局复盘后，选择“保存复盘”。")
                )
            } else {
                List(model.savedReviewSessions) { session in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.title)
                                .font(.system(size: 13, weight: .semibold))
                            Text("\(session.teachingMode.title) · \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(size: 11))
                                .foregroundStyle(BridgePalette.muted)
                        }
                        Spacer()
                        Button("打开") {
                            if model.openReview(id: session.id) { dismiss() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BridgePalette.green)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
        .padding(20)
        .background(BridgePalette.canvas)
    }
}

private struct DeclarerEntryPanel: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @ObservedObject var workflow: DeclarerPlanWorkflow
    @ObservedObject var keyPlayWorkflow: KeyPlayAnalysisWorkflow
    @ObservedObject var screenshotWorkflow: ScreenshotReviewWorkflow
    @Binding var mode: TeachingMode
    @State private var isShowingScreenshotPreview = false
    @State private var isScreenshotDetailsExpanded = false
    @State private var isContextExpanded = false
    @State private var isShowingContractGrid = false
    @State private var isDoubleDummyVerificationExpanded = false
    @FocusState private var isContractPickerFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeading("牌面与问题", subtitle: "两种教学共用这份已确认的牌面。")
            modePicker
                .padding(.top, 14)
            VStack(alignment: .leading, spacing: 14) {
                screenshotImportRow
                DisclosureGroup(isExpanded: $isScreenshotDetailsExpanded) {
                    VStack(alignment: .leading, spacing: 10) {
                        screenshotReview
                        screenshotDecisionTimeConfirmation
                    }
                    .padding(.top, 8)
                } label: {
                    Label(screenshotDetailsTitle, systemImage: "viewfinder")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BridgePalette.ink)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .accessibilityIdentifier("screenshot-review-details")

                contractFields
                auctionFields
                visibleHands

                DisclosureGroup(isExpanded: $isContextExpanded) {
                    Group {
                        if mode == .declarerPlan {
                            contextFields
                        } else {
                            keyPlayFields
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Label(contextDisclosureTitle, systemImage: "text.alignleft")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BridgePalette.ink)
                }
                .accessibilityIdentifier("review-context-details")

                if let warning = inputWarning {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BridgePalette.warning)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("hand-validation-warning")
                }
            }
            .padding(.top, 14)

            Divider().overlay(BridgePalette.border).padding(.vertical, 14)
            HStack {
                Text("计分：IMP")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BridgePalette.muted)
                Spacer()
                Button {
                    Task { await model.generate(mode: mode) }
                } label: {
                    HStack(spacing: 8) {
                        if activeGenerationState == .generating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(generationButtonTitle)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 170)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(BridgePalette.green)
                .disabled(
                    !model.canSendModelRequests
                        || activeGenerationState == .generating
                        || (screenshotWorkflow.screenshotURL != nil && !workflow.draft.decisionTimeConfirmed)
                )
                .accessibilityIdentifier(mode == .declarerPlan ? "generate-declarer-plan" : "generate-key-play-analysis")
            }

            DisclosureGroup(isExpanded: $isDoubleDummyVerificationExpanded) {
                DoubleDummyVerificationView(model: model) {
                    isDoubleDummyVerificationExpanded = false
                }
                    .padding(.top, 10)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("事后双明手核验")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BridgePalette.ink)
                        .accessibilityIdentifier("open-double-dummy-verification")
                    Text("按需录入完整牌局并运行 DDS；核验结果不会进入教学请求。")
                        .font(.system(size: 10))
                        .foregroundStyle(BridgePalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .padding(12)
            .background(BridgePalette.soft.opacity(0.6), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(BridgePalette.border, lineWidth: 1))
            .padding(.top, 12)
        }
        .onChange(of: screenshotWorkflow.screenshotURL) { _, url in
            if url != nil { isScreenshotDetailsExpanded = true }
        }
        .onChange(of: workflow.draft.otherDecisionTimeFacts) { _, facts in
            if !facts.isEmpty { isContextExpanded = true }
        }
        .onChange(of: workflow.draft.question) { _, question in
            if !question.isEmpty { isContextExpanded = true }
        }
        .onChange(of: keyPlayWorkflow.draft.analysisPoint) { _, analysisPoint in
            if !analysisPoint.isEmpty { isContextExpanded = true }
        }
        .onChange(of: keyPlayWorkflow.draft.relevantPlayHistory) { _, history in
            if !history.isEmpty { isContextExpanded = true }
        }
        .onChange(of: isShowingContractGrid) { _, isShowing in
            if isShowing {
                // Release focus from the popover's anchor while the grid owns
                // keyboard navigation; restore it only after the popover closes.
                isContractPickerFocused = false
            } else {
                isContractPickerFocused = true
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
        .sheet(isPresented: $isShowingScreenshotPreview) {
            if let screenshotURL = screenshotWorkflow.screenshotURL {
                ScreenshotImagePreview(url: screenshotURL)
                    .frame(minWidth: 720, minHeight: 680)
            }
        }
    }

    private var modePicker: some View {
        Picker("教学模式", selection: $mode) {
            Text("做庄计划").tag(TeachingMode.declarerPlan)
            Text("分析这一步").tag(TeachingMode.keyPlayAnalysis)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("teaching-mode")
    }

    private var activeGenerationState: PlanGenerationState {
        mode == .declarerPlan ? workflow.state : keyPlayWorkflow.state
    }

    private var screenshotDetailsTitle: String {
        guard let filename = screenshotWorkflow.screenshotFilename else { return "截图识别与核对" }
        return "截图识别与核对 · \(filename)"
    }

    private var contextDisclosureTitle: String {
        mode == .declarerPlan ? "复盘背景与补充事实" : "分析时点与补充事实"
    }

    private var screenshotImportRow: some View {
        HStack(spacing: 9) {
            Button(screenshotWorkflow.screenshotURL == nil ? "导入截图" : "更换截图") {
                model.chooseScreenshot()
            }
            .controlSize(.small)
            .accessibilityIdentifier("import-review-screenshot")

            Text(screenshotWorkflow.screenshotFilename ?? "截图可选；也可以直接录入牌面")
                .font(.system(size: 11))
                .foregroundStyle(BridgePalette.muted)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 0)
        }
    }

    private var screenshotReview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Group {
                    if let screenshotURL = screenshotWorkflow.screenshotURL,
                       let image = NSImage(contentsOf: screenshotURL) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 25, weight: .light))
                            .foregroundStyle(BridgePalette.muted)
                    }
                }
                .frame(width: 76, height: 104)
                .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 9))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(BridgePalette.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 8) {
                    Text("截图识别")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BridgePalette.ink)
                    Text(screenshotWorkflow.screenshotFilename ?? "导入一张牌局截图")
                        .font(.system(size: 11))
                        .foregroundStyle(BridgePalette.muted)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        if screenshotWorkflow.screenshotURL != nil {
                            Button("查看原图") { isShowingScreenshotPreview = true }
                            Button {
                                Task { await model.recognizeScreenshot() }
                            } label: {
                                if screenshotWorkflow.state == .recognizing {
                                    ProgressView().controlSize(.small)
                                }
                                Text(screenshotPresentation.buttonTitle)
                            }
                            .disabled(
                                !model.canSendModelRequests
                                    || !model.modelSettings.canRecognizeImages
                                    || screenshotWorkflow.state == .recognizing
                                    || screenshotWorkflow.state == .succeeded
                            )
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            Text(screenshotPresentation.message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(screenshotPresentation.isFailure ? BridgePalette.warning : BridgePalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            if screenshotWorkflow.screenshotURL != nil,
               let screenshotCapabilityMessage = model.screenshotCapabilityMessage {
                Text(screenshotCapabilityMessage)
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let recognition = screenshotWorkflow.recognitionResponse {
                CodexRequestProvenanceLine(
                    model: recognition.model,
                    requestedModel: recognition.requestedModel,
                    effort: recognition.reasoningEffort
                )
            }

            if let candidate = screenshotWorkflow.candidate {
                VStack(alignment: .leading, spacing: 4) {
                    if let auction = candidate.auction {
                        if auction.entries.isEmpty {
                            Text(auction.isPartial
                                 ? "截图叫牌候选为空，是部分可见片段；没有补入 Pass。可在下方手动录入。"
                                 : "叫牌候选为空；没有补入 Pass。可在下方手动录入。")
                        } else {
                            let entries = auction.auctionRecord.entries.map { entry in
                                "\(entry.seat?.chineseName ?? "位置未知") \(entry.call.displayText)"
                            }
                            Text(auction.isPartial
                                 ? "截图叫牌候选 · 部分可见片段（按可见顺序；不推断缺口、Pass 或座位）：\(entries.joined(separator: " · "))。请在下方逐项核对、修正或补录。"
                                 : "截图叫牌候选：\(entries.joined(separator: " · "))。请在下方叫牌表核对、修正或补录。")
                        }
                    }
                    if let vulnerability = candidate.vulnerability {
                        Text("局况候选：\(vulnerability.chineseDescription)；请核对截图与下方选项。")
                    }
                    if candidate.auction != nil || candidate.vulnerability != nil {
                        Text("截图识别结果尚未确认；只有勾选下方核对声明后才会进入请求。")
                            .foregroundStyle(BridgePalette.warning)
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(BridgePalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("screenshot-auction-candidate-summary")
            }

            if let candidate = screenshotWorkflow.candidate, !candidate.notes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(candidate.notes.enumerated()), id: \.offset) { _, note in
                        Label("\(noteKindLabel(note.kind)) · \(note.field)：\(note.message)", systemImage: "eye.trianglebadge.exclamationmark")
                            .font(.system(size: 11))
                            .foregroundStyle(BridgePalette.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(12)
        .background(BridgePalette.soft.opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
    }

    private func noteKindLabel(_ kind: ScreenshotRecognitionNoteKind) -> String {
        switch kind {
        case .notShown: "截图未显示"
        case .visibleButUnclear: "可见但不清晰"
        case .ambiguous: "识别有歧义"
        }
    }

    private var screenshotPresentation: ScreenshotRecognitionPresentation {
        ScreenshotRecognitionPresentation(
            state: screenshotWorkflow.state,
            model: screenshotWorkflow.recognitionResponse?.model ?? "Codex"
        )
    }

    private var screenshotDecisionTimeConfirmation: some View {
        Group {
            if screenshotWorkflow.screenshotURL != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: draftBinding(for: \.decisionTimeConfirmed)) {
                        Text("我已核对：叫牌、局况、勾选的手牌、定约、做庄人、首攻和补充事实，都是这个决策点当时可得的信息。")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BridgePalette.ink)
                    }
                    .toggleStyle(.checkbox)
                    Text("必须先逐家选择当时可见的手牌。未勾选的截图牌面不会进入计划或关键出牌分析。")
                        .font(.system(size: 10))
                        .foregroundStyle(BridgePalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var contractFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("定约背景")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BridgePalette.ink)
            HStack(spacing: 9) {
                Picker("做庄人", selection: draftBinding(for: \.declarerSeat)) {
                    Text("未知").tag(Seat?.none)
                    ForEach(Seat.allCases, id: \.self) { seat in
                        Text(seat.chineseName).tag(Optional(seat))
                    }
                }
                .frame(width: 100)
                Button {
                    isShowingContractGrid = true
                } label: {
                    HStack(spacing: 8) {
                        Text("定约")
                            .foregroundStyle(BridgePalette.muted)
                        Text(selectedContractTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(selectedContractColor)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(BridgePalette.muted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .frame(width: 150)
                .focused($isContractPickerFocused)
                .accessibilityIdentifier("contract-grid-picker")
                .accessibilityLabel("定约：\(selectedContractTitle)，打开完整叫品表")
                .popover(isPresented: $isShowingContractGrid, arrowEdge: .bottom) {
                    contractSelectionGrid(isShowing: $isShowingContractGrid)
                }
                TextField("首攻（可选，如 S2）", text: draftBinding(for: \.openingLead))
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 120)
                    .accessibilityIdentifier("opening-lead-input")
            }
            .labelsHidden()
            .pickerStyle(.menu)
            if let openingLeadError {
                Text(openingLeadError)
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.warning)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("opening-lead-validation-error")
            }
        }
        .padding(14)
        .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var auctionFields: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("叫牌与局况")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                Spacer()
                Text("未知资料可以留空")
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.muted)
            }

            HStack(spacing: 10) {
                Picker("局况", selection: draftBinding(for: \.vulnerability)) {
                    Text("局况未知").tag(Vulnerability?.none)
                    ForEach(Vulnerability.allCases, id: \.self) { vulnerability in
                        Text(vulnerability.chineseDescription).tag(Optional(vulnerability))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 145, alignment: .leading)
                .accessibilityIdentifier("auction-vulnerability")

                Picker(
                    workflow.draft.auction?.isPartial == true
                        ? "整段叫牌的首个行动位置（不推算片段座位）"
                        : "首个行动位置",
                    selection: auctionStartingSeatBinding
                ) {
                    Text("位置未知").tag(Seat?.none)
                    ForEach(Seat.allCases, id: \.self) { seat in
                        Text(seat.chineseName).tag(Optional(seat))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 150, alignment: .leading)
                .disabled(workflow.draft.auction?.kind == .noAuction)
                .accessibilityIdentifier("auction-starting-seat")
            }
            .font(.system(size: 11, weight: .regular))

        }
        .padding(12)
        .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var auctionRecordBinding: Binding<AuctionRecord?> {
        Binding(
            get: { workflow.draft.auction },
            set: { setAuction($0) }
        )
    }

    private func saveAuctionMeaningNote(_ id: UUID, _ note: String?) {
        guard var record = workflow.draft.auction,
              record.setMeaningNote(note, forEntryID: id) else { return }
        setAuction(record)
    }

    private var auctionStartingSeatBinding: Binding<Seat?> {
        Binding(
            get: { workflow.draft.auction?.startingSeat },
            set: { newSeat in
                var record = workflow.draft.auction ?? AuctionRecord()
                record.setStartingSeat(newSeat)
                setAuction(record)
            }
        )
    }

    private func setAuction(_ auction: AuctionRecord?) {
        var draft = workflow.draft
        draft.auction = auction
        model.updateReviewDraft(draft)
    }

    private func contractSelectionGrid(isShowing: Binding<Bool>) -> some View {
        ContractSelectionGrid(
            selectedContract: selectedContractChoice,
            onSelect: { contract in
                model.handleContractSelectionAction(.select(contract))
                isShowing.wrappedValue = false
            },
            onClear: {
                model.handleContractSelectionAction(.clear)
                isShowing.wrappedValue = false
            },
            onCancel: {
                model.handleContractSelectionAction(.cancel)
                isShowing.wrappedValue = false
            }
        )
    }

    private var selectedContractChoice: ContractChoice? {
        guard let level = workflow.draft.contractLevel,
              let strain = workflow.draft.contractStrain else { return nil }
        return ContractChoice(level: level, strain: strain)
    }

    private var selectedContractTitle: String {
        guard let contract = selectedContractChoice else { return "选择定约" }
        return "\(contract.level)\(contract.strain.symbol)"
    }

    private var selectedContractColor: Color {
        guard let contract = selectedContractChoice else { return BridgePalette.muted }
        return BridgePalette.contractColor(for: contract.strain)
    }

    private var openingLeadError: String? {
        let input = workflow.draft.openingLead.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, OpeningLead(input: input) == nil else { return nil }
        return OpeningLeadInputError.invalidInput(input).localizedDescription
    }

    private var generationButtonTitle: String {
        if activeGenerationState == .generating { return "正在生成…" }
        return mode == .declarerPlan ? "生成做庄计划" : "分析这一步"
    }

    private var visibleHands: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(screenshotWorkflow.screenshotURL == nil
                     ? (mode == .declarerPlan ? "当时可见手牌" : "决策时剩余可见手牌")
                     : "识别候选手牌")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                Spacer()
                Text("仅勾选后加入教学 · 留空 = 未知")
                    .font(.system(size: 11))
                    .foregroundStyle(BridgePalette.muted)
            }
            BridgeDealTable(
                declarerSeat: workflow.draft.declarerSeat,
                auction: auctionRecordBinding,
                onSaveAuctionMeaningNote: saveAuctionMeaningNote,
                actingSeat: mode == .keyPlayAnalysis ? keyPlayWorkflow.draft.actingSeat : nil,
                screenshotReviewMode: true,
                isDecisionTimeVisible: { seat in
                    workflow.draft.decisionTimeVisibleSeats?.contains(seat) ?? true
                },
                holding: { seat, suit in workflow.draft.hands[seat]?[suit] ?? "" },
                onCommit: commitHolding,
                onVisibilityChange: setDecisionTimeVisibility
            )
            Text(screenshotWorkflow.screenshotURL == nil
                 ? "点按花色行编辑 · 留空 = 未知 · “-” = 已确认缺门"
                 : "点按花色行校正候选 · 仅勾选的手牌加入分析")
                .font(.system(size: 11))
                .foregroundStyle(BridgePalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var contextFields: some View {
        VStack(alignment: .leading, spacing: 11) {
            decisionTimeFactsField
            Text("条件假设请写在右侧追问框；不会添加到已确认牌面。")
                .font(.system(size: 10))
                .foregroundStyle(BridgePalette.muted)
            TextField("你最想弄清楚什么？", text: draftBinding(for: \.question))
                .textFieldStyle(.roundedBorder)
        }
    }

    private var decisionTimeFactsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("补充当时已确认的事实")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BridgePalette.ink)
            TextEditor(text: draftBinding(for: \.otherDecisionTimeFacts))
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .padding(7)
                .frame(minHeight: 76)
                .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    if workflow.draft.otherDecisionTimeFacts.isEmpty {
                        Text("当时已确认的叫牌、已出牌或其他影响判断的事实…")
                            .font(.system(size: 12))
                            .foregroundStyle(BridgePalette.muted.opacity(0.75))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var keyPlayFields: some View {
        VStack(alignment: .leading, spacing: 11) {
            decisionTimeFactsField
            Text("关键出牌时点")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BridgePalette.ink)
            TextField("分析时点（例如：第七墩，庄家在第三家）", text: keyPlayBinding(for: \.analysisPoint))
                .textFieldStyle(.roundedBorder)
            Picker("轮到谁行动", selection: keyPlayBinding(for: \.actingSeat)) {
                Text("未确认").tag(Seat?.none)
                ForEach(Seat.allCases, id: \.self) { seat in
                    Text(seat.chineseName).tag(Optional(seat))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 190, alignment: .leading)
            Picker("当前墩状态", selection: currentTrickStateBinding) {
                ForEach(CurrentTrickState.allCases, id: \.self) { state in
                    Text(state.title).tag(state)
                }
            }
            .pickerStyle(.segmented)
            if keyPlayWorkflow.draft.currentTrickState == .cardsRecorded {
                TextField("本墩已出牌（按先后，如 ♥K、♥3、♥5）", text: keyPlayBinding(for: \.currentTrickCards))
                    .textFieldStyle(.roundedBorder)
            }
            TextField("想比较的候选牌（可选，如 ♥A、♥4、♥8）", text: keyPlayBinding(for: \.candidatePlays))
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("key-play-candidates")
            TextField("此前相关出牌历史（仅录入当时已发生的内容）", text: keyPlayBinding(for: \.relevantPlayHistory), axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("key-play-history")
            TextField("这一步最想弄清楚什么？", text: keyPlayBinding(for: \.question))
                .textFieldStyle(.roundedBorder)
            Text("缺少会改变判断的时点或出牌记录时，分析会明确要求补充；未确认的手牌仍保持未知。")
                .font(.system(size: 10))
                .foregroundStyle(BridgePalette.muted)
        }
    }

    private var currentTrickStateBinding: Binding<CurrentTrickState> {
        Binding(
            get: { keyPlayWorkflow.draft.currentTrickState },
            set: { newState in
                var draft = keyPlayWorkflow.draft
                draft.currentTrickState = newState
                if newState != .cardsRecorded {
                    draft.currentTrickCards = ""
                }
                model.updateKeyPlayDraft(draft)
            }
        )
    }

    private var inputWarning: String? {
        if mode == .declarerPlan { return handWarning }
        do {
            _ = try KeyPlayAnalysisRequestBuilder.build(from: workflow.draft, node: keyPlayWorkflow.draft)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private var handWarning: String? {
        let hasInput = workflow.draft.hands.values.contains { hand in
            hand.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        guard hasInput else { return nil }
        do {
            _ = try DeclarerPlanRequestBuilder.visibleHands(in: workflow.draft)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func draftBinding<Value>(for keyPath: WritableKeyPath<DeclarerPlanDraft, Value>) -> Binding<Value> {
        Binding(
            get: { workflow.draft[keyPath: keyPath] },
            set: { newValue in
                var draft = workflow.draft
                draft[keyPath: keyPath] = newValue
                model.updateReviewDraft(draft)
            }
        )
    }

    private func commitHolding(seat: Seat, suit: Suit, value: String) -> String? {
        var draft = workflow.draft
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            draft.hands[seat]?.removeValue(forKey: suit)
            if draft.hands[seat]?.isEmpty == true {
                draft.hands.removeValue(forKey: seat)
            }
        } else {
            draft.hands[seat, default: [:]][suit] = normalized
        }

        do {
            _ = try DeclarerPlanRequestBuilder.visibleHands(in: draft)
            model.updateReviewDraft(draft)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func setDecisionTimeVisibility(_ seat: Seat, isVisible: Bool) {
        var draft = workflow.draft
        var visibleSeats = draft.decisionTimeVisibleSeats ?? Set(
            Seat.allCases.filter { candidateSeat in
                draft.hands[candidateSeat]?.values.contains(where: { !$0.isEmpty }) ?? false
            }
        )
        if isVisible {
            visibleSeats.insert(seat)
        } else {
            visibleSeats.remove(seat)
        }
        draft.decisionTimeVisibleSeats = visibleSeats
        model.updateReviewDraft(draft)
    }

    private func keyPlayBinding<Value>(for keyPath: WritableKeyPath<KeyPlayAnalysisDraft, Value>) -> Binding<Value> {
        Binding(
            get: { keyPlayWorkflow.draft[keyPath: keyPath] },
            set: { newValue in
                var draft = keyPlayWorkflow.draft
                draft[keyPath: keyPath] = newValue
                model.updateKeyPlayDraft(draft)
            }
        )
    }
}

private struct ContractSelectionGrid: View {
    let selectedContract: ContractChoice?
    let onSelect: (ContractChoice) -> Void
    let onClear: () -> Void
    let onCancel: () -> Void

    @FocusState private var isContractGridFocused: Bool
    @State private var focusedContractChoice: ContractChoice?

    private let strains: [ContractStrain] = [.clubs, .diamonds, .hearts, .spades, .noTrump]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("选择定约")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BridgePalette.ink)
                    Text("点选一个阶数与花色组合")
                        .font(.system(size: 10))
                        .foregroundStyle(BridgePalette.muted)
                }
                Spacer()
                if selectedContract != nil {
                    Button("清除定约", action: onClear)
                        .buttonStyle(.plain)
                        .foregroundStyle(BridgePalette.muted)
                        .accessibilityIdentifier("clear-contract-selection")
                }
                Button("取消", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(BridgePalette.muted)
                    .accessibilityIdentifier("cancel-contract-selection")
            }

            Grid(horizontalSpacing: 6, verticalSpacing: 5) {
                GridRow {
                    Text("")
                        .frame(width: 24, height: 26)
                        .accessibilityHidden(true)
                    ForEach(strains, id: \.self) { strain in
                        Text(strain.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BridgePalette.contractColor(for: strain))
                            .frame(width: 52, height: 26)
                            .accessibilityLabel(strain.symbol == "NT" ? "无将" : strain.symbol)
                    }
                }

                ForEach(1...7, id: \.self) { level in
                    GridRow {
                        Text("\(level)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(BridgePalette.muted)
                            .frame(width: 24, height: 36)
                        ForEach(strains, id: \.self) { strain in
                            contractOption(level: level, strain: strain)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 344)
        .background(.white)
        .focusable()
        .focusEffectDisabled()
        .focused($isContractGridFocused)
        .defaultFocus($isContractGridFocused, true)
        .onAppear {
            focusedContractChoice = selectedContract ?? ContractChoice(level: 1, strain: .clubs)
        }
        .onKeyPress(.leftArrow) {
            moveFocus(.left)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            moveFocus(.right)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveFocus(.up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveFocus(.down)
            return .handled
        }
        .onKeyPress(.return) {
            selectFocusedContract()
            return .handled
        }
        .onKeyPress(.space) {
            selectFocusedContract()
            return .handled
        }
    }

    private func contractOption(level: Int, strain: ContractStrain) -> some View {
        let isSelected = selectedContract == ContractChoice(level: level, strain: strain)
        let optionIdentifier = contractOptionIdentifier(level: level, strain: strain)
        let isFocused = (focusedContractChoice ?? selectedContract ?? ContractChoice(level: 1, strain: .clubs))
            == ContractChoice(level: level, strain: strain)
        return Button {
            onSelect(ContractChoice(level: level, strain: strain))
        } label: {
            Text("\(level)\(strain.symbol)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(BridgePalette.contractColor(for: strain))
                .frame(width: 52, height: 36)
                .background(BridgePalette.contractBackground(for: strain), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isFocused ? BridgePalette.amber : isSelected ? BridgePalette.contractColor(for: strain) : BridgePalette.border,
                            lineWidth: isFocused || isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityIdentifier(optionIdentifier)
        .accessibilityLabel("\(level)\(strain.symbol) 定约")
        .accessibilityValue(isSelected ? "当前选择" : "未选择")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func moveFocus(_ direction: ContractGridNavigation.Direction) {
        let current = focusedContractChoice ?? selectedContract ?? ContractChoice(level: 1, strain: .clubs)
        focusedContractChoice = ContractGridNavigation.destination(from: current, direction: direction)
    }

    private func selectFocusedContract() {
        let contract = focusedContractChoice ?? selectedContract ?? ContractChoice(level: 1, strain: .clubs)
        onSelect(contract)
    }

    private func contractOptionIdentifier(level: Int, strain: ContractStrain) -> String {
        "contract-option-\(level)-\(strain.rawValue)"
    }

}

private struct BridgeDealTable: View {
    let declarerSeat: Seat?
    @Binding var auction: AuctionRecord?
    let onSaveAuctionMeaningNote: (UUID, String?) -> Void
    let actingSeat: Seat?
    let screenshotReviewMode: Bool
    let isDecisionTimeVisible: (Seat) -> Bool
    let holding: (Seat, Suit) -> String
    let onCommit: (Seat, Suit, String) -> String?
    let onVisibilityChange: (Seat, Bool) -> Void

    var body: some View {
        VStack(spacing: 8) {
            seatCard(.north)
            HStack(spacing: 8) {
                seatCard(.west)
                AuctionTableView(record: $auction, onSaveMeaningNote: onSaveAuctionMeaningNote)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 82)
                seatCard(.east)
            }
            seatCard(.south)
        }
        .padding(8)
        .background(Color(red: 0.92, green: 0.95, blue: 0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("bridge-deal-table")
    }

    private func seatCard(_ seat: Seat) -> some View {
        HandEntryCard(
            seat: seat,
            isDeclarer: declarerSeat == seat,
            isActingSeat: actingSeat == seat,
            screenshotReviewMode: screenshotReviewMode,
            isDecisionTimeVisible: isDecisionTimeVisible(seat),
            holding: { holding(seat, $0) },
            onCommit: { suit, value in onCommit(seat, suit, value) },
            onVisibilityChange: { onVisibilityChange(seat, $0) }
        )
        .frame(width: 136)
        .frame(minHeight: 82)
    }

}

private struct HandEntryCard: View {
    let seat: Seat
    let isDeclarer: Bool
    let isActingSeat: Bool
    let screenshotReviewMode: Bool
    let isDecisionTimeVisible: Bool
    let holding: (Suit) -> String
    let onCommit: (Suit, String) -> String?
    let onVisibilityChange: (Bool) -> Void
    @State private var editingSuit: Suit?
    @State private var editValue = ""
    @State private var editError: String?
    @FocusState private var editorIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(compassLetter)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(BridgePalette.muted)
                Text(seat.chineseName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                if isDeclarer {
                    roleBadge("庄", tint: BridgePalette.green)
                } else if isActingSeat {
                    roleBadge("行动", tint: BridgePalette.ink)
                }
                Spacer(minLength: 0)
                if screenshotReviewMode {
                    Toggle("当时可见", isOn: Binding(
                        get: { isDecisionTimeVisible },
                        set: onVisibilityChange
                    ))
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                    .controlSize(.mini)
                    .help("当时可见")
                    .accessibilityLabel("\(seat.chineseName) 在当前决策时可见")
                }
            }
            ForEach(Suit.allCases, id: \.self) { suit in
                holdingRow(suit)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
        .onChange(of: editorIsFocused) { _, isFocused in
            if !isFocused, editingSuit != nil {
                cancelEditing()
            }
        }
    }

    @ViewBuilder
    private func holdingRow(_ suit: Suit) -> some View {
        if editingSuit == suit {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    suitSymbol(suit)
                    TextField("牌点", text: $editValue)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .textFieldStyle(.plain)
                        .focused($editorIsFocused)
                        .accessibilityLabel("\(seat.chineseName) \(suit.chineseName) 编辑")
                        .accessibilityIdentifier("hand-edit-\(seat.rawValue)-\(suit.rawValue)")
                        .onSubmit(commitEditing)
                        .onKeyPress(.escape) {
                            cancelEditing()
                            return .handled
                        }
                        .padding(.horizontal, 4)
                        .frame(minHeight: 18)
                        .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(BridgePalette.green.opacity(0.55), lineWidth: 1))
                }
                Text(editError ?? "Enter 保存 · Esc 取消 · - 空门")
                    .font(.system(size: 8, weight: editError == nil ? .regular : .medium))
                    .foregroundStyle(editError == nil ? BridgePalette.muted : BridgePalette.warning)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(editError == nil ? "hand-edit-hint" : "hand-edit-error")
            }
        } else {
            Button {
                beginEditing(suit)
            } label: {
                HStack(spacing: 5) {
                    suitSymbol(suit)
                    Text(displayHolding(holding(suit)))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(holdingColor(holding(suit)))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 13, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("编辑\(seat.chineseName)\(suit.chineseName)；\(accessibilityHolding(holding(suit)))")
            .accessibilityIdentifier("hand-row-\(seat.rawValue)-\(suit.rawValue)")
        }
    }

    private func suitSymbol(_ suit: Suit) -> some View {
        Text(suit.symbol)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(suit == .hearts || suit == .diamonds ? BridgePalette.red : BridgePalette.ink)
            .frame(width: 13, alignment: .leading)
    }

    private func roleBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 7, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(tint.opacity(0.1), in: Capsule())
    }

    private var compassLetter: String {
        switch seat {
        case .north: "N"
        case .east: "E"
        case .south: "S"
        case .west: "W"
        }
    }

    private func displayHolding(_ raw: String) -> String {
        let cleaned = raw.uppercased().filter { !$0.isWhitespace && $0 != "," && $0 != ";" }
        if cleaned.isEmpty { return "未知" }
        if cleaned == "-" || cleaned == "—" || cleaned == "VOID" { return "—" }
        return cleaned.replacingOccurrences(of: "T", with: "10")
    }

    private func holdingColor(_ raw: String) -> Color {
        displayHolding(raw) == "未知" || isConfirmedVoid(raw)
            ? BridgePalette.muted
            : BridgePalette.ink
    }

    private func accessibilityHolding(_ raw: String) -> String {
        isConfirmedVoid(raw) ? "已确认空门" : displayHolding(raw)
    }

    private func isConfirmedVoid(_ raw: String) -> Bool {
        let cleaned = raw.uppercased().filter { !$0.isWhitespace && $0 != "," && $0 != ";" }
        return cleaned == "-" || cleaned == "—" || cleaned == "VOID"
    }

    private func beginEditing(_ suit: Suit) {
        editValue = holding(suit)
        editError = nil
        editingSuit = suit
        editorIsFocused = true
    }

    private func commitEditing() {
        guard let suit = editingSuit else { return }
        if let error = onCommit(suit, editValue) {
            editError = error
            editorIsFocused = true
        } else {
            editingSuit = nil
            editError = nil
            editorIsFocused = false
        }
    }

    private func cancelEditing() {
        editingSuit = nil
        editError = nil
        editorIsFocused = false
    }
}

private struct ScreenshotImagePreview: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("原始截图")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding(14)
            .background(.regularMaterial)
            if let image = NSImage(contentsOf: url) {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 1100, maxHeight: 1800)
                        .padding(14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BridgePalette.canvas)
            } else {
                ContentUnavailableView("无法显示截图", systemImage: "photo.badge.exclamationmark")
            }
        }
        .preferredColorScheme(.light)
    }
}

private struct ScreenshotRecognitionPresentation {
    let message: String
    let buttonTitle: String
    let isFailure: Bool

    init(state: ScreenshotRecognitionState, model: String) {
        switch state {
        case .idle:
            message = "原图和识别候选分开保存；计划只会使用你勾选并确认的决策时信息。"
            buttonTitle = "识别截图"
            isFailure = false
        case .recognizing:
            message = "正在通过独立 Codex 会话读取截图。识别会查看整张图，但不会自动决定哪些信息在当时可见。"
            buttonTitle = "识别截图"
            isFailure = false
        case .succeeded:
            message = "\(model) 的牌面、叫牌与局况均为待核对候选；请编辑左侧表单并明确确认后再发送。"
            buttonTitle = "候选已生成"
            isFailure = false
        case .stale:
            message = "识别期间牌面已改变；迟到的结果已丢弃。确认当前输入后可重新识别。"
            buttonTitle = "重试识别"
            isFailure = false
        case let .failed(errorMessage):
            message = "截图识别失败：\(errorMessage) 输入仍保留，可重试。"
            buttonTitle = "重试识别"
            isFailure = true
        }
    }
}

private struct TeachingPanel: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @ObservedObject var workflow: DeclarerPlanWorkflow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeading("做庄教学", subtitle: "基于本次输入的决策时信息生成。")
            Divider().overlay(BridgePalette.border).padding(.top, 16)
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16) {
                    if workflow.planAnalyses.isEmpty {
                        switch workflow.state {
                        case .idle, .succeeded:
                            emptyState
                        case let .invalid(message):
                            failureState(title: "请先核对输入", message: message, canRetry: false)
                        case .generating:
                            generatingState
                        case let .failed(message):
                            failureState(title: "这次没有生成计划", message: message, canRetry: model.canSendModelRequests)
                        }
                    } else {
                        switch workflow.state {
                        case .generating:
                            generatingState
                        case let .invalid(message):
                            failureState(title: "请先核对输入", message: message, canRetry: false)
                        case let .failed(message):
                            failureState(title: "这次没有生成计划", message: message, canRetry: model.canSendModelRequests)
                        case .idle, .succeeded:
                            EmptyView()
                        }
                        ForEach(Array(workflow.planAnalyses.reversed())) { analysis in
                            planSection(analysis)
                        }
                    }
                    followUpComposer
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
    }

    private var generatingState: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView()
                .controlSize(.regular)
                .tint(BridgePalette.green)
            Text("正在通过 Codex 请求真实教学响应…")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(BridgePalette.ink)
            Text("此请求只包含左侧明确录入的可见牌和补充事实。")
                .font(.system(size: 12))
                .foregroundStyle(BridgePalette.muted)
        }
        .padding(.top, 12)
    }

    private func planSection(_ analysis: DeclarerPlanAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(analysis.id == workflow.planAnalyses.last?.id ? "做庄计划" : "历史计划")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                Spacer()
                if workflow.isOutdated(analysis) {
                    Label("基于旧信息 · 已过期", systemImage: "arrow.trianglehead.2.clockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BridgePalette.warning)
                } else if analysis.id != workflow.planAnalyses.last?.id {
                    Text("较早的计划")
                        .font(.system(size: 10))
                        .foregroundStyle(BridgePalette.muted)
                }
            }
            response(analysis.response)
            ForEach(workflow.followUpExchanges.filter { $0.planID == analysis.id }) { exchange in
                followUpCard(exchange)
            }
        }
    }

    private func followUpCard(_ exchange: DeclarerFollowUpExchange) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("追问")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BridgePalette.green)
                Spacer()
                if workflow.isOutdated(exchange) {
                    Text(
                        exchange.informationVersion == workflow.informationVersion
                            ? "依赖旧计划 · 已过期"
                            : "基于旧信息 · 已过期"
                    )
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BridgePalette.warning)
                }
            }
            Text(exchange.question)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BridgePalette.ink)
            if let assumptions = exchange.assumptions {
                Text("条件假设（未确认）：\(assumptions)")
                    .font(.system(size: 11))
                    .foregroundStyle(BridgePalette.muted)
            }

            switch exchange.status {
            case .sending:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("正在生成追问回答…")
                        .font(.system(size: 12))
                        .foregroundStyle(BridgePalette.muted)
                }
            case let .answered(answer):
                AnalysisMarkdownView(source: answer.text)
                CodexRequestProvenanceLine(
                    model: answer.model,
                    requestedModel: answer.requestedModel,
                    effort: answer.reasoningEffort
                )
            case let .failed(message):
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(BridgePalette.warning)
                    .textSelection(.enabled)
                if workflow.canRetry(exchange), model.canSendModelRequests {
                    Button("重试这条追问") {
                        Task { await model.retryFollowUp(exchange.id) }
                    }
                    .buttonStyle(.bordered)
                    .tint(BridgePalette.green)
                }
            case .outdated:
                Text(exchange.informationVersion == workflow.informationVersion
                    ? "计划已被替代；原回答保留在历史中。可围绕新计划再次追问。"
                    : "信息已修正；原请求已作废。重新生成计划后，可围绕新计划再次追问。")
                    .font(.system(size: 12))
                    .foregroundStyle(BridgePalette.muted)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
    }

    private var followUpComposer: some View {
        Group {
            if workflow.result != nil {
                Divider().overlay(BridgePalette.border).padding(.vertical, 12)
                VStack(alignment: .leading, spacing: 8) {
                    Text("围绕当前计划追问")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BridgePalette.ink)
                    HStack(alignment: .bottom, spacing: 8) {
                        VStack(spacing: 7) {
                            TextField("追问当前计划的理由或路线…", text: followUpQuestionBinding, axis: .vertical)
                                .lineLimit(1...3)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("follow-up-question")
                            TextField("条件假设（可选；不会记作已确认事实）", text: followUpAssumptionsBinding, axis: .vertical)
                                .lineLimit(1...2)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("follow-up-assumptions")
                        }
                        Button {
                            Task { await model.sendFollowUp() }
                        } label: {
                            Label("发送", systemImage: "arrow.up.circle.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BridgePalette.green)
                        .disabled(!model.canSendModelRequests || !workflow.canFollowUp || followUpQuestionBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("send-follow-up")
                    }
                    if workflow.resultIsOutdated {
                        Label("信息已修正；先重新生成做庄计划，再继续追问。", systemImage: "arrow.trianglehead.2.clockwise")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BridgePalette.warning)
                    }
                }
            }
        }
    }

    private var followUpQuestionBinding: Binding<String> {
        Binding(get: { workflow.followUpQuestion }, set: model.setFollowUpQuestion)
    }

    private var followUpAssumptionsBinding: Binding<String> {
        Binding(get: { workflow.followUpAssumptions }, set: model.setFollowUpAssumptions)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(BridgePalette.green)
                .padding(12)
                .background(BridgePalette.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            Text("你的做庄计划会显示在这里")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(BridgePalette.ink)
            Text("填入定约、庄家手牌和其他当时可见的信息，然后生成一份具体路线。未录入的牌会作为未知处理。")
                .font(.system(size: 13))
                .foregroundStyle(BridgePalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 470, alignment: .leading)
            if !model.canSendModelRequests {
                Label("请从顶栏打开模型与连接设置。", systemImage: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BridgePalette.muted)
            }
        }
        .padding(.top, 14)
    }

    private func response(_ result: DeclarerPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(BridgePalette.green)
                Text("Codex 实时响应")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                if let modelName = result.model, !modelName.isEmpty {
                    Text(modelName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(BridgePalette.muted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(BridgePalette.soft, in: Capsule())
                }
            }
            AnalysisMarkdownView(source: result.text)
            CodexRequestProvenanceLine(
                model: result.model,
                requestedModel: result.requestedModel,
                effort: result.reasoningEffort
            )
            if let runtimeVersion = result.runtimeVersion {
                Text("Codex CLI \(runtimeVersion) · ChatGPT 登录")
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.muted)
                    .padding(.top, 5)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BridgePalette.soft.opacity(0.68), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
    }

    private func failureState(title: String, message: String, canRetry: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BridgePalette.warning)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(BridgePalette.ink)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Text("牌面和问题仍保留在左侧。检查原因后可以重试。")
                .font(.system(size: 11))
                .foregroundStyle(BridgePalette.muted)
            if canRetry {
                Button("重试") { Task { await model.generatePlan() } }
                    .buttonStyle(.bordered)
                    .tint(BridgePalette.green)
                    .padding(.top, 2)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BridgePalette.warning.opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(BridgePalette.warning.opacity(0.17), lineWidth: 1))
    }
}

private struct KeyPlayTeachingPanel: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @ObservedObject var workflow: KeyPlayAnalysisWorkflow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeading("关键出牌分析", subtitle: "只分析当前这一步；与整副做庄计划分开。")
            Divider().overlay(BridgePalette.border).padding(.top, 16)
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16) {
                    if workflow.resultIsOutdated {
                        Label("分析时点或共用牌面已改变；旧讲解不适用于当前输入。", systemImage: "arrow.trianglehead.2.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BridgePalette.warning)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BridgePalette.warning.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    switch workflow.state {
                    case .idle:
                        if let result = workflow.result {
                            response(result)
                        } else {
                            emptyState
                        }
                    case let .invalid(message):
                        failureState(title: "请先核对关键节点", message: message, canRetry: false)
                        if let result = workflow.result { response(result) }
                    case .generating:
                        generatingState
                        if let result = workflow.result { response(result) }
                    case .succeeded:
                        if let result = workflow.result { response(result) } else { emptyState }
                    case let .failed(message):
                        failureState(title: "这次没有生成关键出牌分析", message: message, canRetry: model.canSendModelRequests)
                        if let result = workflow.result { response(result) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(BridgePalette.green)
                .padding(12)
                .background(BridgePalette.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            Text("这一步的讲解会显示在这里")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(BridgePalette.ink)
            Text("确认分析时点、轮到谁行动、本墩已出牌和剩余可见手牌。可列出你想比较的牌；若信息不足以判断合法性，先补充当前节点。")
                .font(.system(size: 13))
                .foregroundStyle(BridgePalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 470, alignment: .leading)
        }
        .padding(.top, 14)
    }

    private var generatingState: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView()
                .controlSize(.regular)
                .tint(BridgePalette.green)
            Text("正在通过 Codex 分析当前出牌节点…")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(BridgePalette.ink)
            Text("请求仅包含共享的已确认牌面、本节点和决策时历史；未知信息不会补造。")
                .font(.system(size: 12))
                .foregroundStyle(BridgePalette.muted)
        }
        .padding(.top, 12)
    }

    private func response(_ result: DeclarerPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(BridgePalette.green)
                Text("Codex 实时响应 · 教学推理，未经 DDS 核验")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                if let modelName = result.model, !modelName.isEmpty {
                    Text(modelName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(BridgePalette.muted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(BridgePalette.soft, in: Capsule())
                }
            }
            AnalysisMarkdownView(source: result.text)
            CodexRequestProvenanceLine(
                model: result.model,
                requestedModel: result.requestedModel,
                effort: result.reasoningEffort
            )
            if let runtimeVersion = result.runtimeVersion {
                Text("Codex CLI \(runtimeVersion) · ChatGPT 登录")
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BridgePalette.soft.opacity(0.68), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
    }

    private func failureState(title: String, message: String, canRetry: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BridgePalette.warning)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(BridgePalette.ink)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Text("节点和牌面仍保留在左侧。补充缺失信息后可以重新分析。")
                .font(.system(size: 11))
                .foregroundStyle(BridgePalette.muted)
            if canRetry {
                Button("重试") { Task { await model.generate(mode: .keyPlayAnalysis) } }
                    .buttonStyle(.bordered)
                    .tint(BridgePalette.green)
                    .padding(.top, 2)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BridgePalette.warning.opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(BridgePalette.warning.opacity(0.17), lineWidth: 1))
    }
}

private func panelHeading(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(BridgePalette.ink)
        Text(subtitle)
            .font(.system(size: 12))
            .foregroundStyle(BridgePalette.muted)
    }
}

enum BridgePalette {
    static let canvas = Color(red: 0.952, green: 0.964, blue: 0.951)
    static let soft = Color(red: 0.967, green: 0.972, blue: 0.961)
    static let border = Color(red: 0.874, green: 0.894, blue: 0.864)
    static let ink = Color(red: 0.16, green: 0.22, blue: 0.18)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.44)
    static let green = Color(red: 0.20, green: 0.40, blue: 0.28)
    static let red = Color(red: 0.70, green: 0.24, blue: 0.23)
    static let orange = Color(red: 0.76, green: 0.37, blue: 0.11)
    static let suitGreen = Color(red: 0.20, green: 0.48, blue: 0.28)
    static let purple = Color(red: 0.43, green: 0.32, blue: 0.66)
    static let amber = Color(red: 0.77, green: 0.52, blue: 0.14)
    static let warning = Color(red: 0.67, green: 0.39, blue: 0.11)

    static func contractColor(for strain: ContractStrain) -> Color {
        switch strain {
        case .spades: ink
        case .hearts: red
        case .diamonds: orange
        case .clubs: suitGreen
        case .noTrump: purple
        }
    }

    static func contractBackground(for strain: ContractStrain) -> Color {
        switch strain {
        case .spades: Color(red: 0.94, green: 0.95, blue: 0.94)
        case .hearts: Color(red: 0.99, green: 0.92, blue: 0.92)
        case .diamonds: Color(red: 0.99, green: 0.94, blue: 0.88)
        case .clubs: Color(red: 0.92, green: 0.96, blue: 0.92)
        case .noTrump: Color(red: 0.95, green: 0.93, blue: 0.98)
        }
    }
}
