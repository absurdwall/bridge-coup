# Independent quality and material coverage — candidate1 short-3-r2

Read-only review, 2026-10-23. Artifact root:
`/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate1/short-3-r2/`.

**All 12 delivered decisions PASS quality. Main two-round/new-information
coverage is COVERED. The third-club-first event window occurred, but its only
controlled play was mechanically forced CQ; model use at that window was NOT
TESTED.** This distinction preserves the actual material limit without imposing
a required alternative legal route or converting an uneventful forced card into
an LLM judgment. Raw 12-pass grading and summary remain unchanged.

The short task completed legally at 25 actual events (six completed tricks),
with 12 player/12 reviewer attempts and one forced controlled action. Recorded
driver time is 208.812s. This is an initial/mid-board short run, not a full-board
result or stage acceptance.

## Read evidence / standard

Read all of `grade/input.json`, including rubric, case and final advice/prior
plan/facts, all findings in `grade/evaluation.json` and raw grader output,
`play/trace.json`, and all delivered decision records. Independently checked
final record agreement with the grading package, ownership/current actor and
follow-suit. No original hidden defender fixture, future play, model calls,
source/frozen-artifact writes, GitHub updates or feedback to live roles were used.
Runtime approval was not a quality label; no intermediate draft was graded as
delivered advice.

The rubric accepts nonoptimal feasible alternatives, obvious omitted entries
and completed historical portions of retained plans; it fails explicit
infeasibility, false facts and unjustified hidden-hand certainty. The case says:
“Both defenders actually follow two club rounds, followed by a controlled model
decision. Separately record a third defender club localizing the length before
the other defender discards; no mandatory plan replacement when retention
remains justified.”

Initial South holdings are SA94/HA63/DAK/CAK864 and North S862/HK74/D8653/CQ72,
with only West DQ played. Five outside winners are correct. The initial plan
cashes CA/CK then reaches CQ, returns by a heart to HA, and cashes established
clubs for ten on 3–2. On 4–1, a club concession establishes the last South club
for four clubs/nine total; outside stoppers/entries remain. It explicitly
reassesses 5–0 rather than claiming universal nine-trick safety. After actual
3–2 information the keep operation remains justified. Initial win/CA/CK/CQ/heart
return prose becomes historical as those steps execute; it does not command
replay of consumed cards.

## Delivered decision judgments

| Decision / revision | Quality | Exact advice and authorized basis |
|---|---|---|
| 0001 / 1 | PASS | “We have five side-suit winners and need four club tricks.” Correct DA/DK/HA/HK/SA. “On a 3–2 break, return to South with a heart and cash the remaining clubs for ten tricks.” CA/CK/CQ followed by H4 to HA leaves South two established clubs and North HK still reachable. D3 follows DQ. The 4–1 concession/recovery is feasible; 5–0 is explicitly conditional/reopened. |
| 0002 / 3 | PASS | “Win the opening lead and develop clubs immediately, preserving the remaining side-suit stoppers.” DK wins DQ–D3–D4 and retains DA. Initial club sequence is still available. |
| 0003 / 4 | PASS | “Start establishing clubs while retaining all remaining side-suit stoppers.” South won DK, holds CAK864 and DA; CA starts the retained route. No claimed count or entry is consumed. |
| 0004 / 6 | PASS | “Keep dummy’s queen for the third club round, preserving communication as clubs are established.” Current CA–C3; North CQ72. C2 is legal and leaves CQ7 to follow CK then take round three. |
| 0005 / 8 | PASS | “Cash the second club honor, keeping dummy’s queen for the third round and checking the split.” First club round records West C3/East C5. CK leaves South C864, North CQ7; further follows have not been assumed. |
| 0006 / 10 | PASS | “Preserve the queen to win the third club round.” Current CK–C9 and North CQ7. C7 legally follows under CK and CQ outranks remaining enemy clubs. East's second club is not yet observed or invented. |
| 0007 / 12 | PASS | “Lead to dummy’s queen to draw the last opposing club, establishing two more club winners.” West C3/C9 and East C5/CT have actually followed twice. Only CJ remains outside the partnership, side still unknown. C4→CQ collects it wherever held, and C8/C6 become winners. This concretely uses the new information and retains the anticipated 3–2 route. |
| 0008 / 16 | PASS | “Cross to the heart ace to cash South’s established clubs; ten tricks are now available.” By this snapshot West CJ has fallen under forced North CQ and East has discarded H2; all enemy clubs are gone. North HK74, South HA63/C86/DA/SA. H4→HA executes the planned return; four won plus six accessible winners = ten. |
| 0009 / 18 | PASS | “Win to reach the established clubs. Together with the remaining side-suit winners, they secure ten tricks.” Current H4–H8, South HA. HA wins and reaches C86; future HK crossing from South H3/H6 remains. No overtaking of a partnership honour or phantom entry. |
| 0010 / 20 | PASS | “Cash the established clubs, taking safe winners while watching the defenders’ discards.” South on lead holds C86 and all enemy clubs have actually disappeared. C6 is established; DA/SA/North HK remain. Watching future discards does not assert their identities. |
| 0011 / 22 | PASS | “Discard a low diamond, preserving the heart king and potential major-suit threats while cashing clubs.” Current South C6–West D2; North void in clubs, holds D865/HK7/S862. D5 is legal and preserves the concrete HK route; “potential” major threats do not assert an additional certain winner. |
| 0012 / 24 | PASS | “Cash the last established club before collecting the remaining side-suit winners.” Six tricks won; South C8/DA/SA/H63, North HK7. C8 gives seven, DA/SA then low heart to HK gives ten. The prior heart return is historical, not repeated. |

Every raw grader explanation about these card counts, entries, visibility and
remaining routes is supported by the corresponding authorized facts. No
material defect or unresolved strategic claim was found in the final outputs.
This bounded pass does not establish general player or grader reliability.

## Coverage: actual timing and its limit

| Actual event / model window | What is established | Observed advice / coverage |
|---|---|---|
| First club round ends seq7: CA–C3–C2–C5 | Each defender followed once. | d5/d6 preserve CQ and do not claim the later East follow in advance. |
| Second round ends seq11: CK–C9–C7–CT | Both followed twice; with five clubs missing initially, exactly CJ remains. Split is 3–2 but CJ's owner not yet known. | d7/rev12 states “last opposing club” without naming its owner, and leads C4 to CQ to draw it. Core new-information use is **exercised and correct**. |
| Third-round West CJ at seq13 after South C4 | West's third club locates the long hand before East's discard. This is the desired actual event ordering. | Next controlled action is North CQ at seq14, but trace source is **forced**, not model. North holds only CQ in the led suit. |
| East H2 discard seq15 | First show-out confirms East's original two clubs. | The next genuine model decision d8/rev16 occurs only after this discard. It uses all clubs exhausted and the heart crossing. |

Thus the distinct position window **exists**, unlike r1's ordering, but there is
no player/reviewer judgment observing just West's third club before East's first
show-out. The mechanical CQ can execute and be recorded correctly while
providing no evidence of model localization/explanation in that window. Summary
`third_club_before_other_defender_revisions=[]` is consistent with no model
request there. Do not count forced CQ as a model decision, and do not require
changing an otherwise sound route merely to create that extra model request.

Summary `two_round_break_decision_revisions=[12,16,18,20,22,24]` contains a genuine
immediate model window at rev12, whose answer explicitly exploits the sole
remaining opposing club. That supports the **main short-3 gate with justified
keep**, rather than an automatic pass from task completion. The separate
third-first model-use facet remains untested in this run and needs accurate
candidate-wide reporting across prescribed attempts.

## Artifact identity

Unchanged SHA256:

- `grade/input.json`: `a80a2f2ffefb604311343da2db33c8ac274d8dad3e2a0063feccb3e6e8a4f0ea`
- `grade/evaluation.json`: `eb8a0c3fd66101f44dfe6a126790de7c4580b858b516fb01081e7f5673c569e0`
- `grade/grader-output.json`: `267afea933eb8daa4490bb65d12760c495cea616cd03cd0f63e66a040a376c9c`
- `play/trace.json`: `7c561d4bb836d4d3736919c3c6be66856acc885b5964e18efcb1186fb5652a5b`
- `summary.json`: `c624dddee5fa6956cc9435723c3a7221dfb36ff6b21f109655ef9155bfa1a676`

No grade or summary was rewritten. No issue closure, complete acceptance or
merge recommendation is implied.
