# Current winning play snapshot clarification

Branch: `codex/issue46-current-winner`
Worktree: `/tmp/bridge46-current-winner`
Implementation commit: `98afd4a`
Tip after merging integration11ae4db: `4b92a0961052c05d71728fa42dd703a68fcde53e`

The rationale is tracked in [issue46](https://github.com/absurdwall/bridge-coup/issues/46#issuecomment-6337462204). No GitHub operation was performed by this implementer.

## Actual request diagnosis

Before editing, I inspected full-v2 decision9 and actual HTTP request8. The last user message equals DecisionRecord.input exactly. It correctly contains North HK and East H8 in currentTrick, with South heartsA63. The recorded Domain snapshot already contains currentWinningPlay=North HK; Expert had not serialized that fact. The model chose HA with the reason to cover East H8, incorrectly treating East as ahead. `current-winner-wire-diagnosis.json` preserves source paths, request SHA256, exact public facts and raw output. No tool, grading or hidden-card information was added.

## Change

Expert now maps the existing authoritative currentWinningPlay to current.winningPlay with exactly seat/card, or null when Engine supplies no current play on lead. It performs no winner calculation, candidate ranking or strategic analysis. Both initial and update share this serialization.

INPUT REFERENCE defines the fact as the highest actual play under bridge rules, with later plays able to change it. Decision step3 identifies the current winning partnership and checks the selected card's effect on this trick and the unfinished plan before publicReason. It prescribes no low-card rule: an overtake for an entry or other valid continuation remains available. Instructions grow from720 to762 words. Objective, output schema/format/examples, legal enum, other snapshot fields, Medium configuration, same-thread/history and no-tools policy are unchanged.

commit 98afd4a6e606162f9f171596415ff26d40713a1b
Author: absurdwall <tw2579@columbia.edu>
Date:   Thu Oct 22 05:32:55 2026 -0400

    Expose the current public trick winner to Expert decisions

diff --git a/Sources/BridgeExpert/Expert.swift b/Sources/BridgeExpert/Expert.swift
index 4e88b6e..2d317c6 100644
--- a/Sources/BridgeExpert/Expert.swift
+++ b/Sources/BridgeExpert/Expert.swift
@@ -198,6 +198,7 @@ public actor ExpertSession {
             "completedTricks": completed.map { ["plays": $0.plays.map(play), "winner": seat($0.winner)] as [String: Any] },
             "currentTrick": snapshot.currentTrick.map(play),
             "current": ["toAct": seat(snapshot.actingSeat),
+                        "winningPlay": snapshot.currentWinningPlay.map(play) as Any? ?? NSNull(),
                         "tricksWon": ["declarer": snapshot.declarerTricks, "defenders": snapshot.defenderTricks]],
             "effectivePlan": planAssociation?.text as Any? ?? NSNull()
         ]
diff --git a/Sources/BridgeExpert/Resources/DeclarerInstructions.txt b/Sources/BridgeExpert/Resources/DeclarerInstructions.txt
index 4af31c2..be05237 100644
--- a/Sources/BridgeExpert/Resources/DeclarerInstructions.txt
+++ b/Sources/BridgeExpert/Resources/DeclarerInstructions.txt
@@ -22,9 +22,11 @@ DECISION PROCESS
    OUTPUT FORMAT. Plans and predictions remain advice; actual plays
    establish what happened.
 
-3. Choose selectedCard from the response schema's legal-card enum for
-   current.toAct. Give a brief publicReason explaining the current choice
-   in the context of the playing plan and the actual position.
+3. Read current.winningPlay to identify the current winner and partnership,
+   or that the trick is on lead. Choose selectedCard from the response
+   schema's legal-card enum for current.toAct. Check its effect on this
+   trick and the unfinished plan, then explain the choice briefly in
+   publicReason.
 
 OUTPUT FORMAT
 
@@ -89,7 +91,9 @@ Fields:
 - "completedTricks": completed tricks in chronological order. Each contains
   "plays" in actual play order and "winner". Each play has "seat" and "card".
 - "currentTrick": the actual plays in the unfinished trick, in play order.
-- "current": "toAct" and "tricksWon" ("declarer" and "defenders").
+- "current": "toAct", "tricksWon" ("declarer" and "defenders"), and "winningPlay".
+  "winningPlay" is the highest actual play in the current trick under bridge
+  rules, with "seat" and "card", or null before the lead. Later plays may change it.
 - "effectivePlan": the exact active plan carried into this decision,
   or null when no active plan exists.
 

## TDD and offline checks

- Confirmed red: `/tmp/bridge46-winner-red-confirmed.log`, three failures from missing winningPlay (opening lead, null on lead, partner ahead). An initial draft test was corrected for its bridge play ordering before this confirmed product regression.
- Green: `/tmp/bridge46-winner-green.log`. The public BoardDriver test advances one legal board through six Expert requests. It sees West DQ on the initial lead, null when South later leads, then North HK still ahead after East follows H2 before South acts; no current-card strategy is programmatically imposed.
- Swift playing suite:32 pass, zero failures (`/tmp/bridge46-winner-playing-tests.log`).
- Full Python suite:53 pass, zero failures (`/tmp/bridge46-winner-python-tests.log`), including actual installed-runtime offline HTTP snapshot visibility, current.winningPlay and empty tools assertions.
- `git diff --check` passes. Working tree clean. Integration merge adds only preserved evidence/docs, with no source changes to invalidate these offline checks.

No playing or grading model was called. Existing failed samples remain unchanged; new model-quality evidence is still required for this candidate.
