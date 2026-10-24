# Standards Review — Output-Order Correction v4

Base: `7129ffd352ee332c50b08db9d71a62d069afaaeb`
Target: `bbcbd1b1c1b5e8364dcc5bbb98a90b615878c365` (`codex/issue46-output-order`)

## Findings

No new documented-standard violation, concrete defect, or actionable smell found in the three-file patch.

- `Expert.swift` orders the emitted root schema properties as `plan`, `selectedCard`, `publicReason`, while retaining the nested `update`, `text` order. This aligns schema generation with the existing decision process.
- `DeclarerInstructions.txt` reorders the output field list and two JSON examples to match; the diff preserves their values and all other instruction content.
- `PlanContractTests.swift` checks order in the actual serialized `turn/start.outputSchema`, including nested plan fields, so the regression exercises the outbound boundary.

This is a request-generation consistency correction. It provides no empirical evidence of improved model quality and does not satisfy Stage 1 acceptance. The prior deferred `acceptance.py` module-boundary note is unchanged. The frozen integration matrix remains untouched; no merge was performed.

The handoff reports the targeted external RED/GREEN regression and four contract tests passing. I performed static review only and ran no tests or live calls.

## Incremental Test-Only Migration

Base `d6a8dc3` → `482f79e` changes only the native-runtime regression’s name and expected root schema order to `plan`, `selectedCard`, `publicReason`. It retains the nested `update`, `text` assertion and removes no checks, so the test is not weakened. No source changes or additional standards issues are present. The parent reports all 53 Python tests pass; I did not rerun tests.
