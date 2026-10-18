# full-reserved-r2 independent evidence adjudication

Reviewed all 19 actual public answers, effective plans, raw and processed grades, decision-visible snapshots and chronological events. Independent full fixture replay below verifies legality only, not ex-ante strategy. No future hidden holdings, API/model calls, edits or regrade.

## Per-row quality

| Decision | Proposed | Concrete adjudication |
|---|---|---|
| 0001 | pending | Selected North HQ wins over HJ with HA/HK in South. “if it is not covered” and “if the defenders take it” describe known impossible contingencies, but do not assert an observed defender honor. Under the guarded-branch policy, preserve unclear reasoning pending instead of flat wrong-hand fail; practical selected action is sound. |
| 0002 | pass, manually cited | “North’s queen is currently winning” correctly describes HJ–HQ–H2; South H5 preserves HA/HK and keeps North on lead. |
| 0003 | fail | “South won the first trick with the ace; dummy leads the next card” newly asserts an actual winner/card that never occurred. North HQ won HJ–HQ–H2–H5 and South HA is still held. North C5 toward CKQ is feasible; it does not erase that explicit false observed history. |
| 0004 | pass, manually cited | “East’s ten is currently winning, so play low and let it hold” is a deliberate legal duck with South C3 under CT. CKQ and North CA remain for future winners. No claim that CT outranks the held honors, no forced unique action, and no demonstrated destruction of a safe-nine route. |
| 0005 | pending | “The defenders won this trick; keep the remaining club honors…” is ambiguous: defenders did win the immediately preceding club trick with CT, but East HT has only begun the current trick and selected South HK wins. The reason fails clearly to explain HK. Do not force a hard current winner hallucination from the deictic “this” alone when its previous-trick reading is accurate; do not grant pass either. |
| 0006 | pass, manually cited | North H4 follows HT–HK–H3; “South’s king is currently winning” is true and H8 remains. A potential later use of H8 is not a guaranteed winner assertion. |
| 0007 | pass, manually cited | South D2 toward North DQJ93 is a physically available suit-development line, retaining South DA as stopper/return entry. No hidden DK location is assumed. |
| 0008 | pass, manually cited | North DJ follows D2–D5. “if it loses to the king” is a genuine unknown-location contingency: DK has not appeared. North DQ remains and South DA is real. |
| 0009 | pass, manually cited | “East has shown the diamond king” is authorized: East DK appeared at sequence 15. South D7 toward North DQ is available while DA is retained. |
| 0010 | pass, manually cited | North DQ beats West D8; DK was actually played and South holds DA, so no defender can overtake DQ. “the queen can win this trick” matches the selected card and state. |
| 0011 | pass, manually cited | North C6 toward South CKQ is available and retains North CA as an entry. Current history is HJ/HQ first, actual DA/DK tracking remains factual; the old initial guarded heart sentence alone is not a new error. |
| 0012 | pending | “Cover East’s jack with the king; if West takes with the ace, dummy’s ace remains a control.” CK properly beats CJ; North CA makes the West-ace condition impossible. The impossible guarded allocation is not asserted as actual defender information; pending explanatory consistency under the same fair guard policy. |
| 0013 | pending | Exact reason: “Cash the club queen while it is high; dummy’s ace remains available to capture any outstanding club honor.” North's sole CA must overtake South CQ; however this does not explicitly say South stays on lead or CA survives the trick. It may describe present protection/unblocking. Raw grader adds “for later,” which the answer never states. After the overtake, six tricks are won and SK, SA, DA, established C8 are physically cashable for ten (North SK; North D3 to South DA; South SA/C8). Thus inferior honor consumption does not destroy a safe-nine route. Preserve wording/route uncertainty, not automatic severe winner/entry fail. |
| 0014 | pass, manually cited | North SK is a sure winner with South SA behind; South S64 permits following low and retaining SA as future entry. “South’s ace remains an entry” is real. |
| 0015 | pass, manually cited | South S4 legally follows North SK–East S3, preserving SA. Current winner and retained control agree with the reason. |
| 0016 | pass, manually cited | North D3 toward South DA is a real crossing; DA is unplayed and South SA remains. No invented necessary entry. |
| 0017 | pass, manually cited | Eight tricks won, selected South SA is a sure winner: “secure the contract” is arithmetically correct for the ninth trick. |
| 0018 | fail | “Dummy is void in spades, so discard” contradicts North S7/S2 and selected S2 follow on South SA–West S9. Current explicit void/suit-action contradiction; SA securing the ninth trick is separately true. |
| 0019 | fail | “cash a safe remaining winner” selects S6 while SQ/SJ/ST remain unplayed, all above both South S6 and North S7. With only two cards per hand, at least one defender must play a higher spade. South C8 is a real established winner instead. The hard finding is false current winner identification, not merely a missed optimal overtrick; nine already-won tricks cannot be put at risk by subsequent play. |

Proposed manual quality: **12 pass / 3 fail / 4 pending**. Row list: pending, P, F, P, pending, P, P, P, P, P, P, pending, pending, P, P, P, P, F, F. Raw processed grades remain **0 pass / 7 fail / 12 uncertain**. All 12 raw grader-pass rows (0002/0004/0006/0007/0008/0009/0010/0011/0014/0015/0016/0017) have empty findings, so parser-correct evaluator issues remain in original evidence. Manual passes supply concrete facts above and do not replace missing raw citations. Raw fail rows 0001/0005/0012/0013 are proposed pending. Grader exit 0, no observed tool items, run-level evaluator_error null; row-level citation errors remain.

## Replay, action sources, runtime and timing

Independent corpus.replay confirms **52 unique consumed cards**, all four hands empty, 13 legal tricks, **NS9/EW4**. Nineteen model actions + seven sole-legal forced actions = 26 controlled; 25 driver opponent actions + one opening prefix = 26 opponents. Nineteen Expert attempts, RPC turns and HTTP request captures; every response metadata file exists with HTTP 200, no transport errors and no driver retries. Full-board coverage is covered. Making 3NT does not erase the current false-history/void/winner errors above.

Exactly one fresh ephemeral thread/start, thread `01a14e3d-c05b-72c3-8307-ce8a53a42717`; all records share one board, 19 unique turns and 19 unique DecisionSessions. Requested Luna/medium is consistent; observable runtime acknowledgements do not prove hidden service internals.

First request **14.018722057 s**; 18 subsequent requests total **73.747944951 s**, median **3.940831542 s**, range **3.681702971–5.459357977 s**. All requests sum **87.766667008 s** plus real overhead **0.273581982 s** = full elapsed **88.040248990 s**. Last controlled action is **88.040247917 s** (about one microsecond before completion bookkeeping). Outer wall time **88.288 s** additionally includes runner/wrapper setup. No failed-request latency.

## Preservation

All original evidence unchanged; reviewed-file SHA256 snapshot:

```json
{
  "grade/grader-output.json": "6296d70dec10c88ce234ebe70d56bd93e8d09fa4592d421091762882210beea3",
  "grade/evaluation.json": "5d1c92fc3f5167d104e093c6deb20e6a019b360f3770e52222827d870ad91a8a",
  "play/trace.json": "03ecfbb8b047f762bab2cda4f6701e0f70e14fa96ddc783e57e90f4772be9c21",
  "play/rpc.jsonl": "031b1cd21eb0e826fc191c2eae2d4c4891b33084dd57a0be358aa78fc3ca4c38",
  "play/decision-0001/decision.json": "75c4a6a98d79ade0acd995f26310d21befec2f5e44e322b27f5df60ce546cc64",
  "play/decision-0002/decision.json": "fbc85821afb9aaa5deda8f9590d824429fe7ee309111bfd440e06b007c0f2595",
  "play/decision-0003/decision.json": "652d2af9a94a37cd186ca865aef6007b34036e8495f94321cb3ec230fb4d6ff7",
  "play/decision-0004/decision.json": "36eaec7f321704f15f7f310cd7307713ecb7eb969cedc162cf3b154aa37c059c",
  "play/decision-0005/decision.json": "34572be035a83b31998d3f279c6f5e3f2cccee121cf504402b7576bd73b466ef",
  "play/decision-0006/decision.json": "15edc9f31e1eb23ace0e3eb9bf081e0dbc7905eb2327323760fbb83a0796d63b",
  "play/decision-0007/decision.json": "262ce15fa13238c3334168d84ad73589f1db8c6f28999df74bb7211f3a34f559",
  "play/decision-0008/decision.json": "8dab2b6bfdc4533f5d91946150ecdc762f8aca9a23f52391ec0acaff52f4461f",
  "play/decision-0009/decision.json": "b2cad47a398d4cacab5bfa58d1bcef9b4addbe9d6511c055891245a1edd06537",
  "play/decision-0010/decision.json": "16bf489c636f8e1baf03e86b8ea1e55018aecd6b48868ad743b67e3a9815dc6c",
  "play/decision-0011/decision.json": "9d968a1fef2ad7526aeca057c630254942df7f0297a5f8cb147b8c6895c47864",
  "play/decision-0012/decision.json": "a8602e9c0368bd52b8798980bb274ab7929c26091bbb3f7a57317bc4e4018b3f",
  "play/decision-0013/decision.json": "9d4df4ea42f56b2d784dd87e0b720d6d3bba6aa2c3eaddde50c751249485cded",
  "play/decision-0014/decision.json": "512b050e28509c3badc003fb684a85fe2f2b40cdfb0246abc59cc830ff6d362d",
  "play/decision-0015/decision.json": "080b50cd7ea2780a5c2e987ed7eeab8888c1e3c235fa55ec7f37f0ce00895457",
  "play/decision-0016/decision.json": "5ce233a18c051470d155cfc5e06a4ec67580503c4051e16f5cff12fe4cd6d56b",
  "play/decision-0017/decision.json": "0e57a11564428fcba8c9efb9efbbc74084f6f3038257365bb6e8f4d9d9400207",
  "play/decision-0018/decision.json": "ae12c2a5973523f92405d2db94e3c38fe4612912721c6e673bac97d891965524",
  "play/decision-0019/decision.json": "8835e4beb238285445f531f4451612f64a4a6c1b654f16535f6e79071e0cdd77"
}
```
