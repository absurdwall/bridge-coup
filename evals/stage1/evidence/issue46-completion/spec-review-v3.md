## Spec review v3

No code-level spec defect or unasked product scope was found in the reviewed change.

Issue #46 says snapshots carry a complete current position and that `current` “contains `toAct` and `tricksWon`.” This patch adds `winningPlay` there. The supplied latest Issue #46 clarification (comment #6337462204) records approval for that additive field. It is not new strategic analysis: `DecisionSnapshot.currentWinningPlay` is documented as the highest actual play (Sources/BridgeDomain/BridgeValues.swift:91-92), and BoardState derives it through the existing public trick rule (Sources/BridgeEngine/BoardState.swift:60-66, 77-81). Serialization emits `{seat, card}` or null (Sources/BridgeExpert/Expert.swift:200-202). The fixed instructions tell the Expert how to use it without prescribing a card or plan (Sources/BridgeExpert/Resources/DeclarerInstructions.txt:25-29, 94-96).

The new driver regression covers a current opening winner, null on lead, partner currently winning, selected-card legality, and same-thread continuity (Tests/BridgePlayingTests/SnapshotInputTests.swift:8-41); the runtime test checks the value in the actual public request (evals/stage1/tests/test_runtime_isolation.py:102-123). Output schema, objective, plan carry-forward, tools, and runtime identity policy remain unchanged. The earlier joint walkthrough requirement is already satisfied by the prior inspected run.

**Empirical acceptance remains open, not an implementation finding.** The supplied full-v2 run was 19/20 semantic, with a confirmed winner-management miss; it predates this current-winner input change. It cannot establish v3 quality. The final 22-case matrix remains pending. Reported deterministic suite passes do not close that gate.
