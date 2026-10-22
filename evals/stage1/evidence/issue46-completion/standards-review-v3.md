# Standards Review — Current Winner v3

Base: `4fd65bfae21263e0ab3d38a5ea1b9a2dd6a5ed4f`  
Target: `4b92a0961052c05d71728fa42dd703a68fcde53e` (`codex/issue46-current-winner`)

## Findings

No new documented-standard violation, concrete defect, or actionable smell found in the four active source/test changes. The remaining diff is preserved evaluation evidence and review documentation.

- `Sources/BridgeExpert/Expert.swift` serializes the existing `DecisionSnapshot.currentWinningPlay` as `current.winningPlay` using the same seat/card representation as current plays, and emits JSON null when Engine supplies no current play. `BoardState.snapshot` already derives the field from the actual current trick; no new winner calculation or policy was added.
- The instruction field reference defines the value and its null case, while step 3 asks the model to consider its effect on the trick and plan. It does not prescribe a card ranking or forced low-card rule.
- `SnapshotInputTests` covers an opening lead, an empty trick on lead, and a partner currently winning. The runtime isolation assertion checks the serialized field at the installed-runtime boundary.

The v1 `acceptance.py` module-boundary suggestion remains deferred and unchanged. The parent reports 32 Swift and 53 Python tests passing; I performed static review only. No tests, live calls, GitHub actions, or repository edits were made.
