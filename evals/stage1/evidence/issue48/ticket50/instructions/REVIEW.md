# Independent writing-for-agents review: ticket 50 instructions

Result: CLEAR. No actionable instruction defect found in the reviewed diff. This is a narrow review of instruction semantics, not code review or quality acceptance.

Reviewed working tree: `/Users/tingranwang/.codex/worktrees/issue50-review-loop/bridge-coup`, based on `d4b4f86bae786ab8ec4d49b0c2f22f03cd549c97`. Diff scope: only `Sources/BridgeExpert/Resources/DeclarerInstructions.txt` and `Sources/BridgeExpert/Resources/ReviewerInstructions.txt` against that commit. Applied `/Users/tingranwang/.agents/skills/writing-for-agents/SKILL.md`; checked #48's pending-decision, plan-continuity and instruction requirements, #50, and the retained #46 snapshot semantics.

Reviewed instruction hashes:

- Declarer: `7216835b26ad7b9aa8c00fb9870d1c7a95837953059927623c1d6800efbebf90`.
- Reviewer: `6abfef19977a81a426a48afe12430e7bcc9f7170faef43a298d8313b6dbc9b37`.

Every changed block was checked:

1. Declarer lines 98–99 extend the input reference to the new envelope branch while identifying `latestSnapshot` as the position. The existing fact-view/history rules immediately follow, keeping fact authority co-located.
2. Lines 110–118 name revision versus clarification envelopes, preserve the unchanged snapshot and prior active plan, identify structured/raw candidate and reviewer feedback, keep pending advice uncommitted, and require a complete replacement proposal in the existing output format. Clarification positively directs the player to public facts and retains unknown holdings as unknown. Reviewer statements therefore do not acquire board-fact authority.
3. Lines 119–120 explicitly retain the initial-plan requirement through `latestSnapshot.type`, resolving the new envelope's outer `revision`/`clarification` type without weakening the initial replacement rule.
4. Lines 122–124 define active-plan status as working advice after authorized execution, explicitly permitting unresolved objections without claiming approval. This is the required distinction between execution authorization and actual review verdict, not an instruction to overwrite a verdict.
5. Reviewer lines 72–74 replace the obsolete “previously approved active plan” definition with the same execution-based meaning. Its neighboring proposed-plan definition still derives keep/replace/withdraw from that active text, preserving one factual authority for the current plan and a distinct candidate result.

The added material belongs together in INPUT REFERENCE because it describes a newly supported input branch. It does not add a second decision process, competing strategic objective, answer hints or evaluation knowledge. The confirmed objective, planning guidance, output fields/schema descriptions, initial replacement and keep/replace/withdraw semantics remain unchanged in the diff. The existing reviewer verdict criteria and output contract also remain unchanged.

No repository edit, model request, GitHub write, acceptance judgment or merge authorization was performed.
