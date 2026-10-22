# Evaluator integration fixes

Worktree: /tmp/bridge46-eval-binding
Branch: codex/issue46-eval-binding

## Evidence association

Reproduced the old false pass by substituting decision-0001 turn identity onto saved decision-0002 while both texts remained in shared rpc.jsonl. Now the evaluator binds the single outstanding sequential turn/start request to its returned turn ID, checks the recorded thread ID, then checks a subsequent completed public message from that same turn. Historical response rows omit RPC IDs, so overlapping ambiguous starts are not certified. Authored calibration records without RPC remain unchanged.

Red: /tmp/bridge46-eval-binding-red1.log. Supplemental pre-fix regressions for completion-before-start and wrong thread: /tmp/bridge46-eval-binding-red2.log. Green focused suite: /tmp/bridge46-eval-binding-green2.log. Independent audit of all468 committed actual decisions with RPC (v1:2, v2:21, v3:246, v4:199) found zero new association mismatches.

## Default doubling

The initial real v5 development run could not reach a grader: Codable serialized doubling=undoubled whereas the frozen legacy corpus omitted it. Normalize only omitted default doubling to undoubled in corpus.verify_case_decisions; explicit doubled/redoubled and all other fields remain exact. No corpus asset or frozen hash was changed. A public evaluate.py grade --case regression uses a captured authorized v5 decision and a local recorded grader, proving undoubled dispatch proceeds while doubled/redoubled fail before grader invocation. It is dispatch testing, not a semantic pass.

Red: /tmp/bridge46-eval-doubling-red.log. Green: /tmp/bridge46-eval-doubling-green.log. The original failed live grading evidence was preserved by the parent.

## Integrated verification

Updated the outbound full-snapshot assertion to include objective/publicBackground after snapshot/runtime integration. Built the actual public bridge-play product with env -u SDKROOT swift build --product bridge-play. Final full Python suite:52 tests, zero failures,6.430s (/tmp/bridge46-eval-final-all.log). No playing or grading model was called by this implementation.
