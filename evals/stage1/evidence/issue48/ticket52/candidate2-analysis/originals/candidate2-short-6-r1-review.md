# Candidate 2: short-6-r1 independent public-information adjudication

**Attempt quality: PASS. Delivered decisions: 12 pass, 0 fail, 0 uncertain.**

This is an independent assessment of every final delivered model card, publicReason and actual effective plan. It is not a claim that the board was played to completion or that every targeted contingency occurred. Frozen source: `0a307cbde5498ed24b73da0d781cb9113ce92180`. Evidence root: `evals/stage1/evidence/issue48/ticket52/candidate2/short-6-r1` in the assigned worktree.

## Authority and scope

I began semantic review only after `playing-outcome.json` existed (play exit code 0). I used each decision's canonical `authorized_input`, public history and delivered `raw_output`/`effective_plan`, and checked the completed trace. I subsequently reconciled the saved independent grader output and evaluation after `grading-outcome.json` reported exit code 0 and evidence available. I did not read a hidden complete fixture, unfinished attempts, or use future events to justify an earlier decision. No model/native calls, source changes, feedback, raw-evidence writes, index writes or GitHub operations were made.

The trace contains 12 model actions, 3 forced actions and 13 opponent actions after the initial opening lead. All 12 model deliveries were review-approved; this establishes provenance only. There was one initial replacement and eleven keeps. The recorded bounded play ends after the model leads DQ at the start of trick 8: `complete: false`, declarer 4 tricks, defenders 3. Consequently no completed-contract result is established here.

## Independent decision findings

Every row assesses the selected card, its publicReason and the retained/installed plan together. Earlier completed plan steps are historical; they are not instructions to replay cards. No serious material defect or unresolved strategic dispute was found, so there is no failure counterbranch to prove.

| Decision | Card / operation | Judgment and public support |
|---|---|---|
| 0001 | S7 / replace | **Pass.** “Aim for nine tricks: one spade, three hearts, four diamonds and the club ace.” SA and CA supply two; KQJ opposite A43 supply three hearts; KQJT9 opposite 5432 supplies four diamonds after one DA concession. The plan explicitly reserves HA and South's diamond links, gives the HK/HQ-before-HA sequence, and qualifies unseen spade length/DA location: “cannot guarantee the contract against every layout.” S7 is an equivalent low follow to SK. |
| 0002 | S3 / keep | **Pass.** “Duck as planned, preserving the ace to win the third spade” matches SK–S7–S4 with South A93. It spends the first South low spade and preserves SA9. The initial plan's conditional communication purpose remains feasible. |
| 0003 | S9 / keep | **Pass.** “retaining the ace for the third round to exhaust a defender who started with three spades.” SQ is winning; South A9 can make the second duck with S9. The conditional three-card case is not presented as a known distribution; the effective plan retains its limitation. |
| 0004 | C4 / keep | **Pass.** “preserving all five diamonds and the heart entry while South wins the third spade.” North has no spade, CT54 and HA43/DKQJT9; South still has SA. C4 preserves the required diamond length and heart timing. North still has two clubs, enough for a later return to South's CA. |
| 0005 | D2 / keep | **Pass.** “Start establishing dummy's four diamond winners, retaining the heart ace as an entry if the defenders hold up their diamond ace.” SA has actually won; South can lead D2 from 5432 toward KQJT9. One diamond is spent from each hand on this phase, and HA remains a feasible later entry. Four winners is the source's eventual yield, not a claim that DA is already gone. |
| 0006 | DK / keep | **Pass.** “force out the diamond ace or win the first of dummy's diamond tricks” correctly allows either outcome against D2–D6 with East still to act. No DA location is invented. The preserved HA and South's remaining D543 keep the establishment route workable if DA is held up. |
| 0007 | HK / keep | **Pass.** “Win in hand, then cash the heart queen before crossing to the ace.” Public history now shows DK lost to East's DA, followed by HT. South KQJ and North A43 allow HK, HQ, HJ-to-HA for three hearts and dummy entry. North's QJT9 are now established. The existing plan already covers this defensive switch, so no replacement is required. |
| 0008 | H3 / keep | **Pass.** “preserving the heart ace as an entry to dummy's established diamonds.” After HT–HK–H5, H3 leaves North A4 opposite South QJ. It lets HK win and reserves H4 for HQ and HA for HJ. |
| 0009 | HQ / keep | **Pass.** “Cash the queen, playing low from dummy, then cross to the heart ace” is physically executable from South QJ and North A4. It keeps the heart entry until South's second heart winner is cashed. |
| 0010 | H4 / keep | **Pass.** “keeping the ace to win the third heart and enter dummy for the diamonds.” HQ–H6 is the actual trick; North A4 can follow H4. South retains HJ, and HA remains available to receive it. |
| 0011 | HJ / keep | **Pass.** “Cross to dummy's heart ace, then cash the four diamond winners and return to the club ace for nine tricks.” With three tricks already won, HJ-to-HA supplies the fourth, QJT9 supplies four more, and a North club to CA supplies the ninth. North CT5 and South CAJ6 make the return explicit and available. |
| 0012 | DQ / keep | **Pass.** “Cash the four established diamonds, then lead a club to South's ace to secure nine tricks.” Public state has North on lead with DQJT9/CT5, South D543/CAJ6, and four declarer tricks. DA and DK are already spent. South follows three diamond rounds, discards a spare club on the fourth, and retains CA to receive a North club. This is a feasible five-trick remainder; the trace records only its first DQ lead. |

## Resource, concession and plan-lifecycle check

The initial line deliberately allows two spade losses and one DA loss: three concessions leave room for nine declarer tricks. The actual public history records exactly those three losses through trick 7. The five-card diamond source loses DK to DA, leaving four established winners, rather than mistakenly counting five remaining diamonds. The heart suit produces three partnership tricks, not four, because South follows to HA with HJ. Both North low hearts are spent under HK/HQ before HA receives HJ, so the entry is preserved at every delivered keep.

The club return survives the C4 discard: North retains CT5. After the four diamonds South can retain CA by discarding CJ or C6 when void on the fourth round. No critical promised unfinished resource is consumed contrary to the plan. Keeps at 0002–0006 preserve the initial establishment route, 0007–0011 implement its anticipated heart handling, and 0012 keeps only the feasible cash-out remainder. Completed spade/diamond-concession/heart-entry phases do not require replacement merely because their cards are gone.

## Actual coverage, separate from quality

- **Two-round hold-up actually executed:** S3 ducked SK and S9 ducked SQ; North's S8 second-round follow and South's third-round SA were mechanical sole-legal actions. The two decisive South ducks were model decisions. North's C4 discard was also a model choice.
- **Defensive continuation actually present:** West led SK, continued SQ, then SJ; East followed S4/S5/S6. After winning DA, East switched to HT. This is actual public execution, not a predicted defense.
- **Diamond concession actually present:** the model led D2 and played DK; East's recorded DA won the fourth trick. DA was taken on the first diamond round, so a defender holding it up and repeated diamond development were not exercised.
- **Later entry coordination actually exercised:** HK, H3, HQ, H4 and HJ were model decisions; North's HA receipt was mechanical. The actual heart switch required no new plan because the original plan already specified the applicable sequencing. This demonstrates correct continued use of a conditional plan, not an observed replacement after an unforeseen material change.
- **Severance is conditional, not proven:** East's three spade follows do not publicly establish that East is now void. The subsequent heart switch also does not prove an inability to return a spade. The attempt executes the two ducks, but does not establish that they actually severed communications against the hidden distribution.
- **Cash-out remains partly prospective:** DQ is delivered and executed as the final recorded action. Four completed diamond wins and the final club transfer are unobserved in this bounded trace, although their feasibility follows from the current public cards. No club lead or third-club information window occurs; the only recorded club play is North's C4 discard on a spade. No inference/localization facet from such a window is credited.

## Saved grader reconciliation and evidence binding

The saved native grader returns 12 pass, 0 fail, 0 uncertain, and `grade/evaluation.json` reports mechanical/quality/overall pass for every delivered decision. My independent overlay agrees with all 12 quality labels; there are no raw-grade disputes. Approval, legal execution and grader agreement were not substituted for the decision-specific reasoning above.

SHA-256 at review:

- `play/trace.json`: `9fbff91d6f40e6dd4a33406a43980c57d2226b6376391213a714f4e3a35039a7`
- `grade/input.json`: `653ff7dfd4e83654841b766549eb529a6bdf1dcf0f090e3c9795b0b6643c98b4`
- `grade/evaluation.json`: `21b6fabfb557bdbbbcfe63ba01bda0b8cdeda5afb1f60516bf5ec1d7b4d0882b`

This report adjudicates only short-6-r1's delivered quality and the public execution coverage stated above. It does not alter candidate-level eligibility or overall acceptance.
