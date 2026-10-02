# Staged manual input versus late recognition

Commit: 64d565219d96f33b133574ac1c6aa3bed5fcb3a1
Base: d20cfae671258813af3757761d246cfd9a115014

Diagnosis: when active play caused a manual key-input edit or screenshot replacement to enter pendingPlayReset, its early return bypassed ScreenshotReviewWorkflow recognition revision invalidation. A first in-flight OCR response then replaced the manual pending request with its recognized draft and metadata closure.

Two regressions use public application/workflow actions and a suspended runtime at the external recognition boundary. They cover manual hands, contract, and confirmation edits, plus screenshot replacement, each with cancel and confirm. They assert the manual pending request survives OCR arrival; cancel preserves source, current play and undo/redo; confirm applies only manual input or selected screenshot and clears old play/history; no late candidate/response metadata is published. On unchanged source the two tests failed with 31 assertions (review3-red.log).

Bounded fix: ScreenshotReviewWorkflow exposes invalidatePendingRecognition(), incrementing the existing revision and marking in-flight state stale without applying a draft or modifying manual merge tracking. Existing updateDraft uses the same method. Both staged application entry points call it immediately; recognized proposals also cannot replace an existing manual pending request. Confirmation still applies manual tracking only after approval; cancellation leaves original facts and play untouched. No ephemeral mutate/restore or recognition refactor.

Focused tests: 25 passed (ReviewSourceRegressionTests + ScreenshotReviewWorkflowTests), review3-focus-green.log.
Full suite with actual aggregate .build/dds/bridge-dds via BRIDGE_TEACHER_DDS_HELPER: 189 passed, zero failures, zero skips, review3-full-green.log.
git diff --check passed. Aggregate clean after commit. Original dirty checkout, requirements, and prototypes untouched.

These automated regressions do not claim packaged native acceptance. Independent review and parent packaging/QA remain separate.
