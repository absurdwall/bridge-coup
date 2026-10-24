# Independent grading adjudication — short-5 r1/r2

## Evidence and rule

Reviewed candidate `7129ffd352ee332c50b08db9d71a62d069afaaeb`, only `matrix-v3/short-5-r1` and `short-5-r2`. For all 24 decisions, the last user text in the saved HTTP request exactly matches that decision’s saved `input`; outputs are the original `rawOutput`. Both Sol grade runs requested `gpt-6.1-sol / medium`, with no observed grader tool items. The frozen grader packages contain authorized decisions and case/rubric facts, not the full deal or expected labels. I did not inspect the active r3 evidence. Original `grade/evaluation.json` and `grade/grader-output.json` remain untouched.

The case requires an actual diamond-development attempt while North’s CA remains, a real defense response and a later controlled decision; its two accepted lines include low-diamond/deep-finesse or early-concession routes preserving CA. The rubric accepts alternatives and spot cards, forbids conclusions from hidden holdings, and makes an unresolved strategic route uncertain rather than an automatic failure (manifest lines 105-127; rubric lines 1-3).

## Independent decision grades

| Run | Original Sol grades | Independent adjudication |
|---|---|---|
| short-5-r1 | Fail 1, 2, 7, 8, 9, 10; pass 3-6, 11-12 | **Fail 1, 2, 9, 10; pass 3-8, 11-12** |
| short-5-r2 | Fail 3; uncertain 7-12; pass 1-2, 4-6 | **Same** |

In r1, decisions 1 and 2 are one repeated plan defect: the initial plan says “choosing the honor according to East’s play,” but the order after South’s D3 lead is West–North–East, so North must act before East. Decision 2 keeps that active instruction while North chooses D7. Count this as one root repeated by `keep`, not two independent defects. Decisions 9-10 are a separate repeated order error: the replacement says to “finesse the ten if East plays low”; South leads, West plays, North chooses, and East plays last. Decision 10 keeps the same line. The finding is the impossible East-dependent choice, not the ambiguous phrase that North’s CA “can take it” later.

I overturn Sol’s r1 failures at 7-8. The model says North’s Q95 “may provide tricks only if the remaining high diamonds fall favorably.” At those snapshots DA and DK have been played, but DJ is still unplayed and absent from the authorized North/South hands; Q is not a certain winner. The model’s conditional caution is consistent with the visible information. Its completed first diamond step is historical by decision 3, so the earlier wording is not replayed as an active instruction. No other material false claim appears at 3-8 or 11-12.

In r2, decision 3 is a distinct material false-winner error: North’s DK is described as “Cash DK now” while DA is still unplayed in the authorized history. DK is a legal forcing play, but it is not a known cashing winner. Decisions 1-2 and 4-6 are factually and physically sound.

The six r2 uncertainties are route questions, not six separate proven failures. Decisions 7-8 retain one plan: three declarer tricks, two sure hearts, then a CT/club attempt and conditional D975, without establishing how the line supplies enough further tricks. Decision 8’s CT over C6 is legal and is not asserted to win. Decisions 9-10 form a second plan pair after the club finesse loses to CJ: HK is the correct winner of East’s HQ, but the new plan does not show whether CA access can establish North’s D975 past the still-unplayed DJ/DT. Decision 10’s H3 is a sound follow. Decisions 11-12 replace that plan after HA: trick counts are accurate, CA/CK are treated as a test rather than guaranteed winners, and diamonds remain conditional; however the route to the five/four additional tricks remains unresolved. None is proven impossible from the authorized facts, so uncertainty is the rubric-level result.

## Acceptance consequence

Both runs completed 12 decisions with legal execution, but each has at least one material failure; under acceptance.py lines 366-375 both attempts remain **fail**. The short-5 event trigger is covered in both: r1 has a North diamond attempt followed by D8/DA defense and later decisions. In r2, the first DQ/D8 is the policy’s intentional duck and is not counted by itself; the later North DK attempt is met by DA while CA remains, then later controlled decisions follow. The trigger is therefore covered on that second attempt. This does not erase r2’s DK “cash” failure. No conclusion is made about the full three-run matrix.
