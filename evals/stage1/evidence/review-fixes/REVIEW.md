# Pre-acceptance review fixes

Baseline: `9f1f965524a104f64afe91b34a75c76bc31249c6`. This repairs the two P2 findings in `/tmp/bridge-stage1-research/pre-acceptance-spec-review.md` plus the root's separately reproduced nested-runtime timeout concerns. No playing or grading model was called. Recorded subprocesses are external-boundary test fixtures, not model performance evidence.

## Authorized decision view

The public Engine snapshot constructor now rejects an opponent acting seat before deriving legal choices. The regression covers the opening defender turn, a defender follow-suit turn, and the unchanged complete legal set on North's legitimate dummy turn. `engine-red.log` records the two prior visibility violations; `engine-green.log` records the correction.

## Failure attribution

Expert failures explicitly retain their origin: `runtime`, `invalidOutput`, or `identity`. The actual `bridge-play` executable, driven by a recorded app-server subprocess, now saves `category: invalidOutput` and the original malformed answer; it creates no decision record or execution. `output-category-red.log` and `output-category-green.log` demonstrate this public CLI boundary.

Eval keeps completed invalid output and continuing-session identity violations as mechanical/product failures, distinct from a transport/no-answer runtime failure. Quality remains uncertain when there is no complete decision snapshot to grade, and no grader is requested. An uncategorized legacy failure containing an answer remains failed with pending review: nonempty text alone does not identify the failure's cause. The original failure and raw answer remain intact. Existing historical evidence is unchanged. The `runtime-failures.json` filename and nested `runtimeFailure` evidence key remain compatibility containers; per-result `failure_category`, attribution and deterministic checks now describe the actual category. `eval-red.log` and `eval-green.log` cover these distinctions, including a valid answer rejected for reused runtime identity.

## Nested-runtime deadlines

A recorded playing-runtime parent ignores TERM and spawns a child that also ignores TERM while holding stdout open. Before repair a 0.8-second request returned after 2.765 seconds, when the finite fixture exited (`nested-timeout-red.log`). Reads now poll against the request deadline; termination targets a launched process group only after verifying that its group ID equals the launched child's PID. The failed request immediately kills that owned group. Version probing retains the bounded TERM/KILL fallback. The final public regression also checks that no active child remains. Green returned in about 0.824 seconds (`nested-timeout-green.log`).

The independent grader had a separate confirmed timeout defect: `subprocess.run` returned an evaluator failure while its native-style child remained active. `grader-timeout-red.log` records this active descendant. Grader version probing and execution now each launch an owned session; timeout kills the entire session's group before bounded output draining and return. No active descendant remains in the green public Eval regression (`grader-timeout-green.log`). Grader timeout still means evaluator issue and uncertain quality, never a product-quality pass or fail.

## Impact and validation

Valid controlled-turn snapshots produce the same legal choices, playing instructions, request schema and text. Prompt construction, plan lifecycle and selected-card behavior on the valid path are unchanged. Runtime arguments, model/effort, English instructions and isolation configuration are unchanged; lifecycle changes bound failed or unresponsive processes. Grader arguments, prompt, rubric and output interpretation are unchanged on successful runs. `impact-hashes.json` verifies unchanged playing instruction/schema/configuration fragments, grader configuration/schema, rubric and frozen corpus hashes against the baseline.

Previous live outputs, calibration results and known quality failures remain historical evidence for their original candidates. These fixes neither rerun them nor change their outcomes. Ticket #42 must freeze the new source hashes before acceptance.

Full Swift validation after the new timeout concerns: 224 tests, 10 preexisting DDS/runtime skips, zero failures (`swift-final.log`). All Python Eval/corpus tests: 19 passed (`python-final.log`). Both suites use only recorded subprocess boundaries for these regressions. `git diff --check` passed.
