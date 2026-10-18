# Bridge Coup 2.0 — model-led Bridge Expert and product acceptance

Triage: ready-for-agent

Current authority: this local spec during the temporary local fallback. Origin: [GitHub #33](https://github.com/absurdwall/bridge-coup/issues/33). Migration date: 2026-10-04. Product scope and approved test seams are unchanged; implementation and release acceptance remain pending.

[Tracker and tickets](README.md) · [Execution agreement](execution.md) · [Document map](../../docs/bridge-2/README.md)

## Problem Statement

Bridge Coup already supports screenshot-assisted review, declarer teaching and follow-ups, manual auctions, a full-hand play workspace, saved reviews, and real DDS verification. These are useful foundations, but they do not yet form one reusable expert that handles bidding, declarer play, defense, and continuous advice from an authoritative decision-time perspective.

A player needs recommendations that remain coherent as the board develops, respect partnership agreements, distinguish missing input from hidden cards, and make their evidence limits visible. A technically successful model call or DDS calculation does not establish that the advice is useful or that its information was authorized.

Bridge Coup 2.0 must deliver that usable product while preserving existing workflows. It must demonstrate basic bridge quality on real material and no obvious severe regression; it need not demonstrate statistically significant strength gains over the old teacher or broad expert-level playing strength.

## Solution

Build one in-App Bridge Expert for bidding, declarer play, defense, continuous advice, teaching, evidence, and postmortem. Codex owns strategic judgment and chooses its own computation and resource inquiries. Program-owned boundaries provide authoritative state, visibility, legal actions, immutable sessions/resources, computation semantics, evidence, and execution safeguards.

The core continuous-play experience follows one selected **decision controller** through a board. Other seats' actions may be supplied manually or as external board facts. Completing an entire board this way is valid acceptance. A dedicated blind-practice UI and automatic control of all four seats are not release requirements; the existing full-hand teaching workspace remains available. Its displayed information does not automatically become information authorized for a blind Expert request.

Ad-hoc mid-board help is also supported. It can provide useful qualitative or conditional advice from incomplete material. Calculations whose required inputs are undefined must not run, and missing history must not be invented. Strict continuous-play acceptance uses boards tracked completely from the start.

Ship foundational CCBA agreement material and a small, real knowledge/evaluation/experience corpus sufficient to exercise the product. Fuller system coverage, books, benchmarks, and validated learning content may follow in 2.0.1 or 2.1. Small content scope does not relax correctness or the minimum quality gate.

## User Stories

1. As a player, I want to keep using the existing review and teaching workspace, so that adopting 2.0 does not discard my established workflow.
2. As a player, I want to confirm or correct recognized cards and auction information, so that uncertain recognition never becomes accepted truth automatically.
3. As a player, I want missing App input distinguished from genuinely hidden cards, so that an analysis cannot silently invent information I should have supplied.
4. As a player, I want useful help from a mid-board screenshot with incomplete history, so that I do not have to reconstruct a whole board before receiving any advice.
5. As a player, I want conditional and unsupported parts identified separately, so that one missing fact does not invalidate every useful observation.
6. As a declarer, I want an initial plan grounded in my legal information, so that I can manage entries, timing, threats, and alternative lines.
7. As a declarer, I want advice when playing from dummy to retain my perspective, so that control of the decision is not confused with the seat supplying the card.
8. As a defender, I want advice without access to partner's hidden hand, so that defensive reasoning remains valid at the table.
9. As a defender, I want opening leads and signals interpreted using our stated agreements, so that advice does not silently substitute generic conventions.
10. As a bidder, I want a legal next-call recommendation and an explanation of its meaning, so that I can act consistently with my partnership methods.
11. As a bidder, I want our system distinguished from known opponent methods and public explanations, so that the opponents are not assumed to play our agreements.
12. As a player, I want a usable foundational CCBA profile with a declared coverage boundary, so that I know what the first release actually supports.
13. As a player, I want unspecified agreements to remain explicitly unknown, so that general bridge knowledge is not represented as an agreed partnership rule.
14. As a player, I want relevant supplements and overrides to take precedence predictably, so that the Expert uses the agreement effective for this situation.
15. As a player, I want scoring context distinguished from my strategic objective, so that selecting IMP does not silently impose an unrelated optimization target.
16. As a player, I want an explicit request for contract safety to change the official objective, so that the recommendation reflects what I actually asked to optimize.
17. As a player, I want calculated metrics labeled by their assumptions, so that a sampled DD make fraction is not mistaken for a real-world success probability.
18. As a player, I want Codex to use Engine capabilities when they help, so that important computations are supported by reproducible evidence.
19. As a player, I want simple questions answered without ritual tool calls, so that analysis effort matches the problem.
20. As a player, I want required computational evidence enforced, so that the system cannot quietly substitute unsupported model judgment.
21. As a player, I want the Expert to read the active agreements and useful knowledge when needed, so that recommendations are not limited to model memory.
22. As a player, I want assumptions and scenario sensitivity made explicit, so that a hypothesis is not presented as a proven hidden holding.
23. As a player, I want candidate actions compared on a compatible sample basis, so that apparent differences are not artifacts of unrelated samples.
24. As a player, I want weak sample coverage and solver failures disclosed, so that precise-looking numbers do not overstate the evidence.
25. As a player, I want follow-up questions tied to the right position and prior advice, so that the conversation remains useful without inheriting unauthorized information.
26. As a player, I want changes to accepted facts to expire old recommendations, so that obsolete advice cannot be executed as current.
27. As a player, I want to cancel, retry, or recover from an incomplete request, so that a failed analysis does not lose my material or produce a late action.
28. As a player, I want one executable recommendation applied at most once to its valid state, so that duplicate delivery cannot advance the board twice.
29. As a player, I want continuous advice for one selected controller while I enter other seats' actions, so that I can complete a board without an automatic table simulator.
30. As a player, I want the plan to retain its purpose across tricks, so that later recommendations preserve necessary entries and communication.
31. As a player, I want plan changes to cite a concrete basis, so that replanning is understandable rather than arbitrary.
32. As a player, I want undo and replay to restore the correct information time, so that future-revealed cards cannot leak into an earlier decision.
33. As a player, I want switching defender perspectives to discard private inherited material, so that one defender does not learn partner's hand through an old explanation.
34. As a player, I want the original-holding and current-remaining meanings of constraints kept distinct, so that played cards do not corrupt inference.
35. As a learner, I want action quality and explanation quality both evaluated, so that plausible prose cannot hide poor advice.
36. As a learner, I want model judgment, agreement grounding, knowledge grounding, Engine evidence, and postmortem truth distinguished, so that I understand why a conclusion is supported.
37. As a learner, I want incomplete, needs-input, conditional, and failure results represented honestly, so that every request is not forced into a confident action.
38. As a reviewer, I want the actual full deal analyzed only in an authorized postmortem context, so that retrospective insight cannot contaminate a blind recommendation.
39. As a reviewer, I want unlucky outcomes separated from bad ex-ante decisions, so that learning is not driven by one result.
40. As a reviewer, I want observable tool, resource, evidence, and final-result history, so that decisions can be audited without storing private chain-of-thought.
41. As a reviewer, I want earlier evidence to retain its original meaning after an extension, so that later sampling does not rewrite what the Expert previously saw.
42. As a reviewer, I want deterministic evidence replay distinguished from a fresh model rerun, so that reproducibility claims are accurate.
43. As a player, I want existing saved reviews to remain accessible through a defined compatibility path, so that the migration preserves my work.
44. As a player, I want model selection, login, runtime discovery, and connection recovery to remain usable, so that the new Expert works in the installed application.
45. As a player, I want usable measured response times across a complete board, so that isolated fast tool calls do not conceal an unusable experience.
46. As a knowledge curator, I want knowledge and agreement versions with provenance and rollback, so that updates can be inspected and reversed.
47. As a knowledge curator, I want postmortems to produce structured candidate lessons, so that raw episodes cannot rewrite production knowledge directly.
48. As a knowledge curator, I want independent validation and human approval before lesson promotion, so that discovering a lesson does not also count as proving it.
49. As an evaluator, I want real representative cases with acceptable alternatives and rationales, so that quality is not reduced to one arbitrary answer label.
50. As an evaluator, I want unresolved disputed cases excluded from hard release gates, so that uncertain adjudication does not create false failures or passes.
51. As an evaluator, I want held-out answers and raw experience unavailable to blind runs, so that successful evaluation is not answer leakage.
52. As an evaluator, I want repeated runs and a relevant legacy/model-only baseline, so that instability and severe regressions are visible.
53. As a product owner, I want small but credible release evidence across bidding, declarer, defense, and continuity, so that 2.0 proves basic quality without claiming world-class strength.
54. As a maintainer, I want runnable vertical milestones with explicit remaining scope, so that the first successful slice is not mistaken for completed 2.0.
55. As a maintainer, I want the architecture, source material, decisions, and implementation tickets linked by stable requirement identifiers, so that the large specification remains navigable and auditable.

## Implementation Decisions

Requirement IDs below are stable references for later implementation tickets and acceptance evidence. They define responsibilities and observable contracts, not a mandatory physical folder tree or final API schema.

### R01 — Product boundary and architecture ownership

Keep one monorepo. Bridge Coup comprises the existing App, peer BridgeDomain / BridgeEngine / BridgeExpert responsibilities, versioned agreement / knowledge / experience / evaluation assets, and native DDS. Preserve the UI and migrate incrementally. Necessary perspective, input-status, evidence, incomplete, and stale-state presentation is allowed.

BridgeDomain defines shared bridge values and authoritative state. BridgeEngine owns deterministic/statistical computation. BridgeExpert contains Codex as the reasoning brain plus Declaration, Tool Registration, and Runtime / Resources / Evidence. DecisionSession instantiates those responsibilities for one request; it is not another architecture layer. Assets are separate information domains. Do not introduce a competing environment/coordinator name, a semantic broker, or an Engine taxonomy mirroring the three Expert blocks.

The dependency direction separates bridge meaning from Codex execution. Engine consumes Domain values and has no Codex runtime dependency. Existing App services consume the Expert facade. Physical targets and type names remain implementation choices supported by dependency analysis.

### R02 — Authoritative state, perspective, and accepted input

Use one accepted fact/event entry point; UI drafts, visible projections, snapshots, simulations, and review adapters are not competing mutable truths. Facts retain provenance, confirmation, visibility audience, and effective information time.

Distinguish confirmed visible facts, confirmed not-yet-visible facts, genuinely hidden information, missing App input, unconfirmed recognition, contradictions, conditional assumptions, and postmortem truth. A stored fact is not automatically decision-visible. Preserve screenshot recognition as a separate candidate-extraction operation and validate its actual isolation rather than assuming read-only access prevents reading other files.

Separate action seat from decision controller. Declarer controls dummy's play; a defender does not receive partner's hidden cards; declarer does not receive dummy before exposure. Bidding receives the bidder's authorized hand, public auction/explanations, scoring, and permitted agreements. Postmortem truth has a separate access boundary, including caches and summaries.

### R03 — Supported input modes

Strict continuous acceptance starts from a sufficiently complete tracked board and progresses to completion for a selected controller; manual entry of other seats is valid. Both declarer and defender continuity must be exercised. Existing full-hand teaching and DD review remain separate authorized workflows.

Ad-hoc mid-board help is a normal product entry. It may produce qualitative analysis, conditional advice, needs-input, or incomplete results. Localize limitations to affected conclusions. Do not sample missing controller-known facts, invent historical play, or run a computation without a defined input universe. Sufficient current information for one analysis does not establish sufficient original-deal information for another.

### R04 — Immutable snapshot and one-request session

Every recommendation uses an immutable snapshot identifying board/version, phase, action seat, controller, authorized visible state, scoring/objective, agreements, input status, and legal actions. One user/product request creates one DecisionSession with one frozen Declaration, resource configuration, permissions, budget, and lifecycle.

Several related sessions may share a snapshot. A follow-up is a new session even when the board is unchanged. Terminal sessions are never reopened. Changed accepted board state creates a new snapshot; material official-objective, authoritative resource, or permission changes require a new session/configuration identity. Public state is re-projected from the authoritative record.

If changed official configuration is embedded in the snapshot (for example its objective or agreement identity), create a matching new immutable snapshot as well; a new session must not carry an old snapshot with contradictory configuration. Investigating an alternate Engine metric under R06 does not change the official configuration.

### R05 — Authorized continuity and temporal meaning

Inherited plans, evidence, and explanations retain source session/snapshot, perspective, controller/action seat, information time, private/public input basis, and relevant assumptions/objective. Accept, safely re-project, or reject inheritance before freezing the new Declaration. When prose cannot be safely decomposed, retain its full source visibility restriction.

Test East-to-West defensive isolation, declarer-to-dummy continuity, forward play, undo to an earlier time, and blind analysis after postmortem. Runtime thread reuse is optional and never grants authority to old context.

Hand-derived conditions and features identify original holding, current remaining holding, or a specified historical public state. Original length/HCP and remaining length/HCP are not interchangeable; a later void does not imply an original void. Preserve this distinction through constraints, samples, evidence, caching, and replay. Mechanical translation uses actual recorded play, not invented history.

### R06 — Scoring context, strategic objective, and analysis metric

Keep the three concepts separate. IMP/MP is scoring context. The official strategic objective expresses the user's goal; ordinary IMP requests retain IMP strategic judgment. An Engine analysis metric expresses the quantity actually computed and its assumptions. An easier proxy does not silently replace the official objective.

Record beneficiary/side, sign conventions, comparison reference where needed, and any explicitly authorized fallback. Without a comparison model, do not claim absolute expected IMP; without a field model, do not claim expected matchpoints. Well-defined score, trick, contract-delta, threshold, or reference-based swing evidence is allowed with its meaning intact.

A session may investigate alternate metrics/objectives without changing its official objective. A user instruction to optimize only contract safety is an official objective change and creates a new request/session. Codex owns the final strategic tradeoff, including a reasoned disagreement with a computational ranking.

### R07 — Model-led request and result contract

The public Expert request specifies goal, snapshot, run mode, output contract, evidence requirement, and candidate inherited artifacts. Resolve permissions, objective, authorized inheritance, and pinned resource identities before reasoning. A goal may be natural language; product output shapes may be typed.

Codex chooses zero, one, or many Engine calls and resource reads, refines inquiries, and decides when to stop within program ceilings. Do not reinstate a permanent proposal/computation/synthesis pipeline or build a second generic agent loop. A fixed two-pass flow may remain an evaluation baseline only.

Support recommendation, analysis, conditional advice, needs-input, incomplete, and failure outcomes. Model-only answers are valid when allowed; required evidence cannot be silently downgraded. Engine-supported claims need real, matching evidence, not merely a successful tool call.

### R08 — Runtime, transport, and isolation proof

Retain Codex app-server as the initial harness and the existing ChatGPT login path. Keep tool semantics transport-independent. Prove dynamic-tool callbacks or a supported thin MCP fallback on the actual supported runtime before choosing the durable transport. The current client rejects server-originated requests; bidirectional lifecycle, typed return, errors followed by continued reasoning, interruption, timeout, and late-result rejection must be established.

Prefer native scoped search/read only if it enforces authorization, pinned versions, and observable provenance. Otherwise use an immutable authorized view or thin scoped adapter; do not add query-rewriting intelligence. Fresh threads and read-only sandboxes alone do not prove confidentiality. Test forbidden access through files, symlinks/alternate paths, inherited configuration, built-ins, plugins/MCP, old context, retrieval, and caches.

An unenforceable isolation boundary blocks the affected implementation path. Reconsider transport/runtime based on measured inability to meet these requirements, not preference for another framework. Do not add Agents SDK/API, ADK, or a second Expert reasoner as initial dependencies. Record actual runtime/model/effort and validate compatibility rather than treating every newer runtime as proven.

### R09 — Capability surface and common session envelope

Expose stable meaningful Engine analytical capabilities broadly. Keep raw mutation, sampler/process/cache plumbing, and invariant-bypassing entry points private. Lower-level analytical tools and proven composite shortcuts may coexist; do not freeze a tiny catalog or force one composite route.

Useful families include rules/legality, belief/scenario inspection, hidden-feature/distribution estimation, current-action evaluation, scoring, diagnostics/evidence extension, and authorized complete-position DD analysis. Each has a precise computational object, typed question-specific arguments, and testable result semantics. Do not expose vague natural-language plan comparison without a represented conditional line and information-respecting evaluation semantics.

Every entry point shares program-bound snapshot, objective, resource versions, belief/scenario, visibility, evidence lineage, and budgets. The model does not supply authority by resending a board ID. Adapters decode, bind, enforce, call, encode, and record; they do not duplicate algorithms or make strategic judgments. Make available capabilities and resources clear to Codex without requiring ritual use. Progressive disclosure is optional and evaluation-driven.

### R10 — Belief, inference, scenarios, and sampling

Separate BeliefModel from a concrete DealSampleSet. Preserve Engine responsibilities for rules, constraints, belief/scenarios, sampling, DDS, scoring, evaluation, diagnostics, and caching.

V1 baseline uses authorized mechanical constraints and a target distribution uniform over complete hidden-card assignments satisfying them. This does not make shapes or HCP buckets uniform. Explicit scenarios add supported conditions and, by default, use the corresponding conditional uniform target. Proposal bias requires valid correction or an explicit different target declaration.

Keep agreement meaning separate from actual holding truth. Codex may propose, revise, withdraw, or investigate soft inference with basis, scope, strength, and withdrawal conditions. It cannot mutate the baseline directly or make an inference hard merely by asserting confidence. Engine checks representation, mechanical consistency, feasibility, and supported computation; it does not judge whether the bridge inference is persuasive. Do not treat scenario-conditioned success as proof of the conditioning assumption.

Sample only genuinely hidden cards; enforce uniqueness, hand sizes, played-card handling, voids, and supported temporal constraints. Distinguish proven contradiction from budget exhaustion without a sample. Record target distribution, seed, component version, requested/generated samples, rejection/attempts, conflicts, coverage, and weighting diagnostics where relevant. Duplicate count alone is not a universal reliability measure. Arbitrary model confidence is not a calibrated posterior.

### R11 — DDS and comparable action evidence

Retain real DDS 3.0 and the existing solver abstraction. Exploit one SolveBoard result for legal/equivalent moves in a sampled complete position before considering per-candidate solves. Benchmark complete analyses before introducing persistent helpers or batching.

Compare explicit legal actions on shared compatible sample sets where possible. Aggregate in Engine; do not make Codex manually summarize hundreds of raw solver rows. Record failures and sample/candidate coverage. Partial coverage must not masquerade as complete evidence under the requested target distribution.

Sampled DD outcomes assume complete-information continuation and may suffer strategy fusion/future-information bias. Name make fractions and expected tricks/scores accordingly; no bare real-world make-probability claims. A next-card comparison does not validate an entire plan. Preserve relevant future decisions that still depend on unknown information.

Blind complete-position tools may solve only explicit hypothetical worlds supplied or constructed from authorized information; they never fetch the actual hidden deal and relabel it hypothetical. Full truth belongs to separately authorized review/postmortem.

### R12 — Immutable evidence, diagnostics, and trace

Evidence records identify snapshot, capability/question parameters, temporal meaning, actual analysis metric/objective, separately identifiable official objective, belief/scenario, target distribution, sample basis/range, component versions, results/artifact, coverage, limitations, and parent/extension lineage.

Published evidence never changes meaning. Extending samples creates a new linked record; reopening an old record reproduces its old basis and result. Reusing evidence does not make independent support. Changed scenarios/objectives/computation settings create explicit lineage. Comparable analyses should reuse or extend a compatible basis rather than silently resample until a preferred answer appears.

Distinguish context available to Codex, resolved agreement material, mechanically incorporated inputs, scenario-only assumptions, and information not modeled by Engine. Resource records preserve query/read semantics, scope, version, and returned identities. Observable events preserve requests, capability/resource activity, results/errors, timing, budget/status changes, and final output without private chain-of-thought.

Delivery checks match support to snapshot, action/feature, actual metric/objective, scenario, and coverage. A valid evidence ID with the wrong meaning cannot qualify a claim. Structural checks do not constitute a general validator of strategic reasoning; interpretation quality belongs to evaluation and review.

### R13 — Continuous plans, declarer, defense, and bidding

Use lightweight structured PlanState: objective, immediate action where applicable, key next steps, observable branches, replan triggers, and computational validation scope. Do not require a full policy tree. Branches use information observable when reached. Carry-forward follows R05. Revisions cite newly visible information, revised assumptions, relevant resource material, or new/corrected authorized evidence.

Declarer reasoning covers winners/losers, entries, communication, danger hand, trump control, establishment, avoidance, safety, timing, ducking/hold-up, elimination/endplay, and squeeze prerequisites as reasoning expectations rather than a large hardcoded rule system.

Defense reuses the same infrastructure with correct side/objective and perspective; address leads, count/attitude/suit preference, distributions, active/passive defense, cashing, forcing, promotion/uppercut, and partner communication. No partner-hand leakage.

Bidding V1 supports legal calls, current auction interpretation, versioned system meaning, hand/fit/risk evaluation, candidate calls, explanation, partner/opponent constraints, qualitative comparison, and sampling where useful. It need not use the card-play evaluator or a fixed pipeline. A phase-specific planning representation is allowed. Auction-continuation policy simulation remains future work; DDS alone does not solve bidding.

### R14 — Agreements and foundational CCBA

Bind the complete effective versioned material set, including base notes, supplements, contextual overrides, precedence, known opponent methods, public explanations, and explicit unknowns. Our agreement, opponent information, generic knowledge, and hidden holding truth remain distinct. Every session receives mandatory identity/version and decision-relevant explanation context; large detail can be retrieved lazily.

Start with a foundational CCBA profile and declared coverage adequate for the first representative acceptance cases. Curate and verify its sources during implementation; this spec does not claim that the profile already exists or that an improvised rule is an official CCBA convention. Model memory alone must not masquerade as authoritative partnership material. Missing decision-critical coverage is explicit, with conditional advice or input requests where appropriate; repeated unknown responses cannot substitute for usable behavior in declared supported cases.

Codex owns query choice, refinement, selection, and interpretation. Program owns material membership, pinned version, precedence, and access audit. Backing-file edits cannot change a running session's view. Full CCBA coverage and systematic source expansion are post-2.0 content work.

### R15 — Knowledge and versioned retrieval

Use operational context, curated knowledge cards, and authorized original sources as distinct levels. Operational agreements remain a separate authoritative domain. Knowledge cards retain conditions, reasoning, failure conditions, examples, source, and validation status. Copyrighted/private originals need not enter the repository.

Begin with scoped full-text/path/metadata search and direct reads. Codex decides when and what to search. Do not preload a large corpus or add vector/semantic retrieval without measured need. Pin the knowledge manifest/version; preserve read/search provenance and rollback. A small real corpus must demonstrate useful retrieval and behavior, including query refinement where needed.

### R16 — Postmortem, experience, and human-approved learning

Persist structured episodes from authoritative board/session data. Keep postmortem full truth in separately authorized linked records. Analyze actual outcomes and counterfactual evidence without equating loss with bad ex-ante judgment.

The learning path is episode → postmortem → candidate lesson → independent validation → human decision → promoted/rejected/withdrawn knowledge change. Candidate records retain claim, scope, discovery episodes, independent evidence, counterexamples, sources, and status. Discovery boards do not independently validate their lesson. General knowledge promotion does not modify partnership agreements silently.

Blind runs cannot read raw experience or eval answers. Authorized postmortem/learning can produce structured annotations/candidate lessons, not arbitrary filesystem edits. Promotion requires human approval and rollback with regression checks. The real workflow must be exercised in 2.0, but a large store or many proven new lessons is not required; lack of independent evidence must remain an honest unvalidated outcome.

### R17 — Execution, failures, budgets, and product operation

Before applying an action, validate legality, controller/action seat, originating snapshot/session freshness, cancellation status, and exactly-once application. Timed-out, cancelled, stale, failed, or late sessions cannot act. Preserve input for recovery and use a new request/session for a retry when needed.

Set finite wall-time, tool/compute/sample/resource/read-volume ceilings from the start. Exhaustion produces an honest incomplete result or failure. Codex chooses inquiry order and stopping within those ceilings. Measure whole-request and complete-board typical/tail latency before selecting product budgets or optimizing DDS, sampling, caches, retrieval, or model effort.

Distinguish state/input/visibility/agreement/knowledge/inference/sampling/candidate/evaluation/objective failures from transport/schema/evidence/inheritance/budget/runtime/explanation/execution failures. Postmortems separate model decomposition, session binding, Engine computation, evidence interpretation, and execution defects. Detailed schemas are implementation choices; failure classes must remain diagnosable.

### R18 — Cache, replay, model identity, and compatibility

Cache deterministic work only with all real semantic dependencies: authorized position, belief/scenario and temporal meaning, target distribution, sample basis, actual metric/objective, component versions, and resource version/scope where relevant. Cache hits do not relax visibility or freshness. Evidence reuse obeys immutable lineage rules beyond ordinary caching.

Distinguish stored evidence/resource replay, deterministic recomputation, and stochastic model rerun. Preserve sufficient inputs, versions, seeds/sample ranges, instruction/tool-surface identities, and observable results for the claimed replay mode. A fresh model call is not guaranteed to repeat its inquiry path or prose.

Retain model selection and record requested/actual model, effort, and runtime. Reuse current deterministic play, auction, DDS, input, archive, and workflow behavior through adapters; do not rename old drafts into universal state or assign old archives provenance they never contained. Keep builds/core behavior, screenshot review, login, saved reviews, and DD UI working during migration, with an explicit compatibility path for old data. Gate the new Expert initially so product regressions can be compared and rolled back.

### R19 — Minimum quality and release bar

All four gates are mandatory; architecture completion alone is insufficient:

| Gate | Required release evidence |
| --- | --- |
| G1 Product | Usable bidding, declarer, defense, continuous advice, teaching/explanation, evidence, and postmortem in the actual App. |
| G2 Correctness | Visibility, legality, session isolation, stale-state handling, Engine semantics, evidence provenance, and agreement/resource versioning pass relevant deterministic and real-runtime checks. |
| G3 Basic quality | Small real, human-reviewed representative material covers bidding, declarer, defense, and continuous play; supported scenarios are usable and show no obvious severe regression. Repeated clearly bad advice blocks release even if plumbing works. |
| G4 Real asset workflows | Knowledge, Agreement, Eval, and Experience each run with real material; no empty-interface or placeholder acceptance. Engine/resources materially support behavior in representative cases where they are needed. |

Statistical superiority to the old teacher, broad expert-level benchmarks, world-class strength, large book imports, all CCBA details, and many validated learned rules are not required. Limited coverage must be declared, not generalized into a claim of expert strength. Later content growth does not replace G1–G4.

### R20 — Independent quality adjudication

Use credible sourced expert material plus human adjudication. Each case records decision-time material, goal/output contract, sufficiency, scoring/objective/agreements, acceptable actions/plans, severe errors, rationale, assumptions, provenance, and dispute/confidence status. Allow defensible alternatives. Resolve disputes with another source, expert, or human review; unresolved disputed cases do not become hard gates.

DDS is supporting computation, not a final imperfect-information strategy judge. LLMs may identify rubric contradictions but cannot author their own final gold standard. The product owner approves adjudication without being assumed the sole bridge authority.

Separate development from held-out release evaluation. Establish baseline/pilot evidence, then freeze material, rubric, and thresholds before final held-out evaluation. Begin with a small representative corpus rather than a mandatory 20–30 cases per phase. Include real materials; synthetic fixtures are additional correctness evidence. Mark possible training/retrieval overlap in public book problems and do not use them alone to claim independent expert strength. Retain evaluation contamination boundaries for private originals too.

Release evidence is tied to the tested product/runtime/model/resource configuration. Behavior-affecting fixes, including fixes from final code review, require impact review and renewed affected acceptance before the final release conclusion. Preserve failed runs. A held-out result used to tune the implementation is thereafter development/regression evidence, not fresh independent validation; follow the frozen protocol for reruns and use still-independent material for any renewed independence claim. Predeclared repeated runs are part of one evaluation protocol, not selective retries until a pass.

### 2026-10-04 Ticket 02 的开发推进例外

实施期间，产品负责人对已展示的02人工审阅包明确回复：“我没怎么仔细看，但我觉得就当它过呗，没问题。”据此，02可在有出处的小型开发材料、实际旧版基线与保留失败记录准备完成后，按负责人的开发放行完成，不再以本轮逐题人工裁定或留出题目选定阻塞后续工程。

这不是逐题质量审阅或gold：开发rubric继续标记provisional／pending-human-review，输出与专家来源的差异保留为未裁定观察。留出材料仅为未消费的source intake，保管方式暂定，不能声称真实隔离已验收。实际权限由05／08证明；真实桥牌裁定、留出案例选择与答案保管核验由28／30在发布前补足，R19的G1–G4与最终独立质量门槛未获豁免。既有来源记录、基线、失败与未决问题不覆盖。

### R21 — Vertical migration and engineering discretion

Deliver runnable vertical milestones M0–M7 below, with acceptance evidence and explicit remaining 2.0 scope. The first real slice uses the existing declarer-analysis surface; it does not require all Domain/Engine modules to be finished first. Reuse the existing highest-level workflow/test boundaries.

Final type shapes, targets, physical organization, transport, capability names/count, persistence details, and performance optimizations remain engineering decisions within these contracts. Do not perform broad moves just to match a diagram. A responsibility change requires evidence, an explicit spec/ADR update, and affected tests. The initial foundation work must prove runtime feasibility before a large production refactor.

### R22 — Authority and requirement traceability

This local spec is the current whole-product specification, with R01–R22, T01–T13, G1–G4, and M0–M7 as traceable references. The byte-preserved Spec 1.4 is incorporated as the detailed technical baseline for these requirements except for the explicit amendments in Further Notes. Its code/type sketches remain illustrative, not frozen implementation APIs. Use the source map to reach exact chapters rather than dropping long-document requirements during ticketing.

The glossary defines terms. ADRs explain confirmed tradeoffs. The source archive is immutable historical input, not a separately edited live spec. If an implementation uncovers a responsibility conflict, reconcile this local spec and affected ADRs explicitly. Future tickets identify their parent spec, requirements, milestone, tests, acceptance evidence, dependencies, non-goals, and remaining scope. Do not use one giant implementation ticket or treat a ready label as evidence of completed work.

The [implementation map](implementation-map.md) connects these requirements and the approved user stories/tests to their ticket owners and milestone handoffs. It is navigation and coverage accountability, not another spec or a substitute for per-ticket acceptance evidence.

## Testing Decisions

The user confirmed these test boundaries during this to-spec run: use **App request → Bridge Expert result / continuous board behavior** as the primary seam, retaining focused Engine mathematics, real runtime/isolation integration, and actual packaged-App quality acceptance. Prefer observable contracts to tests tied to private methods, class layout, or a fixed model tool-call order.

### T01 — Reuse the highest application seam

Extend the pattern of existing DeclarerPlanWorkflowTests and PlayWorkspaceIntegrationTests: accepted inputs, controller, request, result, state changes, follow-up, save/reopen, and externally visible failure behavior. Evolve the existing injectable teaching-runtime seam into a general Expert facade rather than creating separate bidding/declarer/defense test harnesses. Fake transports support deterministic lifecycle tests; they do not establish model quality or real isolation.

### T02 — State and input behavior

Reuse AuctionRecordTests, ScreenshotReviewWorkflowTests, KeyPlayAnalysisTests, and play/history workflow coverage. Test uniqueness, hand sizes, turn/follow-suit legality, auctions, accepted corrections, state rebuild, undo/redo, and archive compatibility. Include partial mid-board advice, missing controller-known cards, contradictory/unconfirmed material, and a computation refused because its required universe is undefined. UI four-hand display must not widen a blind request.

### T03 — Frozen session and safe continuity

Test separate sessions for separate requests on the same snapshot, terminal non-reopening, changed official goals/resources, bound tool context despite concurrent board changes, late responses, and execution exactly once. Cover East/West isolation, declarer/dummy continuity, forward state, undo before a revealed event, and new blind analysis after postmortem. Check inherited artifact provenance, not merely fresh thread identity.

### T04 — Hidden-truth invariance

Hold visible state, typed computation, seed, sample configuration, resources, objective/metric, and component versions fixed. Vary only application-held unauthorized truth. Deterministic Engine inputs, generated samples, and returned evidence must remain identical. Stochastic model runs need not have identical prose/tool paths. Add the same visibility assertions to summaries, inherited plans, caches, and hypothetical-position tools.

### T05 — Real runtime and resource boundary

Extend CodexTeachingServiceRequestTests with real supported-runtime checks: several typed tool round trips, one tool failure followed by continued reasoning, structured output, cancellation/timeout, and rejected late results. Verify finite ceilings even while notifications continue. Test actual interruption and Engine cancellation/result rejection separately from UI late-response suppression.

Place sentinels outside authorized resource views and attempt alternate file/built-in/config/plugin/MCP/cache/context access. Mutate backing agreement/knowledge material after session start: reads retain the pinned version or fail explicitly. Test base/addendum precedence, query refinement, and observable source/version reads. Existing request-construction tests and read-only sandbox settings alone cannot pass this gate.

### T06 — Engine distribution and temporal semantics

Use exactly enumerable small states to verify declared baseline/scenario target distributions and any proposal correction. Test rare feasible states, true contradiction versus budget exhaustion, known cards, original/current lengths and HCP, void timing, repeated evidence, and no uncalibrated hardening of inference. Component tests are justified where the mathematical contract cannot be established through App examples alone.

### T07 — Actual DDS and evaluator evidence

Retain DoubleDummyVerificationTests and real DoubleDummySolverIntegrationTests, including independently known deals, all strains, partial tricks, defenders, legal/equivalent-card coverage, and failures. Add shared-sample comparisons, explicit partial coverage, and strategy-fusion examples contrasting DD continuation with a feasible information-respecting policy. A skipped native-solver test is not numerical acceptance. Introduced batch APIs must match the established single-solve behavior.

### T08 — Evidence, metrics, and replay

Assert that evidence extension preserves old results; mismatched real evidence IDs fail or lose qualification; scenario/objective/sample differences remain explicit; alternate analysis metrics do not change the official goal; and repeated reads are not independent support. Replay deterministic evidence and pinned resources with recorded versions. Test truthful limitations when information was available to Codex but not modeled mechanically.

### T09 — Real bridge quality and adjudication

Use a small human-reviewed corpus across bidding, declarer, defense, initial plans, and continuous sequences. Evaluate actions/plans separately from explanations, severe errors, agreement consistency, uncertainty, and usability. Compare relevant legacy/model-only behavior on shared supported tasks; evaluate new phases against adjudicated expectations rather than inventing an old baseline for capabilities it lacked. Freeze release criteria after pilot work and before held-out evaluation. Unresolved disputed cases do not determine release.

### T10 — Model-led inquiry and stability

Repeat important cases. Inspect whether Codex seeks decision-critical evidence/resources, decomposes into valid computable questions, uses lower-level/composite tools appropriately, avoids redundant searches and premature stopping, and states limitations accurately. Include a correct zero-tool case, evidence-required case, resource-helpful case, useful lower-level case, and useful composite case. Do not demand identical call counts/order. Use targeted ablations under comparable budgets to diagnose regressions, not an exhaustive experiment matrix as a release prerequisite.

### T11 — Real asset and learning flows

Exercise a versioned CCBA material set, a real knowledge lookup that helps a supported case, a sourced adjudicated eval, and an actual episode/postmortem/candidate record. Test independent-validation status, human approval for promotion, rejection/withdrawal, rollback, and production blindness to raw episodes/eval answers. No fabricated lesson improvement is needed merely to make the workflow pass; promotion-path testing cannot itself approve an unvalidated production lesson.

### T12 — Packaged-App continuous and compatibility acceptance

Run actual installed-App cases through login/model selection, screenshot/manual input, representative bidding, declarer and defender sessions, full-board continuous advice, follow-up, correction, undo, cancellation, save/reopen, evidence display, and postmortem. Other seats may be manually advanced. Test cold reopen against saved state and ensure interrupted/stale work does not execute after recovery. Preserve existing DD review. Mocks/unit tests do not substitute for this acceptance.

### T13 — Latency and release evidence

Measure complete requests and complete-board use, including model/tool/resource waits, DDS startup/solve, sampling, failure/retry, and typical/tail latency. Define usable per-surface budgets after measurement while enforcing finite safety ceilings from the start. Record the tested product/runtime/model/resources/corpus versions and outstanding limitations. Release evidence explicitly demonstrates all G1–G4; it does not merely count passing infrastructure tests.

## Out of Scope

- Mandatory automatic control of all four seats, a dedicated blind-practice UI as a release blocker, or unrestricted self-play.
- Xinrui and other external autonomous-play adapters as 2.0 release requirements; external integration is a later milestone.
- Rewriting the existing UI, splitting repositories, or wholesale physical reorganization to match a diagram.
- Training/fine-tuning a bridge foundation model, reinforcement learning, a multi-agent society, or a second reasoning specialist without measured justification.
- A replacement generic application-controlled agent framework, routine migration away from Codex app-server, or required cloud-hosted durable jobs.
- Calibrated hidden-deal posterior weights, alpha-mu/POMDP/policy search, full conditional-policy trees, and advanced bidding-continuation simulation as initial prerequisites.
- A deterministic strategic-reasoning validator or a semantic broker that guesses the computation behind arbitrary prose.
- A mandatory tiny tool catalog, fixed pass count, ritual computation/retrieval, or unrestricted exposure of Engine internals.
- Unqualified real-world probabilities from sampled DD, undefined expected IMP/MP, or raw/postmortem/held-out information in blind reasoning.
- Complete CCBA coverage, large book imports, a vector database without measured need, a large expert benchmark, statistically significant superiority to the old teacher, or world-class strength claims.
- Many independently validated new lessons at launch; automatic promotion from a single outcome or arbitrary learning writes.

These exclusions do not waive the small real corpus, usable supported advice, correctness, isolation, or working asset flows required by G1–G4.

## Further Notes

### Document authority and locations

This is the canonical Bridge Coup 2.0 product spec and parent for later implementation tickets. The code baseline examined when this spec was approved was `a11448a`; it contains the interview's merged documentation decisions on top of the source document's implementation baseline `0da8528`. The new Domain/Engine/Expert architecture is a target, not a claim about shipped code.

- [Document entry point and reading order](../../docs/bridge-2/README.md).
- [Byte-preserved source: Bridge Expert Architecture & Implementation Spec 1.4](../../docs/bridge-2/source-spec-1.4.md), 70 sections, 3,571 lines; SHA-256 `a9027db6cdfd10bb19603d896d3c8cb34f04322b1d18f749a45bfcc9eebdc947`.
- [Source-section coverage and amendment map](../../docs/bridge-2/source-map.md).
- [Shared domain glossary](../../CONTEXT.md).
- [ADR 0001: continuous coaching, content scope, and release bar](../../docs/adr/0001-bridge-2-continuous-coaching-and-content-scope.md).
- [ADR 0002: strategic objectives and independent evaluation](../../docs/adr/0002-strategic-objectives-and-independent-evaluation.md).
- [Confirmed interview decisions, merged PR #32](https://github.com/absurdwall/bridge-coup/pull/32).

During the user-authorized local fallback, this file is the canonical live spec, and the [30 local tickets](README.md#ticket-index) own implementation status, dependencies, and evidence. GitHub issue #33 and published ticket #35 are historical remote counterparts; no other implementation ticket was published before the interruption. The [migration baseline](baseline/README.md) preserves the approved inputs for comparison, not live editing. The repository entry/map remain navigation and traceability. Follow the [local execution and recovery agreement](execution.md) for branch, review, and future synchronization rules. All referenced project specification material is available in this checkout; the original Downloads recovery pack is no longer required. The source archive remains unchanged even where the current decisions differ.

### Explicit amendments to the 1.4 baseline

1. **Continuous-play acceptance:** a selected controller receives advice throughout a board; manual actions from other seats count. Automatic table control and a blind-practice UI are optional enhancements.
2. **Incomplete mid-board material:** it is a supported entry, with localized conditional/unsupported analysis and no fabricated history. Strict continuous acceptance still uses complete tracking.
3. **Objective semantics:** scoring context, official strategic objective, and actual Engine metric are separate. The original fallback language cannot silently authorize replacing the strategic goal with a proxy.
4. **Initial agreements:** foundational CCBA with explicit verified material and coverage; comprehensive system/content curation is later work.
5. **Evaluation/content scale:** small real representative, human-reviewed material replaces a fixed initial 20–30-per-phase target or an implied mature benchmark. Expert-source plus human adjudication remains mandatory; disputed cases are not hard gates.
6. **Release bar:** basic usable quality, no obvious severe regression, correctness, and all four real asset workflows are required. Broad statistically significant improvement, comprehensive books/benchmarks, or a mature learned knowledge corpus are not.
7. **2026-10-04 development-only exception:** the product owner allowed local ticket 02 to pass with provisional sourced development expectations and actual legacy runs without detailed human review. The dated R20 exception records its limits; case adjudication, held-out selection/custody verification, and G1–G4 remain release requirements.

The detailed architecture, evidence, privacy, temporal, sampling, and replay constraints in 1.4 remain applicable subject to these amendments. Historical labels and the original document's freeze/status wording do not override this local spec. Its M8 remains post-2.0; the M0–M7 decomposition below retains the vertical sequence without making one milestone equivalent to whole-product completion.

### Vertical milestones and completion boundaries

| Milestone | Runnable result and exit evidence | Explicitly incomplete afterward |
| --- | --- | --- |
| M0 Foundation proofs | Inventory current truth/dependencies and Engine exposure; prove session/snapshot/resource binding, safe inheritance and temporal semantics; at least two meaningful capabilities, multi-tool continuation/error recovery, real runtime isolation, pinned search/read and precedence, cancellation, evidence extension, hidden-truth invariance, DDS whole-analysis baseline, enumerable sampler target, and a minimal evaluation scaffold. No large production refactor before feasibility is established. | No claim of a finished Expert product or final transport/catalog. |
| M1 Declarer analysis | Existing declarer surface uses accepted-state projection → frozen session → model-led tools/resources → structured plan/evidence. Include the five representative inquiry cases in T10, real partial-information input, minimal agreements/knowledge, trace, feature flag, and core correctness/quality checks. | Current-action execution, full continuous product, defense, bidding, and richer assets still pending. |
| M2 Continuous declarer advice | Legal current-action recommendations and full-board selected-controller continuity with externally/manually supplied other-seat actions, plan revision, safe history, failure recovery, and measured complete-board latency. | Defense, bidding, and later asset/release work still pending. |
| M3 Defense | Correct defender perspective, agreements/signals, inference, planning, continuous advice, and representative quality evidence using the shared infrastructure. | Bidding and later asset/release work still pending. |
| M4 Bidding | Legal next calls, usable foundational CCBA interpretation, candidate/hand reasoning, authoritative lookup, supported sampling, and sourced representative evaluation. | Advanced auction rollout is deferred; broader content and hardening remain. |
| M5 Knowledge | Small real curated knowledge corpus and agreement resources with pinned retrieval, provenance, rollback, and demonstrated useful behavior. Minimal resource paths already exist in earlier slices. | Large corpus expansion is not required; experience flow and final hardening remain. |
| M6 Experience | Real episodes/postmortems, structured candidates, independent-validation status, human promotion controls, rollback and isolation exercised. | Many proven new lessons are not required; product-wide release evidence remains. |
| M7 Release | Actual packaged product satisfies G1–G4 across all required flows, correctness, small real adjudicated quality, compatibility, and accepted measured latency. | External adapters and later content/research extensions remain post-2.0. |

The approved decomposition is preserved as [30 local implementation tickets](README.md#ticket-index). Each links to this spec and its R/T/M identifiers, with explicit local blocking relationships; G1–G4 continue to govern product acceptance. The `ready-for-agent` label means the specification is ready to drive bounded implementation work after blockers are resolved, not that the entire program should be implemented in one task or that 2.0 has passed acceptance.

### 2026-10-07 全ticket临时人工审阅通过

用户明确指示：“所有ticket人工审阅部分都可以暂时认为我审阅并通过。会在所有ticket结束后我一起处理。有问题会在那时返工。人工审阅不应成为ticket的blocker”。据此全部ticket人工部分记录为provisional-human-approval，不作为本地工程/ticket阻塞；工程结束后统一人工复核及必要返工。非人工运行/正确性/独立验证/真实资料与证据仍执行，原失败与旧人工范围保留，未声称专家gold或发布。详见[evidence/临时政策](evidence/provisional-human-review-policy-2026-10-07.md)。

### 2026-10-11 工程先行与集中验收顺序

产品负责人明确要求先完成所有ticket的工程实现，再集中检查并按结果返工。此前各产品票要求的基本质量、实际App与复杂重复观察可以集中到工程收尾后的统一验收执行，不再逐票阻塞代码集成／实现进度。工程实现与验收关票分别记录；本修订调整执行顺序，不把已有严重错误判为通过，也不豁免最终R19的G1–G4、R20的独立性与失败保留。全部人工部分沿用暂通过／最后统一复核授权。
