import SwiftUI

struct AnalysisMarkdownView: View {
    private let document: AnalysisMarkdownDocument

    init(source: String) {
        document = AnalysisMarkdownDocument(source)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(document.blocks.indices, id: \.self) { index in
                blockView(document.blocks[index])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
        .accessibilityIdentifier("saved-analysis-markdown")
    }

    @ViewBuilder
    private func blockView(_ block: AnalysisMarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            inlineText(text)
                .font(.system(size: headingSize(level), weight: .semibold))
                .foregroundStyle(BridgePalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        case let .paragraph(text):
            inlineText(text)
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(BridgePalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        case let .listItem(marker, indentation, text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(marker)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BridgePalette.green)
                    .frame(minWidth: 18, alignment: .trailing)
                inlineText(text)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .foregroundStyle(BridgePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, CGFloat(indentation) * 14)
        case let .table(header, rows):
            tableView(header: header, rows: rows)
        }
    }

    private func tableView(header: [String], rows: [[String]]) -> some View {
        let columnCount = max(header.count, rows.map(\.count).max() ?? 0)
        return ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 0) {
                tableRow(header, columnCount: columnCount, isHeader: true, rowIndex: 0)
                ForEach(rows.indices, id: \.self) { index in
                    tableRow(rows[index], columnCount: columnCount, isHeader: false, rowIndex: index)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("analysis-markdown-table")
    }

    private func tableRow(_ cells: [String], columnCount: Int, isHeader: Bool, rowIndex: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<columnCount, id: \.self) { column in
                inlineText(column < cells.count ? cells[column] : "")
                    .font(.system(size: 12, weight: isHeader ? .semibold : .regular))
                    .lineSpacing(3)
                    .foregroundStyle(BridgePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 132, alignment: .leading)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 8)
                    .frame(width: 150, alignment: .topLeading)
                    .frame(minHeight: 36, alignment: .topLeading)
                    .background(cellBackground(isHeader: isHeader, rowIndex: rowIndex))
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(BridgePalette.border)
                            .frame(width: 1)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(BridgePalette.border)
                            .frame(height: 1)
                    }
            }
        }
    }

    private func cellBackground(isHeader: Bool, rowIndex: Int) -> Color {
        if isHeader { return BridgePalette.green.opacity(0.08) }
        return rowIndex.isMultiple(of: 2) ? .white : BridgePalette.soft
    }

    private func inlineText(_ source: String) -> Text {
        Text(analysisMarkdownInline(source))
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: 20
        case 2: 18
        case 3: 16
        default: 14
        }
    }
}
