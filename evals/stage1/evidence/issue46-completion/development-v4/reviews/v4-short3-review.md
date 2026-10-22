# Independent review: development-v4 short-3-r1

## Scope and result

Reviewed only the completed `development-v4/short-3-r1` saved inputs, outputs, wire requests, replay and summary, together with the unchanged `short-3` corpus entry. No model calls, source edits, or grade changes. I did not inspect any active run or hidden defender hands.

I found no material factual, rank, legal-action, or physical-plan defect in the 12 saved decisions. The recorded Sol quality pass is consistent with this review for this short run. This does not establish causality for the schema change, full-board quality, or complete case coverage: the replay stops after 12 controlled decisions at six declarer tricks, and the saved outcome remains pending coverage.

## Card and plan checks

- **d1–d2:** West leads DQ; North’s D3 is a legal low follow, and South’s DA necessarily beats DQ while preserving DK. The replacement plan correctly moves to South’s club source.
- **d3–d6:** CA and then CK are winners because declarer holds A/K and the other high club honors are in North. North’s C2 under CA and C7 under CK preserve CQ. At d6 East has not yet played to the second club round; the answer does not assume East is out of clubs.
- **d7:** Both defenders have followed twice: the first club round is CA–C3–C2–C5 and the second is CK–C9–C7–CT. The next controlled decision is South leading C4 toward North’s CQ, consistent with the retained club-development plan. After those known cards, CJ is the sole unaccounted-for club and CQ outranks it, so the line is physically sound. “Giving it a chance to win” is cautious phrasing, not an incorrect winner claim.
- **d8–d9:** The third club trick is C4–CJ–CQ–H2. North’s CQ wins over CJ; at the next controlled decision North has HK and South still has HA. HK is a sure winner (A is in South’s hand and no defender card can outrank K); the replacement plan’s HK-to-heart-to-HA route is feasible. South’s H3 under HK is legal and preserves HA. The d8 wording that clubs are “potential additional tricks” and to “track defenders’ remaining clubs” understates the fact that both defenders have now shown out, but it does not assert that they still hold clubs or make the route false. By d10, the plan explicitly recognizes the shown-out defenders.
- **d10–d12:** North’s D5 to South’s DK is safe: DA was already used on the opening trick and DQ was the opening lead, leaving DK as the highest remaining diamond. South’s HA and SA are sure winners. The five defensive clubs have all appeared (West C3/C9/CJ; East C5/CT), so South’s remaining C8/C6 are established tricks. North’s H4 is a legal low follow under South’s HA while West has H9; the answer preserves the remaining winners. No action or plan relies on an unseen defender holding.

## Case trigger and coverage

The corpus is unchanged. Its two-round trigger is reached: after both defenders follow to two club rounds, controlled decision d7 leads C4 toward CQ and retains the already valid plan. This is behavioral evidence of an appropriate continuation; the answer does not explicitly state “3–2” or name the sole remaining club, so semantic coverage should remain pending rather than be upgraded based on the selected card alone.

The separate third-club-before-other-defender-discard event occurs in the actual play order: South C4, West CJ (West’s third club), North CQ, East H2 discard. However, North’s CQ was forced as its only legal club; there was no controlled model request after West showed CJ and before East discarded. The next model request is d8, after the complete trick and East’s H2 are already in the snapshot. Thus this run does not cover the requested decision-time facet of using the third club to localize length before the other defender discards. `summary.json` likewise leaves `third_club_before_other_defender_revisions` empty and coverage pending. Do not treat the mere occurrence of the card sequence as model coverage.

## Actual schema and output root order

Inspected all 12 saved `wire/request-*.json` files, not only the local source definition. Each transmitted `text.format.schema.properties` object orders the root fields as `plan`, `selectedCard`, `publicReason`. The schema’s `required` array is still ordered `plan`, `publicReason`, `selectedCard`; that array expresses required membership, not generation order. All 12 captured `rawOutput` JSON objects also serialize root keys in `plan`, `selectedCard`, `publicReason` order. This confirms the requested order in the actual requests and responses. One passing run is evidence of the order being applied, not evidence that the order caused the quality result.

## Bounded disposition

Agree with 12/12 quality passes for these saved decisions. Keep coverage pending: the two-round response is plausible behavioral use but not explicit semantic proof, and the third-club sub-trigger had no model-controlled decision before the other defender discarded. No modification to the evaluator’s stored grades or coverage state is warranted by this review.

## Clarification: basic trigger versus separate facet

Under the frozen manifest, d7 satisfies the basic two-round triggered/justified-retention facet: both defenders followed two club rounds; the next controlled decision keeps the original plan, which already anticipated continuing clubs through CQ; and South leads C4 toward CQ. The manifest explicitly accepts justified retention when the plan anticipated the break. It does not require the answer to restate “3–2,” and I do not impose that requirement or infer internal recognition from the action. This is observable support for the basic facet, not a claim about hidden reasoning.

The separate third-club-before-the-other-defender-discard facet remains unclaimed. West’s third club is followed by North’s forced sole-legal CQ, then East discards H2; the next controlled model decision comes only after that discard. Overall saved coverage remains pending, unchanged, because this separate decision-time window is not exercised.
