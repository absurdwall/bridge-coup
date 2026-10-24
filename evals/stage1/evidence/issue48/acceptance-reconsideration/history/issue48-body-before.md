## Problem Statement

Stage 1 has inspectable structured board inputs and improved player instructions, but direct play still produced basic planning and card-choice errors. The user and agent jointly inspected actual requests and developed an independent play-review loop. A recorded correction passed after one revision, but that experiment does not establish production integration or complete-board acceptance. The runtime, execution boundary, recovery and acceptance runner must now implement the agreed system together.

## Solution

Continue on the current integration branch with a Sol Medium player and an independent Sol Medium reviewer. Review each model-controlled proposal before play proceeds, return feedback to the board's continuing player session, and bound both semantic review and technical retries. After five valid review rounds, allow an otherwise valid legal proposal to proceed as contested play. Preserve the actual review verdict and judge delivered play by the existing quality criteria.

## User Stories

1. As a player, I want the confirmed planning instructions retained as the starting point, so that implementation preserves the design we inspected together.
2. As a player, I want both roles to use gpt-6.1-sol with medium effort, so that runs use the agreed configuration.
3. As a player, I want one player conversation per board/controller, so that plans and discussion continue across decisions and revisions.
4. As a player, I want the reviewer to assess the whole partnership, complete route and current card, so that an initially legal answer can still receive useful correction.
5. As a player, I want rejected proposals returned with their actual findings, so that the player can improve its plan before execution.
6. As a player, I want uncertainty clarified from authorized public facts, so that missing judgment is distinguished from a program failure.
7. As a player, I want at most five semantic review rounds per pending decision, so that disagreement cannot loop indefinitely.
8. As a player, I want a valid legal proposal released with its plan after review exhaustion, so that the board can continue while disputes remain visible.
9. As a player, I want technical retries to have a separate budget, so that network failures do not consume semantic review rounds.
10. As a player, I want exhausted technical recovery to stop the run with evidence, so that a missing reviewer result is not silently treated as approval.
11. As a maintainer, I want approval and execution bound to the exact proposal and position, so that stale feedback cannot authorize another card or plan.
12. As a maintainer, I want complete readable requests, raw outputs, all revisions and timings retained, so that failures can be diagnosed without asking the user to inspect every step.
13. As a maintainer, I want the existing public Expert/BoardDriver entry to exercise the complete pipeline, so that evaluation measures the implementation that actually plays.
14. As an evaluator, I want the original bounded Stage 1 matrix and quality standards retained, so that adding review does not lower the bar for delivered play.
15. As an evaluator, I want repaired drafts, contested execution, legality, contract result and delivered quality distinguished, so that neither rejection nor approval substitutes for actual quality.
16. As the project owner, I want implementation and evidence-based instruction repairs delegated, with writing-for-agents review and versioned validation, so that routine engineering can proceed without another interactive walkthrough.

## Implementation Decisions

### Authority and baseline

This is an amendment to #36 and #46, affecting #37-#42. It changes only the clauses listed below; the remaining Stage 1 scope and quality obligations remain in force.

| Earlier constraint | Replacement |
| --- | --- |
| Luna Medium as the playing model | Player and runtime reviewer both request and verify gpt-6.1-sol / medium. Keep the independent acceptance grader separate. |
| Additional in-play reasoners and automatic answer repair excluded | This explicitly specified reviewer/feedback loop is now in scope. Hidden answers, arbitrary answer substitution and rerolling for a favorable result remain excluded. |
| Apply every structurally valid player's plan/card immediately | Keep a pending proposal until reviewer approval or the explicit contested-execution policy authorizes that exact proposal. |
| No answer repair during acceptance | Bounded in-product revisions are normal product behavior. Grade delivered advice/play; preserve rejected drafts and their costs as diagnostic evidence. |
| Joint one-step walkthrough before continuing | Joint exploration is complete. Autonomous implementation and the bounded validation sequence below are authorized. |
| Original snapshot-amendment branch baseline | Continue from codex/issue48-reviewed-declarer at c74d69781498f5a69ea0be9e0dc26612d5c96e6d, which preserves codex/issue46-completion and its approved working changes. Do not reset to main or restore an earlier prompt version. |

The existing Domain/Engine responsibilities and information boundaries remain. Do not move state solely to rename ownership. No UI integration is required. Retain useful older tickets and their evidence; an obsolete obligation may be explicitly superseded, never closed as implemented merely because a replacement exists.

### Pending decisions and plan continuity

- Preserve complete authorized initial/update snapshots, actual history, current legal-card enum, scoring/doubling, current winner and explicit effective-plan carry-forward from #46 and its winningPlay clarification.
- A pending decision freezes the actual public position, controller, prior active plan and proposal association. Player revisions and reviewer retries do not advance the board or commit a new plan.
- The candidate contains the existing plan operation, selectedCard and publicReason. Reviewer input supplies the authorized latestSnapshot, legalCurrentCards, candidate and proposedEffectivePlan. The latter is a derived result of keep/replace/withdraw, not an independently authored plan.
- Keep the same player session for the board and all its revisions. Use independent reviewer sessions as in the inspected experiments. Neither role receives hidden defender hands, grading answers, strategic Engine tools or Knowledge injection.
- An approval authorizes exactly the reviewed candidate. Validate output contracts, actual model/effort identities, current legality and position/proposal association before commitment. Reject stale replies; never execute a rejected intermediate proposal or execute the final choice twice.
- On revise, send the exact findings, unchanged latest snapshot and relevant proposal back to the same player session. Receive a replacement public answer and review it again. Earlier speculative plans and reviewer assertions do not become board facts.
- The active plan is the currently accepted working plan, not necessarily reviewer-approved. On either normal or contested execution, apply that final candidate's keep/replace/withdraw operation exactly once and carry its text verbatim to the next snapshot. Record whether acceptance came from review approval or contested execution; update instruction wording consistently with this distinction.

### Review, clarification and execution policy

- There are at most five valid semantic review rounds per pending decision, including the first. approve/revise/uncertain each consumes one round; the counter persists across clarification and does not reset within the same pending decision.
- Approve commits the exact candidate and executes its card after program validation.
- For uncertain, first check the authoritative public state, reconstruct omitted serialization where possible, and return the concrete question to the player for clarification before another review. Unknown defender holdings remain unknown. If program validation establishes that genuinely missing facts prevent constructing or validating the authorized position/candidate, return needs-input; this takes precedence over contested release. A reviewer claiming uncertainty does not itself invalidate a complete authorized position: ordinary strategic uncertainty or unseen defender holdings can continue through the five-round policy. Never invent data or disguise a semantic verdict as a runtime exception.
- At the fifth valid review round, if there is still no approval but the latest candidate is structurally valid, current and legal, release that candidate as contested play, apply its plan operation and continue. Preserve the actual reviewer verdict/findings and execution disposition. Legality permits release; it does not prove quality.
- If the position or candidate cannot be validated, do not force execution or silently choose another card. Report the appropriate input, contract, identity or state failure with evidence.
- The existing mechanically sole-legal path can continue to skip model calls after an initial plan, provided its actual play is recorded in the next snapshot. Every genuine model-controlled decision uses the reviewed pipeline.

### Technical recovery and budgets

- Technical failures have an independent budget: after an initial reviewer request fails, allow at most three retries, for at most four technical attempts for that review round. They do not consume the five semantic rounds. Never retry a valid revise/uncertain as if it were a network failure to shop for approval.
- Reviewer retries concern the same candidate and frozen position. Preserve every attempt; ignore late/superseded responses. After all technical attempts fail, stop that board/run with an explicit runtime/protocol failure and evidence; do not use the contested-execution rule as a technical-outage fallback.
- Preserve the one-player-session invariant. A player failure that loses its session or cannot produce a valid proposal is reported as a failed/incomplete run, not silently continued in a fresh conversation.
- Retain a 180-second per-native-request timeout and a 30-minute automatic-runtime protection budget per board. Count player, reviewer, retry and processing time. Explicit human needs-input waiting is recorded separately from automatic runtime. Budget expiry stops automatic work without executing a stale/pending card. These are protection limits, not target response times or a three-minute speed requirement.
- Keep genuine needs-input handling distinct from execution after five unresolved reviews. In-process pending-state retention is in scope; general process-restart recovery and interrupted-board reconstruction remain outside Stage 1.

### Instructions and evidence

- Begin from the jointly approved player and calibrated reviewer instructions. Necessary engineering or evidence-based instruction changes are authorized; apply writing-for-agents review and keep a versioned diff, hashes and affected validation. Do not silently alter model/effort, quality standards or scope.
- Explain feedback envelopes and active versus review-approved plans where required. Preserve the agreed output fields and initial/keep/replace/withdraw semantics.
- Keep Unicode readable in the actual model-facing JSON as well as displayed artifacts. Preserve JSON semantics, necessary control-character escaping and literal backslashes; do not rewrite historical requests or model outputs.
- Record every candidate, feedback envelope, raw role response, runtime/thread/turn identity, semantic round, technical attempt, review verdict, execution disposition, plan association, model configuration, elapsed time and token usage. Credentials stay excluded.
- Promote the useful temporary experiments and fixed cases into durable fixtures/regressions with provenance. Clearly label synthetic replay versus a natural continuing player session. Do not present saved temporary state as proof that a process is still alive.

## Testing Decisions

- Prefer the existing highest public Expert/BoardDriver seam, real state reducer, snapshot builder, parser and execution path. Do not introduce a parallel test-only player or manually replace model cards.
- Offline scripted transports cover approval; revise-then-approve; clarification; five semantic reviews followed by exactly one contested execution and matching plan adoption; three technical retries independent of semantic rounds; technical exhaustion without execution; bad contracts/identities; stale/late approval; single-session continuity; forced actions; readable Unicode; timeout and needs-input boundaries. Assert externally visible state, outputs and evidence.
- Verify the actual native requests and responses for both Sol Medium roles, empty tool surface, exact instructions/schema, same-player continuity and exact feedback binding. A successful synthetic correction replay is supporting evidence, not full-board delivery.
- Freeze both instruction sources, both role configurations, runtime/capture code, corpus and rubrics before candidate acceptance. Grade only actual delivered advice/play through an independent acceptance grader; its feedback is not passed into live play. Reviewer records remain diagnostic, not a substitute for independent grading.
- Preserve the existing matrix: six short scenarios run three times each and two complete notrump boards run twice each, for 18 short plus four complete-board attempts. Keep the original serious-error criteria, material coverage and separate reporting of legality, contract outcome and quality. Repaired drafts do not themselves fail a run; final serious errors, incomplete attempts and unresolved grading do not become accepted passes.
- Save all failures and disputes. Use known failures for targeted regression, not evidence of broad skill. Each frozen candidate runs the prescribed repetitions; never add ad-hoc rerolls to replace failures or stitch passes across versions.
- Report full-board and first/later-decision elapsed distributions, combined role/revision/retry costs and token usage. No new speed gate is introduced.

## Out of Scope

Mac UI, screenshots, bidding, LLM defender advice, trump-contract LLM quality acceptance, strategic Engine analysis/DDS/sampling/ranking, Knowledge integration, general self-play, controller switching, undo, process-restart recovery, model/effort escalation, world-class or optimal-play guarantees, and reducing the existing acceptance standard. Correct deterministic trump rules remain in scope under #36.

## Further Notes

The user confirmed these decisions in the October 23 joint design discussion, including contested execution with matching plan carry-forward and three independent technical retries followed by stop. The latest correction experiment used a constructed fixed proposal and real feedback in a fresh Sol Medium correction session; one revision then passed, with no card executed. This is not an accepted Stage 1 result.

Implementation handoff baseline: codex/issue48-reviewed-declarer at c74d69781498f5a69ea0be9e0dc26612d5c96e6d. This commit preserves codex/issue46-completion at b19df84924b756707600a5aecc14d84cbead27fe plus the four approved instruction/domain-document changes; it does not integrate the reviewer runtime. Initial player instructions hash: 8370e86f5aa68185bcee5cae99b18d3815efb0bbad341c666811f5af455eff4b. Initial calibrated reviewer hash: 99c46d34fcf6e5b9d2c82194562ebbbb1ae8be437409b9718b6c68aa29f933e2. Preserve these starting versions when making authorized changes.

Implementation may proceed through the associated tickets. Use at most three substantive frozen-candidate validation cycles before returning persistent failures and their diagnosis to the user. This is a development working budget, not permission to weaken acceptance. PR #45 and #47 remain unmerged until explicitly approved; publishing or completing this amendment alone does not authorize merge or Stage 1 closure.

## Implementation tickets

- [ ] #49 — Run one Sol Medium declarer decision through independent review
- [ ] #50 — Complete one pending decision through review, revision and contested execution
- [ ] #51 — Bound technical recovery and preserve reviewed play outcomes
- [ ] #52 — Validate the reviewed pipeline with the unchanged Stage 1 quality matrix
