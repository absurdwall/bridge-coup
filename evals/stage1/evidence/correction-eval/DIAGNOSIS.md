# Read-only Eval and material diagnosis

Inspected restored candidate `0cfa39f` at stage1-integration, live issues #36/#41/#42, CONTEXT and both ADRs. No repository edits, model calls, GitHub writes or historical-grade changes. This is diagnosis and a proposed bounded revision, not acceptance or merge approval.

## 1. Confirmed citation-contract mismatch

`evaluate.py:138–151` rejects every result without a nonempty findings array and exact nonempty answer quotations. `grader-schema.json:30–59` permits `findings: []` and `quotes: []`; it has no minimum item counts. `rubric.txt` says “For each finding put one or more exact, contiguous answer excerpts”; it never explicitly requires a finding for a PASS. The actual prompt (`run_grader`, line ~215) only says “Apply this rubric independently to every supplied decision. Return only the required structured result.” This makes the enforced Python contract stronger than the serialized model contract.

An offline scan of all 22 original grader outputs confirms **all 45 citation/format defects are `status: pass, findings: []`**, distributed:

| Attempt | Empty PASS findings |
|---|---:|
| full-development-r2 | 5 |
| full-reserved-r1 | 16 |
| full-reserved-r2 | 12 |
| short-3-r1 | 7 |
| short-3-r3 | 5 |

Example: `evidence/ticket42/matrix/full-reserved-r1/grade/grader-output.json`, first result, is exactly `{id: decision-0001, status: pass, findings: []}`. These outputs meet the saved JSON schema but fail Python validation. This is primarily a **program schema/prompt consistency defect**, rather than evidence of 45 false player answers or necessarily 45 violations of the contract actually sent to the grader. Historical evaluator_issue classifications remain preserved and correctly do not establish semantic passes.

Ranked hypotheses:
1. **Confirmed, high confidence:** the model reasonably treated findings as defect reports and omitted them on passing answers because the schema allowed that. Falsifiable after correction: a serialized schema and offline contract tests must reject empty findings/quotes, while prompts explicitly require cited support for PASS as well as FAIL/UNCERTAIN.
2. **Possible, unproved:** long batch grading encourages abbreviated positive rows. Five affected batches are not proof of a causal length threshold. Do not change the required number of graders/batches or add retries merely on this hypothesis.
3. **Not established:** model inability to quote positive facts. Existing cited passing answers and calibration provide counterexamples. One bounded saved-output grader run after correction can test the contract; no playing call is needed.

Minimal revision: preserve the fields; add `minItems: 1` to findings and quotes, nonempty string constraints where supported, and one sentence requiring at least one exact cited positive basis or precise uncertainty explanation for **every status**. Keep Python exact-quote validation. Version rubric `stage1-basic-v3`; preserve V1/V2 saved-output readers. Check the actual schema sent to `codex exec`, not just an internal validator. Provider acceptance of added constraints must be checked rather than assumed. Do not weaken Python validation or simply accept historical empty PASS rows.

Useful bounded tests at Python public Eval seam:
- Exact serialized schema rejects empty findings/quotes for all three statuses; runtime validator produces evaluator_issue/uncertain, never auto-pass.
- Cited support for a feasible positive alternative can pass; absent/invented quote remains evaluator_issue; genuine cited uncertainty remains pending.
- Duplicate/missing/extra IDs stay evaluator issues; actual retained plans may be cited; no defender hands or desired label leaks into packages.
- Reprocess originals offline into a new directory. Original SHA256 values and original adjudication/grades must stay unchanged. Reprocessing cannot manufacture missing citations, so the 45 remain evaluator issues until a separate fresh grader output or reviewed overlay supplies actual evidence.
- If a model grader is run on saved decisions, record a fresh versioned package/raw result/provenance, review explanations against actual snapshots, and report original versus new classification. This tests the evaluator, not improved player quality. Do not feed results to any playing thread or count unresolved disputes as passes.

Additional confirmed attribution issue (not responsible for the original 45): `evaluate.py:156` gives evaluator_issue precedence over a simultaneous deterministic product failure. An authored offline package with ownership=fail and empty findings yields mechanical=fail/overall=fail but only attribution=evaluator_issue. Keep independent structural and evaluator attribution (or explicit secondary categories) so a grader fault does not hide a known program/product defect. The original 45 had mechanical=pass; their historical counts do not change.

## 2. Reachable Walker test, bypass and opponent gift

The adapted Walker board is legal and the current `conserve-high` profile already continues spades after genuine ducks. An independently replayed legal environment witness is:

```
W SK, N S8, E S4, S S3
W SQ, N S7, E S5, S S9
W SJ, N C4, E S6, S SA
S D2, W D6, N DK, E DA
```

At that point East has no spades, North HA remains a diamond entry, and the defender communication issue has actually been exercised before losing DA. This witness is material reachability evidence, **not a required player sequence or model success**. Swapped North/South low spade spots and other legal discards can work. Holding up twice is not an unconditional IMP rule: hidden distribution is unknown to the player and alternatives require concrete decision-time review.

All original short-6 runs instead took SA at sequence 3 and lost DA at 7, so no pre-loss hold-up was exercised. In r1/r3 East's S6 return produced S6–S3–S2–S7/S8: West played lowest because partner was currently winning, allowing dummy to win the trick. That was a gift, not evidence of communication control. r2 returned S6–S9–ST–S7 and subsequently ran spades; branches respond to actual choices.

`acceptance.py:147–151` currently counts spade plays anywhere plus any diamond play. It cannot distinguish the above paths. It returns pending, which is appropriately not a final pass, but its facts are too weak to label the specialized capability observed.

Bounded corpus-v2 proposal: keep Walker holdings/opening lead, no forced model prefix. Declare facets separately: (a) initial opportunity, (b) actual controlled hold-up while SA remains and defender spade continuation before DA loss, (c) subsequent diamond contest/DA loss and observed response, (d) independent communication/entry review. Early SA can remain a judged alternative, but does not prove exercised hold-up. Avoid demanding exactly two ducks or East void from three observed rounds. Keep case pending/uncovered when the relevant actual path is bypassed.

Optional narrowly scoped environment improvement: a `walker-communication` profile may protect a currently winning partner against the **visible fourth-hand dummy's** higher card, choosing a legal minimal winning cover instead of blindly lowest. Apply only to short-6; do not globally tune all opponents or use hidden truth in Expert. Offline test the gift path (West ST covers S7/S8), the genuine two-duck witness, legality and reasonable alternate player spots. This prevents an obvious third-hand gift but cannot force the player to exercise hold-up and must not make early SA an automatic strategic failure. A profile revision changes actual events and therefore requires new affected playing evidence, not reused old passes.

## 3. Synthetic entries and new information

Short-4 manifest says “consumed club honors plus a remaining entry decision,” without a count threshold. The helper `acceptance.py:133` silently demands >=2 of CA/CK/CQ consumed. Original short-4-r2 had only CQ consumed by decision-0014 (revision 29), with North HK/H7/H4/C7 and South HA/H6/CA/CK/C6 remaining. Actual H4 is an entry/transport decision; its reason wrongly says lead the remaining club. Thus **limited entry/consumed-card opportunity is present, quality fails independently**, while later-two-honor/endgame facets were not established. Do not erase this distinction by calling the whole teaching facet fully covered.

Bounded helper revision: report the exact consumed honor identities and actual snapshot references; at least one consumed honor is sufficient for the manifest's basic consumed-card facet, but return pending for independent entry-route review. Separate a stronger post-two-honor facet if reported; do not silently require it or silently claim it passed. Consuming a heart entry, actually needing transport between the hands and assessing remaining established clubs are distinct observable facts. A club still present alone does not prove that an entry choice is meaningful.

Short-3's two-full-club-round trigger is grounded: with five missing clubs, both defenders following twice proves 3–2. Short-3-r1 at sequences 8–11 completes the second round; sequence 13 West CJ localizes the third club before East discards at 15. The board physically passes that information window at revision 14, but actual trace inspection during correction showed North C2 is sole-legal/forced and model decisions jump from revision 12 to 16. Thus the precise pre-discard model-reasoning facet was not measured in that run. Preserve distinct facets: two-round distribution inference, third-club localization, and non-invention of a not-yet-observed discard. Do not demand plan replacement if the retained conditional plan already covers the actual break; concise omission of a count is not itself a severe defect. Record factual coverage separately from what the answer actually claims.

Pavlicek short-5 helper detects North diamond play, CA retention and a later decision, but does not itself establish a meaningful defender response or sufficient timing/entries. Keep it a pending candidate; distinguish DA duck/DA take, real response and gift/avoidance. Existing `pavlicek-entry` policy includes reviewed state-aware legal responses; preserve alternatives with actual sufficient entries and mark contested strategic lines pending. No blanket rejection of early concessions or spot variants.

## 4. Versioning, impact and stop boundary

Use a bounded `stage1-finite-v2` manifest with the same six short IDs, two full IDs, 3/2 attempt counts and deals. No new held-out claim: rename the *role* of already-exposed reserved board to regression (the historical ID full-reserved may remain stable with explicit former-role metadata). Explain that this is a used acceptance fixture and does not prove fresh generalization. If the spec requires a newly unexposed acceptance board for a new pass claim, present that unresolved requirement rather than silently replace the fixture or expand the corpus.

Version manifest/rubric/frozen hashes and revision log. Keep the old corpus and all output interpretation recoverable from the frozen original commit/evidence. Parser/coverage changes reprocess saved evidence into a separate overlay; they do not establish new player quality. New wire, prompt or policy changes require fresh affected quality attempts. Once a candidate is intended to satisfy #36/#42, run its specified 22 attempts only after preflight/freeze/review; no splicing across incompatible candidates, retries until success or replacement of failed originals. If one bounded affected candidate exhibits a severe confirmed failure, preserve and return the blocker; do not claim a completed final matrix or mergeable engineering checkpoint.

No change here establishes human expert approval. Both ADRs require independent adjudication of disputes and prohibit letting transparent runtime success replace basic quality. Correction PR remains draft; review is not explicit user approval to merge or close reopened tickets.
