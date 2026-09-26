# 07: Accept the app at narrow window widths

**What to build:** Measure and report the installed Bridge Coup app at progressively narrower window widths. This ticket records findings and does not prescribe or implement a layout fix.

**Blocked by:** None

**Status:** complete

- [x] Check the accepted 1320 pt start width, an intermediate width, the 1180 pt minimum, and a below-minimum boundary.
- [x] Check the deal/workspace layout and Save, Open, and Settings access.
- [x] Use only synthetic content in retained content-bearing screenshots.
- [x] Record the below-minimum crop without fixing it in this ticket.

## Acceptance evidence — 2026-09-26

The installed Release app was measured at 1320, 1180, and 1101 pt window widths. Save, Open, and Settings remained in the accessibility tree at each width. The installed window position and size were restored after the check.

The content-bearing [1320 pt](../evidence/narrow-window-2026-09-26/final-release-default.png), [1180 pt](../evidence/narrow-window-2026-09-26/width-1180pt.png), and [1101 pt boundary](../evidence/narrow-window-2026-09-26/width-1101pt-boundary.png) screenshots came from an isolated Release QA copy with a synthetic fixture. The 1101 pt image shows the teaching pane's right edge cropped below the declared 1180 pt minimum. This remains a report-only finding; no layout change was made.

See the [packaged acceptance summary](../evidence/acceptance-summary-2026-09-26.md). No private saved review was included in the screenshots or public report.
