# 03 · Lightweight header acceptance

## Evidence

- [Prototype A reference](02-prototype-a.png) — the existing accepted prototype capture, retained unchanged.
- [App · header collapsed](lightweight-header/01-app-collapsed.png)
- [App · settings expanded](lightweight-header/02-app-settings-expanded.png)
- [App · saved review reopened](lightweight-header/03-app-review-reopened.png)

The app captures show the stacked-card logo and separate image wordmark, compact mode context, discoverable Save/Open actions, and the model/connection entry. The settings capture shows the runtime-reported model state and expanded connection controls. The popover content is 326×354 pt; its outer window is about 352×380 pt and fits within the app window after moving the anchor inward.

## Mac interaction check

- At start, project processes included the running `.build/macos/BridgeTeacher.app` plus separate installed app processes. Their bundles were left untouched; the in-place packaging script was not run.
- Built and launched an isolated release app from a temporary source copy whose only QA change redirected `LocalReviewSessionStore` to an isolated temporary review directory; the committed app code keeps the normal store. It ran without the DDS helper and no solver action was invoked.
- The real machine exposed `codex-cli 0.155.0-alpha.16.3`, below the app’s minimum supported version `0.156.1`. The selector correctly showed models unavailable and disabled. The connection disclosure and “选择 Codex runtime” action remained reachable; the system picker opened and was cancelled without selecting a file. No model list, login, teaching, or screenshot-recognition request was initiated.
- Saved an empty temporary review from the new header, opened the saved-review list, and reopened the record. The header reported “已打开本地复盘 · 南家”. Those records existed only in the isolated temporary review directory.
- Opened the settings popover and returned to the workspace with “完成”. Runtime model selection could not be manually changed because the detected runtime was older than the app’s minimum supported version; the model-selection preference round-trip and runtime capability rules are covered by the settings regression tests.

The expanded view overlaps part of the teaching card while open, as expected for a popover, but remains compact and dismissible. Its options are derived from the runtime catalog; this acceptance did not alter or simulate model support.
