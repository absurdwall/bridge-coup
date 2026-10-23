# Short-3 prospective coverage diagnosis — parent only

Read-only assessment at integrated source `ca0b1a32cb67110773d21baef1ec3ea981868544`, 2026-10-23. This is a future material/runner proposal, **not authority to change candidate1**. All current-cycle files and raw grades remain unchanged. No model/API call or new live attempt occurred.

## Finding and exact scope

The present material plus `mechanical_sole_legal=true` systematically removes the ordinary third-club-first **model** window. Disabling that optimization only for short-3 is a narrow way to make a genuine existing public position eligible for player/reviewer assessment. It does not guarantee the model chooses an ordering that reaches that position, nor require one reference club line.

Distinguish the core gate from its stronger facet. The manifest requires two club rounds with both defenders following, then a controlled model decision; it separately records third-club localization before the other defender's discard. All three candidate1 short-3 overlays support the core two-round inference. Their stronger facet remains untested. r1/r2 pass delivered quality; r3 independently fails the earlier applicable plan's inventory assertion, which is a separate quality issue. This coverage repair cannot cure that failure.

Authority/evidence inspected: `evals/stage1/corpus/{manifest.json,README.md,source-review.md}`, `acceptance.py:155–174,292,359`, production `BoardDriver.swift`, and completed `T/candidate1-short3-r{1,2,3}-review.md`. `T/` means `/tmp/bridge-coup-issue48-context/`. No unfinished live run was read. The synthetic full fixture was inspected only as evaluator-owned prospective material; none of its hidden holdings was supplied to live roles or used to reassess earlier output quality.

## Why the ordinary routes lose the model window

Public initial controlled clubs are South CAK864 (five) and North CQ72 (three). After both defenders follow twice, each controlled hand has followed twice. If North has not previously discarded a club, it has exactly one club left. Five clubs were initially missing; four defender clubs are now public, so exactly one opposing club remains and its owner is still unknown.

In this material West owns the third defender club. With clockwise seats S–W–N–E:

- Third round led from South: West's third club appears, then North acts, then East first shows out. This is the desired public inference window, but North must follow its **one** remaining club. The current driver records a forced action, omitting both player and reviewer.
- Third round led from North: East shows out before South acts and before West plays its third club. The next model sees void-based localization already; it cannot evidence third-club-first inference.
- West leading its third club likewise puts North next with a sole legal club. East has no third club to lead. Changing legal spot choices, CA/CK/CQ order, or crossing through HK does not increase North's remaining club count.

Independent existing-`corpus.replay` confirmation of completed routes is saved in `T/short3-coverage-witness.json`, reproducible by `T/check_short3_coverage_window.py`:

| Completed route | Position | Actual legal North choice/source | Model ordinal if all controlled choices on that same route were reviewed |
|---|---|---|---|
| short-3-r1 | East H2 already precedes West CJ | No third-first window | No claim |
| short-3-r2 | rev14, West CJ seq13, East's H2 still future | CQ only / forced | 8 of unchanged12 |
| short-3-r3 | rev18, West CJ seq17, East's S3 still future | C7 only / forced | 10 of unchanged12 |

These are replayed legal positions, not predictions that a new model run repeats those cards or passes quality. With mechanical mode false, the public production seam can solicit a full plan-operation/card/reason proposal and independent review even when its card enum has one member.

## Avoid an overbroad impossibility claim

The optimization **alone** is not a theorem about every imaginable legal route: North could discard a club after becoming void in a side suit, later have zero clubs, and face several legal discards in a club trick. That is not one of the observed ordinary routes, and it must not be forced merely to satisfy a test.

The fixed material/bound makes this detour unsuitable as a remedy. North has three spades, three hearts and four diamonds. A first club discard needs a fourth major-suit round (no hand in this fixture can lead a fifth diamond). That entails four major rounds plus two club rounds and the initial diamond trick. Even allowing the two mechanically forced last-major follows, those seven tricks consume at least12 delivered controlled decisions before a subsequent third-club lead; South's lead and North's later discard would be beyond the12-decision short bound. Additional concessions/entries only add work. This explains why normal model choices cannot reasonably be expected to rescue the absent facet inside the declared task.

This reasoning concerns a third **club-round** window before East's first club show-out. The current helper counts any third defender club and looks only until the other defender's *next* play; it neither checks the first show-out nor necessarily that the third club was played to a club lead. Do not treat such a permissive predicate as proof of this stronger facet. Reporting should state the exact observed inference event.

## Narrow future change and material/version impact

Recommended after **all candidate1 attempts and adjudication finish**: predeclare `mechanical_sole_legal=false` for short-3 only; retain true for every other case. Keep all six short IDs ×3, both full boards ×2, the12 delivered-decision short-3 bound, opponent policy, original holdings/opening lead, live public production pipeline, ordinary IMP objective, Sol Medium roles, instructions/schemas and serious-error standard unchanged. No model advice, reference sequence, hidden layout, answer label or strategy tool is added. No extra attempt/reroll or extension until a trigger occurs.

This is a changed case execution condition, not a correction to card facts. Freeze it explicitly per case/attempt: the schedule, candidate metadata, exact CLI command and report must agree. `acceptance.py` currently freezes a global true and hardcodes `--sole-legal true`; both must reflect the same declared case setting. Prefer one declarative case configuration rather than a hidden special-case command override. If stored in the frozen manifest, update corpus version/revision log/frozen hashes and the version validator; keep rubric v4 and all board assets unchanged. An explicit versioned runner-configuration map with unchanged corpus assets is also defensible if its effect is equally discoverable and frozen. Never label old/new execution conditions identical or pool their results.

No production Driver rewrite is needed: its existing false mode already routes sole legal controlled plays through Expert/reviewer. It increases actual model/reviewer work and may stop the short run at an earlier actual-card position because those cards now consume delivered-decision slots. The replay witnesses place the desired window comfortably at decisions8/10, but later choices can differ. Other specialty/full-board bounds stay unaffected. A route with East showing out first can still miss this facet; retain that honest coverage outcome, without coercing a different legal line. The change does not guarantee fresh semantic clarification, revision or contested play either.

## Required review/validation before another freeze

1. Public Driver/Expert recorded-transport regression at each replayed window: current true mode yields forced/no request; false mode yields one real pending proposal, reviewer judgment, exact single canonical execution and matching plan. Input must include West's third club and exclude East's future discard. A legal sole card is still model/reviewer advice for counting/quality purposes.
2. Schedule/configuration regression: exactly22 attempts, only short-3's three repetitions false, other19 retain true; short-3 remains12 deliveries. Check candidate metadata/preflight inventory, actual CLI flag and durable report together. An enabled-mode trace must not silently retain mechanically forced controlled plays.
3. Coverage regression using public actual events: require completed two-round proof, third club in the relevant club trick, no earlier other-defender show-out, and an actual model decision before that first show-out. r1 must remain unexercised; r2/r3 expose sole-legal skipped positions. Preserve old permissive predicate history rather than rewrite candidate1 summaries.
4. Run appropriate Swift/66Python regressions sequentially, independently review changed hunks/material/configuration, then freeze a new complete candidate/version. The source/config changes invalidate candidate1 preflight. This would be a new substantive cycle within the maximum3; rerun the full prescribed22, not just short-3 and never mix favorable attempts across versions.

The existing optional mechanical optimization is authorized by #36/#48, so requesting real model review of its sole legal card stays within the public pipeline's scope. This memo grants no source/material change, extra cycle, merge or closure permission. Any later quality-instruction repair is separate, requires its own diagnosis/review/versioned hashes and must not inject this fixture's desired answer.
