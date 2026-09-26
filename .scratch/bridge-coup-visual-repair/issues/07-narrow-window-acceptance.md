# 07: Accept the app at narrow window widths

**What to build:** Measure and report the installed Bridge Coup app at progressively narrower window widths. This ticket records findings and does not prescribe or implement a layout fix.

**Blocked by:** None

**Status:** partial — provenance of the pre-install official-session Save is unresolved

- [x] Check the accepted 1320 pt start width, an intermediate width, the declared 1180 pt minimum, and below-minimum boundaries.
- [x] Check deal/workspace visibility and Save, Open, and Settings access at the measured widths.
- [x] Measure the isolated Release copy's mouse-resize minimum at 90×900 pt with a synthetic review; retain the visible crop.
- [x] Record that the deal, teaching pane, and header actions are cropped or offscreen at 90 pt. Content outside the viewport was not assessed for overlap, overflow, or readability.
- [ ] Confirm that every state-mutating step used only a synthetic fixture. Before installation, Save was invoked in the official app without verifying the active session's fixture provenance.

## Acceptance evidence — 2026-09-26

The sanitized [acceptance report](../evidence/narrow-window-acceptance-2026-09-26.md) records the installed Release measurements, the isolated 90 pt probe, the synthetic screenshot, and all limitations. The below-minimum crop is report-only; no layout change was made. The same probe is complete and does not need to be repeated.

The ticket remains partial only because the pre-install Save provenance was not verified. No saved-review data will be opened or inspected to resolve that gap.
