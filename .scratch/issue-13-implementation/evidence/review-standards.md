# Standards review — PR #22

Reviewed the pinned range `3676ca66c56d6b1d3462b0d6ef4f41970e2c7878..9fa410a03be0ee5811906f35704bd4df5f9c7e60`. HEAD was verified. Sources: parent `AGENTS.md`, `CONTEXT.md`, `README.md`, `APP-README.md`, and supplied global working agreements. These sources define ownership, preservation and domain boundaries, but no additional coding/style rules.

## Documented standard violations

None found. The changes stay within the standalone Bridge Coup repository, preserve legacy DDS materials on conflicting archive migration, and introduce no broad rename or folder restructuring. No violation was inferred from the heuristic smell baseline. `git diff --check` passes. No tests or build were run for this read-only review.

## Possible maintainability smells — judgments, not violations

- **Duplicated Code / Data Clump**, `Sources/BridgeTeacherMac/BridgeTeacherApplicationModel.swift:495–498` and `619–624`: restoration rejects a session using `playSession.originalBoardID != originalHandFacts.boardID || playSession.originalVersion != originalHandFacts.version ...`, while history replacement repeats the same five-field comparison with equality. These paths currently agree, but adding another dependency requires updating both. A single `isCompatible(with:original:context:)` predicate would make restoration and undo/redo share the board/contract validity boundary. This is an optional refactor, not a demonstrated correctness failure.

- **Divergent Change**, `Sources/BridgeTeacherMac/BridgeTeacherApplicationModel.swift:472–512`, `516–647`, and `683–690`: the application coordinator now owns archive migration (`hasLegacyDoubleDummyConflict = ...`), full play history (`playUndoStack.append(position)`), and source/DDS synchronization (`resetDoubleDummyToOriginal(context: draft)`) alongside runtime/login/preferences. A bounded play-workspace controller could own session/history/reset transitions and expose one position-change signal; keep migration at the archive boundary. The file was already an application coordinator, so this is a growing maintenance pressure rather than grounds to reject the PR.

Other changed hunks yielded no actionable baseline smell worth reporting. Correctness/spec acceptance remains the separate Spec review axis.

## Follow-up at `2824db804ed226774a5e3a1cd84b7114b3e21935`

Reviewed the bounded fix diff from `9fa410a`; verified aggregate HEAD and passing `git diff --check`.

- **Duplicated compatibility guard: resolved.** `BridgePlaySession.swift:92–101` owns the predicate; `BridgeTeacherApplicationModel.swift:503` and `625` both call it. Opening-lead and confirmation dependencies are covered in that shared boundary.
- **Coordinator decomposition: accepted deferral.** The disposition retains the specified application coordination boundary and common position revision. The original observation was optional maintenance advice, with no demonstrated defect or documented rule requiring extraction; no follow-up action is needed for this PR.

No residual documented standards violations or new actionable baseline smells found in the bounded fixes. Native/spec acceptance remains separate. No tests/build or repository edits performed.
