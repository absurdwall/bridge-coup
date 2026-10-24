# Candidate 2: short-6-r2 independent public-information adjudication

**Attempt quality: PASS. Delivered decisions: 12 pass, 0 fail, 0 uncertain.**

Frozen source: `0a307cbde5498ed24b73da0d781cb9113ce92180`. Evidence root: `evals/stage1/evidence/issue48/ticket52/candidate2/short-6-r2` in the assigned worktree. This report judges every delivered model card/publicReason/effective plan, separately from coverage and candidate-level eligibility.

## Scope and evidence discipline

Semantic inspection began after `playing-outcome.json` existed, with exit code 0. I used canonical `authorized_input`, delivered `raw_output` and `effective_plan`, and actual public histories/trace. The saved grading outcome subsequently became available with exit code 0 and evidence available; its raw judgments were reconciled only after the public decision review. No hidden complete fixture, unfinished r3 output, other attempt strategy, future defender card as earlier decision-time knowledge, or outside bridge solver was used. No model/native calls, live feedback, source/raw/grade/index edits or GitHub operations were made. The earlier r1 report remains unchanged.

There are 12 model deliveries, all review-approved, plus 3 forced controlled cards and 13 opponent actions after the initial lead. The plan lifecycle is one initial replacement and eleven keeps. Reviewer approval establishes delivery provenance, not quality. This bounded trace ends after North's DQ lead at the start of trick 8: `complete: false`, declarer 4 tricks, defenders 3. It does not record a completed contract.

## Every delivered decision

All judgments include the actual active plan, not merely the current legal card. Completed phases remain history; eliminated conditions do not require plan replacement. No serious material defect or unresolved strategic question was found, so there is no failure counterbranch to establish.

| Decision | Card / operation | Independent judgment, excerpt and authorized support |
|---|---|---|
| 0001 | S7 / replace | **Pass.** “Aim for nine tricks: one spade, three hearts, four diamonds after conceding the ace, and the club ace.” SA and CA supply two tricks, KQJ opposite A43 supplies three hearts, and KQJT9 opposite four small diamonds supplies four diamonds after DA. “Preserve HA as the entry to any diamonds stranded after South's four diamonds are spent” correctly accounts for a late DA hold-up. The plan reserves HA for the third heart round, avoids an unnecessary club finesse, and explicitly limits the hold-up's protection against unseen spade/DA layouts. S7 is a valid low follow to SK. |
| 0002 | S3 / keep | **Pass.** “Duck the first spade as planned, preserving the ace” matches SK–S7–S4 and South A93. S3 leaves SA9 and implements the first duck while preserving the initial establishment/entry route. |
| 0003 | S9 / keep | **Pass.** “retaining SA for the third round to cut communications with a defender holding three spades.” SQ currently wins and South holds A9. This is the second duck and a conditional three-card-defender purpose, not evidence that the unseen defender has exactly three spades. The retained plan explicitly says the hold-up cannot eliminate risk in every layout. |
| 0004 | C4 / keep | **Pass.** “preserving all diamonds and the heart entry while South wins with SA.” North is void in spades with CT54, DKQJT9 and HA43. C4 spends an expendable club, leaving two clubs for eventual return to CA; South's SA is available to win SJ. |
| 0005 | D2 / keep | **Pass.** “Establish dummy’s diamonds now, forcing out the ace while preserving HA as a later entry.” South has just won SA and leads D2 from 5432 toward KQJT9. The effective plan expressly continues diamonds if DA is held up; “forcing out” describes establishment rather than certainty that the ace must win this first round. |
| 0006 | DK / keep | **Pass.** “Play a diamond honor to force out the ace and establish four diamond tricks.” Against D2–D6 with East still to play, DK is a legal establishment honor. The effective plan permits further diamond rounds until DA appears and preserves HA; it does not invent DA's holder. |
| 0007 | HJ / keep | **Pass.** “Win in hand, keeping HA as dummy’s entry. With DA gone, four diamonds, three hearts and CA provide the eight further tricks needed.” Public history now shows DK–DA and East's HT switch. South holds KQJ and North A43, so HJ wins against every remaining defender card: all higher hearts are authorized partnership cards. It is interchangeable with the other South heart honors for this purpose. With SA already won, 4 diamonds + 3 hearts + CA correctly supplies eight more tricks. |
| 0008 | H3 / keep | **Pass.** “Let HJ win, preserving HA as an entry to dummy’s established diamonds.” After HT–HJ–H5, North A43 can follow H3, leaving A4 opposite South KQ for the remaining two heart rounds. |
| 0009 | HK / keep | **Pass.** “Cash a second heart winner before crossing to HA” matches South KQ and North A4. North can follow H4, then receive HQ with HA. The three-heart total remains feasible without blocking the diamond entry. |
| 0010 | H4 / keep | **Pass.** “saving HA to overtake South’s remaining queen and reach dummy’s diamond winners.” After HK–H6, North A4 follows H4. HQ remains in South and HA in North, so the specifically named next transfer is available. |
| 0011 | HQ / keep | **Pass.** “Overtake with dummy’s ace, then cash the four diamond winners and CA to secure nine tricks.” Three tricks are already won. HQ-to-HA makes four; North's QJT9 makes eight; North's remaining CT5 supplies an obvious club lead to South's CA for nine. The current HQ is the promised transfer, not a consumed reserved card requiring revision. |
| 0012 | DQ / keep | **Pass.** “Cash the four established diamonds, discarding a low club from South on the fourth, then lead a club to CA for the ninth trick.” North is on lead with QJT9/CT5 and South holds D543/CAJ6; DA/DK are consumed. Three South diamond follows and a low-club discard preserve CA. Four diamonds and the club transfer supply the five tricks still needed. This is publicly feasible, but only the first DQ lead is recorded as actual execution. |

## Counts, resources and keeps

The line budgets two spade losses plus DA, leaving nine tricks available. Actual history through trick 7 records those three concessions. Losing DK to DA reduces North's five diamonds to QJT9: four winners remain, and the count never invents a fifth remaining diamond. South's KQJ opposite North A43 yields three partnership heart tricks, as the plan explicitly states, because the third South honor is overtaken by HA.

The generic initial heart instruction reserves the third-round HA entry; it does not require a particular order among South's winning honors. Therefore HJ first, HK second and HQ-to-HA third is a valid equivalent implementation. Decisions 0007–0011 do not consume a specifically promised unfinished resource incorrectly. Both low North hearts are used before HA, so all three heart tricks and the dummy entry are preserved. North's C4 discard leaves CT5; South retains CA throughout and can discard C6 on the fourth diamond. The final club transfer is available.

The initial “even a 4–0 break permits four diamond winners” is a valid source/entry claim for KQJT9 opposite four small cards with HA retained. It is not a claim that a 4–0 break actually occurred, and not a guarantee of the contract against a defender with established spades. Once DA falls, the held-up-ace/remaining-suit conditions are completed or eliminated; keeping the feasible remainder is appropriate. The heart switch is already covered by the initial plan and causes no material route change.

## Actual coverage, distinct from the quality verdict

- **Two ducks executed:** model S3 under SK and model S9 under SQ; North's S8 follow and South's SA on round three were sole-legal mechanical actions. The model also chose the C4 discard on the third spade.
- **Defense continuation executed:** West led SK, SQ and SJ; East followed S4/S5/S6. East later won DA and led HT. These are actual public events, not conditional defense in the plan.
- **DA concession executed:** model D2 toward DK and model DK lost to East's DA on the first diamond round. A delayed DA hold-up and repeated establishment rounds were not exercised. A 4–0 break was not demonstrated.
- **Later entry handling executed:** the model chose HJ/H3, HK/H4 and HQ; the forced HA then won trick 7 in North. This exercises actual continuation on the heart switch and correct preserved-entry timing. It does not exercise replacement of the plan after an unforeseen material change, because the original plan still fits.
- **Communication severance unproven from public facts:** East following three spades does not publicly show a void. A subsequent HT switch does not establish inability to return a spade. The ducks were executed; their actual success in exhausting the DA holder is not established without separate environment evidence.
- **Cashing partly prospective:** the trace stops immediately after North's DQ lead with 4 declarer/3 defender tricks. The four completed diamond tricks, South's fourth-round low-club discard and final club transfer are not observed execution. Their feasibility is established by the public remaining cards.
- **Other facets absent:** no club is led; C4 is a discard on a spade. No third-club localization/other-defender show-out window, defender entry-removal branch, or post-window semantic use is credited.

## Saved native grade reconciliation

`grading-outcome.json` reports exit code 0 and grading evidence available. `grade/grader-output.json` returns 12 pass, 0 fail, 0 uncertain; `grade/evaluation.json` reports mechanical, quality and overall pass for every decision. My independently reasoned overlay agrees on all 12 quality judgments. There are no raw-grade disputes. Raw approval, legality and grader agreement were not used as substitutes for the card/entry/trick proof above.

SHA-256 at review:

- `play/trace.json`: `9321205dfaad9e7bb2dc560db559420b8270c96b7bf653531ee6290f1557f334`
- `grade/input.json`: `bdd065bebbfbe06955dde6528446c9801865ebf69cb77f5932a7a627ec62e32c`
- `grade/evaluation.json`: `d3eb3aeda8088aacbcefcfa9a338379ad63485813f5137154a450af7a99ee1e2`

No candidate-wide acceptance or hidden-environment conclusion follows from this attempt's quality pass alone.
