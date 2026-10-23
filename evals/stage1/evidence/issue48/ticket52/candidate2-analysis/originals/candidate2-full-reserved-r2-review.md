# Candidate 2 full-reserved-r2 independent adjudication

**Quality: pass — all 20 final model deliveries pass, 0 fail, 0 uncertain. Full-board coverage: demonstrated, 52 distinct legal cards / 13 completed tricks, declarer 13–0.** This former reserved board is a used regression, not new held-out evidence. Frozen source `0a307cbde5498ed24b73da0d781cb9113ce92180`; final operational-supplement slot.

Evidence root: `/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate2/full-reserved-r2`. While play was running, inspected completion/count metadata only. Semantic inspection began after saved `playing-outcome.json` showed normal exit 0. Read the brief/full rubric, all final outputs/effective plans/authorized snapshots in `grade/input.json`, corresponding actual decision records, complete saved raw grader findings and full actual replay/summary. Every canonical input/raw final output/effective plan matches its decision record; every decision history equals the actual prefix ending at that revision. Quality judgments use those prefixes, not future events or the eventual thirteen tricks.

| Decision / revision | Status | Exact delivered excerpt and public support |
|---|---|---|
| 1 / 1, HQ, replace | Pass | “We have nine immediate tricks: three hearts, two spades, three clubs and the diamond ace.” HQ plus South AK, SK/SA, CA/CK/CQ and DA support this. HQ wins HJ and places North on lead for DQ; SK/CA are real entries. |
| 2 / 3, H5 | Pass | “Let dummy's queen win, preserving both heart controls and the lead for the diamond queen.” H5 under HJ/HQ/H2 preserves South AK and North's lead. |
| 3 / 4, DQ | Pass | “Develop diamonds for overtricks while both major suits remain securely controlled.” North QJ93 toward South A72 is feasible; HAK and SAK remain. |
| 4 / 6, DA | Pass | “Cover the king with the ace, establishing dummy's jack while retaining every side-suit control.” East has actually covered DQ with DK; DA wins, leaving DJ93 and SK/CA access. |
| 5 / 8, D2, replace | Pass | “Ten tricks are now available: three hearts, two spades, three clubs and two diamonds.” HQ/DA already won plus remaining HAK/SAK/CAKQ/DJ gives ten. D2 toward North J93 can try D9 or cover West DT with DJ, with control/entry recovery if DT wins. |
| 6 / 10, D9 | Pass | “Finesse the nine as planned. This seeks an extra diamond trick without risking the contract.” D9 beats current D8; a possible East DT is a conditional concession with ten baseline winners and side controls still preserved. |
| 7 / 12, DJ | Pass | “Cash the diamond jack and check whether both defenders follow, establishing dummy's last diamond.” DA/DK/DQ are gone, making DJ top. Both following a third diamond round would exhaust all six defensive diamonds. |
| 8 / 16, D3 | Pass | “Both defenders followed, so the last diamond is a winner. Discard a low spade from South, retaining all four clubs.” Public defensive DK/D5/D8/D4/D6/DT exhaust all diamonds. South SA64 can discard low without spending SA or club length. |
| 9 / 18, S4 | Pass | “Discard a spare spade, preserving both spade winners and all four clubs for a possible extra trick.” On North D3/East C2, S4 leaves South SA6 and CKQ83, North SK72/CA65. No extra club winner is assumed known. |
| 10 / 20, SK, replace | Pass | “Twelve tricks are secure: five already won, two spades, two hearts and three clubs.” The replacement supplies SK with South S6, low spade to SA, HA/HK, then C3 to CA and a low club back to CK/CQ; C8 remains conditional on actual remaining clubs. |
| 11 / 22, S6 | Pass | “Let dummy's king win, retaining the ace for the planned return to hand.” S6 under SK/S3 leaves South SA and North low spades for the next transfer. |
| 12 / 24, S2 | Pass | “Return to the spade ace, then cash both heart winners before testing clubs.” North S72 toward South's remaining singleton SA is an available transfer; all clubs remain held. |
| 13 / 28, HA | Pass | “Cash the heart winners before clubs, keeping all club length intact.” South HAK/CKQ83 and North H84/CA65 permit both heart cashes followed by the club crossing. |
| 14 / 30, H4 | Pass | “Follow low under the ace; cash the heart king next, then test clubs.” H4 under HA/H6 leaves H8 to follow HK without discarding a club. |
| 15 / 32, HK | Pass | “Cash the last heart winner before testing clubs for a possible thirteenth trick.” Eight won; HK is ninth, leaving South on lead with four clubs and North CA65. No later heart entry is needed by the actual CA-first club route. |
| 16 / 36, C3 | Pass | “Lead to the club ace, then return to the king and queen, checking whether the eight becomes a winner.” C3 from CKQ83 reaches CA65; North retains a low club to CK, with CQ/C8 then in South. |
| 17 / 38, CA | Pass | “Win the ace, then return a low club to South's king and queen to test for the final trick.” CA wins current C3/C4 regardless of East's play and preserves North C65 for return. |
| 18 / 40, C5 | Pass | “Lead to South's king, then cash the queen and check whether the eight is established.” North C65/S7 and South CKQ8 permit the return without consuming C8 or needing a missing side entry. |
| 19 / 42, CK | Pass | “Win the jack with the king, then cash the queen to establish whether the eight wins the last trick.” East CJ is now actual; CK beats it, while C8's status remains appropriately subject to the outstanding inventory. |
| 20 / 44, CQ | Pass | “Cash the queen, drawing the only outstanding club, the nine, and establishing the eight for thirteen tricks.” Public defensive C2/C4/CT/CJ/C7 account for five of six initial outside clubs. Only C9 remains, forced to follow CQ; South C8 will then be the final winner in the same hand. Eleven tricks already won plus CQ/C8 gives thirteen. |

## Whole-hand route, concessions and active advice

The initial DQ finesse is controlled: cover an actual East DK with DA, otherwise play low and permit at most a diamond-king concession while major controls and North entries remain. The early replacement after DK/DA are spent correctly counts DJ as a new sure diamond winner. The D9 probe can lose to DT without losing the nine-trick contract or the ten-winner cashing baseline: HQ/DA already won, HAK, SAK, CAKQ and DJ remain accessible through SK/CA. These are total/won/remaining categories, not duplicated aces or spent entries.

Actual D9 wins and DJ's third-round follows establish D3; the plan's hypothetical losing branches become historical/eliminated rather than future commands. At five tricks won, decision 10 installs a full eight-trick continuation. Cashing all side winners before testing clubs is physically valid for this route: South C3 enters North CA, North's low club then reaches South CK, leaving CQ/C8 in South. Unlike a club route ending in North after its final honor, no later heart return is required. Thus HA/HK being spent before the test does not violate an unfinished necessary transfer. Three replacements and seventeen keeps remain coherent with actual resource consumption.

The fourth club is treated as possible until observed counting justifies certainty. At decision 20, only C9 remains outside; this inference is already established by the authorized prefix, not by its future actual fall. The route to thirteen is then unconditional in notrump because CQ and C8 are in South. Before that point, the text does not assume original 3–3 clubs, an unknown defensive holding or an extra winner.

## Literal replay, sources and full-board coverage

Independently replayed the complete actual event list under ordinary notrump leader/turn/ownership/follow-suit/winner rules. All 52 distinct cards equal the complete thirteen-rank/four-suit deck, sequences 0–51, thirteen reconstructed cards per seat, no residual cards or legality errors. Each next trick is led by the previous actual winner. Computed winners are North 6 and South 7, defenders 0, across thirteen tricks. Complete actual events are used retrospectively only for structural legality; no reconstructed defensive holding becomes earlier quality knowledge.

All 20 final model-selected cards bind their executed event at the recorded revision. The other six controlled cards are genuinely sole legal choices: South D7 at sequence 14, South SA at 26, North H8 at 34, North C6 at 46, South C8 at 48 and North S7 at 50. No nonforced substitution occurs. Twenty model + six forced controlled + 26 defensive cards account for all 52, including the one opening defensive card distinct from 25 later opponent actions.

Actual execution includes both diamond development/spot assessment and full communication through SK→SA and CA→CK. All side winners and all four clubs are actually cashed. Full coverage is demonstrated through all thirteen completed tricks, separately from the twenty semantic checks and separately from simply observing a successful contract. This is regression-case evidence, not held-out generalization.

## Raw reconciliation, counts and limits

Read all saved raw grader findings: 20 passes; no material disagreement with this independent review. One semantic round per delivery, twenty player/twenty reviewer attempts, 40 RPC requests, no feedback revision, technical retry, contested delivery or withdrawal. Normal exit 0 and board complete; final 3NT makes thirteen tricks (four overtricks), 13–0. Driver automatic time 286.278294 seconds; separate outer playing wall time 286.628 seconds.

No hidden fixture, other unfinished output, native/grader call, source/index/raw-artifact edit, live-role feedback or GitHub operation was used. The interrupted short-5-r1 remains incomplete and the separately adjudicated stronger short-3 facet remains unmet at candidate level. This full regression pass neither repairs those blockers nor changes overall candidate 2's NO-GO status or establishes broad ability. Original raw grades remain unchanged.
