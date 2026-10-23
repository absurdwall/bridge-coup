# Standards review — 453ee0030c2bed87aa2e415a5c1ef715c248b94c

Compared with fixed main `b2fb9b1d0433357dcdb6e09e4e06fe7736539fb6`, including the supplied commit list. Scope: changed production Swift, CLI/capture scripts, evaluator/regression code, tests, domain/ADR and operator documentation; inherited raw evidence was inspected selectively.

**Documented standards:** No hard violation found. AGENTS.md requires topic-branch work, hooks and approval before merge; domain.md requires preserved shared vocabulary and explicit ADR conflicts. CONTEXT.md and ADR 0003 consistently distinguish pending proposals, active plans, semantic rounds, contested execution and acceptance grading. No merge/closure or live acceptance was performed during this review. GitHub write pacing is not exercised by these code paths.

**Actionable documentation defect — P3:** `evals/stage1/README.md:16–18,53,72,92,96` presents obsolete facts as current: “fixed to gpt-6-luna”, rubric `stage1-basic-v3`, “--decisions bounds model requests”, “publicReason → plan → selectedCard”, and “Retries are zero.” The implementation requests Sol Medium, uses rubric v4, counts delivered decisions separately from revision requests, emits plan/card/reason and permits reviewer retries. An operator following the primary run guide will audit against the wrong configuration/counters. Update current guidance while labeling historical descriptions. This is an accuracy defect, not a violation of a specific documented coding rule.

**Baseline smells — judgment calls, nonblocking:**

- Duplicated Code, `Sources/BridgeExpert/NeedsInput.swift:19–22` and `Sources/BridgeExpert/PlayReview.swift:59–61`: both repeat `Set(...events.map(\.card)).count == ...events.count`, disjoint holdings/events and sequence checks. The distinct invalid-versus-missing classifications are useful, but their shared conflict predicate could be centralized so future invariants cannot drift.
- Mysterious Name, `evals/stage1/reviewed_evidence.py:65–149`: `q`, `p`, `r`, `rv`, `e`, `rid` simultaneously denote canonical snapshots, candidates, rounds, verdicts and evidence rows. These are provenance-sensitive comparisons; expand names around `expected_ids` and `recorded_turn` to make associations auditable.

Independent Python replay/canonical reconstruction intentionally duplicates Swift behavior; extracting it into the production implementation would undermine independence. No additional actionable P0–P2 runtime bug established. Validation is static review; no model calls or acceptance attempts consumed.
