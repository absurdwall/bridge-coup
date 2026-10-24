# Stage 1 correction after rollback

This correction is **not accepted and not authorized for merge**. PR #43 was reverted by #44. Issues #36–#42 remain open. The correction PR must stay draft through independent review; merging, stage closure, release and UI integration require the user's explicit approval. Passing tests or review are not merge authorization.

## Lineage and preserved evidence

Correction starts at reverted main `b2fb9b1d0433357dcdb6e09e4e06fe7736539fb6`. Commit `0cfa39f` deliberately reverses the revert and restores preserved implementation/evidence `be0cad0632244dafa6f975a09a7c4d24c8743e2b`, adding only the requested AGENTS approval clause. Merging the old implementation branch alone would not restore the reverted tree because its commits are already ancestors of main.

Original failed outputs, captured requests, grades and reviewed overlays remain byte-for-byte under the historical ticket evidence paths. The original frozen playing candidate is `8266947`. Its 22 attempts and 230 requests remain **21 failed attempts / one pending / zero accepted passes**. Four legal full-board completions and successful engineering tests did not satisfy the semantic gate.

The two original missing HTTP metadata records remain unknown. New offline reproduction confirms a shutdown race, not the precise historical cause of those two gaps.

## Bounded corrections and attribution

| Area | Established defect | Correction and evidence needed |
|---|---|---|
| Capture program | Client can observe completion before metadata is persisted; shutdown loses evidence | Persist terminal public metadata before forwarding its bytes; real proxy CLI tests with delayed EOF, split events and bounded cleanup. See [capture/REVIEW.md](capture/REVIEW.md). |
| Playing contract | Actual strict schema permits keep with non-null text, while Expert rejects it | Couple update/text variants in the serialized schema, constrain initial replacement, retain visible rejection without repair; public serialized-boundary regressions. |
| Playing quality | Actual visible inputs contain correct hands/events, but outputs invent honors, mismatch the current card and reason, reuse consumed entries or expect a second play in one trick | Inspect exact requests/positions; make one bounded context/instruction revision and test fresh affected continuations. Salience is a hypothesis, not a proven explanation or quality fix. |
| Grader contract | All 45 historical citation defects are PASS with empty findings: serialized schema permits this, Python rejects it | Align schema/rubric with required positive or negative cited findings. Keep originals unchanged and evaluator errors separate; verify on saved outputs and calibration. |
| Material/coverage | Entry trigger is over-narrow; broad spade/diamond predicates do not demonstrate hold-up before losing DA | Version limited corrections, preserve legal witness and reasonable alternatives; avoided skills remain uncovered. Used reserved board is regression material, not fresh held-out evidence. |

No second in-play reasoner, Knowledge injection, DDS/sampling, answer repair, rerolls, manual nonforced cards, full-history replay or UI work is introduced. Current-card legality remains Engine-owned; semantic quality is independently evaluated.

## Prospective validation and stop rule

Before a new playing call, commit and freeze the exact source, instructions, wire schema, runtime, corpus, rubric and executable. Review deterministic public-boundary tests and reachable case expectations. Validate the revised grader on saved calibration/answers, with new provenance outside historical directories.

One development candidate may run these affected attempts sequentially, once each, in this order:

1. Synthetic normal continuation, at most eight model decisions (initial plan, current-card consistency and actual same-thread continuation).
2. Synthetic entries/consumed cards, at most sixteen model decisions.
3. The formerly reserved board, at most eight model decisions, explicitly regression material (current-trick turn ownership and remaining cards).
4. Walker case, at most twelve model decisions (actual hold-up/communication trigger only if chosen and reached).

Each uses the production public Expert and actual prior model plans, the declared legal environment and independent saved-output grading. These are development attempts, **not the required final 22-attempt matrix**. Stop a board on runtime/contract failure; if post-board review establishes a serious semantic defect, preserve it and stop this candidate's development sequence. Do not reroll or continue unrelated playing runs to seek a passing sample. Pending/disputed judgments require independent review and are never silently accepted.

Only a candidate that survives affected checks can be proposed for the specified final matrix. No compatible-candidate splicing, automatic stage-complete claim, acceptance-ticket closure or merge follows from this plan. If the bounded correction still fails required basic quality, return the concrete blocker and draft PR for review instead of tuning indefinitely or changing the agreed architecture/model/configuration.
