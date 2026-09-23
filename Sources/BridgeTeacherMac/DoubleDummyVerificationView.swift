import SwiftUI
import BridgeTeacherCore

struct BridgeTeacherWorkspaceShell: View {
    @State private var isVerificationPresented = false

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text("双明手结果属于事后核验，不参与教学请求")
                    .font(.system(size: 11))
                    .foregroundStyle(VerificationPalette.muted)
                Button("事后双明手核验") {
                    isVerificationPresented = true
                }
                .buttonStyle(.bordered)
                .tint(VerificationPalette.green)
                .accessibilityIdentifier("open-double-dummy-verification")
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            BridgeTeacherWorkspaceView()
        }
        .sheet(isPresented: $isVerificationPresented) {
            DoubleDummyVerificationView()
                .frame(minWidth: 1120, minHeight: 760)
        }
    }
}

private struct DoubleDummyVerificationView: View {
    @StateObject private var workflow: DoubleDummyVerificationWorkflow
    @Environment(\.dismiss) private var dismiss
    private let suitColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    init() {
        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("bridge-dds", isDirectory: false)
        _workflow = StateObject(wrappedValue: DoubleDummyVerificationWorkflow(
            solver: BundledDDSSolver(executableURL: helperURL)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            heading
            HStack(alignment: .top, spacing: 16) {
                inputPanel
                    .frame(minWidth: 600, maxWidth: 680)
                resultPanel
                    .frame(minWidth: 390, maxWidth: .infinity)
            }
        }
        .padding(22)
        .background(VerificationPalette.canvas.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private var heading: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("双明手核验")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(VerificationPalette.ink)
                Text("假设四家手牌全知且双方都最优行牌；结果不预测普通牌桌走势，也不会写进教学上下文。")
                    .font(.system(size: 12))
                    .foregroundStyle(VerificationPalette.muted)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Label("返回教学", systemImage: "arrow.left")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("close-double-dummy-verification")
            Button {
                Task { await loadAndRunKnownDeal() }
            } label: {
                Label("运行已知结果例牌", systemImage: "checkmark.seal")
            }
            .buttonStyle(.bordered)
            .tint(VerificationPalette.green)
            .accessibilityIdentifier("run-known-double-dummy-example")
        }
    }

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("核验材料")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(VerificationPalette.ink)
            HStack(spacing: 16) {
                Picker("将牌", selection: optionalBinding(for: \.trump)) {
                    Text("选择将牌 / 无将").tag(ContractStrain?.none)
                    ForEach(ContractStrain.allCases, id: \.self) { strain in
                        Text(strain.symbol).tag(Optional(strain))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 190)
                .accessibilityIdentifier("double-dummy-trump")

                Picker("本墩领出者", selection: binding(for: \.trickLeader)) {
                    ForEach(Seat.allCases, id: \.self) { seat in
                        Text(seat.chineseName).tag(seat)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 140)
                .accessibilityIdentifier("double-dummy-trick-leader")
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: 5) {
                Text("本墩已出牌")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(VerificationPalette.muted)
                TextField("按顺序录入，例如 ♠2 ♥K；尚未出牌则留空", text: binding(for: \.currentTrickCards))
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("double-dummy-current-trick")
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("四家剩余手牌")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(VerificationPalette.ink)
                    Spacer()
                    Text("每格填牌点；缺门填 -。已出牌请从手牌中删去。")
                        .font(.system(size: 10))
                        .foregroundStyle(VerificationPalette.muted)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                    ForEach(Seat.allCases, id: \.self) { seat in
                        handCard(seat)
                    }
                }
            }

            contractFields

            HStack {
                Text("DDS \(BundledDDSSolver.solverVersion) · Apache 2.0")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(VerificationPalette.muted)
                Spacer()
                Button {
                    Task { await workflow.verify() }
                } label: {
                    HStack(spacing: 7) {
                        if workflow.state == .solving {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "function")
                        }
                        Text(workflow.state == .solving ? "正在求解…" : "验证当前局面")
                    }
                    .frame(minWidth: 142)
                }
                .buttonStyle(.borderedProminent)
                .tint(VerificationPalette.green)
                .disabled(workflow.state == .solving)
                .accessibilityIdentifier("verify-double-dummy-position")
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(VerificationPalette.border, lineWidth: 1))
    }

    private func handCard(_ seat: Seat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(seat.chineseName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VerificationPalette.ink)
            LazyVGrid(columns: suitColumns, spacing: 5) {
                ForEach(Suit.allCases, id: \.self) { suit in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suit.symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(suitColor(suit))
                        TextField("-", text: holdingBinding(seat: seat, suit: suit))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10, design: .monospaced))
                            .accessibilityIdentifier("double-dummy-\(seat.rawValue)-\(suit.rawValue)")
                    }
                }
            }
        }
        .padding(10)
        .background(VerificationPalette.soft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var contractFields: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("可选定约背景")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(VerificationPalette.ink)
                Spacer()
                Text("庄家、阶数、已得墩数填齐后才换算定约")
                    .font(.system(size: 10))
                    .foregroundStyle(VerificationPalette.muted)
            }
            HStack(spacing: 10) {
                Picker("庄家", selection: optionalBinding(for: \.declarerSeat)) {
                    Text("庄家").tag(Seat?.none)
                    ForEach(Seat.allCases, id: \.self) { seat in
                        Text(seat.chineseName).tag(Optional(seat))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 120)
                Picker("定约阶数", selection: optionalBinding(for: \.contractLevel)) {
                    Text("阶数").tag(Int?.none)
                    ForEach(1...7, id: \.self) { level in
                        Text("\(level) 阶").tag(Optional(level))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 100)
                TextField("庄家已得墩数", text: optionalIntegerBinding(for: \.declarerTricksAlreadyTaken))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 130)
                    .accessibilityIdentifier("double-dummy-declarer-tricks-taken")
            }
            .pickerStyle(.menu)
        }
    }

    private var resultPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("核验结果")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(VerificationPalette.ink)
                Spacer()
                Text("DDS \(BundledDDSSolver.solverVersion)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(VerificationPalette.muted)
            }

            statusCard

            if let validationMessage {
                Label("当前输入：\(validationMessage)", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundStyle(VerificationPalette.warning)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("double-dummy-input-reason")
            }

            if workflow.state == .verified, let result = workflow.result {
                verifiedResults(result)
            } else if workflow.state == .unverified {
                Text("确认四家牌面、将牌和本墩状态后运行 DDS。完整手牌仅用于此核验面板。")
                    .font(.system(size: 12))
                    .foregroundStyle(VerificationPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(VerificationPalette.border, lineWidth: 1))
    }

    @ViewBuilder
    private var statusCard: some View {
        switch workflow.state {
        case .unverified:
            statusLabel("尚未核验", detail: "运行 DDS 后才会显示结果。", color: VerificationPalette.muted, icon: "circle.dashed")
        case let .insufficient(message):
            statusLabel("输入不足", detail: message, color: VerificationPalette.warning, icon: "exclamationmark.triangle.fill")
        case .solving:
            statusLabel("正在求解", detail: "完整牌面已提交给本机随应用打包的 DDS。", color: VerificationPalette.green, icon: "function")
        case let .failed(message):
            statusLabel("计算失败", detail: message, color: VerificationPalette.red, icon: "xmark.octagon.fill")
        case .verified:
            statusLabel("已验证", detail: "所列结果来自 DDS \(workflow.result?.solverVersion ?? BundledDDSSolver.solverVersion)。", color: VerificationPalette.green, icon: "checkmark.circle.fill")
        case .outdated:
            statusLabel("输入已更改 · 结果过期", detail: "旧数字已清除；修正牌面后请重新运行 DDS。", color: VerificationPalette.warning, icon: "arrow.clockwise.circle")
        }
    }

    private func statusLabel(_ title: String, detail: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(VerificationPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func verifiedResults(_ result: DoubleDummyVerificationResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("行牌方：\(result.actingSeat.chineseName) · 剩余 \(result.remainingTricks) 墩（含当前未完成的一墩）")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(VerificationPalette.ink)
            Text(result.declarerSeat.map { "定约庄家：\($0.chineseName)" } ?? "未提供完整定约背景")
                .font(.system(size: 10))
                .foregroundStyle(VerificationPalette.muted)

            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(result.moves.enumerated()), id: \.offset) { _, move in
                        moveRow(move, result: result)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(result.declarerSeat == nil
                 ? "数字表示当前行牌方搭档从此局面起最多可赢得的剩余墩；不代表全副累计总墩或定约超宕。"
                 : "庄家剩余墩与全副累计墩分开显示；定约差值按 6 墩加阶数计算。")
                .font(.system(size: 10))
                .foregroundStyle(VerificationPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("double-dummy-verified-results")
    }

    private func moveRow(_ move: DoubleDummyCardComparison, result: DoubleDummyVerificationResult) -> some View {
        let cardList = move.cards.map(\.description).joined(separator: " = ")
        return HStack(alignment: .top, spacing: 8) {
            Text(cardList)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(VerificationPalette.ink)
                .frame(minWidth: 98, alignment: .leading)
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 3) {
                if let declarerRemaining = move.remainingTricksByDeclarer,
                   let declarerTotal = move.totalTricksByDeclarer,
                   let delta = move.contractDelta {
                    Text("庄家剩余 \(declarerRemaining) · 全副 \(declarerTotal)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(VerificationPalette.ink)
                    Text(contractDeltaLabel(delta))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(delta >= 0 ? VerificationPalette.green : VerificationPalette.red)
                } else {
                    Text("行牌方搭档 \(move.tricksForSideToPlay) / \(result.remainingTricks) 墩")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(VerificationPalette.ink)
                }
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(VerificationPalette.soft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var validationMessage: String? {
        do {
            _ = try DoubleDummyVerificationPositionBuilder.build(from: workflow.draft)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func contractDeltaLabel(_ delta: Int) -> String {
        if delta == 0 { return "正好成约" }
        if delta > 0 { return "超 \(delta) 墩" }
        return "宕 \(-delta) 墩"
    }

    private func loadAndRunKnownDeal() async {
        var draft = DoubleDummyVerificationDraft()
        draft.trump = .spades
        draft.trickLeader = .north
        draft.hands[.north] = [.spades: "AKQJT98765432", .hearts: "-", .diamonds: "-", .clubs: "-"]
        draft.hands[.east] = [.spades: "-", .hearts: "AKQJT", .diamonds: "AKQJ", .clubs: "AKQJ"]
        draft.hands[.south] = [.spades: "-", .hearts: "98765", .diamonds: "T987", .clubs: "T987"]
        draft.hands[.west] = [.spades: "-", .hearts: "432", .diamonds: "65432", .clubs: "65432"]
        workflow.updateDraft(draft)
        await workflow.verify()
    }

    private func binding<Value: Equatable>(for keyPath: WritableKeyPath<DoubleDummyVerificationDraft, Value>) -> Binding<Value> {
        Binding(
            get: { workflow.draft[keyPath: keyPath] },
            set: { value in
                var draft = workflow.draft
                draft[keyPath: keyPath] = value
                workflow.updateDraft(draft)
            }
        )
    }

    private func optionalBinding<Value: Equatable>(for keyPath: WritableKeyPath<DoubleDummyVerificationDraft, Value?>) -> Binding<Value?> {
        Binding(
            get: { workflow.draft[keyPath: keyPath] },
            set: { value in
                var draft = workflow.draft
                draft[keyPath: keyPath] = value
                workflow.updateDraft(draft)
            }
        )
    }

    private func optionalIntegerBinding(for keyPath: WritableKeyPath<DoubleDummyVerificationDraft, Int?>) -> Binding<String> {
        Binding(
            get: { workflow.draft[keyPath: keyPath].map(String.init) ?? "" },
            set: { rawValue in
                var draft = workflow.draft
                draft[keyPath: keyPath] = rawValue.isEmpty ? nil : Int(rawValue)
                workflow.updateDraft(draft)
            }
        )
    }

    private func holdingBinding(seat: Seat, suit: Suit) -> Binding<String> {
        Binding(
            get: { workflow.draft.hands[seat]?[suit] ?? "" },
            set: { value in
                var draft = workflow.draft
                var holdings = draft.hands[seat] ?? [:]
                holdings[suit] = value
                draft.hands[seat] = holdings
                workflow.updateDraft(draft)
            }
        )
    }

    private func suitColor(_ suit: Suit) -> Color {
        switch suit {
        case .spades, .clubs: VerificationPalette.ink
        case .hearts, .diamonds: VerificationPalette.red
        }
    }
}

private enum VerificationPalette {
    static let canvas = Color(red: 0.952, green: 0.964, blue: 0.951)
    static let soft = Color(red: 0.967, green: 0.972, blue: 0.961)
    static let border = Color(red: 0.874, green: 0.894, blue: 0.864)
    static let ink = Color(red: 0.16, green: 0.22, blue: 0.18)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.44)
    static let green = Color(red: 0.20, green: 0.40, blue: 0.28)
    static let red = Color(red: 0.70, green: 0.24, blue: 0.23)
    static let warning = Color(red: 0.67, green: 0.39, blue: 0.11)
}
