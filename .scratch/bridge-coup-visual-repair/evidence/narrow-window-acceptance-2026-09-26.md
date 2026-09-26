# Narrow-window acceptance — 2026-09-26

This public report contains no local filesystem paths or private saved-review content. Content-bearing screenshots linked below use an isolated synthetic review fixture.

## Package and isolation

- Installed Release: Bridge Coup `0.1.0` (build `1`), executable SHA-256 `4ea83d6e63edd9e4698ace702b38caf4fdcc36cae9aa12606c1ccd0d76f91409`.
- Source identity: `c7df42b14f60a453a97e4b416600bfb1f8480a2d`; app sources and tests were unchanged after this build.
- The official installation reported `codex-cli 0.156.1` and ChatGPT connected.
- The below-minimum probe used a copied, sandboxed Release app with a distinct bundle identifier and one synthetic 3NT-by-South review. No source rebuild was used for that probe; the copy had no Codex runtime, and no teaching request or solver run occurred.
- An earlier unsandboxed attempt displayed the saved-review list. It was stopped; no row was opened or selected. The subsequent content-bearing checks used the isolated sandboxed fixture.

## Measurements and observations

The app declares a 1320 pt default width and a workspace minimum of 1180 pt.

| Check | Result |
| --- | --- |
| Official installed app at 1320, 1180, and 1101 pt | The requested widths were reached. Save, Open, and Settings remained in the accessibility tree. The official window geometry was restored afterward. No content-bearing screenshot was taken from the official app. |
| Isolated Release copy at 1320 pt | Both workspace columns and the deal were visible; the synthetic saved analysis rendered headings, lists, emphasis, code, and a table without Markdown source markers. |
| Isolated Release copy at 1240 pt | Both columns and the deal remained in frame. Text wrapped; Save, Open, and Settings remained visible. |
| Isolated Release copy at 1180 pt | Both columns and the deal remained visible. The Markdown table used an internal horizontal scroll area; text remained vertically scrollable. |
| Isolated Release copy at 1101 pt | Below the declared minimum, the teaching pane's right edge was cropped. This is a report-only finding. |
| Isolated Release copy at 90×900 pt | Mouse resizing clamped at 90 pt. Only a narrow slice of the left workspace remained visible; the deal, teaching pane, Save, Open, and Settings were cropped or offscreen. The [synthetic screenshot](narrow-window-2026-09-26/width-90pt-isolated-minimum.png) records the visible viewport. |

At 90 pt, the controls remained in the accessibility tree but were not visible. Overlap, overflow, and readability of content entirely outside the viewport were not assessed and are not claimed to pass. The 90 pt minimum measurement and visible crop are complete; repeating the same probe would not resolve the unassessed offscreen properties.

## Remaining acceptance gap

Before replacing the official app, Save was invoked on its active session. The session's fixture provenance was not verified, so that state-mutating step cannot be certified as synthetic-only. No saved-review row was opened and no private content-bearing screenshot was retained. This is the sole reason issue 07 remains partial. Do not inspect saved-review data to resolve it.

No layout change was made in this report-only ticket. The official app's direct measurements and the isolated synthetic screenshots are kept distinct throughout this report.
