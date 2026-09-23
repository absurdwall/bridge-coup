import SwiftUI
import BridgeTeacherCore

@main
struct BridgeTeacherMacApp: App {
    var body: some Scene {
        WindowGroup {
            BridgeTeacherWorkspaceView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1320, height: 900)
    }
}

struct BridgeTeacherWorkspaceView: View {
    @StateObject private var model = BridgeTeacherApplicationModel()
    @State private var teachingMode: TeachingMode = .declarerPlan

    var body: some View {
        VStack(spacing: 18) {
            header

            HStack(alignment: .top, spacing: 18) {
                DeclarerEntryPanel(
                    model: model,
                    workflow: model.workflow,
                    keyPlayWorkflow: model.keyPlayWorkflow,
                    mode: teachingModeBinding
                )
                    .frame(minWidth: 560, maxWidth: 600, maxHeight: .infinity)
                if teachingMode == .declarerPlan {
                    TeachingPanel(model: model, workflow: model.workflow)
                        .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    KeyPlayTeachingPanel(model: model, workflow: model.keyPlayWorkflow)
                        .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 1180, minHeight: 790)
        .background(BridgePalette.canvas.ignoresSafeArea())
        .preferredColorScheme(.light)
        .task { await model.bootstrap() }
    }

    private var teachingModeBinding: Binding<TeachingMode> {
        Binding(
            get: { teachingMode },
            set: { newMode in
                guard teachingMode != newMode else { return }
                teachingMode = newMode
                model.keyPlayWorkflow.invalidate()
            }
        )
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("桥牌复盘")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(BridgePalette.ink)
                Text("\(teachingMode.title) · 决策时信息 · IMP")
                    .font(.system(size: 13))
                    .foregroundStyle(BridgePalette.muted)
            }
            Spacer()
            HStack(spacing: 9) {
                Circle()
                    .fill(model.connectionStatus.isSignedIn ? BridgePalette.green : BridgePalette.amber)
                    .frame(width: 8, height: 8)
                Text(model.connectionStatus.message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BridgePalette.ink)
                    .lineLimit(1)
                    .frame(maxWidth: 360, alignment: .leading)

                if model.connectionStatus.isSignedIn {
                    Button("检查登录") {
                        Task { await model.checkLogin() }
                    }
                    .disabled(model.isConnecting)
                    Button("重新登录") {
                        Task { await model.connectToChatGPT() }
                    }
                    .disabled(model.isStartingLogin)
                } else if case .awaitingLogin = model.connectionStatus {
                    Button("检查登录") {
                        Task { await model.checkLogin() }
                    }
                    .disabled(model.isConnecting)
                    Button("重开登录") {
                        Task { await model.connectToChatGPT() }
                    }
                    .disabled(model.isStartingLogin)
                } else if model.connectionStatus.runtimeVersion != nil {
                    Button("连接 ChatGPT") {
                        Task { await model.connectToChatGPT() }
                    }
                    .disabled(model.isStartingLogin)
                }

                Button("选择 Codex") {
                    model.chooseRuntime()
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(.white.opacity(0.82), in: Capsule())
            .overlay(Capsule().stroke(BridgePalette.border, lineWidth: 1))
        }
    }
}

private struct DeclarerEntryPanel: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @ObservedObject var workflow: DeclarerPlanWorkflow
    @ObservedObject var keyPlayWorkflow: KeyPlayAnalysisWorkflow
    @Binding var mode: TeachingMode

    private let seatColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeading("牌面与问题", subtitle: "两种教学共用这份已确认的牌面。")
            modePicker
                .padding(.top, 14)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    contractFields
                    visibleHands
                    if mode == .declarerPlan {
                        contextFields
                    } else {
                        keyPlayFields
                    }
                    if let warning = inputWarning {
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BridgePalette.warning)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("hand-validation-warning")
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 8)
            }

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
                        Text(activeGenerationState == .generating ? "正在生成…" : mode == .declarerPlan ? "生成做庄计划" : "分析这一步")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 170)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(BridgePalette.green)
                .disabled(!model.connectionStatus.isSignedIn || activeGenerationState == .generating)
                .accessibilityIdentifier(mode == .declarerPlan ? "generate-declarer-plan" : "generate-key-play-analysis")
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
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

    private var contractFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("定约背景")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BridgePalette.ink)
            HStack(spacing: 12) {
                Picker("庄家", selection: draftBinding(for: \.declarerSeat)) {
                    ForEach(Seat.allCases, id: \.self) { seat in
                        Text(seat.chineseName).tag(seat)
                    }
                }
                .frame(maxWidth: 150)
                Picker("阶数", selection: draftBinding(for: \.contractLevel)) {
                    Text("选择").tag(Int?.none)
                    ForEach(1...7, id: \.self) { level in
                        Text("\(level) 阶").tag(Optional(level))
                    }
                }
                .frame(maxWidth: 125)
                Picker("将牌", selection: draftBinding(for: \.contractStrain)) {
                    Text("选择").tag(ContractStrain?.none)
                    ForEach(ContractStrain.allCases, id: \.self) { strain in
                        Text(strain.symbol).tag(Optional(strain))
                    }
                }
                .frame(maxWidth: 100)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            TextField("首攻（可选，例如 ♠2）", text: draftBinding(for: \.openingLead))
                .textFieldStyle(.roundedBorder)
        }
        .padding(14)
        .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var visibleHands: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(mode == .declarerPlan ? "当时可见手牌" : "决策时剩余可见手牌")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                Spacer()
                Text("留空 = 未知")
                    .font(.system(size: 11))
                    .foregroundStyle(BridgePalette.muted)
            }
            LazyVGrid(columns: seatColumns, spacing: 12) {
                ForEach(Seat.allCases, id: \.self) { seat in
                    HandEntryCard(
                        seat: seat,
                        isDeclarer: workflow.draft.declarerSeat == seat,
                        isActingSeat: mode == .keyPlayAnalysis && keyPlayWorkflow.draft.actingSeat == seat,
                        binding: { seat, suit in holdingBinding(seat: seat, suit: suit) }
                    )
                }
            }
            Text("按花色录入已知牌：A K Q J 10 和 2–9。输入 “-” 表示已确认缺门。")
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

    private func holdingBinding(seat: Seat, suit: Suit) -> Binding<String> {
        Binding(
            get: { workflow.draft.hands[seat]?[suit] ?? "" },
            set: { value in
                var draft = workflow.draft
                draft.hands[seat, default: [:]][suit] = value
                model.updateReviewDraft(draft)
            }
        )
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

private struct HandEntryCard: View {
    let seat: Seat
    let isDeclarer: Bool
    let isActingSeat: Bool
    let binding: (Seat, Suit) -> Binding<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(seat.chineseName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                if isDeclarer {
                    Text("庄家")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(BridgePalette.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(BridgePalette.green.opacity(0.1), in: Capsule())
                }
                if isActingSeat {
                    Text("行动")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(BridgePalette.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(BridgePalette.border.opacity(0.55), in: Capsule())
                }
            }
            HStack(spacing: 4) {
                ForEach(Suit.allCases, id: \.self) { suit in
                    VStack(spacing: 3) {
                        Text(suit.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(suit == .hearts || suit == .diamonds ? BridgePalette.red : BridgePalette.ink)
                        TextField("·", text: binding(seat, suit))
                            .font(.system(size: 11, design: .monospaced))
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .frame(width: 48, height: 25)
                            .background(.white, in: RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(BridgePalette.border, lineWidth: 1))
                            .accessibilityLabel("\(seat.chineseName) \(suit.chineseName) 已知牌")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(BridgePalette.soft.opacity(0.78), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
    }
}

private struct TeachingPanel: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @ObservedObject var workflow: DeclarerPlanWorkflow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeading("做庄教学", subtitle: "基于本次输入的决策时信息生成。")
            Divider().overlay(BridgePalette.border).padding(.top, 16)
            ScrollView {
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
                            failureState(title: "这次没有生成计划", message: message, canRetry: model.connectionStatus.isSignedIn)
                        }
                    } else {
                        switch workflow.state {
                        case .generating:
                            generatingState
                        case let .invalid(message):
                            failureState(title: "请先核对输入", message: message, canRetry: false)
                        case let .failed(message):
                            failureState(title: "这次没有生成计划", message: message, canRetry: model.connectionStatus.isSignedIn)
                        case .idle, .succeeded:
                            EmptyView()
                        }
                        ForEach(Array(workflow.planAnalyses.reversed())) { analysis in
                            planSection(analysis)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }
            followUpComposer
        }
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
                Text(answer.text)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .foregroundStyle(BridgePalette.ink)
                    .textSelection(.enabled)
            case let .failed(message):
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(BridgePalette.warning)
                    .textSelection(.enabled)
                if workflow.canRetry(exchange), model.connectionStatus.isSignedIn {
                    Button("重试这条追问") {
                        Task { await workflow.retryFollowUp(exchange.id) }
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
                            Task { await workflow.sendFollowUp() }
                        } label: {
                            Label("发送", systemImage: "arrow.up.circle.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BridgePalette.green)
                        .disabled(!model.connectionStatus.isSignedIn || !workflow.canFollowUp || followUpQuestionBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        Binding(get: { workflow.followUpQuestion }, set: workflow.setFollowUpQuestion)
    }

    private var followUpAssumptionsBinding: Binding<String> {
        Binding(get: { workflow.followUpAssumptions }, set: workflow.setFollowUpAssumptions)
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
            if case .runtimeMissing = model.connectionStatus {
                Button("选择 Codex runtime") { model.chooseRuntime() }
                    .padding(.top, 5)
            } else if case .needsLogin = model.connectionStatus {
                Button("连接 ChatGPT") { Task { await model.connectToChatGPT() } }
                    .padding(.top, 5)
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
            Text(result.text)
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(BridgePalette.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
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
            } else if case .failed = model.connectionStatus {
                Button("检查 ChatGPT 登录") { Task { await model.checkLogin() } }
                    .buttonStyle(.bordered)
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
            ScrollView {
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
                        failureState(title: "这次没有生成关键出牌分析", message: message, canRetry: model.connectionStatus.isSignedIn)
                        if let result = workflow.result { response(result) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }
        }
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
            Text(result.text)
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(BridgePalette.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
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
            } else if case .failed = model.connectionStatus {
                Button("检查 ChatGPT 登录") { Task { await model.checkLogin() } }
                    .buttonStyle(.bordered)
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

private enum BridgePalette {
    static let canvas = Color(red: 0.952, green: 0.964, blue: 0.951)
    static let soft = Color(red: 0.967, green: 0.972, blue: 0.961)
    static let border = Color(red: 0.874, green: 0.894, blue: 0.864)
    static let ink = Color(red: 0.16, green: 0.22, blue: 0.18)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.44)
    static let green = Color(red: 0.20, green: 0.40, blue: 0.28)
    static let red = Color(red: 0.70, green: 0.24, blue: 0.23)
    static let amber = Color(red: 0.77, green: 0.52, blue: 0.14)
    static let warning = Color(red: 0.67, green: 0.39, blue: 0.11)
}
