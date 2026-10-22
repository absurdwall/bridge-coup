# No-tools runtime integration

Branch: `codex/issue46-no-tools`
Worktree: `/Users/tingranwang/.codex/worktrees/issue46-no-tools/bridge-coup`
Implementation commit: `4d18097`; tip after merging integration: `7e53124f14d3616ea1afabcf28f4a41fb699aa92`.

The production adapter reads the installed bundled catalog without refresh, changes only the four verified Luna tool fields, and loads that catalog before starting app-server. It saves original/effective catalogs and final config in each run. Catalog discovery shares the playing request deadline; failures stop before a thread with no tool-enabled fallback. Luna Medium, instructions and all_turns history are unchanged. Question tools and current-time reminders are disabled in config.

Acceptance freeze saves/hashes the bundled catalog, verifies it before each attempt and checks the catalog discovered by the actual playing process. Supply the native CLI executable for exact binary attestation; launcher hashes do not attest native children. No brittle npm resolver was added.

## TDD and checks

- `/tmp/bridge46-tools-red.log`: installed-runtime public HTTP boundary failed because four generic tools were present.
- `/tmp/bridge46-tools-green2.log`: 3 installed-runtime public boundary tests pass; only loopback HTTP400, no inference/auth.
- `/tmp/bridge46-catalog-freeze-red.log`: unchanged executable/version with mutated catalog was incorrectly accepted.
- `/tmp/bridge46-catalog-freeze-green.log`: mutation correctly rejected.
- `/tmp/bridge46-runtime-python-green.log`: 49 Python tests pass.
- `/tmp/bridge46-runtime-swift-merged.log`: 31 playing Swift tests pass after integration merge.
- Existing nested-process timeout fixture now responds to catalog discovery, with a 1.8s instead of0.8s deadline so the added Python bootstrap finishes before testing the app-server descendant; finite hang increased correspondingly to4.5s. The test still checks forced termination and no active descendant.

## Actual request evidence

`/tmp/bridge46-runtime-offline-evidence/request.json` preserves the actual HTTP request bytes. `play/` preserves runtime catalogs, config, RPC and failed fake-provider outcome. `summary.json` reports tools[], gpt-6-luna/medium, all_turns. The fake provider rejects immediately; no successful model output or quality claim.

The runtime boundary also asserts source/effective catalogs differ only in the four Luna fields; full metadata and other models are unchanged. Existing instruction-source, snapshot visibility and schema order assertions pass. No GitHub writes or live model calls were made.
