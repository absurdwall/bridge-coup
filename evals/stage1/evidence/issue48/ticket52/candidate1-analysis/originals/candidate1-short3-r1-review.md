# Independent quality and material-coverage overlay — candidate1 short-3-r1

Read-only review, 2026-10-23. Root:
`/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate1/short-3-r1/`.

**Quality: PASS, all 12 delivered decisions. Main new-public-information coverage:
COVERED. Distinct third-club-first localization before the other defender's first
show-out: UNEXERCISED in this ordering.** The summary's later-window predicate is
not evidence that this stronger facet occurred. Thus this attempt supports the
main short-3 quality/coverage gate with an explicit facet limit; it must not be
reported as complete coverage of that stronger condition. Candidate-wide coverage
of that facet must be assessed across the prescribed remaining short-3 attempts;
this does not require every reasonable line to reproduce one reference sequence.

The 12-decision task completed legally (23 recorded cards, 5 completed tricks,
12 player/12 reviewer calls; 164.282s driver runtime). This is not a full board.
All runtime dispositions were reviewApproved; that fact was not used as quality
proof. Raw graders said pass for all 12 and remain unchanged. No discarded
proposal was treated as delivered advice. No source/frozen artifact change,
model request, GitHub write, hidden-fixture read or live feedback occurred.

## Evidence and standard applied

Read complete `grade/input.json` including rubric, case properties, all 12
actual final outputs/effective plans and each authorized snapshot; read all
findings in `grade/evaluation.json` and raw `grade/grader-output.json`; checked
the actual event ordering and delivered snapshots in `play/trace.json` and
`play/decision-NNNN/decision.json`. Verified each delivered record agrees with
the grader input, current card belongs to the acting hand, and follows suit
where held. These checks supplement the bridge judgment, not substitute for it.

The rubric permits reasonable nonoptimal alternatives, concise feasible
remainders and obvious omitted entries. Completed steps in retained plan prose
are historical, not instructions to replay consumed cards. Serious false facts,
impossible routes/entries and false certainty about unseen hands fail. The
short-3 material accepts justified keep or replacement and does not mandate a
replacement when the anticipated line still applies.

Shared initial visible hands are South SA94/HA63/DAK/CAK864, North S862/HK74/D8653/
CQ72; only West DQ has initially been played. Defender holdings remain unknown.
The initial plan chooses CA, low club to CQ, then club toward CK; 3–2 yields
five clubs, 4–1 one concession/four clubs, and 5–0 requires reassessment. It
preserves DA/major controls and the HK/hand entries rather than claiming
unconditional protection against every break. This is a feasible initial line.

## Every delivered decision

Revision is the number of actual prior events; no later event is used in the
judgment at an earlier revision.

| Decision / rev | Disposition | Exact delivered text and authorized supporting facts |
|---|---|---|
| 0001 / 1 | PASS | “cash the club ace, lead a low club to dummy’s queen, then return a club toward the king.” D3 is a lawful North follow to DQ; South DA/K can win. CA then C4→CQ then C7→CK leaves South long clubs. Five outside winners plus four/five clubs give nine/ten. “If the first club round reveals 5–0, reassess” avoids an unsupported safety guarantee. |
| 0002 / 3 | PASS | “Win with the king, retaining the ace as a diamond stopper while developing clubs.” Current DQ–D3–D4, South DA/K. DK wins; DA remains. Keep retains the feasible uncompleted club route. |
| 0003 / 4 | PASS | “Start establishing clubs while the diamond ace still protects against the defenders’ attack.” South won DK and holds CAK864/DA. CA starts the actual retained sequence; no consumed-card reuse. |
| 0004 / 6 | PASS | “Follow low, preserving the queen as the entry for the next club round.” Current South CA, West C3; North CQ72. C2 legally preserves CQ7, so CQ can still receive the next low club. East's future follow is not presumed as fact. |
| 0005 / 8 | PASS | “Lead toward dummy’s queen, then return a club to the king to reveal the break.” Actual first round CA–C3–C2–C5; South CK864 opposite CQ7. C4→CQ and later C7→CK is available. At this moment the 3–2 break is not known. The generic future phrase does not explicitly deny that the second round may already reveal the split. |
| 0006 / 10 | PASS | “Win with the queen, then lead dummy’s remaining club toward the king to continue establishing the suit.” Current C4–C9, North CQ7, South CK86. CQ wins; C7 remains for return toward CK. No precise East play has yet occurred or is invented. |
| 0007 / 12 | PASS | “Lead to the club king, dropping the sole outstanding club, the jack, and establishing all five club tricks.” Actual defender clubs are West C3/C9, East C5/CT. CJ is the sole outstanding defender club; its side is not yet known. C7→CK necessarily collects it wherever held and establishes South C8/C6. “all five” correctly means total club source (CA/CQ already won), not five additional future club tricks. Keep is justified by the initial 3–2 branch. |
| 0008 / 14 | PASS | “Cash the king to capture West’s remaining jack and establish the last two clubs, securing ten tricks.” Actual current C7–East H2 proves East void; only CJ remains outside South/North. Therefore West CJ is now deducible before West's play. CK captures it, leaving C8/C6; 3 already won plus CK/C8/C6/DA/HA/HK/SA = ten. This uses public information, not hidden truth or hindsight. |
| 0009 / 16 | PASS | “Cash the established clubs, discarding dummy’s diamonds and watching the defenders’ discards before taking the outside winners.” Actual completed third club includes West CJ under CK, exhausting defender clubs. South C86/DA/HA/SA and North HK remain. C8 is a winner; dummy can discard diamonds. Watching subsequent discards is prospective, not an invented East discard. |
| 0010 / 18 | PASS | “Discard an idle diamond, preserving both majors while cashing the clubs.” Current South C8–West D2; North has no clubs and D865/HK74/S862. D5 is a legal discard, leaving HK/major resources. East's later S3 is not asserted. |
| 0011 / 20 | PASS | “Cash the last club, discarding another diamond from dummy; ten tricks remain secure.” Five tricks already won; South C6/DA/HA/SA, North HK are five more accessible winners. C6 is established. This is ten total secure, not ten still-to-be-played tricks. |
| 0012 / 22 | PASS | “Discard another idle diamond, retaining both majors and the heart king entry.” Current established C6–West H5; North D86/HK74/S862. D6 is lawful and retains HK, reachable through South H3/H6. No unavailable necessary entry is asserted. |

The full initial plan is carried unchanged on decisions 2–12. Its diamond win,
CA/CQ crossing and CK return become completed historical steps as they happen.
The unfinished portions—cash established clubs then outside winners—remain
physically available. There is no need to replace merely to erase completed
prose or repeat an obvious low-heart crossing. All grader explanations about
these concrete holdings, accounting and routes are supported.

## Actual material-information timing

The unchanged case coverage trigger states: “Both defenders actually follow two
club rounds, followed by a controlled model decision. Separately record a third
defender club localizing the length before the other defender discards; no
mandatory plan replacement when retention remains justified.” The principal and
separately recorded facets are assessed independently below.

| Event / snapshot | Authorized knowledge at that point | What the delivered advice demonstrates |
|---|---|---|
| Round 1 ends at sequence 7: West C3, East C5 follow to CA | Two defenders have followed once; 3–2 vs 4–1 etc not yet resolved | d5 still plans a feasible second club/crossing without inventing a split. |
| Round 2 ends at sequence 11: West C9, East CT follow to CQ | Five defender clubs initially missing; four now seen, both defenders at least two. Thus 3–2 and sole remaining CJ are deduced; which defender has CJ remains unknown. | d7/rev12 explicitly uses sole CJ, but names no defender. Correct use of newly determined facts and justified keep. |
| Sequence 12 North C7, then sequence 13 East H2 discard | East is now publicly void, so remaining CJ belongs to West even though West has not played yet. | d8/rev14 correctly says “West’s remaining jack.” This is the actual localization/decision window exercised. |
| Sequence 15 West CJ under CK | Third West club confirms the already localized long hand; East's first show-out H2 happened **earlier**, at seq13. | No fresh third-club-first localization occurred here. |
| d9/rev16 and d10/rev18 occur before East's **next** discard S3 at seq19 | All defender clubs gone; actual East H2 already known, S3 still future | d9 watches future discards, d10 discards a dummy diamond. Neither invents S3 or another future defensive card. |

Summary lists `two_round_break_decision_revisions=[12,14,16,18,20,22]`; the
principal window begins correctly at d7/rev12. That is not merely a predicate:
the actual answer identifies CJ, leaves its side unknown and executes the
anticipated route. d8 then adjusts its factual description once East shows out.

Summary also lists `third_club_before_other_defender_revisions=[16,18]`. That
predicate uses West's third club at seq15 and East's **next** subsequent play at
seq19. It must not be read as West's third club preceding East's first show-out
in the third club round: East already discarded H2 at seq13. The stronger
pre-first-show-out localization condition is unexercised here. Main short-3
coverage is supported through two-round inference and the actual subsequent
void-based localization; separately report the stronger facet limit. No false
quality failure or mandatory plan replacement follows from that limit.

## Preserved artifact identities

SHA256:

- `grade/input.json`: `33375298a38cfff1a764060c798e6f57c11a143d9793efea2417ec596df8a61d`
- `grade/evaluation.json`: `f044b30c03192f2bff448e2dd43c7062ef715faf3f892e88c1bc697085e8a2cc`
- `grade/grader-output.json`: `3ca78f36fcff1ac0c89c02926ff43fef7dd80d819f65698b664544f459b3fb81`
- `play/trace.json`: `3fb4018c6b87018367bd07ca5717c1f3c6103eb23d4bfa448e689dd258ab3379`
- `summary.json`: `47f92436702843d6074bc286b069c0e136beb6f6f91a8def1fa65fc7bb1f0d19`

The overlay establishes neither whole-matrix quality nor full-board completion,
and proposes no issue closure or merge.
