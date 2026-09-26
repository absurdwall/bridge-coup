# Final installed runtime model catalog — 2026-09-26

## Installed app and runtime

- App: Bridge Coup, bundle `app.tortillaflat.bridge-teacher`, version/build `0.1.0` / `1`.
- Installed executable SHA-256: `4ea83d6e63edd9e4698ace702b38caf4fdcc36cae9aa12606c1ccd0d76f91409`.
- Source code identity: `c7df42b14f60a453a97e4b416600bfb1f8480a2d`; application sources and tests were unchanged afterward.
- Runtime: `codex-cli 0.156.1`. The installed app reported ChatGPT connected, then fetched the catalog during bootstrap. A separate read-only app-server query returned the same seven visible model records; the sanitized, model-only page is in [the JSON record](08-runtime-model-catalog-live-2026-09-26.json).
- The query used `initialize`, `account/read`, and `model/list` with `includeHidden: false` and `limit: 100`. It did not call `thread/start` or `turn/start`, and did not open a saved review.

## Runtime catalog and product filter

| Runtime ID | Runtime-supported efforts | Runtime default | Installed app choices |
| --- | --- | --- | --- |
| `gpt-6-astra` | low, medium, high, xhigh, max, ultra | medium | low, medium, high, xhigh |
| `gpt-6-sol` | low, medium, high, xhigh, max, ultra | medium | low, medium, high, xhigh |
| `gpt-6-luna` | low, medium, high, xhigh, max | medium | low, medium, high, xhigh, max |

All three GPT-6 entries report text and image input. Product rules remove Ultra for every family and Max for Astra and Sol. The raw runtime page also includes `gpt-5.6-luna`, `gpt-5.6-sol`, `gpt-5.6-terra`, and `gpt-5.5`; none is accepted as a GPT-6 family option. The settings UI explicitly showed `gpt-5.6-luna` and `gpt-5.6-sol` as filtered lookalikes while keeping the corresponding GPT-6 choices available.

## Selection and restore

- Before the check, the installed app showed the saved explicit selection Astra · Medium.
- I selected Luna · High. The preference stored `family=luna`, `modelIdentifier=gpt-6-luna`, and `effort=high`; after quitting and relaunching the app, the UI restored Luna · High and reloaded the catalog.
- I restored Astra · Medium. After a second relaunch, the UI and preference both showed `family=astra`, `modelIdentifier=gpt-6-astra`, and `effort=medium`.
- No teaching request was issued. Existing focused regression tests cover request model/effort mapping and preference validation. The full standalone `swift test` run passed 67 tests with 3 skipped and 0 failures; prior focused runs passed 43 tests total.

## Final preference follow-up — 2026-09-26

- After the selection/restore checks above, the user requested Luna · Medium as the final installed-app selection. I selected Luna and Medium in the official app's model settings.
- The workspace was empty; no saved-review row was opened and no save prompt appeared. The app quit gracefully.
- After relaunch, the official app's workspace button showed Luna · Medium, ChatGPT connected, and `codex-cli 0.156.1`. The app inventory showed only one Bridge Coup instance running.
- No teaching request, solver run, or content-bearing screenshot was produced.

No saved-review row was opened during this check. The older catalog note and JSON in this folder describe a prior app session and are retained only as historical context; this follow-up is the final installed-build evidence.
