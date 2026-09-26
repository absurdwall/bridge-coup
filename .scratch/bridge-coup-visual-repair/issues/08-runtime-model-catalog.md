# 08: Verify the GPT-6 model catalog and explicit selection

**What to build:** Use the current runtime catalog to expose supported GPT-6 Astra, Luna, and Sol choices, their policy-approved reasoning efforts, and durable explicit selection.

**Blocked by:** None

**Status:** complete

- [x] Record the installed app/runtime versions and sanitized current runtime catalog.
- [x] Accept only GPT-6 Astra, Luna, and Sol family identifiers; filter GPT-5.6 lookalikes.
- [x] Apply the effort policy: remove Ultra; allow Max only for Luna.
- [x] Verify explicit selection and restore after app relaunch.
- [x] Keep the test read-only with respect to teaching requests; do not open saved reviews.

## Acceptance evidence — 2026-09-26

The installed app reported `0.1.0` build `1` and `codex-cli 0.156.1`. The live catalog contains GPT-6 Astra, Sol, and Luna plus GPT-5.6 entries; the settings panel made the three GPT-6 families available and identified GPT-5.6 Luna/Sol as filtered lookalikes. The current model-only catalog page is in [the JSON evidence](../evidence/08-runtime-model-catalog-live-2026-09-26.json).

The starting selection was Astra · Medium. Luna · High persisted across a relaunch. Astra · Medium was restored and also survived a relaunch. No `thread/start` or `turn/start` call was made. See the [runtime and persistence report](../evidence/08-runtime-model-catalog-live-2026-09-26.md).
