# short-4-r1 independent evidence adjudication

Independent agent review, separate from the Standards axis. Read all ten saved decision answers, their visible snapshots and histories, every raw grader row, the frozen short-4 case/rubric, trace, and typed root failure. No hidden defender holdings or later events were used to judge an earlier decision. No model/API invocation, regrade, raw edit, or answer repair.

## Proposed per-row decisions

| Row | Proposed overall | Concrete basis |
|---|---|---|
| decision-0001 | fail | “Take the trick with dummy's ♦A” contradicts North D8653 and selected D8. DA/DK belong to South; this is a current false hand and action/reason mismatch. |
| decision-0002 | pass | “Win this trick with ♦K” matches selected DK over West DQ. South retains DA; North D653 and both heart honors leave real transport. It replaces the erroneous initial plan. |
| decision-0003 | pass | “Lead a low club toward dummy's queen” matches South C6 with South CAK864 and North CQ72. CQ is reachable and heart entries remain. The loose word “finesse” does not establish a specific impossible current action. |
| decision-0004 | pending | Raw grader calls this a rank failure, citing “no reason to spend the queen under West's nine.” But the new plan explicitly says “Let West's ♣9 hold if dummy can play below it; preserve ♣Q as a later stopper and entry.” Selected C2 deliberately ducks; CQ remains an available later winner/entry. The prose does not explicitly claim CQ loses to C9. The strategic merit of sacrificing this club trick is unresolved; do not turn ambiguous “under” into a proven rank hallucination. No pass is granted. |
| decision-0005 | fail | “♦8 is the lowest remaining diamond” is false now: North D8 was played at sequence 1, remaining D653. Selected D5 also conflicts with the named D8; even D3 is lower than D5. |
| decision-0006 | pass | “Lead a low club toward dummy's queen” matches South C4 and North CQ7. North can win CQ then return C7 toward South CAK8; HA/HK also remain. This is a feasible alternative notwithstanding earlier losses. |
| decision-0007 | pending | Raw grader calls “waste the queen under West's jack” a rank error. The plan instead says “Preserve dummy's ♣Q under West's ♣J”; selected C7 explicitly ducks while retaining CQ. CQ certainly could win, but a deliberate suboptimal duck is not proof that the model thinks J outranks Q. Need strategic/wording adjudication; no pass is granted. |
| decision-0008 | fail | “Dummy must follow to the club trick; ♣7 is the lowest club remaining” is currently false: West led DT, North selected D6, and C7 was consumed at sequence 14. Current reason/action/trick mismatch suffices. |
| decision-0009 | fail | “Play the remaining diamond honor to beat West's ♦10 and East's ♦9” contradicts South's diamond void and selected SA discard. DA was consumed at sequence 11. The plan's “Win with ♦A if necessary” cannot rescue that explicit current false reason. |
| decision-0010 | fail | New replacement promises “preserving ♥A and ♠A as controls” after SA was discarded at sequence 19. The low S4 discard itself is legal, but this newly installed control inventory is false. “If declarer regains the lead” does not make the absent SA available. |
| play / request 11 | fail (structure); semantic pending | Typed failure is invalidOutput / ambiguousPlan. Raw answer uses update keep together with non-null text, contrary to the public keep/null contract. No CQ action executed. Its reason says “keep the existing plan until the next lead or play” although North is now on lead; no complete saved DecisionRecord exists for calibrated quality grading. Preserve structural product failure without inventing a semantic pass. |

Overall rows: **3 pass, 6 fail, 2 pending**. For semantic quality alone: **3 pass, 5 fail, 3 pending** (including ungraded request 11). Raw grader's ten complete decisions were 3 pass / 7 fail; proposed manual changes are d4 and d7 fail → pending, with raw grades untouched. No empty-findings grader pass occurred in these rows.

## Trigger and trace

**short-4 coverage: uncovered.** Club establishment was attempted at sequences 4 (South C6) and 12 (South C4), but no CA, CK, or CQ was consumed in the entire actual prefix through sequence 23. All three club honors remain at the stopped request. Therefore the frozen trigger requiring consumed club honors plus a later remaining-entry decision did not occur. Consumed DA/DK and model mistakes about SA do not substitute for the club-honor trigger.

Actual accounting: 24 accepted events, ten model actions, two forced actions, eleven driver opponent actions plus one opening-prefix opponent action; six complete tricks, NS3/EW3. Eleven Expert/RPC/HTTP attempts; the eleventh completed answer was rejected structurally. The board did not reach the sixteen-request task bound. Existing legal-execution pass describes the accepted prefix, not successful completion. Several independent hard semantic failures establish no-go regardless of d4/d7 adjudication.

## Preservation

Read-only reviewed-file SHA256 snapshot (raw files left unchanged):

```json
{
  "grade/grader-output.json": "b0be710a06dd5e1448052195e4acf9d6da997215fc5f5d8eabee1298cb9f8fa7",
  "grade/evaluation.json": "c6d67379a171a21a919f9da0d6529d27d4d4f2362d506a6637465c67a3e21c77",
  "play/failure.json": "5f5c0948de9d5b41c9162b0d4c386c2f4a8932b5c141ff3a2a6efe783c8d7c4f",
  "play/trace.json": "7072fb72871ae487e9fbe719151a389f85cec18c1e5bbd71146719aae5214cfb",
  "play/decision-0001/decision.json": "a65ca60f69e626a2a827a3536a711c09756631a84fd19a819d81f209f3e392b6",
  "play/decision-0002/decision.json": "13051dc06aaa945da591fd01ef08da95839b1ec9e117cf70057fbb9eab95e57e",
  "play/decision-0003/decision.json": "614d5d1cbb30bde0c39d3e49d338060b53d4cb3e0f2655c6f9337a24c5a9718d",
  "play/decision-0004/decision.json": "174c87d6ffdf949f6042e20e3bc24cee2f338b488f7aba02d7507c3426984b3d",
  "play/decision-0005/decision.json": "efcbf09f2d974188ba5f5f9c9536c819fc0c984db478e71127d5509959729db5",
  "play/decision-0006/decision.json": "41875e907f5ac847d35e7cd21c9a0be0678d6f4e276fb5103c0878e522f96225",
  "play/decision-0007/decision.json": "c9cc9eb7fb3507e4ba3ce7ea2c97e87323b41e63c9caada7896d9eb91ea41ce6",
  "play/decision-0008/decision.json": "0836cfb59d7e427da9d1d885da9e1b16a44371c3e6b8e4bc0eba9c5f5b5a5be4",
  "play/decision-0009/decision.json": "7b6e4ddbe2fc6dffc74281e3ac885752bd0ef76c5d9ea79b30d5d211943e125b",
  "play/decision-0010/decision.json": "abed2b5ddbc5c8cab4ba2add7631d05e4f6f8dbe0f2c44bf543bcf0047fc941b"
}
```
