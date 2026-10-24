## Spec review v2

No confirmed implementation defect or unasked product scope was found in the three changed source/test files.

The instruction revision (`Sources/BridgeExpert/Resources/DeclarerInstructions.txt:15-23`) adds a general check of unfinished lines against remaining cards, entries, possible higher cards, won tricks, and future trick sources. This fits Issue #36’s requirement that plans express routes, entries, conditions, and reassessment naturally. It adds no fixture-specific card, fixed route, word ban, schema field, tool, or reasoning stage; the approved objective and output contract remain unchanged.

The interrupted-evidence fallback (`evals/stage1/evaluate.py:18-24`) correctly reads a parent `rpc.jsonl` when a per-decision folder lacks one, including when the board was stopped before a final trace was written. The public regression (`evals/stage1/tests/test_evaluate.py:161-178`) exercises the captured interrupted layout and checks matching-thread success plus unrelated-thread rejection. Existing request/response correlation still binds the identity to one turn.

**Empirical gate remains open, not a code defect.** Issue #36 requires “each of the six short scenarios three independent times and each complete board twice.” The previous eight-step and stopped full-board runs have confirmed quality failures; they predate this instruction change. No semantic improvement is claimed for v2, which changes all playing requests and therefore needs fresh real evidence. The final 22-attempt matrix remains unrun and unpassed.

No scope-creep or wrong-implementation finding is confirmed.
