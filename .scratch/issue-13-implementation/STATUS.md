# Issue #13 implementation

Scope: https://github.com/absurdwall/bridge-coup/issues/13 and tickets #14–#21.
Fixed reference: prototype commit `7478abf51aa3346ba3f31b726739c99f8b5667fe`; A corner auction, compact continuous ranks, explicit play start. Prototype solver values are never product data.

Dependency graph: #14 / #15 / #16 ready; #16 → #17 / #20; #17 → #18 / #19; #14 + #15 + #18 + #19 + #20 → #21.

All tickets #14–#21 are implemented on `codex/issue-13-play-workspace`, following that dependency graph. Final code revision: `2824db804ed226774a5e3a1cd84b7114b3e21935`. PR: https://github.com/absurdwall/bridge-coup/pull/22. Issues remain open until normal review/merge; no parent issue was directly edited or closed.

Validation:179 tests passed with0 failures and0 skips, using the real DDS3.0.0 helper. Normal Mac packaging and strict signature verification passed. Packaged native scenarios, actual Runtime requests, legacy archive handling and final review fixes are documented in [NATIVE-ACCEPTANCE.md](NATIVE-ACCEPTANCE.md).

Standards review found no documented violations. Spec review's two P2 findings are fixed and independently rechecked; final native alert and minimum-window fixes were also exercised. See the separate reports under `evidence/`.

Original checkout's uncommitted `CONTEXT.md` diff and20 requirement/prototype files were checked against their initial bytes/hashes and preserved. They are outside this implementation branch. Acceptance used synthetic records and isolated QA stores; the user's running app and review records were retained.
