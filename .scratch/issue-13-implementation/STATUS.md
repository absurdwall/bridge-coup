# Issue #13 implementation

Scope: https://github.com/absurdwall/bridge-coup/issues/13 and tickets #14–#21.
Fixed reference: prototype commit `7478abf51aa3346ba3f31b726739c99f8b5667fe`; A corner auction, compact continuous ranks, explicit play start. Prototype solver values are never product data.

Dependency graph: #14 / #15 / #16 ready; #16 → #17 / #20; #17 → #18 / #19; #14 + #15 + #18 + #19 + #20 → #21.

All tickets #14–#21 are implemented on `codex/issue-13-play-workspace`, following that dependency graph. Latest code revision: `64d565219d96f33b133574ac1c6aa3bed5fcb3a1`. PR: https://github.com/absurdwall/bridge-coup/pull/22. Issues remain open until normal review/merge; no parent issue was directly edited or closed.

Validation:189 tests passed with0 failures and0 skips, using the real DDS3.0.0 helper. Normal Mac packaging and strict signature verification passed. Packaged native scenarios, actual Runtime requests, legacy archive handling and final review fixes are documented in [NATIVE-ACCEPTANCE.md](NATIVE-ACCEPTANCE.md).

Standards review found no documented violations. Spec review's two P2 findings are fixed and independently rechecked; final native alert and minimum-window fixes were also exercised. See the separate reports under `evidence/`.

Original checkout's uncommitted `CONTEXT.md` diff and20 requirement/prototype files were checked against their initial bytes/hashes and preserved. They are outside this implementation branch. Acceptance used synthetic records and isolated QA stores; the user's running app and review records were retained.

Independent review at62e226a found P1 independent DDS material loss and P2 recognition submission bypass. Both have failure-first regressions and packaged native proof; a native repeat-save asset failure was also repaired. See [REVIEW-FOLLOWUP.md](REVIEW-FOLLOWUP.md). A fresh two-axis review is requested after pushing these updates; do not treat the earlier review as covering these new commits.

A fresh review confirmed the earlier P1/P2 repairs and found another P2: late recognition could replace a staged manual edit. This is repaired at64d5652 with failure-first public regressions and the exact independent race probe.189 tests pass with actual DDS. Native QA8 verifies immediate request invalidation and cancellation preservation; see the follow-up report. The new source still requires independent re-review.
