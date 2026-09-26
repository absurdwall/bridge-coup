# Bridge Coup visual review — public summary

This shareable summary records issue-level observations only. It contains no saved-review hands, analysis text, personal paths, or screenshot from a saved review. Review captures that contain or may retain a saved-review state are excluded.

## Scope

The screenshot-led review used an isolated release build based on source commit `8b73fca`, which included the compact table, first-screen workspace, and lightweight-header changes. The review did not assess bridge correctness, send a model request, or run the double-dummy solver.

## Findings

- The A-style table, four separate seat cards, first-screen teaching area, in-place edit entry, and compact header were present in the reviewed build.
- The app table appeared larger than the prototype reference while keeping the four seats and contract visible together. This remains an unresolved design question, recorded in the [design memo](../../design-memos/future-table-and-window-design.md).
- A saved-analysis view exposed a Markdown rendering issue. The actual review content and its screenshot are intentionally omitted; ticket 05 tracks the generic formatting defect.
- The isolated review runtime was below the app's minimum supported version, so model selection and preference behavior were not accepted from that run. The current installed-app check is summarized separately in `../installed-app-setup-2026-09-26/INSTALLATION-SUMMARY.md`; ticket 08's final runtime and preference checks are recorded in the [live catalog follow-up](../08-runtime-model-catalog-live-2026-09-26.md).
- Narrow-window behavior and assistive-technology behavior were not established by this review. Ticket 07 tracks packaged-app width acceptance.

## Safe visual references

These references show the approved prototype, empty states, and a prototype settings panel. They do not show the saved analysis that prompted the Markdown finding.

- [Prototype A baseline](01-prototype-a-matched-sample.jpg)
- [New-review empty state](02-app-empty-new-review.png)
- [Matched synthetic deal with empty analysis](03-app-sample-empty-analysis.png)
- [Prototype settings panel](04-prototype-model-settings.jpg)
