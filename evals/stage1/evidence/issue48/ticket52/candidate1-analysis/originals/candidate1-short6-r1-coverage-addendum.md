# short-6-r1 — evaluator-only coverage refinement

2026-10-23. This addendum supplements, without rewriting, the original
`candidate1-short6-r1-review.md` or any frozen/raw artifact. Quality remains
**7 pass / 5 fail**, based only on the authorized decision-time information.
The original review's public-inference limit remains correct: three East follows
alone do not establish its original length to the player.

After that independent public-quality assessment, the coordinator explicitly
authorized evaluator-only environment replay for material coverage. The actual
fixture named by `short-6-r1/play-command.json` is
`evals/stage1/corpus/boards/walker-holdup-adapted.json` (SHA256
`1ee7dd3747426124dee7cd29f914aa8677818ad6558e2e5a327373cdacbea208`).
Existing `corpus.replay` independently replayed only the actual trace prefix
through East's DA at seq15. The replay confirms:

- Environment East began S654, West SKQJT2; East held DA.
- Actual S4/S5/S6 were spent on three continued spade rounds; SA took the third.
- Immediately after DA won, East had **no spades**, while West retained ST2.
  East's remaining cards were CK97/D87/HT982. Thus returning a spade to West was
  legally impossible. HT at seq16 was one of several possible nonspade choices,
  rather than voluntarily declining an available spade return.

This verifies the **actual** material communication premise: the short spade
hand took DA after its three spades had been exhausted. The observed heart
switch therefore did not fake hold-up coverage by gifting relief while a spade
return remained available. It does not prove optimal defense, universal hold-up
safety or that the player knew the hidden length.

The environment proof is saved outside the repo in
`candidate1-short6-r1-r2-coverage-environment-proof.json`, with actual trace,
fixture and reducer hashes. It is **evaluator-only coverage evidence**, excluded
from all decision-quality facts, grading labels to live roles and player/reviewer
inputs. No actual or historical input/output was changed, and no model/network
call occurred.

Final coverage disposition for r1: **COVERED**, including actual short-hand
exhaustion before DA loss, real defender continuation/contest, and subsequent
entry handling. The five delivered stale-plan quality failures remain, so the
attempt's quality/acceptance disposition remains FAIL.
