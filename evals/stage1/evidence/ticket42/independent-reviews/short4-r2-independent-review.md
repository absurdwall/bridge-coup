# Independent saved-output adjudication — short-4-r2

Source `8266947`; corpus `stage1-finite-v1`; rubric `stage1-basic-v2`. Reviewed all 16 actual answers, English inputs/deltas, current visible hands/tricks, retained plan and every grader finding. No hidden defender holdings/future events, model call, regrade or original-file change. There is no root runtime failure: 16 requested/model-executed actions, one forced action, legal partial play, normal exit.

**Conservative proposed review: 6 fail / 10 pending / 0 pass. Overall quality FAIL.** Raw grader reports 16 fail. The clear current errors below independently settle the no-go; pending rows distinguish repeated old-plan disputes from new current errors. Pending is not a pass.

The initial plan contains two different defects: “dummy's ace **if available**” is a known-inapplicable conditional whose interpretation remains disputed; “use dummy's **remaining diamond honors** carefully” is an unconditional false possession claim. North has D8653. The latter supports decision 1's fail. Its continued repetition does not by itself prove a new severe current error in each later otherwise sound decision; those rows remain pending under the conservative retained-plan policy.

| Decision | Proposed | Independent current-position review |
|---|---|---|
| 1 | fail | North D5 is legal and the reason explicitly acknowledges no dummy ace, but the installed plan unconditionally assigns dummy nonexistent remaining diamond honors. This finding does not depend on rejecting the guarded ace clause. |
| 2 | pending | South DA wins DQ-D5-D4 as stated. No current wrong-hand action or nonexistent finesse is executed. Grader fails solely for the retained diamond-honors fragment; preserve that plan-consistency dispute. |
| 3 | pending | South DK is a sure remaining winner after DA won; cashing it before clubs is physically feasible. Sole grader basis remains the retained plan. |
| 4 | pending | North D3 is its lowest remaining diamond under South DK; preserving D8/D6 as potential later cards does not claim they beat DK. Sole grader basis remains the retained plan. |
| 5 | pending | South C4 toward North CQ is an accepted club route and CQ is an actual dummy entry. South CA/CK and HA plus North HK provide transport. Sole grader basis remains the retained plan. |
| 6 | pending | North CQ covers West C9 correctly. C7 is not an established current stopper while CJ/CT are outstanding; the wording calls it a “later stopper,” without specifying a future sequence. Under the ordinary two-further-round establishment C7 would be consumed under CK, so the claim lacks a supported concrete route. Keep this future-route/wording issue pending rather than convert it into an explicit rank reversal or already-established-entry claim. The retained-plan issue also remains. |
| 7 | pending | After CQ wins, North C2 legally leads toward South CAK86. “Remaining low club” need not mean North has only one club (C7 also remains). Sole grader failure is the old plan. |
| 8 | fail | North C2-East CT is the current trick. Selected South C8 cannot “take the club trick cheaply”; 8 < T. CA/CK could win. This is a direct action/winner contradiction, independent of the old plan. |
| 9 | fail | East led D9; South is void and S4 is a discard. Calling it a spade lead toward “dummy's king” invents both the trick structure and a North SK (North has S862; its king is HK). |
| 10 | fail | At East D9-South S4-West DT, West's ten is winning. “East's nine is currently winning” is false; North D6 follows legally but cannot cure the incorrect current-winner explanation. |
| 11 | pending | South H3 discards under West DJ-North D8-East H2. South is diamond-void, West DJ wins, and keeping HA/spade honors is feasible. Sole grader failure cites the retained plan after North's last diamond is consumed; no new current false diamond action is specified. |
| 12 | pending | On West SK, North S2 is its lowest spade and preserves S6/S8; SK is currently winning. Sole grader failure is the retained plan. |
| 13 | fail | South holds SA/S9 and selects S9 beneath West SK. “Preserve the ace and nine” contradicts consuming the nine. A conscious duck could be legal/non-optimal; preserving the selected card is still impossible. |
| 14 | fail | West HT is led and North selects H4. The reason says to lead a club toward South CA/CK, which describes neither the current trick nor the mandatory heart-follow action. |
| 15 | pending | South HA beats HT-H4-H8 as stated; North HK remains an actual later entry. Sole grader failure repeats nonexistent dummy diamond honors. |
| 16 | pending | South CA is a top club, with CK6, SA and H6 remaining; North HK/C7 remain. Cashing South winners and then H6 toward HK is feasible. The grader itself accepts the route and fails solely for the retained plan. |

## Entry/consumption trigger

**Pending, with partial actual entry evidence.** Club development was genuinely attempted and CQ was consumed at sequence 10. CA/CK remain in South through decisions 1–15; decision 16 plays CA, then the bounded run stops. The runner's automatic `uncovered` result reflects its conservative two-consumed-club-honors helper; that numerical threshold is not itself an additional manifest rule.

After CQ is spent, decision 9 explicitly attempts to describe entry management but mistakes a diamond-trick discard for a lead toward a nonexistent North SK. Decision 14 has a genuine choice to win West HT with North HK and reach dummy, but instead selects H4 while describing an impossible club lead. Decision 15 wins South HA while leaving North HK; decision 16 cashes South CA with H6-to-HK transport still available. These facts offer meaningful evidence about entry accounting, including clear failures, even though the full intended club-establishment/consumed-honors/later-entry sequence is not demonstrated. Whether those partial actual entry choices satisfy the literal short-4 trigger requires root adjudication; do not declare it uncovered solely because only CQ was previously consumed, or claim successful/complete specialized coverage.

No citation-parser defects appear here: all 16 grader failures contain exact findings. Repeated retained-plan severity and C7's “later stopper” are substantive adjudication disputes. Decisions 1,8,9,10,13,14 independently establish failure without resolving those disputes.
