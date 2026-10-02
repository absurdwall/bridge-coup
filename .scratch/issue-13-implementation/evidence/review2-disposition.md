# PR22 second review repair disposition

Scope: one bounded implementer on user-requested aggregate branch codex/issue-13-play-workspace, beginning62e226a. No packaging, deployment, GitHub mutation, or original dirty workspace edits.

P1 independent DDS preservation: new optional persisted DoubleDummyHandSource records shared original, independent needing review, or explicitly reviewed independent. Legacy records without the field migrate from their existing source/version/conflict facts. Start/play/history/restart and original-hand/confirmation/context synchronization only update linked DDS inputs. Unresolved and explicitly kept independent draft/solver material remain untouched. Save/reopen preserves the choice via LocalReviewSessionStore's snapshot reconstruction; a reviewed independent source no longer resurrects the unresolved warning. Explicit use-original remains the replacement entry. Independent verification does not depend on the main screenshot's confirmation.

P2 recognition reset boundary: ScreenshotReviewWorkflow offers its first merged draft to the application policy before any original mutation. Candidate/response/succeeded metadata commit is staged with that draft via a revision-and-URL-checked closure. Cancellation retains source, session, undo/redo and keeps recognition idle/retryable with no newly applied candidate. Confirmation clears old play/history, applies the existing merged draft without marking recognized values as manual edits, and commits recognition metadata. In-flight recognition started before play, manual correction invalidation, and reopening another record obey existing request revision guards. Pending edits freeze play/history actions without discarding history. Unexpected direct source mutations drop incompatible play and emit the common position revision, clearing current-card labels; play/collect also verify source compatibility.

Failure-first evidence:
- review2-dds-red.log: original source failed unresolved independent DDS preservation after start/save (two exact draft-preservation failures).
- review2-dds-green.log: same public-workflow regression passed after the bounded source fix.
- review2-screenshot-red.log: original direct recognition path failed eleven source/session/history/reset assertions.
- review2-screenshot-green.log: initial cancellation regression passed after staging fix.
- review2-focused-green.log:49 relevant high-level screenshot/archive/history/source checks, including7 new regressions, passed without skips after atomic metadata staging.
- review2-full-green.log:186 tests passed, zero failures/skips, using the actual aggregate DDS helper.
- review2-original-probe.txt: parent/root independently reproduced both original bugs before repair. Root will rebuild and rerun /tmp/pr22-spec-probe.swift after the commit and record exact command/output; that standalone rerun and final native acceptance remain pending at this handoff.

Native QA paths for root: legacy unresolved start/play/save retains independent materials; explicit keep then save/reopen retains source without conflict warning; explicit original choice replaces. For a no-candidate screenshot with manually confirmed full board and active play, first recognition presents reset; cancel keeps original/play/history and enables recognition retry; confirm applies candidate, clears old play/history, and requires screenshot confirmation before restart. Also confirm late recognition after record open/manual edits cannot change that record.

Optional P3 shared delta formatter deferred: no correctness defect depends on it, and this repair stays focused on the authorized source/reset failures. No transient debug instrumentation or temporary product files remain.
