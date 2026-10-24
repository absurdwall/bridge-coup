# Short-3 coverage predicate refinement — parent only

Read-only prospective refinement, 2026-10-23, source `ca0b1a32cb67110773d21baef1ec3ea981868544`. No source/material/frozen candidate edit, GitHub write, native network/model call, live feedback or unfinished-output inspection occurred. `T/` below means `/tmp/bridge-coup-issue48-context/`.

**Correction to my prior memo:** requiring the third defender club to be played **to a club lead** was unnecessarily restrictive. Remove that prerequisite from `T/short3-coverage-diagnosis.md`'s prospective predicate/test recommendation. A third club discarded on another suit can establish the same public original-length inference. The ordinary-route mechanical-skip diagnosis remains valid for the three completed candidate1 short-3 routes, but it must not be promoted to a general claim that no other legal inference route exists.

## Exact retained authority

- #36, supplied `T/36.md:129`: “once each defender has followed to two club rounds, 3–2 is already determined, though which hand has three may still be unknown. When one defender's third club appears, its location is known before the other defender actually discards. Do not confuse mechanically inferred remaining length with an unobserved specific discard.” “Appears” does not specify the led suit.
- #36 `:33,77,131` accepts alternative lines and says the reference/sample sequence is a demonstration, not the only accepted sequence. An added club-lead requirement would exclude a legitimate information route without source authority.
- #48 body:32 retains non-replaced #36 obligations; body:62 says the mechanically sole-legal path **can** skip after an initial plan; body:86 preserves the original22attempt matrix, serious-error criteria and material coverage. It does not narrow the inference to one route or authorize silently counting a forced play as model evidence.
- Current frozen manifest short-3: both following twice prove3–2; the defender showing its third club localizes length before the other discards; assess keep/replace on actual information. Its coverage trigger separates the core two-round model decision from the third-card facet. No mandatory replacement or exact card route is prescribed.

## Minimal correction: first club show-out, not next defender play

Keep separate facts:

1. **Core two-round opportunity:** two actual completed club tricks in which both defenders followed, followed by an actual controlled model decision. The public five-missing-clubs count proves3–2; it does not yet name the long defender.
2. **Third-card inference opportunity:** after that public count basis, defender D's actual third club is observed at event sequence `t`. The card may be followed, led or discarded on another suit. Public card counts establish D originally held three and other defender O two.
3. **Distinct early model window:** a canonical snapshot for an actual model-controlled pending decision includes that third card but excludes O's **first observed failure to follow a club lead**. This tests whether the model can use the third-card information before void-based localization becomes available. A sole-legal forced action has no player/reviewer judgment and does not satisfy this window.

Define `s` from the entire prior public event history as O's earliest event whose trick's led suit is clubs and whose played suit is not clubs. This is a club show-out. An unrelated earlier diamond/heart/spade discard does not prove a club void and must not close the window. Likewise O's next side-suit follow after `t` does not close it. If `s < t`, the stronger third-card-first facet did not occur; there is no new localization opportunity merely because some later O play remains future.

With zero-based event sequence and snapshot `revision == number of included events`, a candidate structural window requires **`t < revision <= s`** when `s` exists; if it has not occurred in the bounded recorded prefix, require `t < revision` and no prior club show-out in that snapshot. No later show-out needs to be manufactured or awaited. Record `s` as unobserved, not an invented future event. Validate the snapshot actually matches the public prefix; do not rely on a revision label alone.

The current helper uses `next_other` after the third club. That can falsely admit candidate1 r1 rev16/18 even though East H2 already showed out at seq13 before West CJ seq15. Replacing that cap with the global **first club-show-out** boundary is the essential correction. A led-suit restriction on the third club is not needed to fix that false positive.

## Public proof and independent judgment

The structural helper should expose opportunities, not announce successful model inference. Its public proof can use only initial authorized controlled holdings reconstructed from current holdings plus actual controlled plays, complete actual public events, ordinary suit/turn rules and the13-card-per-suit count. In this case five clubs initially lay outside the partnership; after both defenders' two follows, four defender clubs are public; the third card from D identifies the fifth. This proof needs no hidden fixture holdings, desired answer label or future O card.

A prior equivalent public deduction may already have localized the last club even without a club show-out (for example a complete late-hand reconstruction). If so, label the observation honestly as confirmation rather than a newly tested localization skill. The simple first-show-out predicate is an eligibility screen; independent review resolves this nuance from the actual snapshot and advice. Do not add an elaborate hidden-hand solver to the production path.

A covered semantic facet additionally needs the delivered advice/retained plan to use the public consequence correctly where material, accept a justified keep or replacement, and avoid inventing O's as-yet-unobserved specific card/discard. The current legal card alone—even an unavoidable sole follow—does not prove inference. Runtime review approval likewise is not quality evidence. Preserve both an event-only window and an actual-model-window record so forced mechanics cannot masquerade as tested reasoning.

## Legal discarded-third witness, with an explicit scope limit

`T/check_short3_discarded_third.py` replays an authored27-event prefix through the existing evaluator `corpus.replay`; result `T/short3-discarded-third-witness.json` is a legality/predicate witness only. After opening DQ/D3/D4/DK, actual club rounds CA/C3/C2/C5 and CK/C9/C7/CT show each defender twice. Three heart rounds end with East HJ winning; East then legally leads HQ, South discards S4, West discards CJ. North now acts at rev27, on a **heart** trick, before any East club show-out. Public West C3/C9/CJ versus East C5/CT proves original3–2. North has multiple legal discards; no club-led test is necessary for the inference.

This witness is **not current production-opponent-policy reachability or model performance**: East's legal HQ lead differs from the fixed conserve-high policy, which would prefer its remaining opening-suit diamonds. It is not a proposal to substitute opponent cards, change policy, stretch the short run or force that sequence. Its narrow purpose is to falsify the proposed universal club-lead prerequisite. Accordingly, the prior memo's beyond12 detour argument concerns a later club-round after a controlled club discard, not every possible appearance of a defender's third club on a side suit. Do not cite it as universal untestability of the broader source requirement.

## Minimal future regression set / impact

- Completed r1 must have no early model window: East's **first** show-out precedes West's third card; later East plays do not reopen it.
- Completed r2/r3 must expose event windows but no current model windows, because North CQ/C7 is forced. With future short-3-only mechanical mode false, those same public positions become eligible reviewed decisions at same-route ordinals8/10; this remains no guarantee of a new run repeating that ordering.
- A third club discarded on another suit, with valid two-round public count proof and no prior O club show-out, must remain eligible. Earlier O side-suit discards/follows must not disqualify it; a later O club show-out closes it at the correct prefix boundary.
- A third club before the required count basis, a model snapshot after first show-out, a forced-only event, a fabricated prefix, or a repeated previously localized fact must not be relabeled as demonstrated new model inference. Keep the core opportunity and stronger facet distinct.

A future first-show-out helper repair may generate a separately labeled overlay from saved events, but must not rewrite candidate1 summaries/grades or silently change its acceptance criteria. Document the interpretation/version, assess affected historical coverage, preserve original predicates/results, independently review/test the change and freeze it with any future short-3 execution-mode adjustment. Keep22attempts and all bounds unchanged. No changes are proposed while candidate1 continues; no extra live call, merge or closure is authorized by this memo.
