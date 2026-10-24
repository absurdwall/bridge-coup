## Summary

Continue #48 from approved integration checkpoint `c74d697`, inheriting draft #47. Target is `main`; #45 and #47 remain open drafts and unmerged. **Acceptance is NO-GO; all three permitted frozen candidate cycles are consumed. Keep this PR draft.**

```text
BoardDriver → ExpertSession (one continuing player thread)
  pending proposal → independent Sol Medium reviewer
    approve → canonical execution once → matching plan commitment
    revise / uncertain → same player and frozen position (five valid rounds)
    unresolved fifth review → validated contested execution and matching plan
    technical failure → at most three retries per review → stop on exhaustion
```

Both production roles use `gpt-6.1-sol / medium`, complete authorized snapshots and empty tools. Independent acceptance is separate from runtime authorization.

## Evidence

- **Before:** approved instructions and structured declarer input had no production reviewer loop.
  **After:** #49–51 scoped runtime work is integrated: exact candidate binding, same-session revision/clarification, contested plan adoption, independent retry/deadline boundaries and complete role evidence. Their evidence-backed scoped closures do not establish Stage 1 acceptance or delivery on main.
- **Before:** deterministic tests lacked the reviewed lifecycle and failure boundaries.
  **After:** 255 Swift tests (10 preexisting skips, zero failures), followed by 74 Python tests (zero failures). Independent Standards, Spec and changed-instruction reviews are clear; evidence helpers also received an independent audit. The initial host compiler/SDK mismatch and successful command-scoped SDK selection are retained.
- **Cycle 1 — NO-GO:** prescribed 22 attempts complete; independent 247 passing / 22 failing deliveries across 17 passing / 5 failing attempts. Five concrete defects and the unexercised stronger third-club-first model facet prevent acceptance.
- **Cycle 2 — NO-GO:** 21 normal completed attempts independently pass all 254 deliveries. The interrupted short-5-r1 has three separately passing partial deliveries and remains incomplete; it was never replayed. Nine untouched slots ran once as an explicitly recorded operational supplement. Missing usage/process associations remain unknown. The stronger semantic facet remains unmet, with the alternative independent interpretation retained.
- **Cycle 3 — NO-GO:** all 22 fixed attempts completed once and were independently reviewed: **265 pass / 5 fail / 0 uncertain deliveries**, 21 passing / 1 failing attempt, all 22 core targets covered. One material conditional-plan error originates at short-5-r2 D7 and survives D8–D11; D12 repairs it without erasing earlier delivered failures. A public-compatible legal counterbranch verifies the error. The stronger short-3 new-localization-use requirement is separately unmet. Raw grades remain unchanged at 259 pass / 11 fail; the six rejected raw allegations are individually explained. All four full boards pass each delivered decision and separately replay 52 unique legal cards / 13 tricks (10–3, 10–3, 12–1, 13–0); those results do not replace quality assessment.
- C3 records 270 model deliveries, 28 mechanical actions, 280 player + 280 reviewer requests, 10 feedback revisions, zero technical retries and zero human wait. All 22 board and grader subprocess returns are observed as zero; the detached orchestrator's OS exit is unknown. Exact source, executable, both resource bundles, raw records, drafts/disagreements and portable saved-evidence audits are preserved. No fourth candidate, reroll, stitched pass or additional model call is authorized.

See the committed [acceptance report and all 13 issue assessments](https://github.com/absurdwall/bridge-coup/blob/20e4d44fb7210d460aa3a42ad832f959cc737c47/evals/stage1/evidence/issue48/ACCEPTANCE-REPORT.md), [41-obligation ledger and eight explicit supersessions](https://github.com/absurdwall/bridge-coup/blob/20e4d44fb7210d460aa3a42ad832f959cc737c47/evals/stage1/evidence/issue48/OBLIGATION-LEDGER.md), and [C3 raw/independent results and reproducible audits](https://github.com/absurdwall/bridge-coup/blob/20e4d44fb7210d460aa3a42ad832f959cc737c47/evals/stage1/evidence/issue48/ticket52/candidate3-analysis/REPORT.md). Each candidate retains its own frozen version; results are not pooled into a passing candidate.

## Merge Danger

**Door:** two-way

Code can be reverted; historical evidence remains preserved. Merge and acceptance/reintegration closure require explicit owner approval. #36–42, #46, #48 and #52 remain open; #49–51 retain their scoped closures.

**Blast Radius:** Core

Expert/BoardDriver authorization, native role transport, active-plan lifecycle and evaluation are affected. Actual acceptance has failed; main is unchanged.
