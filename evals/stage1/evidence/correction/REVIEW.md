# Correction result: basic playing quality remains blocked

**Stage 1 is NOT accepted. Keep PR #45 draft and issues #36–#42 open. No merge, release or UI integration is authorized.** The bounded correction repaired confirmed program contracts and capture behavior, then stopped after the first affected playing attempt still produced independently confirmed severe errors. This is a failed candidate for review, not a mergeable engineering checkpoint.

## Candidate and lineage

Reverted main is `b2fb9b1d0433357dcdb6e09e4e06fe7736539fb6`. Restoration `0cfa39f` deliberately reverses the revert and preserves `be0cad0` plus the requested AGENTS user-approval clause. [Original tree verification](original-preservation.json) confirms ticket37–42 evidence and calibration files remain byte-identical. Original 22-attempt/230-request results remain **21 failed / one pending / zero accepted**; they are not reclassified or combined with this candidate.

Frozen correction source is **`1d0fae4e1b3044b31ebf9f47425645c5e545c985`**, wire `stage1-plan-variants-v4`, corpus `stage1-finite-v2`, rubric `stage1-basic-v3`, Codex CLI `0.160.0`. [Candidate](live-candidate/candidate.json) records exact instructions, schema, source/assets/runtime and executable hashes before calls. The playing executable SHA-256 is `943973fed52c50f81def4181258d5dc1c45bfd8b4241514d2ab0cea832df8913`. Later commits contain evidence only. [Post-run comparison](live-candidate/post-run-freeze-verification.json) matches source/executable/runtime bytes; this is not continuous per-request filesystem attestation.

## Confirmed program corrections

- **Capture:** terminal public metadata is atomically saved before forwarding its completion bytes. Offline real proxy CLI tests cover complete/split terminal events with delayed EOF and bounded immediate shutdown. The coordinator's original reproduction preserves metadata in three of three corrected trials. See [capture review](capture/REVIEW.md) and [independent merge review](capture-merger.md). The two historical missing metadata files remain unknown; their precise cause is not proven.
- **Playing contract:** nested schema variants couple keep/withdraw to null and replace to nonblank text; the first turn permits only replace. The public Expert still rejects all four exact historical keep-with-text answers unchanged. No silent repair, replacement card, regeneration or retry is added. [Expert review](expert/REVIEW.md) includes actual serialized app-server boundary tests and red/green logs.
- **Context/task:** initial authorized cards use explicit card codes; continuations give concise acting-seat/role, lead/ordinal and legal current choices from the same Engine set already in the schema, plus actual event deltas. The application's new continuation user message does not replay both remaining hands, old plans/reasons or full history; the actual wire payload still carries prior same-thread user/assistant messages and opaque reasoning history supplied by the Codex runtime. One positive bridge-task instruction covers available winners, establishment, timing and entries. This salience hypothesis did not establish adequate playing quality.
- **Grader:** the schema/rubric now require cited findings for every verdict, matching the existing Python validator. Simultaneous deterministic and grader defects retain both attributions. All 45 original empty-findings PASS rows were valid under the old schema and invalid under the revised schema; they remain historical evaluator issues. See [Eval review](../correction-eval/REVIEW.md).
- **Material/coverage:** same eight case IDs, deals, policies and 18-short/four-full schedule; the used former reserve is explicitly regression material. Revised helpers distinguish limited entry opportunities, actual model information windows and pre-DA-loss hold-up from broader events. A legal authored Walker witness proves reachability only. No opponent policy or player line was forced.

## Tests and independent review

The unchanged corrected Swift sources passed **227 tests, 10 existing skips, zero failures**; focused public tests passed after integration. The combined Python suite passed **41 tests, zero failures**. [Source review](source-review.md) preserves Standards and Spec separately: no documented-rule breach or new source defect; one P3 README version drift was fixed and rechecked. The semantic/final-matrix gate remains unmet. New-change diff check passes relative to restoration; pre-existing whitespace in restored historical logs is preserved.

Four separate Sol Medium grader calls ran sequentially, outside playing time:

| Purpose | Saved rows | Seconds | Result and independent review |
|---|---:|---:|---|
| Calibration r1 | 6 | 26.092 | A/B pass, C–F fail; 6/6 verdicts and explanations justified |
| Calibration r2 | 6 | 24.178 | Same independently reviewed result; all citations valid |
| Old former-reserve r1 | 21 | 64.343 | All cited; raw 16 pass/5 fail, reviewed 16 pass/1 definite fail/4 pending |
| New affected development | 8 | 48.600 | All cited; raw 2 pass/6 fail, reviewed 2 pass/2 definite fail/4 pending |

Total grader time **163.213 seconds**. No playing model was called for the first three rows. [Calibration review](live-candidate/calibration-review.md) and [saved-output review](live-candidate/saved-output-review.md) preserve concrete explanations and reasonable alternatives. The 21-row batch addresses 16 of the historical empty-findings rows with fresh cited results; it does not overwrite or pretend to regrade all 45. Four severity disputes remain pending. These correlated samples are not general reliability estimates or human expert signoff.

## The one new playing attempt and STOP

The [predeclared development plan](live-candidate/development/development-plan.json) allows at most four affected attempts, sequentially and once each, stopping on a confirmed severe defect. Only **development-normal**, the first eight-decision synthetic continuation, ran. All previous plans came from this actual Luna Medium thread through the production public Expert/driver.

Independent [replay/count audit](live-candidate/development-replay-audit.md) confirms **8 Expert/RPC/HTTP requests, 8 model actions, 1 sole-legal forced action, 7 driver opponent actions plus one opening-lead prefix**: 17 legal unique cards, NS/EW tricks 3/1, zero retries or structural failures. The board is incomplete and has no new full-board timing or contract outcome.

CLI total time was **49.350977 s**, last controlled action **49.349229 s**, initial request **17.743037 s**, seven later requests **3.821691–6.938655 s**, recorded environment overhead **0.044364 s**. All individual latencies and separate failed/grade records remain in the saved trace. [Wire audit](live-candidate/development-wire-audit.md) matches every actual schema/input/history/delta to public RPC facts; first-turn replacement-only and later plan variants were accepted in these eight observed requests. All eight response metadata files record HTTP 200/completed/Luna. One board/thread and eight fresh sessions/turns are observed. Requested/observable identity is recorded, not proof of hidden service internals. Inherent runtime tools and opaque reasoning history remain disclosed; no tool-call items or extra tool roundtrips were observed.

[Independent semantic review](live-candidate/development-normal-spec-review.md) conservatively finds **2 pass / 2 definite fail / 4 pending**, preserving raw grader **2 pass / 6 fail** separately. Pending is not pass. Decisive failures:

1. **Decision 6, new replacement plan:** “Cash CA and CK as club controls, then use dummy’s remaining clubs to assess whether the suit is established.” North has exactly **CQ/C7**. It must follow to both prescribed club honors, leaving no dummy club for the next step. This is an unavailable physical route, not a demand for optimal strategy or a hidden-hand inference.
2. **Decision 7, current reason:** “Play CQ to try to cash dummy’s remaining club honor while South retains CK as a control.” The actual current trick is **South CA–West C3**, North acts third and also holds C7. CQ cannot cash as a winner under the already played ace. The card is legal; the stated current purpose is not.

The supplied inputs contained correct hands, actual events, current ordinal and legal choices. Correct factual availability does not establish correct use, and this evidence does not prove a unique model-capacity or runtime-distraction cause.

The eight-decision segment finished before separate post-board grading established these failures; this report does not claim the CLI stopped at decision6. [STOP](live-candidate/development/STOP.json) and [root overlay](live-candidate/development/development-normal/root-review.json) stop this candidate now. The entries attempt, formerly reserved regression attempt, Walker attempt and **new final 22-attempt matrix were not executed**. The freeze's `plan.json` is a prospective schedule, not execution evidence. No rerolls or further tuning followed.

## Achieved, unmet and return boundary

Confirmed program bugs have bounded regression evidence and actual contract/capture observations. **Required basic playing quality is still not met**, and the required final matrix has not been attempted for this failed candidate. Walker communication, fuller entry/endgame coverage and precise new-information facets remain unproven by corrected live play. Used reserve is not fresh held-out evidence. Grader format alignment does not resolve all semantic disputes.

Return this concrete draft and blocker for another independent review. Further policy accumulation, model/configuration substitution, answer repair or redefining success would exceed the approved correction. Keep issues open and await the user's explicit decision; a review result alone authorizes no merge or stage closure.
