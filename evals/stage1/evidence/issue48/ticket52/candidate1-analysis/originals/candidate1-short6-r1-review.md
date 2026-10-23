# Independent quality and material coverage — candidate1 short-6-r1

Read-only adjudication, 2026-10-23. Evidence root:
`/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate1/short-6-r1/`.

**Attempt quality FAIL: d1–6 PASS, d7–11 FAIL, d12 PASS. Coverage target is
EXERCISED/COVERED with a limit: the play and conditional explanation test
hold-up/communication and heart entry handling, but do not prove East actually
had exactly three spades or that the actual switch resulted from severed
communication.** This independently supports the raw 7-pass/5-fail distribution.
One stale explicitly named heart-entry sequence produces the five failures;
it is not five independent card-play blunders.

The actual alternative heart play is legal and reaches dummy: HJ wins, HK wins,
and HQ overlaps HA for **three**, not four, heart tricks. The failed
condition is the delivered **keep** operation retaining an unavailable explicit
HJ-to-HA continuation while the current reason follows a different route. A
feasible substitute route does not silently update the authoritative active
plan. Once the actual HQ-to-HA crossing is completed, that entry phase is
historical; d12's remaining diamond/club cashout is sound.

No raw grades or frozen artifacts were changed. No hidden fixture, model/API
call, GitHub action or live role feedback was used. This review read the played
records first and then the completed `grade/input.json` full rubric/case,
`grade/evaluation.json`, raw grader output and summary. Every final delivered
record agrees with its package, current actor/holding and follow-suit. The
12 graded actions have trace source=model; three additional sole-legal cards
are forced and separately accounted. Every delivered decision has one player
proposal/one reviewer judgment; rejected proposals are not the basis of failure.

## Shared authorized facts / initial plan

After West SK, North acts with S87/HA43/DKQJT9/CT54; South controls both hands
and holds SA93/HKQJ/D5432/CAJ6. Defender hands are unknown. Four diamonds after
one concession, three hearts and the two black aces is a feasible nine-trick
source. The initial plan conditions 5–3 communication on short-side DA and
reassesses a switch rather than asserting a known hidden distribution.

The initial installed plan explicitly says:

> Preserve HA as the entry to any stranded diamond winners; if needed, cash HK and HQ before leading HJ to HA.

At d7, East has actually won DA and returned HT to South, leaving North's four
diamond winners stranded until an entry is used. The entry phase is needed and
unfinished. Playing HJ now consumes the specifically named future crossing
card; South subsequently holds only HKQ. The initial ordering (cash both HK
and HQ, then lead HJ to HA) cannot still execute. At d9 the current reason
explicitly gives the correct different route, HK then HQ to HA, but **keep**
retains the old incompatible route unchanged. This is a concrete named-card/
ordering conflict under the rubric, not a demand for a different strategy or
an objection to the legal HJ winner itself.

## Each delivered decision

| Decision / revision | Judgment | Exact delivered claim and authorized assessment |
|---|---|---|
| 0001 / 1 | PASS | “Aim for nine tricks: four diamonds after conceding the ace, three hearts, and the two black aces.” Counts are correct. “normally duck spades twice, winning the third round to exhaust a three-card spade holding opposite a five-card suit” is conditional with reassessment/short-side-DA qualification. S7 is legal; the initial HK/HQ then HJ→HA entry is initially feasible. |
| 0002 / 3 | PASS | “Duck the first spade as planned, preserving the ace to cut defensive communications on the third round.” Current SK–S7–S4, South SA93. S3 genuinely ducks while SA remains, under the plan's conditions. No assertion of a known East holding is added. |
| 0003 / 7 | PASS | “Duck again, preserving the ace for the third round to exhaust East’s spades if they began with three.” Actual West SQ continuation, East S5 after S4; South SA9. S9 is a legal second duck. The explicit “if” correctly keeps East length unknown. |
| 0004 / 9 | PASS | “Discard a spare club, preserving all five diamonds and the heart entry while South wins the third spade.” Current West SJ, North spade-void/CT54, South SA. C4 is legitimate; South's sole SA will beat SJ regardless of East's next card. No nonexistent entry or extra diamond is invoked. |
| 0005 / 12 | PASS | “Lead toward dummy’s diamonds to dislodge the ace and establish four tricks, preserving the heart ace as an entry.” South won SA and has D5432; North DKQJT9/HA43. D2 begins the planned actual contest. DA location remains unknown here. |
| 0006 / 14 | PASS | “Play the king to drive out the diamond ace, establishing dummy’s four remaining diamonds.” Current D2–West D6, North DKQJT9. DK is a legal high play toward forcing DA; the retained plan allows continued diamonds if the unseen DA holder ducks. It does not assert East must take now. |
| 0007 / 17 | FAIL | “Win in hand, keeping dummy’s heart ace as an entry. Four diamonds, three hearts and the club ace now provide the eight tricks needed.” HJ legally beats HT and source counts fit one SA already won. But choosing HJ with keep consumes the old plan's explicitly future HJ crossing, before its stated HK/HQ cashes or HA entry have occurred. The necessary entry phase is unfinished. |
| 0008 / 19 | FAIL | “Let South’s jack win, preserving the heart ace as dummy’s entry to the established diamonds.” North H3 is correct on HT–HJ–H5 and preserves HA. However, South now only has HKQ, while keep still directs later HK+HQ cashes and unavailable HJ→HA. The good current follow does not repair that active route. |
| 0009 / 20 | FAIL | “Cash the king with dummy playing low, then lead the queen to the ace and run the diamonds.” This **different** HK then HQ→HA route is correct from South HKQ/North HA4. Keep nevertheless carries the original HK+HQ then HJ→HA sequence. The plan/reason mismatch is explicit, not an omitted obvious entry. |
| 0010 / 22 | FAIL | “Let the king win, retaining the ace to receive South’s queen next and reach the diamond winners.” North H4 legally follows current HK–H6 and preserves the correct HQ crossing. South's only remaining heart is HQ; the kept plan still says to cash it before a later consumed HJ crossing. The old entry has not been completed historically. |
| 0011 / 24 | FAIL | “Cross to dummy’s heart ace, then cash all four diamonds and the club ace to secure nine tricks.” HQ→HA is executable (North's next HA is sole-legal). At this delivery the crossing has **not yet occurred**; the kept unfinished plan still names unavailable HJ and tells South to cash HQ first. The correct card does not by itself make keep consistent. |
| 0012 / 28 | PASS | “Cash the established diamonds, retaining the club ace for the ninth trick.” HQ→HA is now actually complete, North on lead DQJT9/CT5, South D543/CAJ6, four tricks already won. Four diamond winners plus CA give five more. South follows three diamonds and can discard a spare club on the fourth; a North club then reaches CA. This obvious remaining crossing need not be restated. The heart-entry phase is now historical, so no new demand to replay HJ is inferred. |

The actual runtime reviewer at d7/d8 issued nonblocking advisories that HJ was
no longer available for the retained transfer and suggested a different heart
sequence. Those records corroborate provenance of the mismatch but are not the
quality criterion or proof: actual authorized HJ consumption and unchanged
plan text establish it independently. Reviewer approval and later correct
cashout do not erase the five earlier delivered inconsistencies.

## Coverage: actual events and substantive meaning

The unchanged material trigger is:
“An actual controlled opening-suit hold-up while SA remains, followed by
defender spade continuation before DA loss, then a diamond contest/defensive
response and later controlled decision. Judge actual communication
independently. Early control or a defensive gift does not prove exercised
hold-up; reasonable alternatives remain separately judged.”

Actual sequence:

| Phase | Recorded events / relevant model use |
|---|---|
| First duck | SK–S7–S4–**South S3** at seq3; SA remains. d2 explicitly connects the duck to communication. |
| Real spade continuation and second duck | West **SQ** seq4, forced North S8 seq5, East S5 seq6, **South S9** seq7; SA still remains. d3 conditions exhaustion on East originally three. |
| Third continuation/control | West **SJ** seq8, North C4 seq9, East S6 seq10, forced South **SA** seq11. D4 preserves diamond/heart resources. |
| Actual diamond contest | South D2 seq12, West D6 seq13, North DK seq14, **East DA** seq15. The ace wins; it is not supplied as a known location before the actual response. |
| Later controlled play / entries | East HT seq16, South HJ seq17, North H3 seq19, HK seq20, North H4 seq22, HQ seq24, forced HA seq26; d12 DQ seq28 starts the established diamonds. |

This is substantive exercised hold-up, not an early-SA shortcut: South actually
foregoes the first two spade winners before DA is lost, and opponents actually
continue that suit. The player states the conditional short-hand-exhaustion
purpose and later actually establishes diamonds and transports to them. The
heart return does not donate an extra counted winner: the initial source already
contained three hearts, and HA still must be reserved/unblocked to reach North.
The run therefore tests entries and plan continuity rather than bypassing them;
it fails part of that test through the stale explicit entry plan.

**Communication inference limit:** East followed S4/S5/S6 on three rounds. That
alone does not prove it started with exactly three; two defender spades remain
unseen after SA, and they are not publicly assigned. East's later HT switch
neither proves it lacked a spade return nor licenses labeling it exhausted.
The final advice does not make that error: d3 says “if they began with three,”
and the active plan conditions 5–3 success on DA being in the short spade hand.
Do not use hidden actual fixture truth to convert that hypothesis into a fact
or claim the switch proves the hold-up caused success. The meaningful control
technique/conditions and diamond/entry challenge were exercised; universal
severance or defensive strength is not established.

All four raw coverage predicates are supported by the actual events, with the
above judgment/limits rather than an automatic predicate pass. Quality FAIL is
separate from that exercised material coverage.

## Counts / identities retained

Short run: 239.461331s driver duration, 29 actual events, seven completed tricks
(4 declarer / 3 defenders), 12 model deliveries, three forced controlled plays,
13 later opponent actions plus opening-lead prefix. Twelve player/twelve
reviewer requests, no feedback revisions or technical retries. No full-board
or contract-completion claim follows from this bounded task.

Unchanged SHA256:

- `grade/input.json`: `3215ed7d819c672693ed110cfbdedd925de9c036c5ddee27b21526abf3dc2c6a`
- `grade/evaluation.json`: `c715acbb91c7fa614db804f0657197cfd654f70d1a9036a8afdeb740477c34e8`
- `grade/grader-output.json`: `b044ca916ccf85d65d80e31e23acdd40a9d69bfd70bd994e1450674fe80052ee`
- `play/trace.json`: `681cf5dd259f1bcf9750298bb036070d1f8c84c6ca05f0f4bf81d818a49003c6`
- `summary.json`: `bdd1584bb877b83ca914a2290397e54660a26844ee7e2cdf4ff4ce26a729a669`

No issue closure, final matrix acceptance or PR merge is proposed.
