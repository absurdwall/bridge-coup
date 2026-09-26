# 05: Render saved analysis as readable Markdown

**What to build:** Render common Markdown in the saved analysis panel while preserving the source analysis text and review data.

**Blocked by:** None

**Status:** complete

- [x] Render headings, paragraphs, emphasis, lists, inline code, and tables without exposing raw formatting markers.
- [x] Keep long analysis vertically scrollable and tables inside the teaching panel at narrow widths.
- [x] Keep plain text and incomplete Markdown readable; do not regenerate or rewrite the analysis.
- [x] Validate with a synthetic fixture and regression tests.

## Acceptance evidence — 2026-09-26

- The Release build rendered synthetic headings, paragraphs, bold text, a numbered list, inline code, and a Markdown table without raw markers. The teaching panel scrolled vertically; at 1180 pt the table used an internal horizontal scroll area.
- Opening, rendering, and reloading the fixture left its archive unchanged. No teaching request was made.
- `AnalysisMarkdownDocumentTests` passed as part of the focused regression runs. Window and fixture limits are documented in the [public packaged acceptance summary](../evidence/acceptance-summary-2026-09-26.md).
