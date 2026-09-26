import Foundation

enum AnalysisMarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case listItem(marker: String, indentation: Int, text: String)
    case table(header: [String], rows: [[String]])
}

struct AnalysisMarkdownDocument: Equatable {
    let blocks: [AnalysisMarkdownBlock]

    init(_ source: String) {
        blocks = Self.parse(source)
    }

    private static func parse(_ source: String) -> [AnalysisMarkdownBlock] {
        let lines = source.components(separatedBy: .newlines)
        var blocks: [AnalysisMarkdownBlock] = []
        var paragraphLines: [String] = []
        var index = 0

        func appendParagraph() {
            guard !paragraphLines.isEmpty else { return }
            let text = paragraphLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(.paragraph(text))
            }
            paragraphLines.removeAll(keepingCapacity: true)
        }

        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                appendParagraph()
                index += 1
                continue
            }

            if let heading = parseHeading(line) {
                appendParagraph()
                blocks.append(.heading(level: heading.level, text: heading.text))
                index += 1
                continue
            }

            if let table = parseTable(startingAt: index, in: lines) {
                appendParagraph()
                blocks.append(.table(header: table.header, rows: table.rows))
                index += table.lineCount
                continue
            }

            if let item = parseListItem(line) {
                appendParagraph()
                blocks.append(.listItem(marker: item.marker, indentation: item.indentation, text: item.text))
                index += 1
                continue
            }

            if isBareListMarker(line) {
                appendParagraph()
                blocks.append(.paragraph(line.trimmingCharacters(in: .whitespaces)))
                index += 1
                continue
            }

            paragraphLines.append(line)
            index += 1
        }

        appendParagraph()
        return blocks
    }

    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        let leadingSpaces = line.prefix(while: { $0 == " " }).count
        guard leadingSpaces <= 3 else { return nil }
        let content = line.dropFirst(leadingSpaces)
        let level = content.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(level) else { return nil }

        let remainder = content.dropFirst(level)
        guard remainder.isEmpty || remainder.first?.isWhitespace == true else { return nil }
        var title = remainder.trimmingCharacters(in: .whitespaces)
        if let closingMarks = title.range(of: #"\s+#+$"#, options: .regularExpression) {
            title.removeSubrange(closingMarks)
            title = title.trimmingCharacters(in: .whitespaces)
        }
        return (level, title)
    }

    private static func parseListItem(_ line: String) -> (marker: String, indentation: Int, text: String)? {
        let leadingSpaces = line.prefix(while: { $0 == " " }).count
        let content = line.dropFirst(leadingSpaces)
        guard let first = content.first else { return nil }

        if ["-", "+", "*"].contains(first), content.dropFirst().first?.isWhitespace == true {
            let text = content.dropFirst().drop(while: { $0.isWhitespace })
            guard !text.isEmpty else { return nil }
            return ("•", leadingSpaces / 2, String(text))
        }

        let digits = content.prefix(while: { $0.isNumber })
        guard !digits.isEmpty else { return nil }
        let suffix = content.dropFirst(digits.count)
        guard let punctuation = suffix.first, punctuation == "." || punctuation == ")",
              suffix.dropFirst().first?.isWhitespace == true else { return nil }
        let text = suffix.dropFirst().drop(while: { $0.isWhitespace })
        guard !text.isEmpty else { return nil }
        return ("\(digits)\(punctuation)", leadingSpaces / 2, String(text))
    }

    private static func isBareListMarker(_ line: String) -> Bool {
        let content = line.drop(while: { $0 == " " })
        return ["-", "+", "*"].contains(String(content))
    }

    private static func parseTable(startingAt index: Int, in lines: [String]) -> (header: [String], rows: [[String]], lineCount: Int)? {
        guard index + 1 < lines.count,
              tableCells(in: lines[index]) != nil,
              let secondRow = tableCells(in: lines[index + 1]) else { return nil }

        let hasSeparator = isTableSeparator(secondRow)
        let hasIncompletePipeTable = isPipeDelimited(lines[index]) && isPipeDelimited(lines[index + 1])
        guard hasSeparator || hasIncompletePipeTable else { return nil }

        var rawRows: [[String]] = []
        var cursor = index
        while cursor < lines.count {
            let line = lines[cursor]
            if line.trimmingCharacters(in: .whitespaces).isEmpty { break }
            guard let cells = tableCells(in: line) else { break }
            rawRows.append(cells)
            cursor += 1
        }

        let dataRows = rawRows.filter { !isTableSeparator($0) }
        guard let header = dataRows.first else { return nil }
        return (header, Array(dataRows.dropFirst()), cursor - index)
    }

    private static func tableCells(in line: String) -> [String]? {
        var source = line.trimmingCharacters(in: .whitespaces)
        if source.hasPrefix("|") { source.removeFirst() }
        if source.hasSuffix("|"), !source.hasSuffix("\\|") { source.removeLast() }

        var cells: [String] = []
        var cell = ""
        let characters = Array(source)
        var index = 0
        while index < characters.count {
            if characters[index] == "\\", index + 1 < characters.count, characters[index + 1] == "|" {
                cell.append("|")
                index += 2
            } else if characters[index] == "|" {
                cells.append(cell.trimmingCharacters(in: .whitespaces))
                cell = ""
                index += 1
            } else {
                cell.append(characters[index])
                index += 1
            }
        }
        cells.append(cell.trimmingCharacters(in: .whitespaces))
        return cells.count >= 2 ? cells : nil
    }

    private static func isPipeDelimited(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") || trimmed.hasSuffix("|")
    }

    private static func isTableSeparator(_ cells: [String]) -> Bool {
        cells.count >= 2 && cells.allSatisfy(isAlignmentCell)
    }

    private static func isAlignmentCell(_ source: String) -> Bool {
        var cell = source.trimmingCharacters(in: .whitespaces)
        if cell.hasPrefix(":") { cell.removeFirst() }
        if cell.hasSuffix(":"), !cell.isEmpty { cell.removeLast() }
        return cell.count >= 3 && cell.allSatisfy { $0 == "-" }
    }
}

func analysisMarkdownInline(_ source: String) -> AttributedString {
    let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    return (try? AttributedString(markdown: source, options: options)) ?? AttributedString(source)
}
