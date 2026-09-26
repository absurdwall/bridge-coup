# Installed runtime model catalog — 2026-09-26

> Historical app-session evidence. The full raw historical response is kept in the canonical project and omitted from this public export. For the final installed Release build and current live catalog check, see [the installed follow-up](08-runtime-model-catalog-live-2026-09-26.md) and [its sanitized catalog page](08-runtime-model-catalog-live-2026-09-26.json).

## Installed app and runtime

- App: Bridge Coup, bundle `app.tortillaflat.bridge-teacher`, version `0.1.0` (build `1`), read from the installed bundle's `Info.plist`.
- Runtime: `codex-cli 0.156.1`, read from the app's configured executable.
- The current app-server session returned a signed-in ChatGPT account. The catalog was fetched with `model/list` using `includeHidden: false` and `limit: 100`; one page contained seven records. Only the model fields relevant to this ticket are reproduced below.
- The diagnostic called `initialize`, `account/read`, and `model/list`; it did not call `turn/start` or open a saved review.

## Runtime records relevant to this ticket

| Family | GPT-6 runtime record | Runtime efforts and default | Product-approved efforts |
| --- | --- | --- | --- |
| Astra | `gpt-6-astra` | low, medium, high, xhigh, max, ultra; default medium | low, medium, high, xhigh |
| Sol | `gpt-6-sol` | low, medium, high, xhigh, max, ultra; default medium | low, medium, high, xhigh |
| Luna | `gpt-6-luna` | low, medium, high, xhigh, max; default medium | low, medium, high, xhigh, max |

All three GPT-6 records advertise text and image input. The product rules remove `ultra` for every family and remove `max` for Astra and Sol.

The same raw catalog also contains `gpt-5.6-luna` and `gpt-5.6-sol`, plus `gpt-5.6-terra` and `gpt-5.5`. It contains no `gpt-5.6-astra`. These records are not GPT-6 family choices. The installed app's settings panel initially grouped the GPT-5.6 Luna/Sol entries with their GPT-6 counterparts and marked both families unavailable. The runtime did provide `gpt-6-luna` and `gpt-6-sol`; that display was caused by app-side matching, not runtime omission.

## Validation boundary

Regression fixtures cover first-use Luna · Medium, GPT-5.6 exclusion, the effort intersection, explicit choice persistence, and preference revalidation. Service tests use a recording fake app-server to inspect the model and effort prepared for `turn/start`; no teaching request was sent to the live runtime.

## Packaged synthetic-review check

- Built the current Release app and opened a disposable copy with its own bundle identifier, preferences, runtime workspace, and review store. The only review in that store was a generated synthetic record; no personal review was opened.
- With the installed `codex-cli 0.156.1` catalog, the settings panel showed GPT-6 Luna, Sol, and Astra as available, identified `gpt-5.6-luna` and `gpt-5.6-sol` as filtered entries, and omitted Ultra. Luna offered Max; Sol and Astra did not.
- On first launch, the copy selected Luna · Medium while its model-selection preference was absent. Choosing Sol · High wrote the preference. After quitting and restarting the copy, it reconnected to the same runtime, restored Sol · High, revalidated the catalog, and reopened the same synthetic review with that choice shown.
- No real `turn/start` request was sent. Request model and effort propagation is covered by recording-fake service tests.
