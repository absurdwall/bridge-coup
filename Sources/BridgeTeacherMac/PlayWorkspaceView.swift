import BridgeTeacherCore
import SwiftUI

/// Four balanced seats retain the accepted compact table; the corner auction
/// reuses the existing expanded editor and call notes.
struct PlayWorkspaceView: View {
    @ObservedObject var model: BridgeTeacherApplicationModel
    @ObservedObject private var results: PlayCardResultsWorkflow
    @Binding var auction: AuctionRecord?
    let onSaveMeaningNote: (UUID, String?) -> Void

    init(model: BridgeTeacherApplicationModel, auction: Binding<AuctionRecord?>, onSaveMeaningNote: @escaping (UUID, String?) -> Void) {
        self.model = model
        self.results = model.playCardResultsWorkflow
        self._auction = auction
        self.onSaveMeaningNote = onSaveMeaningNote
    }

    var body: some View {
        if let session = model.playSession {
            VStack(spacing: 8) {
                resultControls
                VStack(spacing: 12) {
                    seatCard(.north, session: session)
                    HStack(spacing: 8) {
                        seatCard(.west, session: session)
                        trickCenter(session)
                            .frame(maxWidth: .infinity)
                        seatCard(.east, session: session)
                    }
                    seatCard(.south, session: session)
                }
                .padding(10)
                .background(Color(red: 0.92, green: 0.95, blue: 0.92), in: RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    AuctionTableView(record: $auction, onSaveMeaningNote: onSaveMeaningNote, isCornerSummary: true)
                        .frame(width: 172, height: 86, alignment: .topLeading)
                        .padding(10)
                }
                HStack {
                    Text("已收 \(session.completedTricks.count) 墩 · NS \(session.northSouthTricks) · EW \(session.eastWestTricks)")
                    Spacer()
                    Button("撤销") { model.undoPlay() }
                        .disabled(!model.canUndoPlay)
                        .accessibilityIdentifier("undo-play")
                    Button("重做") { model.redoPlay() }
                        .disabled(!model.canRedoPlay)
                        .accessibilityIdentifier("redo-play")
                    Button("重走") { model.restartPlay() }
                        .accessibilityIdentifier("restart-play")
                    Button("收墩") { model.collectPlayTrick() }
                        .disabled(!session.awaitingCollection)
                        .accessibilityIdentifier("collect-play-trick")
                }
                .font(.system(size: 11))
                if let delta = session.actualContractDelta {
                    Text("实际推演：庄家 \(session.declarerTricks) 墩 · \(delta == 0 ? "=" : (delta > 0 ? "+\(delta)" : "\(delta)"))")
                        .font(.system(size: 12, weight: .semibold))
                        .accessibilityIdentifier("play-actual-result")
                }
                Text(model.playStatus).font(.system(size: 11)).foregroundStyle(BridgePalette.muted)
            }
        }
    }

    private var resultControls: some View {
        VStack(alignment: .leading, spacing: 3) {
            Toggle("逐牌结果", isOn: Binding(get: { results.isEnabled }, set: { results.setEnabled($0) }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .accessibilityIdentifier("toggle-play-card-results")
            if results.isEnabled {
                HStack(spacing: 5) {
                    if results.state == .calculating { ProgressView().controlSize(.mini) }
                    Text(resultStatus).font(.system(size: 10)).foregroundStyle(BridgePalette.muted)
                    if case .failed = results.state {
                        Button("重试") { results.retry() }.controlSize(.small)
                            .accessibilityIdentifier("retry-play-card-results")
                    }
                }
                .accessibilityIdentifier("play-card-results-status")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resultStatus: String {
        switch results.state {
        case .hidden: ""
        case .unavailable: "开始有效四手推演后显示逐牌结果。"
        case .awaitingCollection: "请先收墩，再计算下一位行动家的结果。"
        case .complete: "全副结束；下方显示实际推演结果。"
        case .calculating: "正在计算当前合法牌；旧标签已清除。"
        case .ready: "庄家定约视角：= 成约 · − 宕墩 · + 超墩；按四手最佳打法计算。"
        case let .failed(message): "计算失败：\(message)"
        }
    }

    private func seatCard(_ seat: Seat, session: BridgePlaySession) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(seat.chineseName).font(.system(size: 10, weight: .semibold))
                if seat == session.declarerSeat { Text("庄").font(.system(size: 8)) }
                Spacer(minLength: 0)
                Toggle("教学可见", isOn: Binding(
                    get: { model.workflow.draft.decisionTimeVisibleSeats?.contains(seat) ?? true },
                    set: { visible in
                        var draft = model.workflow.draft
                        var seats = draft.decisionTimeVisibleSeats ?? Set(Seat.allCases)
                        if visible { seats.insert(seat) } else { seats.remove(seat) }
                        draft.decisionTimeVisibleSeats = seats
                        model.updateReviewDraft(draft)
                    }
                ))
                .labelsHidden().toggleStyle(.checkbox).controlSize(.mini)
                .accessibilityLabel("\(seat.chineseName) 教学可见")
            }
            ForEach(Suit.allCases, id: \.self) { suit in
                HStack(spacing: 0) {
                    Text(suit.symbol).frame(width: 14, alignment: .leading)
                    let ranks = session.remainingHands[seat]?[suit] ?? []
                    if ranks.isEmpty { Text("—").foregroundStyle(BridgePalette.muted) }
                    ScrollView(.horizontal) {
                        HStack(spacing: 0) {
                            ForEach(ranks, id: \.self) { rank in
                                let card = DoubleDummyCard(suit: suit, rank: rank)
                                Button { model.playCard(card, by: seat) } label: {
                                    VStack(spacing: 0) {
                                        Text(rank.rawValue)
                                            .foregroundStyle(session.actingSeat == seat && session.legalCards.contains(card)
                                                             ? (suit == .hearts || suit == .diamonds ? BridgePalette.red : BridgePalette.ink)
                                                             : BridgePalette.muted)
                                        if let label = results.label(for: card, by: seat) {
                                            Text(label)
                                                .font(.system(size: 7, weight: .semibold, design: .monospaced))
                                                .foregroundStyle(BridgePalette.green)
                                                .accessibilityIdentifier("play-result-\(seat.rawValue)-\(suit.rawValue)-\(rank.rawValue)")
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)
                                .disabled(session.actingSeat != seat || !session.legalCards.contains(card))
                                .accessibilityLabel("\(seat.chineseName) 出 \(card.description)\(results.label(for: card, by: seat).map { "，庄家定约结果 " + $0 } ?? "")")
                                .accessibilityIdentifier("play-card-\(seat.rawValue)-\(suit.rawValue)-\(rank.rawValue)")
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .frame(height: results.isEnabled && session.actingSeat == seat && session.legalCards.contains(where: { $0.suit == suit }) ? 28 : 18)
                    Spacer(minLength: 0)
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
        }
        .padding(7)
        .frame(width: 148, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(session.actingSeat == seat ? BridgePalette.green : BridgePalette.border, lineWidth: session.actingSeat == seat ? 2 : 1))
    }

    private func trickCenter(_ session: BridgePlaySession) -> some View {
        VStack(spacing: 5) {
            Text(session.isComplete ? "全副结束" : "第 \(session.completedTricks.count + 1) 墩")
                .font(.system(size: 10))
            Text(session.actingSeat.map { "轮到\($0.chineseName)" } ?? (session.isComplete ? "实际结果" : "等待收墩"))
                .font(.system(size: 11, weight: .semibold))
            centerCard(.north, session: session)
            HStack(spacing: 8) {
                centerCard(.west, session: session)
                centerCard(.east, session: session)
            }
            centerCard(.south, session: session)
        }
        .frame(minHeight: 115)
        .accessibilityIdentifier("play-current-trick")
    }
    private func centerCard(_ seat: Seat, session: BridgePlaySession) -> some View {
        let played = session.currentTrick.first { $0.seat == seat }
        return Text("\(seat.chineseName)\n\(played?.card.description ?? "·")")
            .font(.system(size: 11, design: .monospaced))
            .multilineTextAlignment(.center)
            .frame(minWidth: 35)
    }

}
