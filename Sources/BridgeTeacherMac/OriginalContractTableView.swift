import BridgeTeacherCore
import SwiftUI

struct OriginalContractTableView: View {
    @ObservedObject var workflow: OriginalContractTableWorkflow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("原始四手定约表").font(.headline)
                Spacer()
                Button("关闭") { dismiss() }
                    .accessibilityIdentifier("close-original-contract-table")
            }
            Text("基于已确认的原始完整四手与双方最佳打法，显示各庄位最高可成定约。推演出牌与教学勾选不改变此表。")
                .font(.system(size: 12))
                .foregroundStyle(BridgePalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            switch workflow.state {
            case .unavailable(let reason):
                Label(reason, systemImage: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(BridgePalette.warning)
                    .fixedSize(horizontal: false, vertical: true)
            case .idle:
                Button("计算原始定约表") { Task { await workflow.calculate() } }
            case .calculating(let completed):
                ProgressView("正在计算原始四手 · \(completed)/20", value: Double(completed), total: 20)
                    .accessibilityIdentifier("original-contract-table-progress")
            case .failed(let message):
                Text(message).font(.system(size: 12)).foregroundStyle(BridgePalette.warning)
                Button("重试计算") { Task { await workflow.calculate() } }
                    .accessibilityIdentifier("retry-original-contract-table")
            case .ready(let table):
                Grid(horizontalSpacing: 16, verticalSpacing: 12) {
                    GridRow {
                        Text("花色 / 庄家").font(.system(size: 11))
                        ForEach(OriginalContractTable.declarers, id: \.self) { seat in
                            Text(seat.chineseName).font(.system(size: 12, weight: .semibold))
                        }
                    }
                    Divider()
                    ForEach(OriginalContractTable.strains, id: \.self) { strain in
                        GridRow {
                            Text(strain.symbol).font(.system(size: 17, weight: .semibold))
                            ForEach(OriginalContractTable.declarers, id: \.self) { seat in
                                let cell = table.cell(strain: strain, declarer: seat)
                                Text(cell?.contract ?? "—")
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                    .frame(minWidth: 48, minHeight: 24)
                                    .accessibilityLabel("\(seat.chineseName)庄家，\(strain.symbol)，\(cell?.contract ?? "—")")
                            }
                        }
                    }
                }
                .padding(16)
                .background(BridgePalette.soft, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("original-contract-table-grid")
                Text("— 表示最佳打法也不足 7 墩。原始牌面版本 \(table.identity.version) · DDS \(table.solverVersion)")
                    .font(.system(size: 10)).foregroundStyle(BridgePalette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(width: 490, height: 450)
        .background(BridgePalette.canvas)
        .task(id: workflow.identity) { await workflow.calculate() }
    }
}
