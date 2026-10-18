# Ticket 39: continuing execution implemented; basic model quality fails

Scope is Issue #39 under #36, based on integration b6cec24, including the approved spec preparation. This is an engineering checkpoint with preserved failed developmental evidence. It is not stage acceptance, final-matrix evidence, or permission to treat failed quality as passed.

## Public behavior and wire change

`ExpertSession.decide` binds one board/controller and continuing transport. Each accepted request has a fresh `DecisionSession` UUID bound to the immutable snapshot ID. Repeated/stale snapshots, overlapping requests, another board/controller, changed public history/objective and reused turn identities fail. Transport/decoding failures terminate the session; `BoardDriver` also stops after an illegal current action. No answer retry, semantic repair, alternate current card or second in-play LLM exists.

After the initial authorized position, each client turn sends actual events since the preceding request, whether the previous recommendation actually executed, current actor/current trick, and trick totals. Program-owned execution labels distinguish model, opponent and forced mechanics. A different actual legal card is reported as different, never converted into the suggestion. Each declarer and dummy choice goes through the same entry. The initial decision is requested even with sole-legal mechanics enabled; later permitted sole-legal actions are separately labeled. The driver retains complete authoritative state for Engine execution without supplying hidden holdings to Expert.

`PlanAssociation` owns board, controller, source snapshot and source DecisionSession metadata. Keep retains the original association, replacement installs the current source, and withdrawal clears effective state. Prior plans and reasons stay in conversation history rather than being copied into subsequent user input.

The versioned wire contract is `stage1-plan-publicReason-selectedCard-v2`. Its single wire action `selectedCard` maps to internal `currentCard`; no duplicate executable field exists. Deterministic JSON key sorting now produces plan → publicReason → selectedCard. This is a bounded ordering correction motivated by the actual v1 ordering and the restored continuity discussion; it is not evidence that ordering caused or repaired the bridge mistakes. All v1 failures remain in ticket37 evidence, and this candidate was tested afresh. The unchanged single English paragraph remains minimal and contains no reference answer, winner count, club route or grading rubric.

`BoardDriver.advance` is the public App-independent one-action execution boundary used by `bridge-play`. `--decisions N` runs bounded short sequences, `--opponent conserve-high` supplies legal state-aware environment play, and optional `initialEvents` supports reachable mid-board starts. Complete-board budgets and specialized Pavlicek defense remain ticket40 work. No archived implementation was restored.

## Predeclared actual attempts

Three separate developmental boards were launched once, concurrently across boards, with strictly sequential requests within each board. Timings include request/runtime startup and driver overhead from driver construction, and reflect concurrent resource conditions; they are not sequential final-acceptance board durations. All three used the same pinned synthetic deal, gpt-6-luna / medium, codex-cli 0.160.0, no mechanical controlled substitutions and a 180-second per-request bound. The reserved acceptance board was untouched. See run-configuration.json, synthetic-fixture.json and predeclared-cases.json.

| Run | Declared model-request bound | Actual requests / legal controlled actions | Driver elapsed | Result and coverage |
| --- | --- | --- | --- | --- |
| short2 normal continuation | 8 | 8 / 8 | 37.083 s | All cards legal; quality fails. At least three real continuation decisions occurred. Initial plan invents a conditional dummy ace despite the visible holding; later prose claims DA establishes diamonds and treats D8 as an entry despite outstanding higher diamonds. |
| short3 new public information | 12 | 12 / 11 | 52.741 s | Both defenders actually followed two club rounds, establishing 3–2; the third West club appeared before East's later discard. Quality fails from the initial retained plan, and request12 selected C8 from club-void North. Engine rejected it and stopped. |
| short4 entries/consumed cards | 16 | 1 / 0 | 10.016 s | Initial DA for North was illegal and claimed a dummy ace. Stopped immediately; intended entry/consumed-card trigger remains uncovered. |

The short runs were graded only after their bounded play ended or Engine rejected the action. Therefore legal bad prose executed according to runtime semantics before its semantic defect was established by the independent grader. This is not an acceptance board allowed to continue after an established serious finding. No reroll-to-pass or human/script replacement occurred.

The first short3 plan says to win the lead in dummy with DA, while its legal selected card is D6. Keeping that plan carries the factual defect forward; later legal execution cannot erase it. Other concrete failures include suggesting an East club higher than CQ although CA/CK are visibly South's, calling a low club a cashing winner, and saying a played C2 is preserved. These are basic factual/consistency failures, independent of whether the contract might eventually make.

## Independent grading and review

The calibrated stage1-basic-v2 Sol Medium grader read the exact authorized requests, actual raw outputs, visible decision snapshots, deterministic checks, actual effective plans and predeclared case rules. No full defender deal, expected answer label or future events entered a grader package. It ran independently after play; none of its feedback entered a playing thread.

Original grader outputs and original evaluations are preserved in short*-grade. A localized citation-validator defect rejected exact excerpts of the actual retained effective plan on keep turns because only current raw output was accepted. A failing Python public-seam test reproduces this, and the fix accepts exact effective-plan excerpts while rejecting unobserved text. Offline regrade of the same saved grader output appears in short*-offline-reviewed; no new model call occurred. This is parser compatibility, not a changed rubric or substituted grade.

After that correction, short2 has six pass/two fail decisions, short3 twelve fail decisions, and short4 one fail. All remaining mechanical checks pass except the two explicitly rejected illegal decisions. The retained-plan findings were manually checked against the actual first outputs and source snapshots. The broad phrase about dummy's "spade stoppers" is not the sole basis for any board failure; the impossible dummy diamond ace and directly illegal cards independently establish failure. No disputed strategic alternative is counted as a pass.

## Effective context audit and diagnosis boundary

wire-audit-summary.json verifies all 21 actual Responses payloads: exact accumulated user inputs and prior public assistant outputs, one thread per board, unique turn and DecisionSession IDs, and plan/publicReason/selectedCard schema order. Subsequent client messages are only actual deltas plus current position; Codex retains the earlier user/assistant messages in its own effective conversation history. That history includes the initial authorized hands exactly once, plus actual prior plans rather than hand-authored ideal plans. Hidden defender holdings, case rubric, grader feedback and unplayed future events are absent from actual user history. All play inputs and public plans/reasons are English.

The catalog-selected runtime still injects the same built-in additional_tools and v2 collaboration role/mode recorded in ticket37. There is no shell/file-reading, MCP, Engine analysis or Knowledge retrieval surface, and no tool invocation occurred. This is a known effective-context limitation, not a newly empty tool-surface claim. The model/effort request and runtime/upstream model names are observable; they do not prove internal service identity. Response metadata again reports zero reasoning tokens; no causal explanation is inferred.

Actual context establishes that the relevant visible ownership was supplied initially and prior actions were retained exactly. The v2 ordering change alone did not fix basic ownership, ranking, entries or retained-plan errors. This evidence does not isolate whether residual runtime context, model behavior or another service characteristic caused those errors. No stronger prompt, repeated complete hands, strategic bans, extra model or alternate model was introduced to chase a pass.

## Validation and impact

TDD logs cover the versioned public advice contract, real-event continuity/plan source, public one-action driver and Python wire compatibility/retained-plan citations. Public regressions also cover replacement/withdrawal, execution differing from advice, overlap/stale/cross-board rejection, terminal illegal failure, changed-objective rejection and nonadjacent turn-ID reuse. The root independent review identified the latter guard gap; a red public-seam test preceded the all-used-turn-ID fix.

The full Swift suite before the last two defensive guards passed 211 tests with 10 pre-existing DDS/runtime skips and zero failures; focused final public playing tests cover the added guards. Those guards affect only invalid-context/reused-turn requests and do not change any of the 21 recorded valid live inputs or model output contracts. Python tests retain v1 evidence readability and validate v2 plus retained-plan citations. Build and diff checks pass. Skips are not quality acceptance.

Engineering behavior is implemented and reviewable. The three required capability areas were attempted honestly, but the entries case remains uncovered and basic model quality fails. Stage completion, six-case/complete-board final evaluation, and broad bridge strength are not established.
