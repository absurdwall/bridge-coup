import XCTest
@testable import BridgeTeacherMac

final class AnalysisMarkdownDocumentTests: XCTestCase {
    func testParsesHeadingsParagraphsListsAndTables() {
        let source = """
        # Decision **point**

        Choose a route with `entries` in mind.

        - **First** line
        2. Keep the *entry* for later.

        | Route | Reason |
        | :--- | ---: |
        | A | Safe `♥` entry |
        """

        let document = AnalysisMarkdownDocument(source)

        XCTAssertEqual(document.blocks, [
            .heading(level: 1, text: "Decision **point**"),
            .paragraph("Choose a route with `entries` in mind."),
            .listItem(marker: "•", indentation: 0, text: "**First** line"),
            .listItem(marker: "2.", indentation: 0, text: "Keep the *entry* for later."),
            .table(
                header: ["Route", "Reason"],
                rows: [["A", "Safe `♥` entry"]]
            ),
        ])
    }

    func testPlainTextAndIncompleteMarkdownRemainReadable() {
        let source = """
        A plain saved analysis still reads as prose.

        -
        - unfinished list item
        | Route | Reason
        | A | Entry is still unknown
        """

        let document = AnalysisMarkdownDocument(source)

        XCTAssertEqual(document.blocks, [
            .paragraph("A plain saved analysis still reads as prose."),
            .paragraph("-"),
            .listItem(marker: "•", indentation: 0, text: "unfinished list item"),
            .table(
                header: ["Route", "Reason"],
                rows: [["A", "Entry is still unknown"]]
            ),
        ])
        XCTAssertEqual(source, """
        A plain saved analysis still reads as prose.

        -
        - unfinished list item
        | Route | Reason
        | A | Entry is still unknown
        """)
    }

    func testParsesGFMTableWithoutOuterPipesAndKeepsEscapedCellPipes() {
        let document = AnalysisMarkdownDocument("""
        Route | Reason
        :--- | ---:
        A\\|B | The choice is **conditional**.
        """)

        XCTAssertEqual(document.blocks, [
            .table(
                header: ["Route", "Reason"],
                rows: [["A|B", "The choice is **conditional**."]]
            ),
        ])
    }

    func testInlineFormattingRemovesCommonMarkersAndPreservesUnfinishedText() {
        let formatted = analysisMarkdownInline("A **bold** and *emphasized* `code`.")
        XCTAssertEqual(String(formatted.characters), "A bold and emphasized code.")

        let unfinished = "An unfinished **bold marker"
        XCTAssertEqual(String(analysisMarkdownInline(unfinished).characters), unfinished)
    }
}
