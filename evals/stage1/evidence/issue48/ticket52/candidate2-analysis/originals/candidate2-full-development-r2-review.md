# Candidate 2 full-development-r2 independent adjudication

**Quality: pass — 20 delivered model decisions pass, 0 fail, 0 uncertain. Full-board coverage: demonstrated; 52 distinct legal cards / 13 completed tricks, declarer 10–3.** Frozen source `0a307cbde5498ed24b73da0d781cb9113ce92180`; original slot 20, operational supplement 7/9, distinct from the interrupted short capture.

Evidence root: `/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate2/full-development-r2`. Normal playing outcome is saved with exit 0. Read the brief/full rubric, all 20 final answers/effective plans/authorized snapshots in `grade/input.json`, corresponding decision records, all saved raw grader findings and full actual replay/summary. Every canonical input/raw final output/effective plan matches its actual decision record; all 20 public histories exactly match actual prefixes ending at the respective revision. This attempt was judged independently of the earlier full run.

| Delivery / revision | Status | Exact final excerpt and decision-time support |
|---|---|---|
| 1 / 1, D3, replace | Pass | “There are eight immediate winners: two diamonds, two hearts, one spade and three clubs.” South AK864/North Q72, DA/DK, HA/HK and SA support the count. The A→K→Q club route and conditional fourth-club establishment are feasible; D3 follows DQ. |
| 2 / 3, DK | Pass | “Win with the king, retaining the ace as a diamond stopper while developing clubs.” DK wins DQ/D3/D4; DA remains. |
| 3 / 4, CA | Pass | “Start establishing clubs, checking the break while retaining all side-suit controls.” CA begins the named sequence with DA/SA/HA/HK unspent. |
| 4 / 6, C2 | Pass | “Follow low, preserving the queen for the third club round.” C2 under CA leaves Q7, enabling C7 under CK and CQ subsequently. |
| 5 / 8, CK | Pass | “Cash the second club honor, continuing to establish at least four club tricks.” Both defenders actually followed to CA; CK864 opposite Q7 retains the intended route. |
| 6 / 10, C7 | Pass | “Preserve CQ to win the third club round and establish South’s remaining clubs.” C7 follows under CK, leaving CQ and South 864. |
| 7 / 12, C4 | Pass | “Lead to CQ, drawing the last opposing club and establishing C8 and C6 for ten tricks overall.” Two actual follows from each defender account for four of five initial outside clubs; only CJ remains. C4 to CQ removes it regardless of owner. |
| 8 / 16, HK, replace | Pass | “With four tricks already won, cash HK now, then lead a low heart to HA.” North HK74/South HA63 makes the transfer possible. Together HK, HA, C8, C6, DA and SA are six additional tricks, giving ten. The following sentence's “six more tricks” is this aggregate, not six new tricks from its four-card list alone. |
| 9 / 18, H3 | Pass | “Keep HA as the entry to South’s remaining winners after dummy’s king wins.” H3 under HK/H8 preserves HA and North H74 for the next transfer. |
| 10 / 20, H4 | Pass | “Cross to HA to cash South’s remaining winners and secure ten tricks.” HK is already historical; H4 to HA gives five further tricks (HA plus C86/DA/SA) after five won. |
| 11 / 22, HA | Pass | “Win and retain the lead to cash both established clubs and the diamond and spade aces for ten tricks.” HA beats actual HJ; six won then four cashing South winners gives ten. |
| 12 / 24, C8 | Pass | “Cash an established club winner, continuing toward ten tricks without surrendering the lead.” All defensive clubs are gone; C86/DA/SA are accessible in South. |
| 13 / 26, D5 | Pass | “Discard a small diamond; all remaining winners are in South.” North is club-void, D865 is expendable; South C6/DA/SA are the remaining sure winners. |
| 14 / 28, C6 | Pass | “Cash the last established club, then collect DA and SA to secure ten tricks.” Seven won plus these three immediate winners gives ten. |
| 15 / 30, D6 | Pass | “Discard another small diamond, retaining all remaining winners.” North D6 consumes no necessary resource; D8 remains to follow South DA, and SA remains. |
| 16 / 32, DA | Pass | “Cash the diamond ace to secure the contract, then take SA for the overtrick.” Eight won; DA and SA are immediately cashable. DK is already consumed. |
| 17 / 36, SA | Pass | “Cash the spade ace to secure the overtrick.” Nine won; SA is still held by South. |
| 18 / 38, S2 | Pass | “Follow low under the ace, securing the tenth trick.” S2 follows SA/SJ and cannot disturb the ace's win. |
| 19 / 40, S4, replace | Pass | “Lead S4, retaining S9 and dummy’s S8 in case the defense allows a promotion.” North H7/S86 and South H6/S94 have no forced additional winner against outstanding spade/heart honors. The replacement explicitly makes promotion conditional and supplies an executable exit. |
| 20 / 42, S6 | Pass | “Follow low under the queen, retaining dummy’s higher spade. Ten tricks are already secured.” S6 legally follows S4/SQ while preserving North S8 and South S9. |

## Whole-hand route and plan lifecycle

The initial 4–1 route does not require unavailable transport: after CA/CK and a low club to CQ, lead a low North heart to HA while preserving HK, concede the fourth club, then recover through DA, SA or HK. A heart return to HK leaves a low diamond/spade route to South; a return to DA or SA leaves South able to cash the club, reach HK by a low heart and return through the other South side entry if needed. Four clubs plus two diamonds, two hearts and SA make nine total. The initial plan does not promise nine on 5–0 and asks for reassessment before consuming the second honor. No adverse-break contract guarantee or unique best-play test is added.

Actual two-follow history proves 3–2 and retires the concession branch. After all three club honors are consumed, decision 8 installs a complete cashing plan: HK, a low heart to HA, then C86/DA/SA. “South’s five remaining winners” in that decision's reason correctly includes HA before the transfer plus four other winners. Actual H3 does not overtake HK; H4/HA then crosses, and the South winners are cashed without another entry. Decision 19 replaces the completed cashing plan with endgame advice; decision 20's keep preserves its explicit higher spade spots. Three replacements and seventeen keeps do not reuse historical cards or obsolete control conditions.

## Independent actual-event/source replay and coverage

Independently simulated the full saved actual event list under notrump turn, follow-suit and winner rules. Exactly 52 distinct cards equal all thirteen ranks of each suit; event sequences are 0–51, initial reconstructed seat counts are thirteen each, and all holdings finish empty. Every trick leader follows the previous actual winner and no legality error occurs. Calculated trick winners: South 8, North 2, West 2, East 1; declarer 10–3 across all thirteen tricks. Completed actual events are used retrospectively only for this structural audit, never to supply earlier semantic knowledge or a hidden fixture.

Each of the 20 model-selected cards matches its executed event at the recorded revision. Six other controlled plays are genuinely sole legal choices: North CQ at sequence 14, North D8 at 34, North S8 at 45, South S9 at 47, North H7 at 49 and South H6 at 51. There is no nonforced controlled substitution. Twenty model cards + six forced controlled cards + 26 defensive cards account for all 52 (one opening defensive card plus 25 later opponent actions).

Material transport is performed, not inferred from opportunity metadata: CA/CK/CQ are consumed, HK is cashed with H3 following, H4 reaches HA, then South C8/C6/DA/SA are cashed. Endgame replacement S4/S6 and subsequent sole-card finishes also execute through trick thirteen. Full-board coverage is covered independently of the making-contract result or reviewer approvals.

## Raw reconciliation and limits

Full saved raw grader: 20 passes, agreeing with independent review; no material raw dispute. Normal exit 0, board complete, final 3NT making ten tricks (one overtrick). Twenty player/twenty reviewer attempts, 40 RPC requests, one semantic round per delivery, no feedback revision, no technical retry or contested delivery. Driver automatic elapsed 271.354027 seconds; separate outer playing wall time 271.657 seconds. These are distinct timers for this completed attempt.

No other unfinished output, hidden fixture, new model call, live-role feedback, source/index/raw-artifact edit or GitHub operation was used. The earlier interrupted partial remains separate, and this result neither repairs it nor resolves the short-3 cohort condition or candidate-wide acceptance. Full replay and ten tricks support execution/coverage; they are not substitutes for the twenty individual quality checks above.
