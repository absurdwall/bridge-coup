# Publication review: design diagnosis report

Reviewed `/Users/tingranwang/.codex/worktrees/issue46-integration/bridge-coup/evals/stage1/evidence/issue46-completion/design-diagnosis-20261022/REPORT.md` against the archived manifest and saved addendum. No model calls or source edits were made.

The headline counts reconcile: 42 requests total, comprising 20 seeded-history and 22 fresh-context requests. The d12 figures also reconcile: original-current-input fresh context chose CA in 4/4; unchanged full-history trials chose CJ in 6/7 (history and reasoning-window pairs plus the memory-rule control). The report correctly treats these as observed outcomes rather than proof of a causal mechanism. It does not claim hidden-reasoning-only causation, a production fix, or full acceptance. The corrected addendum supports the specific d12 comparison: from the current position, CA followed by the guaranteed heart and diamond route wins all seven remaining tricks; choosing CJ gives up one, regardless of unseen defenders’ cards. That establishes this position’s concrete consequence without generalizing to all strategy decisions.

The diagnostic archive’s response metadata is consistent with the report’s stated completed requests. The archived manifest includes the final addendum. The next design question is appropriately framed as a hypothesis about operationalizing reassessment, not as a tested remedy.

Two small wording changes would make the report more precise before publication:

1. The sentence “No player source, fixed instructions, output schema, model, effort, or one-board/one-thread production behavior changed” reads as if no fixed instruction text changed anywhere in the diagnostic requests. The memory-rule arm did test a generic instruction variant in three requests. Suggested replacement: “No production player source, fixed instructions, output schema, model, effort, or one-board/one-thread behavior changed; one generic instruction variant was tested in diagnostic requests.”
2. The token-count sentence about correct public-only probes using 53/103 reasoning tokens versus incorrect full-history probes using 151/71 refers specifically to the two history-study d12 pairs. Other public-only reasoning-window trials chose CJ with zero reported reasoning tokens. This is not numerically false, but should be scoped: “In the original-history-study pair, the two correct public-only probes used 53 and 103 reasoning tokens; the two incorrect full-history probes used 151 and 71.”

I found no other factual overclaim requiring correction. These are publication-precision suggestions; they do not change the report’s conclusion or imply a production change.
