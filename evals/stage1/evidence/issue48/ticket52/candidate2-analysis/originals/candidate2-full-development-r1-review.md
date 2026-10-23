# Candidate 2 full-development-r1 independent adjudication

**Quality: pass — all 22 final model deliveries pass, 0 fail, 0 uncertain. Full-board coverage: demonstrated, 52 distinct cards / 13 tricks, declarer 10–3.** Frozen source `0a307cbde5498ed24b73da0d781cb9113ce92180`; normal operational-supplement attempt, separate from the interrupted short attempt elsewhere.

Evidence root: `/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate2/full-development-r1`. Before the saved normal playing outcome existed, only completion/count metadata was inspected. After play completed, read all final outputs/effective plans, authorized snapshots and public histories in `grade/input.json`, corresponding actual decision records, complete saved raw grader findings, trace/replay and summary. Every canonical input/raw final output/effective plan matches its decision record; each decision's public event history exactly equals the final actual prefix ending at its revision. No future event is treated as earlier quality knowledge.

| Decision / revision | Status | Exact final excerpt and decision-time support |
|---|---|---|
| 1 / 1, D3, replace | Pass | “We have five outside winners (two diamonds, two hearts and one spade), so four club tricks suffice.” South AK864/North Q72 and DA/DK, HA/HK, SA support the count and A→Q→K route; D3 follows DQ. Conditional branch audited below. |
| 2 / 3, DK | Pass | “Win with the king, then develop clubs while retaining the diamond ace as a stopper.” DK wins DQ/D3/D4, preserving DA. |
| 3 / 4, CA | Pass | “Start clubs with the ace, then lead toward dummy’s queen to identify the break while preserving control.” Both the low club approach and outside controls remain available. |
| 4 / 6, C2 | Pass | “Keep the queen for the second club round, following low under the ace.” C2 under CA leaves Q7. |
| 5 / 8, C4 | Pass | “Lead toward dummy’s queen; the defenders’ follows will reveal whether clubs require a safety duck.” South K864/North Q7 permit the test and retained king/duck route. |
| 6 / 10, CQ | Pass | “then use East’s follow or discard to determine the club continuation.” CQ beats current C9; East's future play is still a condition, not invented information. |
| 7 / 12, C7 | Pass | “Clubs are 3–2. Lead to the king to remove the last opposing club and secure five club tricks.” Both defenders actually followed twice; five initial outside clubs leave CJ. North C7 reaches South K86. |
| 8 / 14, CK | Pass | “Cash the king to capture West’s remaining jack, establishing both small clubs and securing ten tricks.” East has shown out with H2, so CJ is publicly localized to West. CK wins; five clubs plus the five outside winners make ten. |
| 9 / 16, C8 | Pass | “Cash the established clubs, discarding dummy’s small diamonds while preserving the heart entry.” All defensive clubs are consumed; North D865 is spare while HK74 remains. |
| 10 / 18, D5 | Pass | “Discard a small diamond, preserving dummy’s heart king and major-suit length.” North is club-void; D5 consumes no necessary winner/entry. |
| 11 / 20, C6 | Pass | “Cash the last club winner, discarding another small diamond from dummy.” C6 is established, North D86 still supplies the discard. |
| 12 / 22, D6 | Pass | “retaining both major-suit holdings and a diamond to follow under the ace.” D6 leaves D8 plus HK74/S862, consistent with DA and later heart movement. |
| 13 / 24, DA | Pass | “the spade ace and both heart honors then secure ten tricks.” Six won; DA, SA, HA and reachable HK supply four more. DK is historical, not reused. |
| 14 / 28, SA | Pass | “Cash the spade ace, then take both heart honors to secure the overtrick.” Seven won; SA→HA→low heart to HK is available. |
| 15 / 30, S2 | Pass | “Follow low under the ace, retaining dummy’s higher spades.” S2 follows actual SA/SJ, retaining HK and the available heart route. |
| 16 / 32, HA | Pass | “Cash the heart ace, then lead to dummy’s king for a guaranteed tenth trick.” Eight won; North follows low and South retains H63 to reach HK. |
| 17 / 34, H4 | Pass | “Follow low, preserving the heart king for the tenth trick.” H4 under HA/H9 leaves K7 opposite 63. |
| 18 / 36, H3 | Pass | “Lead to dummy’s heart king to secure the overtrick.” Nine won; H3 reaches North K7 after HA is consumed. |
| 19 / 38, HK | Pass | “Win with the heart king to secure the tenth trick.” HK beats current HT and any remaining heart; the ace is historical. |
| 20 / 40, H7, replace | Pass | “The outstanding heart queen and spade KQT control our remaining cards.” At this snapshot those honors are genuinely unplayed: the earlier SA trick contained East S7, not SK. North H7/S86 opposite South H6/S94 have no sure winner. “Exit with H7” is feasible and does not promise an eleventh trick. |
| 21 / 45, S4 | Pass | “Discard the lower spade, retaining the nine for the last trick.” East leads D9; South is diamond-void with S94. S4 retains the higher spot; H7 exit is completed history. |
| 22 / 47, S6 | Pass | “Discard the lower spade; ten tricks are already secured.” Current D9/S4/SQ is still won by led diamond D9; North S86 is diamond-void. S6 preserves S8 without inventing a winner. |

## Whole-hand feasibility and active-plan lifecycle

The initial 3–2 line is executable across both hands: CA with North low, South low club to CQ, North's final club to CK, then South's two long clubs. It provides five clubs plus DK/DA, SA and HA/HK = ten. The initial club-concession language is conditional; once both defenders follow twice, no concession is necessary or taken. The 4–1 branch retains CK while ducking the third round, then removes the last higher defensive club and cashes the remaining long club for at least four club tricks. If North's small club happens to win against only lower opposing spots, the resulting extra trick does not strand the contract: outside controls return to South and C8 still outranks those spots. SA/DA and both heart controls have not been prematurely spent. A 5–0 break explicitly requires reassessment and does not carry a four-club guarantee.

The actual 3–2 history retires adverse-break branches. Initial plan stays active through decision 19, with completed cashes historical and the unspent heart entry materially available. South actually cashes HA, leads H3 and North wins HK; this spends the named entry in its intended phase, not before a critical unfinished transfer. Decision 20 then replaces the exhausted development plan with a complete three-trick exit plan. The two later keeps preserve that remainder; no high card is reused.

## Independent structural replay and coverage

Independently replayed the saved actual 52-event list using ordinary notrump turn/winner/follow-suit rules. The list contains every rank of every suit exactly once, sequences 0–51, 13 cards per seat, and all holdings empty at the end. Thirteen trick leaders follow the previous actual winner; no ownership, turn or follow-suit error occurs. Calculated winners: South 8, North 2, East 2, West 1, therefore declarer 10 and defenders 3. This is a separate actual-event audit, not a quality inference from the successful result. Reconstructing defensive holdings from completed actual events was used only for retrospective structural legality; those reconstructed future cards were never supplied as earlier semantic facts.

Bound all 22 proposed final selected cards to their actual event at the recorded revision. The other four controlled cards are sole legal choices: North D8 at sequence 26, South H6 at 42, South S9 at 49 and North S8 at 51. No nonforced controlled substitution is present. Twenty-two model actions + four forced controlled cards + 26 actual defensive cards account for all 52; the opening defensive DQ is distinct from the 25 subsequent opponent actions.

Actual material continuation includes consumed CA/CQ, the C7→CK return and C8/C6 cashing, then the completed HA/H3/HK transfer. Actual endgame play exits H7 to HQ, discards under East's D9 and loses the final spade trick to SK. Full-board coverage is demonstrated through actual choices and all thirteen completed tricks, not assumed from a legal short prefix or earlier attempt. No reference route or making-contract-only quality gate is imposed.

## Raw reconciliation, counts and limits

Read all saved raw findings: 22 passes, no material disagreement. Both independent quality and replay checks support the conclusion separately from reviewer approvals. Two replacements, twenty keeps, no withdrawals; each delivered decision has one semantic round. Twenty-two player/twenty-two reviewer attempts, 44 RPC requests, zero technical retries, zero contested deliveries. Normal exit 0; driver automatic time 343.128986 seconds, separate outer playing wall time 343.466 seconds. Final result is 3NT making ten tricks (one overtrick), 10–3. These timers and this completed result apply only to this attempt.

No hidden fixture, other unfinished run, new model call, live role feedback, source/index/raw-artifact edit or GitHub operation was used. Raw grades remain immutable. This full-board pass does not repair the separate interrupted capture, resolve the short-3 coverage condition or establish candidate-level acceptance/broad ability.
