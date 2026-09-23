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

    var body: some View {
        VStack(spacing: 18) {
            header

            HStack(alignment: .top, spacing: 18) {
                DeclarerEntryPanel(model: model, workflow: model.workflow)
                    .frame(minWidth: 560, maxWidth: 600, maxHeight: .infinity)
                TeachingPanel(model: model, workflow: model.workflow)
                    .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(24)
        .frame(minWidth: 1180, minHeight: 790)
        .background(BridgePalette.canvas.ignoresSafeArea())
        .preferredColorScheme(.light)
        .task { await model.bootstrap() }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("桥牌复盘")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(BridgePalette.ink)
                Text("做庄计划 · 决策时信息 · IMP")
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

    private let seatColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeading("牌面与问题", subtitle: "只录入你在这个决策点已经看到的内容。")
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    contractFields
                    visibleHands
                    contextFields
                    if let warning = handWarning {
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
                    Task { await model.generatePlan() }
                } label: {
                    HStack(spacing: 8) {
                        if workflow.state == .generating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(workflow.state == .generating ? "正在生成…" : "生成做庄计划")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 170)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(BridgePalette.green)
                .disabled(!model.connectionStatus.isSignedIn || workflow.state == .generating)
                .accessibilityIdentifier("generate-declarer-plan")
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
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
                Text("当时可见手牌")
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
            Text("补充决策时信息")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BridgePalette.ink)
            TextEditor(text: draftBinding(for: \.otherDecisionTimeFacts))
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .padding(7)
                .frame(minHeight: 82)
                .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    if workflow.draft.otherDecisionTimeFacts.isEmpty {
                        Text("叫牌、已经发生的出牌或其他影响这一步判断的事实…")
                            .font(.system(size: 12))
                            .foregroundStyle(BridgePalette.muted.opacity(0.75))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
            TextField("你最想弄清楚什么？", text: draftBinding(for: \.question))
                .textFieldStyle(.roundedBorder)
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
                workflow.updateDraft(draft)
            }
        )
    }

    private func holdingBinding(seat: Seat, suit: Suit) -> Binding<String> {
        Binding(
            get: { workflow.draft.hands[seat]?[suit] ?? "" },
            set: { value in
                var draft = workflow.draft
                draft.hands[seat, default: [:]][suit] = value
                workflow.updateDraft(draft)
            }
        )
    }
}

private struct HandEntryCard: View {
    let seat: Seat
    let isDeclarer: Bool
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
                    Text("旧信息版本 · 已过期")
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
                Text("信息修正前的请求已作废。重新生成计划后，可围绕新计划再次追问。")
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
