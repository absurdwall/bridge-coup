# Bridge Coup packaged acceptance — 2026-09-26

## Release package

- App bundle: `app.tortillaflat.bridge-teacher`, version `0.1.0` (build `1`).
- Installed executable SHA-256: `4ea83d6e63edd9e4698ace702b38caf4fdcc36cae9aa12606c1ccd0d76f91409`.
- Source code identity: `c7df42b14f60a453a97e4b416600bfb1f8480a2d`; source and tests did not change after this build.
- The prior app bundle was preserved before replacement, and the existing session was saved through the app. The new app launched under its original bundle identifier; exactly one official app instance remained running after QA copies closed.

## Ticket results

### 02 — Contract grid

The Release build exposed 35 keyboard-accessible level/strain buttons. Cancel preserved 3NT; keyboard confirmation selected the focused choice; choosing 4♠ updated the workspace and marked the earlier plan stale. Reloading the synthetic review restored its original state. No teaching request or solver run occurred.

### 05 — Saved Markdown

Synthetic headings, paragraphs, emphasis, a numbered list, inline code, and a table rendered without source markers. Long content scrolled vertically; the table stayed inside its panel with internal horizontal scrolling at 1180 pt. The saved synthetic archive remained unchanged.

### 07 — Narrow window

The installed app accepted 1320, 1180, and 1101 pt widths, and Save, Open, and Settings remained in the accessibility tree. The content screenshots are from the isolated Release QA copy and show only a synthetic review: [1320 pt](../evidence/narrow-window-2026-09-26/final-release-default.png), [1180 pt](../evidence/narrow-window-2026-09-26/width-1180pt.png), and [1101 pt](../evidence/narrow-window-2026-09-26/width-1101pt-boundary.png). The below-minimum 1101 pt view crops the teaching panel's right edge; that finding is recorded but not fixed here.

### 08 — Runtime catalog

The current `codex-cli 0.156.1` catalog and installed UI expose GPT-6 Astra, Sol, and Luna. GPT-5.6 Luna/Sol lookalikes are filtered. The installed app accepted Luna · High, restored it after relaunch, then returned to Astra · Medium and restored that preference after another relaunch. The live model-only record and effort policy are documented [here](08-runtime-model-catalog-live-2026-09-26.md) and [here](08-runtime-model-catalog-live-2026-09-26.json).

## Verification boundary

`swift test` passed on this standalone branch: 67 tests executed, 3 skipped, 0 failures. Earlier focused runs also passed 43 tests across contract selection, Markdown rendering, runtime catalog/settings/preferences/request mapping, stale-response handling, double-dummy correction, and archive recovery. No real teaching request or double-dummy solve was issued. No personal saved review appears in these notes or screenshots.
