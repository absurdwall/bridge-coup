# Independent saved-output adjudication — short-3-r3

Frozen source `8266947`, corpus `stage1-finite-v1`, rubric `stage1-basic-v2`. Read every saved answer, visible snapshot/current trick, English delta, effective plan and original grade. No full defender holdings/future events were used; no model call, regrade or evidence edit occurred.

**Proposed: 5 pass / 7 fail / 0 pending. Run quality FAIL.** All 12 actions are mechanically legal. Raw evaluation is 7 fail / 5 uncertain; the latter five are raw pass verdicts with empty findings, hence evaluator-output defects. Original results remain unchanged.

| Decision | Reviewed | Visible facts and basis |
|---|---|---|
| 1 | fail | North D8653 selects D6 under West DQ, but the unconditional plan says “Win the diamond lead in dummy with the king” and the current reason says “The diamond king wins.” DK is South's, not North's; D6 is not DK and cannot beat DQ. This is not an “if available” condition. |
| 2 | fail | South DA is legal and its reason correctly locates both honors in South. However `keep` retains the unconditional wrong-hand DK instruction while this very opening trick is still active. The active plan and current action remain materially inconsistent; this is not merely an old completed step. |
| 3 | pass | The first trick has now ended with South DA. South DK is high and cashes legally. Its reason explicitly acknowledges DA already won; the residual opening-plan defect is historical, not a new current-hand contradiction. Cashing DK before clubs is a feasible alternative. |
| 4 | fail | On South DK-West D2, North holds D853 and selects D8. “Dummy is void in diamonds” and “discard a low spade” are both false and contradict the actual follow-card. |
| 5 | pass | South CA starts the expressly accepted AK-then-Q club route and retains CK. North still has CQ72 and HK; South HA supplies the obvious eventual return entry. No need to restate every entry. |
| 6 | fail | On South CA-West C3, North CQ72 selects C2. “Dummy is void in clubs” and “slough a low spade” contradict both holdings and action. |
| 7 | pass | South CK continues club establishment, with North CQ7 remaining. The reason's generic later “entry or finesse decision” does not prescribe an impossible finesse or assert a specific hidden honor. Preserved club spots and actual heart entries permit the accepted route. |
| 8 | fail | On South CK-West C9, North CQ7 selects C7. The reason again falsely calls dummy club-void and describes a spade discard. North actually retains all S862. |
| 9 | pass | South H3 leads toward North HK while retaining HA. At this point both defenders followed two club rounds; moving to CQ through HK is physically available, with a low heart back toward HA afterward. |
| 10 | pass | On South H3-West H5, North HK beats H5 and preserves South HA as a return entry. Correct hand/rank facts and current action. |
| 11 | fail | North's HK has just been consumed. Remaining North hearts H7/H4 are not established entries: all unplayed opposing hearts HQ/J/T/9/8 outrank H7, while South HA is an entry to South. “Preserving dummy’s remaining heart entry” falsely treats a current North entry as available without a conditional development route. The legal S2 toward South SA does not cure that factual error. North CQ remains a separate actual entry, but is not a heart. |
| 12 | fail | North has already played S2, East S3, and South selects SA. “Dummy’s eight is not high enough to overtake East’s three” reverses rank order (8 > 3) and invokes a North card after its turn. SA legally wins; the false rank/action explanation is independently severe. |

## Trigger and evaluator review

**New-club-information trigger covered.** Sequence 8–11 is CA-C3-C2-C5; 12–15 is CK-C9-C7-CT. Both defenders follow to both rounds, proving the five missing clubs split 3–2 after sequence 15. Decision 9 at revision 16 is a subsequent real model decision. No third club round has yet occurred, so which defender holds the remaining CJ is not observed by the end of these 12 decisions. Do not claim coverage of that later localization/discard ordering.

Rows 3,5,7,9,10 have raw grader pass labels with no cited findings; their manual passes above rest on fresh visible facts. Grader failures 1,2,4,6,8,11,12 are independently supported, with row 2 specifically limited to the still-active opening trick. The known-inapplicable-conditional policy does not apply to this run's unconditional initial DK claim.
