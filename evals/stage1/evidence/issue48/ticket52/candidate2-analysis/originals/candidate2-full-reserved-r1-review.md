# Candidate 2: full-reserved-r1 independent public quality review

**Independent attempt quality: PASS — 21 delivered decisions pass, 0 fail, 0 uncertain.**

**Raw saved quality grades: 20 pass, 1 fail, 0 uncertain.** The disagreement is decision-0009, discussed explicitly below. Raw evidence and grades are unchanged. Candidate-wide acceptance is a separate decision.

Frozen source: `0a307cbde5498ed24b73da0d781cb9113ce92180`. Evidence root: `evals/stage1/evidence/issue48/ticket52/candidate2/full-reserved-r1` in the assigned worktree. This is a previously used regression board, not a newly held-out board.

## Scope, provenance and result

I watched metadata only until `playing-outcome.json` existed with exit code 0, then reviewed every final delivered model selectedCard/publicReason and actual effective plan from its authorized public snapshot/history. I waited for the saved native grader and evaluation before finalizing this report. I did not inspect a complete hidden regression fixture, unfinished r2, or use later defender cards to justify earlier quality judgments. No model/native calls, live feedback, source/raw/grade/index writes or GitHub operations were made. The earlier Walker environment proof concerns a different board and supplies no quality facts here.

There are 21 final model deliveries, 5 mechanical controlled cards and 26 defender cards including the opening lead. The 22 player requests and 22 semantic reviewer judgments include one revision of a pending proposal; the non-delivered draft is not a separate quality failure. All final deliveries were review-approved. Plan operations: 4 replace, 17 keep, 0 withdraw. Review approval and result are provenance/outcome facts, not quality proof.

**Actual execution:** 52 distinct cards, 13 completed notrump tricks, `complete: true`, declarer 13 tricks / defenders 0. The board was played through, not merely claimed. I independently checked acting order, card ownership, follow-suit, unique cards and trick winners from the completed public record: each seat played 13 cards, every prefix was legal, all remaining holdings were empty, all 13 winners were North/South, and the reconstructed North/South original cards matched the initial authorized hands. Using the completed record to verify integrity is separate from evaluating any earlier decision using only its then-authorized information.

## All delivered decisions

Each judgment includes the active plan, not just legality of the selected card. Completed phases are historical; retaining their text does not instruct replay of consumed cards.

| Decision | Card / operation | Independent finding and exact answer excerpt |
|---|---|---|
| 0001 | HQ / replace | **Pass.** “We have nine cashing tricks: three hearts, two spades, three clubs and DA.” Authorized North HQ84/SK72/CA65/DQJ93 and South HAK5/SA64/CKQ83/DA72 support that count and nine cashing winners. “lead DQ from dummy, cover East's king with DA if played, otherwise play low from South” is feasible; a possible DK concession leaves side suits controlled and another diamond winner reachable through retained SK/CA. Three-club versus conditional fourth-club counting is correct. |
| 0002 | H5 / keep | **Pass.** “Leave dummy on lead to attack diamonds while retaining both heart winners in hand.” On HJ–HQ–H2, H5 from AK5 leaves HQ winning and South AK intact. Dummy can begin DQ as planned. |
| 0003 | DQ / keep | **Pass.** “Develop an extra diamond trick while every other suit remains securely stopped.” North is on lead; DQ toward South A72 implements the named conditional cover/duck. Hearts AK, spades AK and clubs AKQ retain controls. |
| 0004 | DA / keep | **Pass.** “Capture the king, establishing dummy's jack as our tenth winner.” East has actually played DK on DQ. DA captures it; North's DJ becomes highest and remains reachable through SK or CA. The count is HQ already won, DA now, two hearts, two spades, three clubs and DJ = ten. |
| 0005 | D2 / replace | **Pass.** “Ten tricks are secure: two already won, two remaining hearts, two spades, three clubs and DJ.” This is exact. “play D9 if West follows below it, or DJ over West's ten” seeks extras from J93 opposite 72 after DQ/DK/DA are gone. A possible loss to DT leaves side-suit controls and North entries available; the 3–3 establishment condition is conditional, not known. The later CK/CQ/club-to-CA and heart-return resources exist. |
| 0006 | D9 / keep | **Pass.** “Finesse the nine as planned; this offers extra diamond tricks while preserving ten secure tricks.” D2–D8 is the actual trick; D9 covers D8 and can lose only to outstanding DT. DJ is retained, and SK/CA preserve access if necessary. No defender holding is assumed. |
| 0007 | DJ / keep | **Pass.** “Cash the jack, testing whether the remaining diamonds split and establish dummy's three.” D9 has actually won; East and West each followed twice. DJ is the highest remaining diamond and tests the third round without asserting the break in advance. South still has D7 to follow and North retains D3. |
| 0008 | D3 / replace | **Pass.** “Diamonds have split 3–3, so cash D3 now and discard South's S4.” Authorized history shows East DK/D4/D6 and West D5/D8/DT: all six opposing diamonds are gone. “four already won, D3, two hearts, two spades and three clubs” correctly counts twelve. North can lead low club to CK, follow low to CQ, win a club with CA, and return a heart to South's AK if the fourth club is established. S4 is spare. |
| 0009 | S4 / keep | **Pass, raw fail disputed.** “Discard the spare spade, retaining all winners and the fourth club for a possible thirteenth trick.” This executes the expressly planned S4 discard, preserving South A6, AK and KQ83 opposite North K72/84/A65. East's current C2 discard creates additional possible club layouts; the retained plan's sufficient 3–3 case and conservative twelve-trick fallback are no longer exhaustive, but its club test, all entries, twelve-trick assurance and current discard remain valid. The condition is broadened before the club test at 0010. The materiality limit and raw interpretation are examined below. |
| 0010 | C5 / replace | **Pass.** “East has already discarded C2, so the fourth club can become established even from an original 4–2 split.” This correctly incorporates the observed discard without asserting East's original length. “Whenever South's remaining club is established, return with a heart to cash it” is a concrete condition-based continuation. C5 to CK, CQ with North C6, club to CA, and North heart toward South AK are available. |
| 0011 | CK / keep | **Pass.** “Win the ten and continue testing clubs, preserving the heart entry to South.” On C5–CT, CK wins from KQ83 regardless of West's play. North A6, South Q83 and both North low hearts/South AK remain for the named test and return. |
| 0012 | CQ / keep | **Pass.** “Cash the queen as planned, counting the remaining clubs before crossing to the ace.” South is on lead after CK; North A6 can follow C6 and retain CA. South still has C83 to lead the next club toward CA. |
| 0013 | C6 / keep | **Pass.** “Keep the ace for the third club round, leaving South on lead to continue the test.” On CQ–C7, C6 preserves separate CQ and CA tricks, leaves South on lead, and preserves North's third-round receipt. |
| 0014 | C3 / keep | **Pass.** “Cross to the ace, retaining the eight; only the defenders' club nine remains outstanding.” Public clubs already exposed are defenders' C2/CT/C4/C7/CJ; partnership holds CA and C83. C9 is indeed the sole outstanding defender club. C3 toward CA removes it, while the preserved heart return makes the remaining C8 reachable. |
| 0015 | H4 / keep | **Pass.** “Cross to South's heart winners to cash the established club eight. Two spade winners complete all thirteen tricks.” Public history now shows C9 under CA and East's club show-out. With eight tricks won, South AK/C8/A6 and North K72/H84 supply the remaining five via a heart return, C8, the other heart and separate spade honors. |
| 0016 | HK / keep | **Pass.** “Win in hand; the remaining heart, club eight and two spade winners secure all thirteen tricks.” On H4–H9, HK from AK wins. HA, established C8, SA and SK are four reachable winners after this ninth trick. |
| 0017 | C8 / keep | **Pass.** “Cash the established club, discarding a low spade from dummy; then take the heart ace and both spade winners.” All external clubs are publicly gone. North K72/H8 can discard a low spade while preserving SK plus one low spade for separate SA/SK cashing; H8 follows to HA. |
| 0018 | S2 / keep | **Pass.** “preserving the king and a low spade so both spade winners remain separately cashable.” North K72/H8 discards S2 on the established C8. North K7 can later follow S7 under South SA, then receive South S6 with SK. |
| 0019 | HA / keep | **Pass.** “Cash the heart ace, then the spade ace and king for all thirteen tricks.” Ten tricks are won. South HA/A6 and North H8/K7 permit HA/H8, SA/S7 and S6/SK for three more. The heart return for clubs is already completed, so cashing HA now does not consume an unfinished critical entry. |
| 0020 | SA / keep | **Pass.** “Cash the ace with dummy following low, then lead to the king.” South A6 and North K7 provide two separate spade tricks. Earlier club/heart plan phases are complete; SA followed by S6-to-SK is executable. |
| 0021 | S7 / keep | **Pass.** “Preserve the king to win the last trick, completing all thirteen.” On SA–S9, North K7 follows S7, retaining SK to receive South's remaining S6. This keeps two separate winners rather than colliding the honors. |

## Raw grade dispute: decision-0009

The raw grader fails the kept plan excerpts:

> If clubs split 3–3, return to South with a heart to cash the fourth club.

> If clubs do not split, take the twelve established tricks.

It interprets those words as making original 3–3 necessary and instructing refusal of a thirteenth trick when East's C2 discard makes original East-four/West-two possible. The mathematical observation is correct: an original 4–2 split with C2 discarded from East leaves 3–2; three club honor rounds can exhaust the remaining defenders' clubs, and the preserved heart return reaches South's fourth club. No hidden cards or actual future defense are needed for that counterbranch. The condition in the old plan is therefore incomplete once C2 is observed.

My overlay does **not** treat that incompleteness alone as a material failure at this delivery. The text does not explicitly claim “only if 3–3,” “at most twelve,” or require throwing away an established winner. Twelve is still a true secured floor; the 3–3 success condition remains sufficient. The selected S4 discard, club-test sequence, retained fourth club and critical heart return are unchanged and correct. At 0010, the very next model decision and before any club test, the complete replacement explicitly accounts for C2 and expands the continuation to every established fourth club. No bad card, lost entry, false winner count, dangerous concession, impossible transfer or decision to abandon an actually established thirteenth winner is delivered at 0009.

This is a limited disagreement about the materiality/interpretation of a conservative transient fallback, not a rejection of the grader's club arithmetic. A policy demanding immediate textual exhaustiveness for each newly possible additional overtrick branch could fail 0009; the agreed basic-quality rubric does not demand optimal play or one reference line. I record a minor stale-condition observation, accept the feasible current route/resources, and retain **pass**. The later revision is not used to erase an earlier material defect; rather, no material defect is established at the earlier card. Raw `grade/evaluation.json` remains fail and the attempt's raw summary remains fail. This report preserves the independent overlay separately from the raw result and coordinator adjudication.

The complete raw finding is preserved verbatim in values under `raw_grader_decision_0009_verbatim_values` in the separate proof JSON. Its substantive text is:

> The retained plan incorrectly makes a 3–3 club split necessary for taking thirteen.

> The authorized current trick now includes East's C2 discard, leaving five opposing clubs. An original East-four/West-two holding leaves three and two; CK–CQ–CA exhausts them and establishes South's fourth club, reachable through the preserved hearts. The explicit instruction to stop at twelve when clubs do not split 3–3 therefore rejects an available established winner. S4 itself is a sound discard.

Public counterbranch artifacts: `/tmp/bridge-coup-issue48-context/candidate2-full-reserved-r1-counterbranch-proof.json` and runnable `/tmp/bridge-coup-issue48-context/check_candidate2_full_reserved_r1_counterbranch.py`. The verifier passed generation and a separate comparison rerun. It constructs an original East-four/West-two club layout compatible with all exact public events through decision 0009 and the initial authorized North/South hands, then legally completes a hypothetical 52-card/13-trick continuation. After CK/CQ/CA, no opponent club remains and the retained heart entry reaches South's C8. No actual complete fixture is read. This proves underinclusiveness of the old condition, while explicitly leaving the instruction's exclusivity/materiality to the independent textual judgment above. It is a counterfactual possibility, not evidence that this was the actual distribution or known by the player.

## Whole-hand accounting, entries and actual coverage

Initial count: HAKQ (3), SAK (2), CAKQ (3), DA (1) = nine. DQ draws the actually played DK, captured by DA, and DJ becomes a tenth source. D9 then wins; DJ draws the third defender diamonds; D3 becomes an additional winner after public confirmation that each opponent held three diamonds. The total rises to twelve: five early tricks, two hearts, two spades, three club honors. These are source yields and already-won counts, not double-counting cards spent under honors.

The club phase preserves South's fourth club through the S4 discard, reaches South via C5-to-CK, cashes CQ while retaining CA, then reaches North via C3-to-CA. North retains H84 opposite South AK until the club test is complete. After the observed C9 removal, H4-to-HK returns to South and C8 is actually cashed. North's S2 discard preserves both SK and a low spade. HA, SA with North low, then S6-to-SK are all actually completed. Spending CA and later HA is consistent with their roles: the corresponding entry phases are completed, rather than still reserved for an unfinished route.

Actual full-board coverage is complete: all 52 cards and 13 tricks are recorded, including all planned final transfers/cashing. Conditional losses to DK/DT, a club break leaving a loser, and opponent-winning control-recovery branches are not exercised: defenders never win a trick. That does not invalidate the feasible conditional routes, but their successful execution is not demonstrated by this result. The club-discard adjustment is observed; there is no claim of new held-out generalization or broad playing/grading reliability.

## Timing and evidence binding

Play process wall time: **350.034 s**. Trace automatic/elapsed time: **349.712377 s**; human waiting 0; reported environment overhead **0.954481 s**. First reviewed decision took **47.165781 s**; subsequent delivered decision intervals ranged **5.053295–41.468078 s**. No technical retries. There were 44 actual role RPC requests (22 player, 22 reviewer); the extra semantic round is distinct from the 21 delivered quality items. Saved grading outcome: exit code 0, evidence available. No separate grade wall-time measurement is asserted.

SHA-256 at review:

- `play/trace.json`: `5caa80efaf12ed6f9eab28239f17c7ebcf4533bf4342fd9105fc076a20da8176`
- `grade/input.json`: `0ededac3a6c3dd891e79c353265770fb271c4365a46b13cfd33c96f51a11f522`
- `grade/grader-output.json`: `2ddb6aaeb4500d04d716795837f4b5190e4b3402faaf5dc34e0761a022dedd6c`
- `grade/evaluation.json`: `fe49107ac677ec1ac312cf7da35c46e147a1dbebaaf5d3818c434f1823b5d11f`

This report establishes the independent overlay, the original raw disagreement, and actual bounded evidence. It does not merge a PR, close an issue, change evidence, or establish overall candidate acceptance.
