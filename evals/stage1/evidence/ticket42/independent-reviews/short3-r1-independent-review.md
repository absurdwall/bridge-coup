# Independent saved-output adjudication — short-3-r1

Frozen source `8266947`, corpus `stage1-finite-v1`, rubric `stage1-basic-v2`. Read all 12 actual `decision.json` records, their current visible holdings/tricks, English event deltas, retained plan, raw grader results and evaluation. No hidden defender holdings, future events, API/model call, file rewrite or regrading was used. This note proposes manual review outcomes; original grades remain unchanged.

**Proposed aggregate: 7 pass / 3 fail / 2 pending. Run remains quality FAIL.** All 12 mechanical decisions passed. Raw evaluation is 0 pass / 4 fail / 8 uncertain. Seven raw grader rows actually say pass but have empty findings, which the frozen evaluator correctly refuses to accept as cited evidence. Those are evaluator-output defects, not product errors; the independent facts below support manual passes.

| Decision | Proposed | Concrete basis |
|---|---|---|
| 1 | pending | North holds D8653 and selects D6; the reason correctly says “South’s ace-king are winners.” The retained plan says “dummy’s ace **if available**.” That known-inapplicable condition is poor plan phrasing, but does not assert North actually holds DA, and the actual route explicitly lets South win. Dispute the grader's automatic severe-failure interpretation; do not silently pass it. |
| 2 | pass | South holds DK/DA and is fourth to DQ-D6-D4. DK wins legally and retains DA. Keeping the plan does not make its already passed opening condition a fresh false ownership claim. |
| 3 | pass | South leads C4 toward North CQ, retaining CA/CK. This is an expressly accepted club-development alternative. North HK and South HA provide an obvious return route; prose need not spell it out here. |
| 4 | fail | At C4-C9, North chooses CQ. “Force West’s club honor” is impossible: West has already played, and all honors above CQ are in South. Legal CQ does not excuse that false mechanism. Grader's ownership wording should be read as partnership holdings: CQ is North, not South. |
| 5 | pass | After CQ wins, North C7 leads toward South CA/CK and retains C2 for a later club lead. The described route is physically available. |
| 6 | pass | At North C7-East CT, South CA wins and retains CK. CT currently outranks C7, so the phrase “already forcing” need not mean a nonexistent higher honor. |
| 7 | pass | After two rounds both defenders followed. CK is a winner and clears the sole outstanding opposing club honor CJ wherever held; this valid action continues establishment. No requirement to restate the inferred 3–2 split. |
| 8 | fail | South, holding SA94, leads S4 while describing a finesse “toward South’s nine” if East plays low. South cannot lead toward its own S9 or play that card again on the same trick; East plays fourth. Four tricks are won and established C8/C6 plus SA/HA/HK already supply five more winners (DA also remains). |
| 9 | pass | At South S4-West SJ, North S2 follows, preserving S8. “South’s ace can win later” is physically possible on a later trick; it does not explicitly claim South can play twice now. Non-optimal preservation language alone is not a severe factual defect. |
| 10 | fail | West won SJ's trick and then led DJ. “West has ruffed” is false in NT; North is not diamond-void and holds D853. “Shed a small heart” also contradicts selected D5 and mandatory diamond follow. |
| 11 | pass | South H3 toward North HK retains South HA. HK can win immediately; a later North low heart toward HA is an obvious remaining return. This is not an impossible entry route. |
| 12 | pending | North H4 ducks West H5 while retaining HK; South HA remains. The duck lacks a concrete demonstrated benefit and might permit damaging continuations, but the text does not invent an entry or necessarily lose the contract. Keep strategic adjudication pending rather than promote this into a mechanically certain severe failure. |

## Actual trigger coverage

**Covered.** First club round is sequences 4–7: South C4, West C9, North CQ, East C5. Second is 8–11: North C7, East CT, South CA, West C3. Both defenders have followed twice, so their five missing clubs are already proved 3–2 after sequence 11. Decision 7 is a real subsequent model decision at revision 12. West's third club CJ at sequence 13 localizes the length before East's actual H2 discard at sequence 15; decision 8's visible history includes both. These statements use observed events, not full fixture holdings.

Evaluator issues: rows 2,3,5,6,7,9,11 lack required cited findings despite raw pass labels. Row 1 is a substantive conditional-language dispute, not a citation parser defect. Row 12 is a preserved strategic uncertainty. Rows 4,8,10 independently establish the run's no-go.
