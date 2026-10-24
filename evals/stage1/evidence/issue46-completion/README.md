# Issue 46 implementation and evaluation evidence

**Stage 1 has not passed acceptance.** PR #47 remains draft; neither it nor PR #45 may be merged without explicit user approval.

Playing requests use Luna Medium. Independent semantic grading uses Sol Medium; independent code review uses Luna Max. Names describe requested and observable identities, not independently established internal service routing.

For the current complete disposition, start with [REPORT.md](REPORT.md).

## Current evidence

- [Luna Medium design diagnosis](design-diagnosis-20261022/REPORT.md): 42 predeclared diagnostic calls, exact request/history audits and independent reviews. Full history often preserves the wrong winner conclusion; fresh d11 can also introduce it. A sentence-only candidate failed and was not adopted. No acceptance or production-fix claim.

- [Frozen v3 review](matrix-v3/REVIEW.md): all 22 prescribed attempts completed legally, with 266 player requests. The four full boards took 75.214, 88.017, 106.971 and 79.604 seconds. Independent attempt disposition is **4 pass / 17 fail / 1 pending**. Original grades and exact payloads remain unchanged.
- [Detailed matrix](matrix-v3/REPORT.md): every attempt, request/action count, timing distribution, original grade and coverage predicate.
- [Wire and thread audit](matrix-v3/review-work/final-wire-and-thread-audit.json): 266 HTTP 200 responses, empty tools, Luna Medium, one continuing thread per board, no playing retries or public Chinese text. Internal encrypted reasoning language is not asserted.
- [v4 output-order implementation](output-order-implementation.md): schema, existing field enumeration and examples now follow plan → selectedCard → publicReason; nested update → text and all field meanings remain unchanged. This is a consistency correction with unproven quality benefit.
- [v4 development plan](development-v4/DEVELOPMENT-PLAN.json): three different scenarios, one fresh run each, separately frozen. Independent result: one basic-quality/coverage pass, one pending, one confirmed failure. See [v4 disposition](development-v4/REVIEW.md). These are development checks, not a final 22-attempt matrix, and cannot be combined with v3 passes.

Current offline verification is **234 Swift tests, 10 preexisting skips, and 53 Python tests, zero failures**. The first Python run caught a stale native-boundary expectation for the old order; its failure, corrected assertion and final passing run are preserved in [tdd](tdd/). Both Luna Max review axes found no new concrete source defect. Engineering checks do not establish bridge quality.

## Earlier development and calibration

Two independent grades of the same six reviewed calibration answers use the unchanged stage1-basic-v4 rubric: A/B pass, C–F fail, exact citations, no evaluator errors. [Calibration 1](calibration-r1/) and [calibration 2](calibration-r2/) preserve commands, packages and judgments. The first temporary directory had an obsolete v3 name; the actual rubric/results are v4. This bounded calibration does not establish universal grader accuracy.

- `development-v1`: eight legal Medium decisions; the original contract-default grading dispatch error is preserved alongside saved-output regrading and independent review.
- `development-full-v1`: interrupted after explicit known-rank/consumed-card defects. Saved evidence was retained; no final trace or repaired answer was synthesized.
- `development-full-v2`: legal completion in 117.316 seconds; independent review confirms an unnecessary HA overtake of partner HK. This motivated exposing the Engine's existing public current winner, not adding strategic analysis.
- v3 added `current.winningPlay`, with rationale in issue #46 comment 6337462204. The subsequent full matrix still failed basic semantic quality.

Caller objective/public background, scoring-neutral defaults, the production no-tools path and same-turn evaluator evidence were repaired before the frozen matrix. Their implementation notes, public-boundary regressions and red/green logs remain in this directory. Original manual worktrees and unrelated user work were preserved. No UI work or new in-play reasoner was added.
