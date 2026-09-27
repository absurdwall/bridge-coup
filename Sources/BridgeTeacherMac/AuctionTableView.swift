import BridgeTeacherCore
import SwiftUI

typealias AuctionCallInk = AuctionCallDisplayTone

extension AuctionCallDisplayTone {
    static func forCall(_ call: AuctionCall) -> Self {
        call.display.tone
    }

    var foreground: Color {
        switch self {
        case .neutral: BridgePalette.ink
        case .pass: BridgePalette.green
        case .clubs: BridgePalette.suitGreen
        case .diamonds: BridgePalette.orange
        case .hearts: BridgePalette.red
        case .spades: BridgePalette.ink
        case .noTrump: BridgePalette.purple
        }
    }

    var background: Color {
        switch self {
        case .neutral: BridgePalette.soft
        case .pass: BridgePalette.green.opacity(0.08)
        case .clubs: BridgePalette.contractBackground(for: .clubs)
        case .diamonds: BridgePalette.contractBackground(for: .diamonds)
        case .hearts: BridgePalette.contractBackground(for: .hearts)
        case .spades: BridgePalette.contractBackground(for: .spades)
        case .noTrump: BridgePalette.contractBackground(for: .noTrump)
        }
    }
}

struct AuctionTableCellPresentation: Equatable {
    enum Content: Equatable {
        case layoutBlank
        case call(id: UUID, text: String, ink: AuctionCallInk, hasMeaningNote: Bool)
    }

    let seat: Seat?
    let content: Content
}

struct AuctionTablePresentation: Equatable {
    let rows: [[AuctionTableCellPresentation]]?

    init(record: AuctionRecord) {
        guard let layoutRows = record.layoutRows else {
            rows = nil
            return
        }

        rows = layoutRows.map { row in
            Seat.allCases.map { seat in
                switch row[seat] {
                case .layoutBlank:
                    AuctionTableCellPresentation(seat: seat, content: .layoutBlank)
                case let .entry(entry):
                    AuctionTableCellPresentation(
                        seat: seat,
                        content: .call(
                            id: entry.id,
                            text: entry.call.displayText,
                            ink: .forCall(entry.call),
                            hasMeaningNote: !(entry.meaningNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                        )
                    )
                }
            }
        }
    }
}

struct AuctionTableView: View {
    static let compactTableMaxHeight: CGFloat = 124

    @Binding var record: AuctionRecord?
    let onSaveMeaningNote: (UUID, String?) -> Void

    @State private var isExpanded = false
    @State private var newBidLevel = 1
    @State private var newBidStrain: ContractStrain = .clubs

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if record?.kind == .calls, record?.isPartial == true {
                Label("部分叫牌片段 · 不推断省略叫品或座位", systemImage: "ellipsis")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BridgePalette.warning)
                    .accessibilityIdentifier("auction-partial-transcript-marker")
            }
            recordContent()
        }
        .sheet(isPresented: $isExpanded) {
            expandedEditor
        }
    }

    @ViewBuilder
    private func recordContent() -> some View {
        if let record {
            if record.kind == .noAuction {
                HStack(spacing: 8) {
                    Label("已确认本局无叫牌", systemImage: "minus.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(BridgePalette.muted)
                    Spacer()
                    Button("改为录入叫牌") {
                        self.record = AuctionRecord()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: .medium))
                    .accessibilityIdentifier("start-auction-entry")
                }
            } else {
                if record.entries.isEmpty {
                    HStack(spacing: 8) {
                        Text("空白记录：尚无已确认叫品。可直接生成计划，或继续录入。")
                            .font(.system(size: 10))
                            .foregroundStyle(BridgePalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Button {
                            isExpanded = true
                        } label: {
                            Label("展开录入", systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 10, weight: .medium))
                        .accessibilityIdentifier("auction-expand")
                    }
                } else {
                    HStack {
                        Spacer()
                        Button {
                            isExpanded = true
                        } label: {
                            Label("展开编辑", systemImage: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("auction-expand")
                    }
                    table(for: record, compact: true)
                }
            }
        } else {
            HStack(spacing: 8) {
                Text("未提供叫牌记录；仍可录入局况和生成计划。")
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Button {
                    isExpanded = true
                } label: {
                    Label("展开录入", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.borderless)
                .font(.system(size: 10, weight: .medium))
                .accessibilityIdentifier("auction-expand")
            }
        }
    }

    @ViewBuilder
    private func table(for record: AuctionRecord, compact: Bool) -> some View {
        let presentation = AuctionTablePresentation(record: record)
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 5) {
                if let rows = presentation.rows {
                    if !rows.isEmpty {
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                ForEach(Seat.allCases, id: \.self) { seat in
                                    Text(shortSeatName(seat))
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(BridgePalette.muted)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                HStack(spacing: 5) {
                                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                        tableCell(cell, record: record, compact: compact)
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    seatAssignmentReview(record, compact: compact)
                }
            }
        }
        .frame(maxHeight: compact ? Self.compactTableMaxHeight : .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(compact ? "auction-round-table-compact" : "auction-round-table-expanded")
    }

    @ViewBuilder
    private func tableCell(_ cell: AuctionTableCellPresentation, record: AuctionRecord, compact: Bool) -> some View {
        let cellHeight: CGFloat = compact ? 23 : 39
        switch cell.content {
        case .layoutBlank:
            Color.clear
                .frame(maxWidth: .infinity, minHeight: cellHeight)
                .accessibilityHidden(true)
        case let .call(id, _, ink, _):
            if let entry = record.entries.first(where: { $0.id == id }) {
                AuctionCallPresentation(
                    entry: entryForDisplay(entry, in: cell),
                    onSaveMeaningNote: { note in onSaveMeaningNote(id, note) },
                    onCallChange: { call in updateCall(id, call) },
                    onDelete: { deleteCall(id) }
                ) {
                    AuctionCallLabel(call: entry.call, ink: ink, minHeight: compact ? 20 : 32)
                }
                .frame(maxWidth: .infinity, minHeight: cellHeight)
                .background(ink.background, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(BridgePalette.border, lineWidth: 1))
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: cellHeight)
                    .accessibilityHidden(true)
            }
        }
    }

    private func entryForDisplay(_ entry: AuctionEntry, in cell: AuctionTableCellPresentation) -> AuctionEntry {
        guard entry.seat == nil else { return entry }
        return AuctionEntry(
            id: entry.id,
            seat: cell.seat,
            call: entry.call,
            meaningNote: entry.meaningNote
        )
    }

    private func seatAssignmentReview(_ record: AuctionRecord, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(
                record.isPartial
                    ? "部分可见片段；只保留已确认记录项顺序，不推算缺口或座位。请逐项核对位置。"
                    : record.startingSeat == nil
                        ? "叫品座位未确认；不默认北家。"
                        : "起始位置与已确认叫品座位不一致；已保留原归属，请逐项核对。",
                systemImage: "exclamationmark.circle"
            )
            .font(.system(size: 10))
            .foregroundStyle(BridgePalette.warning)

            ForEach(record.entries, id: \.id) { entry in
                HStack(spacing: 6) {
                    Text("\(entryOrdinal(entry.id, in: record) + 1)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(BridgePalette.muted)
                        .frame(width: 18, alignment: .trailing)
                    Picker(
                        record.isPartial
                            ? "记录项 \(entryOrdinal(entry.id, in: record) + 1) 位置"
                            : "第\(entryOrdinal(entry.id, in: record) + 1)次行动位置",
                        selection: entrySeatBinding(entry.id)
                    ) {
                        Text("未知位置").tag(Seat?.none)
                        ForEach(Seat.allCases, id: \.self) { seat in
                            Text(seat.chineseName).tag(Optional(seat))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: compact ? 118 : 150, alignment: .leading)
                    .accessibilityIdentifier("auction-entry-seat-\(entry.id.uuidString.lowercased())")
                    tableCell(
                        AuctionTableCellPresentation(
                            seat: entry.seat,
                            content: .call(
                                id: entry.id,
                                text: entry.call.displayText,
                                ink: .forCall(entry.call),
                                hasMeaningNote: !(entry.meaningNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                            )
                        ),
                        record: record,
                        compact: compact
                    )
                    .frame(width: compact ? 132 : 180)
                    Spacer(minLength: 0)
                }
            }
        }
        .accessibilityIdentifier("auction-seat-review")
    }

    private var addCallControls: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Text("定约")
                    .foregroundStyle(BridgePalette.muted)
                Picker("定约叫品阶数", selection: $newBidLevel) {
                    ForEach(1...7, id: \.self) { level in
                        Text("\(level)阶").tag(level)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 66)
                Picker("定约叫品花色", selection: $newBidStrain) {
                    ForEach(ContractStrain.allCases, id: \.self) { strain in
                        Text(strain.symbol).tag(strain)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 54)
                Text("预览：\(newBidLevel)\(newBidStrain.symbol)")
                    .foregroundStyle(BridgePalette.muted)
                Button("添加叫品") {
                    appendCall(.bid(level: newBidLevel, strain: newBidStrain))
                }
                .accessibilityIdentifier("add-auction-bid")
                Spacer(minLength: 0)
            }
            .font(.system(size: 10, weight: .medium))
            HStack(spacing: 5) {
                Button("Pass") { appendCall(.pass) }
                    .accessibilityIdentifier("add-auction-pass")
                Button("加倍") { appendCall(.double) }
                    .accessibilityIdentifier("add-auction-double")
                Button("再加倍") { appendCall(.redouble) }
                    .accessibilityIdentifier("add-auction-redouble")
                Button("未知叫品") { appendCall(.unknown) }
                    .accessibilityIdentifier("add-auction-unknown")
                Spacer(minLength: 0)
            }
            .font(.system(size: 10, weight: .medium))
            .buttonStyle(.bordered)
        }
    }

    private var expandedEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("叫牌记录")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                Spacer()
                Button("完成") { isExpanded = false }
                    .buttonStyle(.borderedProminent)
                    .tint(BridgePalette.green)
                    .accessibilityIdentifier("auction-collapse")
            }

            if let record {
                if record.kind == .calls {
                    Toggle(isOn: partialTranscriptBinding) {
                        Text("这是部分叫牌片段")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .toggleStyle(.checkbox)
                    .accessibilityIdentifier("auction-partial-transcript-toggle")
                    Text("只保留可见记录项，不补推缺口、Pass 或座位。启用时会清除按连续次序推算的位置，保留逐项确认的座位。")
                        .font(.system(size: 10))
                        .foregroundStyle(BridgePalette.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    if record.entries.isEmpty {
                        Text("空白记录：尚无已确认叫品；这不等于本局无叫牌。")
                            .font(.system(size: 11))
                            .foregroundStyle(BridgePalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    table(for: record, compact: false)
                        .frame(maxHeight: .infinity)
                    addCallControls
                    HStack {
                        Spacer()
                        Button("清除叫牌记录") { self.record = nil }
                            .buttonStyle(.borderless)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BridgePalette.muted)
                            .accessibilityIdentifier("clear-auction-record")
                    }
                } else {
                    Label("已确认本局无叫牌", systemImage: "minus.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(BridgePalette.muted)
                    Button("改为录入叫牌") { self.record = AuctionRecord() }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("start-auction-entry")
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("未提供叫牌记录。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BridgePalette.muted)
                    HStack {
                        Button("录入叫牌") { record = AuctionRecord() }
                            .accessibilityIdentifier("start-auction-entry")
                        Button("确认无叫牌") { record = AuctionRecord(kind: .noAuction) }
                            .accessibilityIdentifier("confirm-no-auction")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(18)
        .frame(minWidth: 600, minHeight: 570)
        .background(BridgePalette.canvas)
    }

    private func appendCall(_ call: AuctionCall) {
        var next = record ?? AuctionRecord()
        guard next.kind == .calls else { return }
        let seat = next.sequenceSeat(at: next.entries.count)
        next.entries.append(AuctionEntry(seat: seat, seatIsSequenceDerived: seat != nil, call: call))
        record = next
    }

    private var partialTranscriptBinding: Binding<Bool> {
        Binding(
            get: { record?.isPartial ?? false },
            set: { isPartial in
                guard var next = record, next.kind == .calls, next.isPartial != isPartial else { return }
                next.setIsPartial(isPartial)
                record = next
            }
        )
    }

    private func updateCall(_ id: UUID, _ call: AuctionCall) {
        guard var next = record,
              next.updateCall(forEntryID: id, to: call) else { return }
        record = next
    }

    private func deleteCall(_ id: UUID) {
        guard var next = record,
              next.removeEntry(id: id) else { return }
        record = next
    }

    private func entryOrdinal(_ id: UUID, in record: AuctionRecord) -> Int {
        record.entries.firstIndex(where: { $0.id == id }) ?? 0
    }

    private func entrySeatBinding(_ id: UUID) -> Binding<Seat?> {
        Binding(
            get: { record?.entries.first(where: { $0.id == id })?.seat },
            set: { seat in
                guard var next = record,
                      let index = next.entries.firstIndex(where: { $0.id == id }) else { return }
                next.entries[index].seat = seat
                next.entries[index].seatIsSequenceDerived = false
                record = next
            }
        )
    }

    private func shortSeatName(_ seat: Seat) -> String {
        switch seat {
        case .north: "北家"
        case .east: "东家"
        case .south: "南家"
        case .west: "西家"
        }
    }
}

private struct AuctionCallLabel: View {
    let call: AuctionCall
    let ink: AuctionCallInk
    let minHeight: CGFloat

    var body: some View {
        Text(call.displayText)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(ink.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .contentShape(Rectangle())
    }
}
