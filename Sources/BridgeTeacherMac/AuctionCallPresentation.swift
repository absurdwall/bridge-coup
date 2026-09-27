import SwiftUI
import BridgeTeacherCore

/// A reusable call-cell interaction for compact and expanded auction views.
/// Tapping the call edits only this occurrence's meaning note; call correction
/// and deletion are available in the same popover.
struct AuctionCallPresentation<Label: View>: View {
    let entry: AuctionEntry
    let onSaveMeaningNote: (String?) -> Void
    let onCallChange: (AuctionCall) -> Void
    let onDelete: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isShowingEditor = false
    @State private var noteDraft = ""

    init(
        entry: AuctionEntry,
        onSaveMeaningNote: @escaping (String?) -> Void,
        onCallChange: @escaping (AuctionCall) -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.entry = entry
        self.onSaveMeaningNote = onSaveMeaningNote
        self.onCallChange = onCallChange
        self.onDelete = onDelete
        self.label = label
    }

    private var hasMeaningNote: Bool {
        AuctionEntry.normalizedMeaningNote(entry.meaningNote) != nil
    }

    var body: some View {
        Button {
            noteDraft = AuctionEntry.normalizedMeaningNote(entry.meaningNote) ?? ""
            isShowingEditor = true
        } label: {
            label()
                .overlay(alignment: .bottomTrailing) {
                    if hasMeaningNote {
                        Text("A")
                            .font(.system(size: 7, weight: .bold, design: .rounded))
                            .foregroundStyle(BridgePalette.green)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(.white.opacity(0.96), in: Capsule())
                            .overlay(Capsule().stroke(BridgePalette.green.opacity(0.32), lineWidth: 0.5))
                            .offset(x: 2, y: 2)
                            .accessibilityLabel("有用户含义备注")
                            .accessibilityIdentifier("auction-meaning-note-marker-\(entry.id.uuidString)")
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingEditor, arrowEdge: .top) {
            AuctionCallMeaningPopover(
                entry: entry,
                note: $noteDraft,
                onSaveMeaningNote: onSaveMeaningNote,
                onCallChange: onCallChange,
                onDelete: onDelete,
                onClose: { isShowingEditor = false }
            )
        }
        .accessibilityIdentifier("auction-call-\(entry.id.uuidString)")
        .accessibilityLabel("\(entry.seat?.chineseName ?? "位置未知")，\(entry.call.displayText)\(hasMeaningNote ? "，有用户含义备注" : "")；点击查看或编辑")
        .onChange(of: entry.meaningNote) { _, newValue in
            if !isShowingEditor {
                noteDraft = AuctionEntry.normalizedMeaningNote(newValue) ?? ""
            }
        }
    }
}

private struct AuctionCallMeaningPopover: View {
    let entry: AuctionEntry
    @Binding var note: String
    let onSaveMeaningNote: (String?) -> Void
    let onCallChange: (AuctionCall) -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    init(
        entry: AuctionEntry,
        note: Binding<String>,
        onSaveMeaningNote: @escaping (String?) -> Void,
        onCallChange: @escaping (AuctionCall) -> Void,
        onDelete: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.entry = entry
        _note = note
        self.onSaveMeaningNote = onSaveMeaningNote
        self.onCallChange = onCallChange
        self.onDelete = onDelete
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(entry.call.displayText) · 含义备注")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BridgePalette.ink)
                Text("记录你理解的含义和适用条件；这是应用内用户备注，不代表已核实约定，也不等同于比赛 Alert。")
                    .font(.system(size: 10))
                    .foregroundStyle(BridgePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextEditor(text: $note)
                .font(.system(size: 12))
                .frame(width: 290, height: 92)
                .padding(4)
                .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(BridgePalette.border, lineWidth: 1))
                .accessibilityIdentifier("auction-meaning-note-field")

            Menu("修正本次叫品") {
                Section("特殊叫品") {
                    callCorrectionButton("Pass", call: .pass)
                    callCorrectionButton("加倍 X", call: .double)
                    callCorrectionButton("再加倍 XX", call: .redouble)
                    callCorrectionButton("未知叫品", call: .unknown)
                }
                Menu("定约叫品") {
                    ForEach(1...7, id: \.self) { level in
                        Menu("\(level)阶") {
                            ForEach(ContractStrain.allCases, id: \.self) { strain in
                                callCorrectionButton("\(level)\(strain.symbol)", call: .bid(level: level, strain: strain))
                            }
                        }
                    }
                }
            }
            .font(.system(size: 11, weight: .medium))
            .accessibilityIdentifier("correct-auction-call-\(entry.id.uuidString)")

            HStack {
                Button("删除这次叫品", role: .destructive) {
                    onDelete()
                    onClose()
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("delete-auction-entry-\(entry.id.uuidString)")

                Spacer()

                Button("清除备注") {
                    note = ""
                    onSaveMeaningNote(nil)
                    onClose()
                }
                .buttonStyle(.borderless)
                .disabled(AuctionEntry.normalizedMeaningNote(note) == nil)
                .accessibilityIdentifier("clear-auction-meaning-note-\(entry.id.uuidString)")

                Button("保存备注") {
                    onSaveMeaningNote(AuctionEntry.normalizedMeaningNote(note))
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .tint(BridgePalette.green)
                .accessibilityIdentifier("save-auction-meaning-note-\(entry.id.uuidString)")
            }
        }
        .padding(14)
        .frame(width: 326)
        .background(.white)
        .accessibilityIdentifier("auction-meaning-note-editor-\(entry.id.uuidString)")
    }

    private func callCorrectionButton(_ title: String, call: AuctionCall) -> some View {
        Button(title) {
            onCallChange(call)
            onClose()
        }
    }
}
