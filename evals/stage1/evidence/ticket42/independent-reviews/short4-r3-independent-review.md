# short-4-r3 independent evidence adjudication

Read-only post-run review of all saved answers, raw grader output/evaluation, visible initial holdings and event snapshots, typed root failure, trace, frozen short-4 case and shared rubric. Only decision-visible facts were used; no hidden defender holdings, future information, API/model call, regrade, or raw edit.

| Row | Proposed overall | Semantic quality | Concrete adjudication |
|---|---|---|---|
| decision-0001 | fail | fail | “Win the diamond lead with dummy's ♦A” and “Dummy must cover West's ♦Q with the ♦A” explicitly invent an ace in North. North holds D8653; DA is South's. Selected D8 neither matches that reason nor beats DQ. This is an active current false-hand/action mismatch, not an ambiguous retained old step. Raw grader's factual fail is confirmed. |
| play / request 2 | fail (structure) | pending | Typed invalidOutput / ambiguousPlan: update keep has non-null plan.text. The contract requires null text for keep, so rejection is a product structure failure and DA was not applied. Its current reason “Play the ♦A to win the trick; the ♦8 and ♦4 are lower than West's ♦Q” is physically correct for South at revision 3. The accompanying text “After winning the ♦A, cash ♦K and develop clubs, using ♣Q as dummy's entry” has available cards/entries. However it was not accepted as a replacement, and keep would retain the original plan with the earlier bad dummy-ace step. Do not manufacture a completed DecisionRecord/semantic pass, or turn that old already-acted step alone into a fresh hard ownership failure. Preserve semantic uncertainty. |

Counts: **0 pass / 2 fail / 0 pending overall**. Semantic counts: **0 pass / 1 fail / 1 pending**. No verdict changes to raw saved results are proposed; no grader empty-findings pass occurred. Grader exit was zero, observed tool items empty, evaluator_error null.

## Actual coverage and termination

**short-4 trigger: uncovered.** Only West DQ (sequence 0), North D8 (1), East D4 (2) were actually played. Club establishment was never attempted, no club honor was consumed, and there was no later entry decision. This result does not rely on imposing the helper's conservative two-honor threshold: even the broader meaningful one-honor/entry interpretation cannot trigger without any club play.

One model action, zero forced actions, one driver opponent action plus the opening prefix; two Expert/RPC/HTTP requests with HTTP 200. Request 2 was rejected structurally. Three accepted events, zero completed tricks, no full board, sixteen-request short task not completed. The legal-execution pass only certifies the accepted three-event prefix.

## Preservation

Reviewed raw-file SHA256 snapshot; all files were left unchanged:

```json
{
  "grade/grader-output.json": "b784631f80703da3a4bdc6e4eb04abeb65d45c2a69ade2958e2ac556b4053028",
  "grade/evaluation.json": "78f3d290037a31a0163b2fcfb95e65d5655e7e1e934cf385296480669e5b3623",
  "play/failure.json": "2b45a2eefea3add02631f2566e8570ed862d61232ce2753e19e352c8951ddb3d",
  "play/trace.json": "932ca910db4164acb3da4426192c5e3eb1dbdd2219343329d4d89006add9610b",
  "play/decision-0001/decision.json": "e86b023eb773c14f57e0553942814a4448bca92337f557df884afe747cce3c2e"
}
```
