# Bounded quality correction v2

Branch: `codex/issue46-quality-v2`
Worktree: `/tmp/bridge46-quality-v2`
Implementation commit: `b1aedba`
Tip after merging integration2bb6872: `4fd65bfae21263e0ab3d38a5ea1b9a2dd6a5ed4f`

## Actual request diagnosis

Before editing, I compared the last user message in actual captured HTTP requests with the corresponding DecisionRecord.input for full-v1 decisions1 and8 and short-v1 decision7. They are byte-for-byte text-equal; the structured snapshot was not lost or altered by transport. Source paths and request SHA256 values are recorded in `quality-v2-wire-diagnosis.json`.

- Full-v1 initial: South clubsAK864, NorthQ72; no defender can beat CQ. The model nevertheless plans a potentially losing finesse to CQ.
- Full-v1 decision8: actual input South clubs86 and current completed history includes CA already played. Output invents CA86 and overlooks the publicly established remaining clubs.
- Short-v1 decision7: with three tricks won, the replacement names HA/HK/DK/CK/SA (five further tricks) and omits the remaining-club continuation. Cashing CK captures the sole unseen CJ, establishing C86; that is the missing concrete source, not hidden-hand information.

These are observed model-output failures under a correct snapshot, not a demonstrated schema or payload-assembly defect. Refining instructions is a prospective correction; offline tests cannot establish better model quality. All original attempts remain unchanged.

## Instruction change

Only DECISION PROCESS step2 changes, adding39 words (681→720 total). It strengthens completion criteria for the unfinished line: remaining cards/entries, possible higher-card holdings, won tricks plus future sources and material conditions before keep/replace. Completed plan steps remain historical and may stay verbatim. No fixture card, answer, word ban, prescribed route or new output is added. The approved OBJECTIVE sentence, notation, field reference, output protocol/examples, schema, runtime configuration and history policy are unchanged.

commit b1aedbaba4b22f892e7a405a24233c5de3195850
Author: absurdwall <tw2579@columbia.edu>
Date:   Thu Oct 22 05:19:15 2026 -0400

    Ground unfinished plans in current cards and retain interrupted turn evidence

diff --git a/Sources/BridgeExpert/Resources/DeclarerInstructions.txt b/Sources/BridgeExpert/Resources/DeclarerInstructions.txt
index a62e317..4af31c2 100644
--- a/Sources/BridgeExpert/Resources/DeclarerInstructions.txt
+++ b/Sources/BridgeExpert/Resources/DeclarerInstructions.txt
@@ -13,10 +13,14 @@ DECISION PROCESS
    in the remaining hands; repeated history describes the same events.
 
 2. Form or reassess the playing plan using the latest position and
-   the earlier discussion. Represent the result in the output JSON's
-   "plan" object as defined in OUTPUT FORMAT. Interpret plan steps already
-   recorded in play history as completed. Plans and predictions remain advice;
-   actual plays establish what happened.
+   the earlier discussion. Check its unfinished line against the remaining
+   cards and entries, treating recorded steps as completed. Compare proposed
+   trick winners with known higher cards and higher cards defenders could
+   still hold. Reconcile tricks already won with the line's remaining trick
+   sources and material conditions before keeping or replacing the plan.
+   Represent the result in the output JSON's "plan" object as defined in
+   OUTPUT FORMAT. Plans and predictions remain advice; actual plays
+   establish what happened.
 
 3. Choose selectedCard from the response schema's legal-card enum for
    current.toAct. Give a brief publicReason explaining the current choice

## Interrupted saved-evidence reader

The public reader now uses an existing parent rpc.jsonl regardless of whether a final trace exists. The new public read_decision→grader_package regression reproduces the actual interrupted directory layout, certifies its matching turn and rejects an unrelated thread. It failed before the one-line reader fix. No final trace is synthesized and no interrupted-session recovery is added. Reading all eight actual stopped decisions now gives request_evidence/output_evidence=pass; the separately stored audit contains these results. Their semantic failures remain unchanged.

## Offline checks

- Red: `/tmp/bridge46-quality-reader-red.log` (missing request_evidence because the shared RPC was skipped).
- Green: `/tmp/bridge46-quality-reader-green2.log` (matching and wrong-thread cases).
- Swift playing tests:31 pass (`/tmp/bridge46-quality-playing-tests.log`).
- Full Python suite:53 pass (`/tmp/bridge46-quality-python-tests.log`).
- `git diff --check` passed. Integration merge is documentation/evidence-only; it changes no tested source. Working tree clean.

No live playing/grading call, GitHub write or integration merge-back was performed.

## Impact and next validation

The instruction change affects every playing request, so prior development samples cannot establish quality for this candidate. Run fresh affected continuous/full-board scenarios, retain every outcome, then run the complete specified22-attempt matrix for the frozen final candidate. Do not combine prior passes across candidates. The reader fix changes mechanical evidence association for interrupted layouts only; the grader model, rubric, schema and authored calibration semantics are unchanged.
