# Native runtime ordering regression migration

- Base integration merged by fast-forward: `d6a8dc3c93d1222e24228091cfb7f6a0dc08a421`.
- Worker checkout: `/tmp/bridge46-output-order`, branch `codex/issue46-output-order`.
- Commit: `482f79e1ae32aace9f4c9f2c3881a00a0f149ec6`.
- Only test name and expected root-field property order changed in `evals/stage1/tests/test_runtime_isolation.py`. Actual native HTTP expectation now matches approved `plan`, `selectedCard`, `publicReason`. All nested `update`/`text`, complete-snapshot, schema-legal-choice, exact-instruction-loading, native transport identity, no-auth and no-tools assertions remain unchanged.
- This migrates a stale contract expectation; no playing source, schema meaning, corpus, rubric or acceptance bar changed.

## Checks

- RED: parent full suite at `/tmp/bridge46-v4-python-all.log`; preserved copy `output-order-native-red.log` shows actual correct plan/card/reason order versus old reason/plan/card expectation (one failure of 53).
- Build first: `env -u SDKROOT swift build --jobs 2 --product bridge-play`, exit 0, `output-order-native-build.log`.
- Targeted actual-native offline HTTP test: 1 test, zero failures, `output-order-native-green.log`.
- Entire Python suite with built worker player and `PYTHONDONTWRITEBYTECODE=1`: 53 tests, zero failures, 6.625 seconds; `output-order-python-all-green.log`.
- `git diff --check` passes; local `.githooks` enabled; commit hook passed.

All Python commands use `/var/folders/1l/xh7kf4ss1rqg3vxjr17q9_0w0000gn/T/bridge-pr45-review-h8xadm03/env/bin/python`. Native HTTP tests are loopback 400 rejections with no credentials/inference; no live model calls, GitHub writes or integration edits were made.

The separate main output-order correction remains an unproven model-quality hypothesis. These passing offline checks establish the runtime contract, not playing acceptance.
