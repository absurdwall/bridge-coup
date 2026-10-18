# full-development-r2 independent evidence adjudication

Review covers all 20 saved actual answers, effective plans, raw/processed grader rows, visible snapshots and chronological events. Full fixture replay below is strictly a mechanical legality check, not hidden-layout strategic evidence. No API/model calls, edits, regrade, repaired answer, or inspection of the currently running reserved attempt.

## Per-row quality

| Decision | Proposed | Concrete basis |
|---|---|---|
| 0001 | fail | “Win the diamond lead with dummy’s ace-king” assigns South DA/DK to North D8653. Also “The 5 is the lowest card” overlooks D3. Current initial false hand, not an old retained phase. |
| 0002 | pass by manual review; raw evaluator issue | DA correctly beats DQ; “South’s king as a diamond entry” is real when returning from North. “Entry for dummy’s clubs” can mean supporting the club route, not explicitly locating DK in North. Raw grader pass has empty findings, so original processed uncertainty/evaluator error remains. |
| 0003 | fail | New plan explicitly says “Retain the diamond king as an entry to dummy.” DK is South's, opposite North D863; it cannot transfer lead to North. Legal C4 does not repair that route. |
| 0004 | pending | CQ beats West C9 with CA/CK in South. “unless East covers with a higher club” is a known inapplicable contingency, not evidence East holds a higher card. Selected CQ and practical route work. Preserve unclear conditional-plan wording pending rather than convert it into an unconditional false holding. |
| 0005 | fail | New replacement again says “preserve the diamond king as an entry to dummy.” North C2 toward South honors is feasible, but the asserted DK crossing is explicitly in the wrong direction. |
| 0006 | fail | Newly installed plan repeats “Preserve the diamond king as an entry to dummy”; DK remains South's. CK properly beats current East CT; the hard finding is the explicitly wrong entry, not the legal selection. |
| 0007 | fail | New plan repeats DK as North entry. CA cash itself is sound. This is a newly asserted false route, not an already-completed stale step alone. |
| 0008 | fail | Selected South DK accompanies “cross to dummy with the diamond king and lead a heart toward South’s ace.” DA is already consumed and DK wins in South. The claimed current crossing/next hand's lead is impossible by that route. |
| 0009 | fail | With South DK currently led and North following D3, retained plan still requires this very trick to cross into dummy. That active crossing is impossible, not yet an old completed phase. “if East does not overtake” is an inapplicable guard and supplies no separate hard claim. |
| 0010 | pass by manual review; raw evaluator issue | South H3 toward North HK is physically available and preserves HA. SA/HA and established clubs remain, so the route can still reach nine; the conditional “any established heart winners” does not explicitly name a new nonexistent winner. Raw empty-findings pass remains an evaluator defect in the original. |
| 0011 | fail | “take the trick and establish the suit” and reliance on “established heart winners” are false development claims: after HK wins the remaining HA6/H74 face unseen HQJT9. No lower heart becomes established by this cash. The failure is this concrete false establishment claim, not merely omitting the available established clubs. |
| 0012 | pass by manual review; raw evaluator issue | North H4 to South HA is an actual crossing. “preserving dummy’s 7 as a potential later winner” is explicitly potential, not an established-winner assertion. Established South C8/C6 remain available after the heart crossing. Raw empty-findings pass is retained as evaluator issue. |
| 0013 | pass by manual review; raw evaluator issue | South HA is the only South card that beats East HJ on the current heart trick. The selected card and reason match; SA and established clubs provide real remaining winners. Raw empty-findings pass remains uncorrected. |
| 0014 | fail | Seven tricks are won; South holds SA/C8/C6 and every opposing club is already played. Cashing these guarantees ten without yielding the lead. Instead “spade finesse toward dummy’s 8 to seek the ninth trick” selects S4, exposing unguarded hearts/diamonds to avoidable loss. This has a concrete available safe contract/overtrick route, not a requirement to maximize all play or hindsight from going down. |
| 0015 | pending | North S8 under observed West SJ is legal; “preserving smaller spots cannot win this trick” is correct. The now-acted finesse step alone and vague “If the finesse loses … reassess” do not establish a new current false card/entry. Retained plan clarity remains pending; raw fail is not silently counted as pass. |
| 0016 | fail | “West won with the diamond jack … completed trick; await the next lead” contradicts a new trick containing only West DJ and the required/selected North D6 follow. Plan also calls H6 a stopper without rank support, but current trick mismatch suffices. |
| 0017 | pass by manual review; raw evaluator issue | South is diamond-void; selected C6 is real and lower than retained C8. Seven won plus SA and established C8 could still supply nine if control returns; “if … when available” does not assert a guaranteed entry. Raw pass has empty findings, retained as evaluator issue. |
| 0018 | fail | On current DT–D8–S5, South SA is a discard in NT. Calling it “the safest immediate winner, though the current lead is not shown” contradicts the shown diamond lead and destroys SA rather than winning. |
| 0019 | fail | “South’s ace is already on the trick and beats West’s king” is false now: SA was discarded at sequence 39, and current trick contains only West SK. |
| 0020 | fail | Seven tricks are won and the twelfth trick SQ–S6–ST will be lost. Only one trick remains, so “cash the club 8 when possible for the ninth trick” is numerically impossible even if C8 could win. H6 discard and C8's intrinsic established rank are otherwise correct. This is an explicit count error, not failure merely because contract is already down. |

Proposed manual quality: **5 pass / 13 fail / 2 pending**. Raw processed grades remain **0 pass / 15 fail / 5 uncertain**. Raw rows 0002/0010/0012/0013/0017 were grader pass with empty findings; the parser correctly marks evaluator issues. Their manual passes above have independent concrete facts and do not repair raw grades. Proposed changes for raw fail rows 0004/0015 are pending, not pass. Grader process exited 0, invoked no tools, run-level evaluator_error null; row-level missing-findings errors are still preserved.

No CQ-under-CK or other inferior-but-feasible club route is penalized merely for losing a potential club trick. This trajectory actually uses CQ, CK, CA on separate winning club rounds. Legal completion/result cannot erase earlier explicit ownership/entry/state failures.

## Independent replay, lifecycle and timing

Replayed initialEvents plus all 51 driver steps using independent corpus.replay: **52 unique cards, empty hands, 13 tricks, NS7/EW6**, legal turn/follow-suit progression. Counts: 20 model actions + six sole-legal forced actions = 26 controlled actions; 25 driver opponent actions + one opening prefix = 26 opponents. No driver retries. Twenty Expert attempts, 20 actual RPC turns and 20 HTTP request payload captures.

All 20 records share one board and one fresh ephemeral thread (`01a14e39-230d-78b1-8d11-3908b173e336`); there is exactly one thread/start, with 20 distinct turn IDs and 20 distinct DecisionSession IDs. Requested playing identity is Luna/medium throughout. These are observable identities, not proof of hidden service internals.

First request **10.301484942 s**; 19 subsequent requests total **80.984060049 s**, median **3.799794078 s**, range **3.489715934–7.166488051 s**. All request latencies total **91.285544991 s**; environment overhead **0.294510007 s**; sum **91.580054998 s**, exactly matching elapsed and last-controlled-action time. No failed-request latency. Outer attempt wall time 91.873 s includes wrapper/runner setup and is separate.

**Wire evidence limitation:** 20 payload captures but only 19 response-metadata files; `response-metadata-19.json` is missing. All 19 saved statuses are 200; it is incorrect to report 20 independently confirmed HTTP 200 statuses. All 20 answers and RPC completions exist, so this does not imply a failed play request. The cause of missing final metadata is not established by this review; preserve the gap rather than synthesize a status. Full-board coverage is covered by actual legal consumption, while the candidate remains quality no-go.

## Preservation

Raw evidence and grades unchanged; reviewed-file SHA256 snapshot:

```json
{
  "grade/grader-output.json": "1fe2aae437197d42ddcd28fa3d8089ca28ebe3bf25d86a4995505be9f63f9dc8",
  "grade/evaluation.json": "c5de613a0322172766d0053fe09d81bce657dd805f18bc77bd28351f2fdde4c9",
  "play/trace.json": "96cde286bdfbbda96555f3f42a7d6f2d5a39da875ddb44a03cd2539acabe47e3",
  "play/rpc.jsonl": "b1d0fa9d205356fdf7cb756a21271c505d81c08bf09d81ca67f1d43bcbc746c8",
  "play/decision-0001/decision.json": "4433d78f3fc6a9ebbc5fd822e7fd303c66a0807bbe463b37242f3247580b24ba",
  "play/decision-0002/decision.json": "de1be9f40a681d8320269576638cf864d41f78982810da1df704e0d542d84433",
  "play/decision-0003/decision.json": "e8f37764dcdb0f674bc0e5903b3f7fe69d283bec542390095a9ca577ca90d8a3",
  "play/decision-0004/decision.json": "c4f0ceeae04b556e4b96d7f77c6661ceb6da29604362feba637e81b40495b855",
  "play/decision-0005/decision.json": "d1921e2b85822d2fb9859cc48564a8e8ec51427fd2c3ecbfe9e404c9f523301f",
  "play/decision-0006/decision.json": "ec84cec9154e2b3b345d7d20791ef2d47a604af6099b2351c0b6493f26dbb21f",
  "play/decision-0007/decision.json": "00c8a1603bd2ce4c05513ee1026c9a714cee58aec05d7558c4a3dc64cca578b0",
  "play/decision-0008/decision.json": "2fa1cf9e407263a7fe3f05194041c99e9574dbebf4be9b91b99058f8f1773c51",
  "play/decision-0009/decision.json": "afc64e9b05508247a308049ae0a619c5eff80de514f54336e3cc894a152293d1",
  "play/decision-0010/decision.json": "e3c8e1c40aaea7e1400701a7f7b6d530ba28cfb6488ed828e0a3ca2c01903fa7",
  "play/decision-0011/decision.json": "bbdcf4feff743b519c1d412d9d93aebf62d4d878395f9fcbe33a8c852fc72db6",
  "play/decision-0012/decision.json": "a3bb93b2a424232d7f841d225aabcbf313c9e8411d4729e64131266f4509de50",
  "play/decision-0013/decision.json": "960d5a9429b4d6c7b8225695eee721d787382c25ac61dc01f6bb30f879df3b4e",
  "play/decision-0014/decision.json": "047f38704809b839e74184a0412e963b25c761c2f22acdf013988aa10c6aa0cf",
  "play/decision-0015/decision.json": "e34d0701744d4fbe805bd38b04155e265a5baa7c2cfb90349964882fb73df050",
  "play/decision-0016/decision.json": "6f17c5081720e8e8634ebbec8da446567b4b65f72ce72eda28c97d99e66c152e",
  "play/decision-0017/decision.json": "215975a6668e4eed8ac4f2e8b709343bcab0cafaea1a748c4c6cc8f109f86e10",
  "play/decision-0018/decision.json": "db39c9e4f388eb6b68c587651e21cdb9b2b130484808d709f9e48ef59576c3f7",
  "play/decision-0019/decision.json": "eac20dd53a8679e86545748d836550c467e8025c4a5d87964941d36e1941dcb7",
  "play/decision-0020/decision.json": "0dc643185ca08df204d2473530a23a2903262854a9740a3e1c00d6a933001fcc"
}
```
