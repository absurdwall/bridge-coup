# Independent saved-output adjudication — full-development-r1

Frozen source `8266947`; corpus `stage1-finite-v1`; rubric `stage1-basic-v2`. Reviewed all 20 actual public answers, English deltas, current authorized holdings/tricks, retained plan and cited grades. Quality judgments use decision-visible facts, not future defender holdings. Separately replayed the saved complete event/source record for rules/count verification. No model/API call, regrade, source or evidence edit.

**Proposed: 11 pass / 7 fail / 2 pending. Quality FAIL despite legal completion.** Original grader is 11 pass / 9 fail; decisions 3 and 6 are proposed pending rather than automatically failing feasible but inferior unblocking choices. All raw findings are cited; no citation-parser defect occurred. Root agrees that a feasible unblocking tradeoff is not automatically a severe failure under the non-optimal-line allowance.

| Decision | Proposed | Independent basis |
|---|---|---|
| 1 | pass | North D5 follows legally. Plan's “win ... with the ace” does not say dummy owns it; the reason explicitly says dummy has no diamond honor, then describes playing the ace and developing from declarer's hand. A coherent reading is South's subsequent DA, which the visible hands support. Do not invent an express North-ace claim from this imperfectly scoped prose. |
| 2 | pass | South DA beats DQ-D5-D4 and retains DK. Reason and current card agree. |
| 3 | pending | South CA is a sound start. The future suggestion that CQ “can be unblocked under the king next” is legal but consumes a separate top winner and is unnecessary with available side-suit transport. It is not yet executed and does not explicitly say Q must be discarded or that the suit is otherwise inaccessible. Preserve inferior-alternative/severity review rather than mark every unnecessary unblock suggestion a certain severe factual defect. |
| 4 | pass | North C2 follows under CA, preserving CQ as a real later entry; South CK remains. No automatic execution of decision 3's free-text future suggestion occurs. |
| 5 | pass | South CK continues the accepted AK-then-Q line, and the current reason correctly recommends retaining CQ. North can play C7 now and win the next club lead with CQ, then return through a real heart entry. |
| 6 | pending | North actually plays CQ under CK with C7 available. Retaining CQ and returning through HA/SA would preserve an extra winner, so the proposed unblock is inferior. However, with a 3–2 club break, unblocking then conceding the last club honor can still supply four clubs + two diamonds + three major-suit tricks = nine. The text does **not** say the remaining clubs run immediately; don't invent that stronger claim. Under the allowance for reasonable non-optimal lines and no optimal-overtrick requirement, root leaves severity pending rather than hard-fail the feasible communication tradeoff. |
| 7 | pass | Both defenders followed twice; only CJ remains outside declarer's C864/North C7. C4 forces that actual last honor and establishes C8/C6. Side controls remain available. |
| 8 | pass | West DJ is led; North D3 is its lowest diamond and South's only diamond DK can win. “If needed” does not invent a hidden honor. |
| 9 | pass | After DK wins, declarer has four tricks; South HA/SA/C8/C6 plus North HK supply five further cashing tricks with correct sequencing. HA now is safe if North follows low. |
| 10 | fail | North HK under South HA consumes the separate heart winner, although H4/H7 are available and South has only H63 afterward. A concrete nine-trick route exists: follow low now, cash the two established clubs and SA from South, then lead H3/H6 to HK. The asserted unblock preserves no South heart honor/entry and destroys that risk-free route. This is not inferred merely from the eventual down score. |
| 11 | pass | All five opposing clubs C3/C5/C9/CT/CJ have visibly appeared. C8 is an established winner; “toward the contract” does not falsely guarantee nine after the previous mistake. |
| 12 | fail | North is club-void; selected S8 is a discard. “Follow with a low club” describes an unavailable card and a different suit. |
| 13 | pass | South C6 is the last actual established club and wins. Correct remaining-card accounting. |
| 14 | pass | North club-void D6 discard is available; retaining S6/S2 “in case” they contribute is conditional rather than an invented winner claim. |
| 15 | fail | After C6's trick, South holds SA94/H63 and seven tricks are won. “Cash the last established club” invents an already consumed card and contradicts selected S4; the claimed subsequent ninth-trick route is unavailable. |
| 16 | pass | At South S4-West SJ, North S62 cannot beat SJ; S2 is a legal lowest follow that preserves S6. |
| 17 | fail | At West DT-North D8-East D9, South H3 is a legal discard and DT wins. The separate claim to preserve a “remaining club winner” invents a card: South has only SA9/H63. |
| 18 | fail | South SA legally beats West SK, but the promised following club cash cannot occur; South has only SA9/H6 before this play and no clubs. |
| 19 | fail | South holds only S9/H6 and selects S9. “Cash the last club ... securing the ninth trick” invents a club, misdescribes the selected suit and falsely guarantees a winner while SQ is unplayed. |
| 20 | fail | North has only H7/H4, with D8 already consumed. H4 is legal but “discard a diamond spot” names an unavailable suit/card. |

## Complete execution, provenance and timing

**Full-board coverage covered; independent of quality.** Independent replay passes with no errors: 52 unique cards, 13 tricks, NS 8 / EW 5. There are 20 model request attempts, 20 actual turn/start RPCs, 20 executed model actions, six controlled sole-legal forced actions, 25 driver opponent actions and one opponent opening-prefix action. Total controlled actions are 26; every non-forced controlled action is model-sourced. One thread has 20 distinct turns; source labels and immutable one-event appends match. No retry, substituted non-forced card or root/runtime failure appears.

First request: 10.319600 s. Nineteen subsequent requests have median 3.880708 s, range 3.537833–7.871396 s. All request latencies sum to 97.465539 s; real driver overhead 0.264409 s gives 97.729948 s total, matching last-controlled-action and full-driver times. No failed-request latency. This board is below the three-minute experience goal, but timing/completion does not establish quality or broad reliability.

The current impossible-card/suit failures and destroyed heart winner independently establish no-go regardless of disputes over the optional club unblock. Original grader outputs remain unchanged.
