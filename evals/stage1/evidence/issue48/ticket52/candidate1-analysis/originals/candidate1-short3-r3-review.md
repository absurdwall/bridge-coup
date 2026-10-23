# Independent quality and material coverage — candidate1 short-3-r3

Read-only adjudication, 2026-10-23. Root:
`/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate1/short-3-r3/`.

**Quality: FAIL overall, decisions 1–8 fail / 9–12 pass.** This agrees with the
raw grade but rests on independent resource accounting. It is **one repeated
unfinished-plan defect**, not eight independently demonstrated bridge errors.
Main two-round/new-information coverage is supported. The third-club-first
position occurred, but the only controlled action in that window was forced;
model use in that window remains untested.

The defect is an explicit impossible reserved holding, **not** a demonstration
that the stated nine-trick route fails. The stated fourth/fifth club cashout
needs only CK plus one low club and remains feasible. That qualification is
essential: legal play, actual 3–2 and a feasible result do not make the explicit
future inventory true, but the inventory error must not be inflated into a
counterexample to the contract plan or a demand for stronger strategy.

No model/API request, source/frozen artifact change, hidden fixture read,
GitHub action or live feedback occurred. Raw grades remain unchanged. Read the
full `grade/input.json` rubric/case and every delivered output/snapshot/plan,
all raw grader findings, all delivered decision records, trace and summary.
Ownership/follow-suit and final-record/package agreement also checked.

## The exact resource defect and why it is counted

Trace labels all twelve graded controlled actions `source=model`; the additional
North C7 at seq18 is separately `source=forced`. Delivered decision 1 installs
the quoted plan with replace; decisions 2–8 use keep and carry that same text
unchanged while the 4–1 premise remains possible. Each has one actual player
proposal/one reviewer round and reviewApproved disposition. Those approvals do
not establish resource correctness. The later keeps on decisions 9–12 retain the
text but select the now-established 3–2 branch; no rejected draft is involved.

Active plan installed at decision 1 and kept throughout:

> Cross to dummy's heart king and lead the club queen, following low from South; then lead a low club to the ace.

> If either defender shows out on the second club round, duck the third round in both hands, retaining South's king and two small clubs.

> Regain the lead using the appropriate remaining stopper, then cash the king and established fifth club for nine tricks.

Authorized South clubs initially are **CAK864**, five cards. The stipulated
conditional sequence has this unavoidable consumption:

| Stage | South clubs still held, using actual C4 first follow and C6 as an illustrative third-round duck |
|---|---|
| Initial | CA CK C8 C6 C4 — five |
| Low follow to North CQ | CA CK C8 C6 — four |
| Second round won with CA | CK C8 C6 — three |
| Third round ducked with a small club | CK C8 — two |

Any different lawful low spots have the same counts. After three club rounds,
five minus three is two: **CK and one small club**, never CK plus two small
clubs. This does not depend on the actual hidden defenders or on a desired
reference line. It is a directly falsifiable future resource assertion in the
unfinished advice, not an omitted obvious entry or ambiguous strategic
alternative. It overstates the reserved South club inventory by one card within
the exact sequence the plan supplies.

The rubric explicitly tests invented/consumed resources and physical feasibility
of the **actually stated** active plan. On that criterion this is a definite
basic plan-accounting defect while the condition remains live; it is not passed
merely because the extra claimed small card is unnecessary for the final four
club tricks. Conversely, I do **not** find that its fourth/fifth-club route needs
three South cards: CK and one established small card are enough after the duck.
The findings establish inventory inconsistency, not loss of the promised ninth
trick, actual execution of a nonexistent card, or general strategic weakness.

## When the branch remains live

- At d1–d6, the two-round club break has not been revealed. The 4–1 conditional
  remains possible, and its false post-duck inventory is unfinished future
  advice. At d6/rev10 only North CQ and East C5 have been played in club round 1;
  South and West have not yet played that round.
- At d7/rev12 both defenders followed round 1 (East C5, West C3); South has
  actually spent C4 and now holds CAK86. Only one round has completed, so 4–1
  remains possible. The future CA + small-card duck still leaves CK plus one
  small club, not two.
- At d8/rev14, club round 2 currently has North C2, East CT. West's second club
  has **not yet been observed**. West could still show out, with East holding
  four; the plan itself says to “watch West’s card.” The false conditional
  inventory therefore remains part of unfinished applicable advice at d8.
- Only after West follows C9 at seq15 is 3–2 proven. From d9/rev16 onward the
  true 3–2 branch is selected, and the unexercised 4–1 conditional is no longer
  applicable. It should not be treated as a continuing fresh error or as an
  instruction to recreate cards; there is no need to replace the whole plan
  just to delete an inapplicable conditional branch.

## Every delivered decision

All current cards are legal and their immediate reasons fit the current
position. The early failures are attached to the still-active false conditional
resource assertion, not an illegal selected card.

| Decision / rev | Quality | Exact text / public-fact assessment |
|---|---|---|
| 0001 / 1 | FAIL | D3 and “Play low, planning to win in South and develop clubs with protection against a 4-1 break.” are lawful/coherent immediately. Initial plan correctly targets four clubs + five side winners but explicitly retains “South's king and two small clubs” after three rounds, impossible from five. |
| 0002 / 3 | FAIL | DK legally wins DQ–D3–D4. Kept plan still has the unobserved 4–1 branch and its false future inventory. This is not yet completed historical prose. |
| 0003 / 4 | FAIL | “Cross to dummy’s heart king to lead the club queen” via H3 is physically available; HA remains. No clubs have yet been played, so false post-duck inventory remains future advice. |
| 0004 / 6 | FAIL | HK legally wins H3–H5 and reaches North CQ72. The club branch has still not begun; false reserved count persists under keep. |
| 0005 / 8 | FAIL | “Cash dummy’s queen first, then lead a low club to the ace. This preserves a low club in dummy to duck if clubs break 4–1.” is otherwise feasible: North Q72 leaves 72 then 7. It does not fix South's explicit extra-small-card assertion in the kept plan. |
| 0006 / 10 | FAIL | “Let dummy’s queen win, preserving the ace and king for the planned club development.” C4 under CQ is correct, leaving South AK86. Subsequent A and duck leave only K+one small; 4–1 remains possible. |
| 0007 / 12 | FAIL | “Lead to the club ace to test the split, keeping dummy’s seven available to duck the third round if clubs are 4–1.” C2 is legitimate and North C7 really remains. South's extra low card after the later duck remains falsely claimed by active advice; only one club round has completed. |
| 0008 / 14 | FAIL | “Win with the ace and watch West’s card: if West follows, cash the king; if West shows out, duck the next club to establish four club tricks safely.” CA is sound and the duck branch can establish four. But West's current follow is still unknown, so the active branch's explicit three-card South remainder remains applicable and false. |
| 0009 / 16 | PASS | “Clubs are 3–2. Cash the king to remove the remaining jack, establishing both small clubs for ten tricks overall.” Both defenders now followed twice: East C5/CT, West C3/C9. Only CJ remains outside South CK86/North C7; its owner is not asserted. CK establishes C8/C6. Four already won + CK/C8/C6/DA/HA/SA = ten. Old 4–1 branch is now inapplicable. |
| 0010 / 20 | PASS | “Cash the established clubs before the three remaining aces, securing ten tricks.” Actual CJ fell under CK and East showed out. South C86/DA/HA/SA are five cashing winners plus five won. HK has already won historically, so no phantom fourth remaining ace/heart trick is introduced. |
| 0011 / 22 | PASS | “Discard a spare diamond while South cashes the established clubs; ten tricks remain secure.” North void in clubs, D865; D5 legal on South C8. South C6 and three aces plus current winner/five won support ten total. |
| 0012 / 24 | PASS | “Cash the last established club, then the three remaining aces to secure ten tricks.” South on lead C6/DA/HA/SA, six already won. No opposing club remains. Four accessible winners produce ten. |

The raw grader's eight early explanations correctly identify the impossible
future inventory and do not claim a specific actual card violation. Its four
later passes correctly treat the now-inapplicable 4–1 branch separately. The
result should be reported as repeated delivered plan-accounting failure while
that branch was live, followed by sound actual 3–2 continuation; later sound
play does not erase the earlier advice.

## Material coverage and actual windows

The unchanged case trigger requires both defenders to follow two club rounds
followed by a model decision; it separately records third-club localization
before the other defender discards, with no mandatory replacement when keep is
justified.

- Club round 1: North CQ seq8, East C5 seq9, South C4 seq10, West C3 seq11.
- Club round 2: North C2 seq12, East CT seq13, South CA seq14, West C9 seq15.
- **d9/rev16** is the first model snapshot after both follow twice. It explicitly
  states 3–2, identifies a sole remaining jack without naming its owner, and
  cashes CK along the correct anticipated branch. This demonstrates core
  new-information inference and justified retention, beyond a mere predicate.
- Third round: South CK seq16, **West CJ seq17**, North C7 seq18, East S3 seq19.
  West's third club locates its length before East's first show-out: the desired
  actual event position exists. But North C7 seq18 is trace source **forced**
  (sole remaining legal club); no player/reviewer request occurs at rev18.
  The next model snapshot is d10/rev20, after East S3 has actually appeared.
- Therefore summary `third_club_before_other_defender_revisions=[]` is consistent
  with no model localization/explanation at that narrow window. The position
  occurred; model ability in it was not tested. Do not count forced mechanics
  as a model judgment or invent a required change of legal route.

Core short-3 coverage is supported; separate third-first model-use facet remains
untested in this attempt. Attempt quality is nevertheless **FAIL** for the
independently evidenced earlier active plan inventory defect. This 236.944s
12-decision task has 25 actual cards, six completed tricks, 12 player/12 reviewer
attempts and one forced action; it is not full-board acceptance.

## Preserved artifact identities

SHA256:

- `grade/input.json`: `da65d647070f0805506c6cb3d75943aca27f9da828902904c831c4f10be68416`
- `grade/evaluation.json`: `caf6f9f75b9f97d489add84f49c2a641a9b97304d63ae3e41d2b7d231b4bff8a`
- `grade/grader-output.json`: `61a26b96cff3185f9a1a2921595dfde62f9a8483715592f4834b1db81e6b5029`
- `play/trace.json`: `f6f08e88af6002936791609d36e2c8e8bd7159ffb49c6ea2b6574eb8d26a428d`
- `summary.json`: `5c3274b479ff665af9d870b600fbde1281843353d771db9d1358cef674201dd0`

No raw grade or summary was rewritten; no acceptance/issue closure/merge is
implied. Current live matrix work remains unaffected.
