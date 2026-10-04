# Bridge Expert Architecture & Implementation Spec 1.4

**Status:** Freeze-oriented architecture baseline for implementation after final diagram, session, continuity, and temporal-semantics consolidation  
**Date:** 2026-10-04  
**Repository:** `absurdwall/bridge-coup`  
**Repo baseline reviewed:** `0da8528438ccefcec46a02609d8f2fb40632fb9f`  
**Purpose:** Define the agreed architecture, evidence semantics, runtime boundary, product acceptance criteria, and vertical implementation plan for evolving Bridge Coup from a primarily UI / teaching application into a serious bridge platform core with a reusable expert capable of bidding, declarer play, defense, continuous in-App play, explanation, teaching, verification, and eventually learning from validated experience.

**Revision note:** Spec 1.4 preserves the architecture corrected in Spec 1.3 and performs the final implementation-readiness consolidation before development. It adds an explicit expected whole-project architecture map so BridgeDomain, BridgeEngine, BridgeExpert, assets, native DDS, and the existing App are visually balanced rather than presenting Bridge Expert as the parent of the platform. It keeps BridgeEngine component-based and removes the last migration/milestone remnants of the rejected `Declarative/Model → Computation/Tool → Evidence/Analysis` Engine taxonomy. It also makes the run contract unambiguous: one user/product request is one `DecisionSession`, while multiple related sessions may share the same immutable `DecisionSnapshot`; cross-session PlanState/evidence/history inheritance is allowed only through explicit visibility/provenance checks; and hand-derived constraints/features must carry an unambiguous temporal reference such as original holding versus current remaining holding. The previously agreed hidden-truth/DD and actual-analysis-objective corrections remain unchanged.

---
# 1. Product goal

Bridge Coup should evolve into one coherent **bridge application and platform**, not an Expert subsystem with miscellaneous support hanging off it.

The expected architectural shape is:

```text
Bridge Coup / bridge-coup
│
├── Bridge App
│   ├── BridgeTeacherCore
│   └── BridgeTeacherMac
│
├── Bridge Platform Core
│   ├── BridgeDomain
│   ├── BridgeEngine
│   └── BridgeExpert
│
├── Bridge Assets
│   ├── agreements/
│   ├── knowledge/
│   ├── experience/
│   └── evals/
│
├── Native
│   └── DDSHelper
│
└── Engineering Support
    ├── Tests
    ├── Scripts
    ├── AppResources
    └── docs
```

This is an **expected architecture and responsibility map**, not a frozen folder/file tree. During implementation, Milestone 0 may discover that a Swift target, folder boundary, transport adapter, or persistence detail should move. Such changes are allowed when repo-grounded evidence justifies them. What should remain stable unless we explicitly revise the architecture is the responsibility ownership described here.

The three Bridge Platform Core modules are peers with different jobs:

- **BridgeDomain** defines the shared bridge language, authoritative facts/events, visibility, and immutable decision-state objects.
- **BridgeEngine** provides deterministic/statistical bridge computation through concrete components such as legality/rules, constraints and `BeliefModel`, scenario mechanics, sampling and `DealSampleSet`, DDS, scoring/objectives, candidate/action evaluation, diagnostics, and related analysis.
- **BridgeExpert** combines the Codex reasoning brain with three programmatic support blocks: **Declaration**, **Tool Registration**, and **Runtime / Resources / Evidence**.

The Bridge Assets are separate versioned information/evaluation domains rather than hidden submodules of BridgeExpert or BridgeEngine:

- `agreements/` contains authoritative partnership/opponent method material and precedence/override metadata;
- `knowledge/` contains curated bridge knowledge and provenance;
- `experience/` contains structured episode/postmortem/learning artifacts and is isolated from ordinary blind decisions;
- `evals/` contains development/holdout/rubric material and is isolated from production decision access.

The finished system should be able to:

- understand the current bridge position from the correct decision perspective and information time;
- distinguish genuinely hidden bridge information from information that is missing, unconfirmed, contradictory, or mis-recognized by the App;
- follow configurable partnership bidding systems and defensive agreements while keeping our agreements, opponent agreements/explanations, and unknowns distinct;
- reason under hidden information rather than assuming all four hands are visible;
- form strategic hypotheses, plans, candidate bids, candidate plays, and defensive actions;
- let Codex decompose a bridge problem into explicit computational or retrieval questions when additional evidence would help;
- expose useful BridgeEngine analytical capabilities broadly enough for Codex to choose its own analysis path;
- let Codex search/read authorized bridge knowledge and the active agreement material when outside bridge memory is useful;
- use deal sampling and DDS-based simulation as explicitly qualified evidence rather than as an oracle for imperfect-information policy;
- distinguish IMP, matchpoint, contract-safety, trick-maximization, and other decision objectives without inventing unsupported objective functions;
- maintain a lightweight, observable conditional plan across consecutive tricks and revise that plan only with an auditable basis;
- explain recommendations at an expert teaching level;
- expose assumptions, evidence boundaries, and uncertainty;
- support bidding, declarer play, and defense through one shared architecture rather than separate agent systems;
- support continuous in-App bridge decisions across a board rather than only isolated one-shot analysis;
- produce auditable decision / tool / resource-read / evidence traces without storing private chain-of-thought;
- support postmortem analysis after hidden information becomes available;
- eventually learn reusable lessons from books and played boards without treating unverified experience as truth;
- serve the current Bridge Coup UI as the core product and later support external play adapters such as Xinrui.

The north-star definition is:

> **Bridge Coup is a bridge platform in which BridgeDomain defines the shared state language, BridgeEngine supplies reliable computation, BridgeExpert supplies Codex-led bridge judgment inside explicit program-owned boundaries, and versioned agreements/knowledge/experience/evals provide the external information and improvement loop. Program owns invariants; Codex owns strategic judgment.**

Bridge Coup 2.0 is complete based on the in-App product. Xinrui or another external autonomous-play adapter is a later integration milestone and is **not** a Bridge Coup 2.0 release blocker.

# 2. Explicit non-goals for the first implementation

The first implementation should **not** attempt to:

- train a bridge foundation model;
- fine-tune the model;
- perform reinforcement learning;
- implement unrestricted self-play;
- build a multi-agent society of bidding / declarer / defense agents;
- create a second generic agent framework around Codex;
- replace Codex app-server with Agents SDK merely because this is an “agent” project;
- use Agents API for cloud-hosted execution;
- add Google ADK;
- introduce a vector database before retrieval requirements justify it;
- import a large bridge book corpus before the decision architecture works;
- minimize the Bridge Tool count as an architectural goal;
- expose meaningless Engine implementation plumbing merely because a method exists;
- hide useful stable analytical Engine capabilities solely to force Codex through one preselected composite workflow;
- create a deterministic “semantic broker” that tries to understand arbitrary strategic natural language and invent the required Engine computation;
- create vague pseudo-typed tools such as “compare two lines” before the represented object and evaluation semantics are precisely defined;
- require a fixed number of model turns or tool calls for every expert request;
- force every answer to use Engine computation when model-only reasoning is sufficient and the request permits it;
- build a standalone programmatic validator that attempts to judge whether Codex's bridge reasoning or teaching explanation is strategically correct;
- allow unrestricted repository/filesystem, shell, evaluation-answer, raw-experience, or postmortem access;
- let native read/search resolve against mutable agreement/knowledge contents that differ from the versions declared by the DecisionSession;
- treat DDS as an imperfect-information bridge player;
- label sampled double-dummy outcomes as real policy success probabilities without qualification;
- make αμ search, POMDP-style policy search, or another sophisticated imperfect-information search algorithm a V1 prerequisite;
- convert arbitrary LLM confidence scores directly into calibrated posterior probabilities;
- build a full policy tree before a lightweight continuous-play `PlanState` has proved useful;
- treat one result on one board as evidence that a decision rule is correct;
- allow postmortem hidden information to leak into decision-time reasoning;
- rewrite the existing Bridge Coup UI;
- make Xinrui autonomous play a Bridge Coup 2.0 release blocker;
- introduce a second LLM-based Expert specialist in V1 merely because multi-agent architecture is possible.

# 3. Decisions that are currently considered frozen

Unless implementation evidence proves one of these wrong, proceed with the following decisions.

## 3.1 One monorepo

Everything remains inside `bridge-coup`.

The repository may contain multiple Swift targets, native components, agent assets, knowledge, evaluations, and adapters, but these remain one project.

Do **not** create separate repositories such as `bridge-expert`, `bridge-engine`, or `bridge-knowledge` unless a future independent deployment lifecycle provides a concrete reason.

Logical modularity is required. Repository fragmentation is not.

## 3.2 Preserve the existing Bridge Coup UI

The current UI has already undergone significant iteration and is not the focus of this project.

Existing workflows should continue functioning during migration.

Bridge Expert is added behind the UI rather than replacing it. Necessary status, evidence-boundary, stale-state, input-sufficiency, and model-vs-computation provenance presentation may be added without redesigning the product.

## 3.3 Canonical architecture vocabulary

The following names are authoritative for Spec 1.4:

| Term | Meaning |
| --- | --- |
| **Bridge Expert** | The whole expert subsystem. |
| **Codex** | The reasoning brain inside Bridge Expert. |
| **Declaration** | The Bridge Expert block that defines one run's frozen decision contract and authorized context. |
| **Tool Registration** | The Bridge Expert block that exposes callable Engine capabilities and authorized read/search surfaces to Codex. |
| **Runtime / Resources / Evidence** | The Bridge Expert block that owns run control, pinned resources, EvidenceLedger, observable history/trace, and related invariants. |
| **DecisionSession** | One instantiated Bridge Expert run for one user/product request, bound to one immutable decision snapshot and one frozen Declaration/resource configuration. Multiple related sessions may bind the same snapshot. |
| **BridgeEngine** | Deterministic/statistical bridge-computation components. It is not a reasoning agent and is not reorganized to mirror the three Bridge Expert blocks. |
| **BridgeDomain** | Shared bridge language and authoritative state/snapshot types. |

Do not introduce another formal top-level name such as `Bridge Research Environment` for the programmatic support around Codex.

Do not reuse the names **Declaration**, **Tool Registration**, and **Runtime / Resources / Evidence** as a new internal layer taxonomy for BridgeEngine.

## 3.4 Bridge Expert has three programmatic support blocks

The programmatic support inside Bridge Expert is organized conceptually as:

```text
Declaration
Tool Registration
Runtime / Resources / Evidence
```

Codex is the reasoning brain that operates with those three blocks.

This is an architectural vocabulary rule, not a requirement to create exactly three Swift targets or three directories. Physical code organization may remain pragmatic as long as responsibility ownership is clear.

## 3.5 BridgeEngine keeps the agreed component architecture

BridgeEngine remains organized around concrete bridge-computation responsibilities such as:

```text
rules / legality
constraints
BeliefModel
scenario mechanics
DealSampler / DealSampleSet
DDS integration
scoring / DecisionObjective
candidate / action evaluation
diagnostics and statistical semantics
caching / deterministic computation support
```

These components may call one another and may be composed into analytical capabilities. They are **not** redefined as Declaration / Tools / Evidence layers.

The existing Domain/Engine separation remains: BridgeEngine consumes BridgeDomain types and must not depend on Codex-specific runtime types.

## 3.6 Model-led capability use is the production architecture

The production architecture does **not** prescribe a permanent fixed `Pass A → Engine → Pass B` reasoning workflow.

Instead:

- Codex reasons about the bridge problem and chooses what to investigate;
- Codex may answer without Engine computation when the request permits and additional evidence is unlikely to matter;
- Codex may make zero, one, or many registered tool calls in one DecisionSession;
- Codex may search/read authorized agreement and knowledge resources when useful;
- program-owned infrastructure supplies context, permissions, budgets, resource versions, evidence identity, and staleness/cancellation guarantees;
- BridgeEngine supplies computation; it does not decide strategic reasoning order;
- executable actions are checked at the application/execution boundary.

A fixed two-pass path may remain as a historical baseline/fallback for evaluation, but it is not the target architecture.

## 3.7 Useful Engine analytical capabilities are broadly available

Do not make a tiny tool catalog an architectural goal.

Stable, meaningful Engine analytical capabilities should generally be registrable for Codex. A capability should be kept private when there is a concrete reason, such as implementation plumbing, lack of independent analytical semantics, invariant bypass risk, or unsafe mutation/control of internal state.

Proven composite capabilities may coexist with lower-level analytical capabilities. Composite tools are convenience paths, not mandatory workflows.

## 3.8 Knowledge and agreement access is model-led but session-authorized

Prefer Codex's native scoped read/search when the runtime can enforce the required access, version, and audit guarantees.

The DecisionSession must pin:

- the active agreement identity/version;
- the complete effective agreement material set, including applicable supplements/overrides/exceptions and precedence;
- the authorized knowledge snapshot/version;
- the run-mode permissions determining which resource classes are readable.

Codex chooses search terms, refinement, file selection, and interpretation. Program code does not try to outsmart Codex by semantically rewriting queries.

## 3.9 V1 runtime remains Codex app-server

Continue using:

```text
Bridge Coup
   ↓
Codex app-server
   ↓
ChatGPT-authenticated Codex model + Codex harness
```

Use Codex's native agent loop rather than building a second generic model/tool loop in the application.

Agents SDK / Agents API remain possible future runtime adapters, not current dependencies.

## 3.10 Current DDS integration is retained

The repository already contains a real DDS 3.0 integration. Do not replace it.

Extend the layer above it to support shared sampled worlds, qualified candidate evidence, evidence lineage, and later batching/persistence only if benchmarks justify it.

## 3.11 One primary Codex reasoner in V1

V1 uses one primary Codex reasoner.

Do not add a second LLM merely to translate Codex questions into tools. Reconsider a specialist only if evaluation reveals a genuinely separable reasoning task that cannot be handled cleanly by the primary Codex model plus explicit Engine capabilities and authorized resource access.

## 3.12 Bridge Coup 2.0 is an in-App product milestone

Bridge Coup 2.0 must include the agreed in-App expert capabilities: bidding, declarer play, defense, continuous play, teaching/explanation, review, evidence boundaries, and the agreed knowledge/evaluation infrastructure.

Xinrui / external computer-use integration remains an important later Bridge Expert integration milestone but does not block Bridge Coup 2.0 release.

# 4. Core architecture principles

## 4.1 Program owns invariants; model owns judgment

Program-owned invariants include authoritative state, visibility, legality, immutable snapshot identity, session/resource binding, Engine computation semantics, evidence identity/lineage, stale-state handling, access boundaries, budgets, cancellation, and exactly-once executable-action behavior.

Model-owned judgment includes strategic reasoning, hypothesis formation, bridge-problem decomposition, deciding which registered capability or resource to use, refining retrieval queries, interpreting evidence, deciding whether more evidence is useful, planning/replanning, teaching, and final bridge judgment.

The central rule is:

> **Program owns invariants; model owns judgment.**

## 4.2 The three Bridge Expert blocks support Codex; they do not reason for it

`Declaration`, `Tool Registration`, and `Runtime / Resources / Evidence` exist to make Codex's reasoning correctly contextualized, capable, bounded, and auditable.

They must not become a second strategic planner, an intelligent semantic broker, or a fixed workflow engine.

In particular, deterministic Swift code should not accept vague bridge prose such as “compare these two plans” and guess what computation Codex really intended. Codex should decompose the strategic question and call a capability whose computational meaning is explicit.

## 4.3 BridgeEngine organization and Codex tool exposure are different concerns

BridgeEngine owns computational components and semantics.

Tool Registration decides which useful analytical capabilities are callable by Codex for a given run mode.

A tool may expose one Engine capability or a stable composition of several Engine components. That does not redefine the Engine's architecture.

## 4.4 Broad capability exposure is the default, not unrestricted internals

Expose stable, meaningful analytical capabilities broadly enough that Codex can choose its own analysis path.

Do not expose implementation plumbing merely because a method exists.

Good reasons to keep something internal include:

- it exists only to implement a higher-level operation;
- independent invocation has no clear analytical semantics;
- it would allow mutation of program-owned baseline state;
- it would bypass visibility, scenario, evidence, budgeting, or authorization rules;
- it exposes cache/randomness/process-control details with no decision value.

## 4.5 Composite tools are shortcuts, not monopolies

A proven composite capability may encapsulate a common flow such as:

```text
BeliefModel / scenario
      → DealSampleSet
      → DDS
      → candidate aggregation
      → qualified evidence
```

Codex may use that shortcut when appropriate, while still retaining access to useful lower-level analytical capabilities such as inspecting the current belief, checking a scenario, estimating a hidden feature, or inspecting/extending evidence.

## 4.6 Session context is bound by the program, not repeatedly reconstructed by Codex

Codex supplies question-specific parameters.

The DecisionSession supplies authoritative ambient context such as:

- immutable snapshot identity and visible state;
- official decision objective;
- agreement identity/effective material set/version;
- knowledge snapshot/version;
- baseline BeliefModel identity where relevant;
- explicit scenario identity;
- prior PlanState;
- run-mode permissions;
- evidence identity/lineage;
- budget/cancellation/staleness state.

No tool call may silently bind a later “current” board state or changed resource version.

## 4.7 Knowledge and agreement search is Codex-owned

When supported safely, `knowledge/` and the session-authorized agreement material should be exposed as scoped read/search resources.

Codex owns query wording, refinement, file selection, and semantic interpretation.

The program owns which material is authoritative/readable, the pinned version, precedence metadata, and access audit.

## 4.8 No standalone reasoning validator

Do not create a general deterministic component whose job is to decide whether Codex's bridge reasoning is strategically correct.

Local checks belong where the program has authority: schema decoding, Engine input invariants, evidence-reference/support matching, resource-version authorization, snapshot freshness, action legality, cancellation, and execution exactly-once behavior.

Strategic correctness remains an eval/postmortem/human-review concern.

## 4.9 WHAT BRIDGE MEANS remains separate from HOW CODEX RUNS

BridgeDomain and BridgeEngine must not require Codex-specific types.

Codex/app-server-specific code may implement Bridge Expert runtime interfaces, but a future runtime transport should be able to reuse the same Domain, Engine, Declaration semantics, tool contracts, and evidence rules.

## 4.10 Diagram and vocabulary discipline

Canonical architecture diagrams in this spec use the terms defined in Section 3.3.

A later sequence diagram may show runtime order, and a repository diagram may show physical modules, but neither may silently introduce a competing architecture vocabulary.

If implementation chooses a different class/file name, that is allowed. If it changes responsibility ownership, that requires an explicit spec revision.

# 5. Canonical architecture diagrams

This section is the visual source of truth for the architecture. Later diagrams may show a workflow or repository layout, but they must not redefine these responsibilities.

## 5.1 Expected whole-project architecture

This diagram is the canonical **project mental map**: it shows the architectural pieces we currently expect to exist and the responsibilities we have already agreed. It deliberately stops before per-file implementation details.

```text
bridge-coup
│
├── Bridge App
│   │
│   ├── BridgeTeacherCore
│   │     existing reusable application/core behavior during migration
│   │
│   └── BridgeTeacherMac
│         UI / application composition
│         Codex app-server runtime integration
│
├── Bridge Platform Core
│   │
│   ├── BridgeDomain
│   │   ├── bridge primitives / values
│   │   ├── authoritative facts / events / auction / play state
│   │   └── decision perspective / visibility / snapshots / input status
│   │
│   ├── BridgeEngine
│   │   ├── rules / legality
│   │   ├── constraints / BeliefModel / scenarios
│   │   ├── DealSampler / DealSampleSet
│   │   ├── DDS
│   │   ├── scoring / DecisionObjective
│   │   ├── candidate / action evaluation
│   │   ├── hidden-feature / distribution analysis where implemented
│   │   └── diagnostics / statistical semantics / deterministic caching
│   │
│   └── BridgeExpert
│       ├── Codex
│       │     reasoning brain
│       ├── Declaration
│       │     frozen request / decision / access contract
│       ├── Tool Registration
│       │     Engine capabilities + authorized resource surfaces
│       └── Runtime / Resources / Evidence
│             run control + pinned resources + EvidenceLedger + trace
│
├── Bridge Assets
│   ├── agreements/
│   │     versioned authoritative methods + supplements / overrides / precedence
│   ├── knowledge/
│   │     curated bridge concepts / techniques + provenance
│   ├── experience/
│   │     episodes / postmortems / candidate lessons; isolated from blind play
│   └── evals/
│         development / holdout / rubrics; isolated from production decisions
│
├── Native
│   └── DDSHelper
│         native DDS backend used by BridgeEngine
│
└── Engineering Support
    ├── Tests
    ├── Scripts
    ├── AppResources
    └── docs
```

This is **not** a promise that every box becomes one Swift target or that the physical folder tree will match the diagram one-for-one. If implementation evidence supports a cleaner physical organization, the code layout may change. The architectural responsibilities and information boundaries should not drift silently merely because files are rearranged.

BridgeDomain, BridgeEngine, and BridgeExpert are peer platform-core responsibilities. BridgeExpert does not contain BridgeEngine or BridgeDomain; it consumes their types/capabilities through explicit contracts. `agreements/`, `knowledge/`, `experience/`, and `evals/` are versioned asset domains with different access rules, not generic files that every runtime may read.

## 5.2 Bridge Expert internal map

```text
┌──────────────────────────────────────────────────────────────┐
│                        Bridge Expert                         │
│                                                              │
│  ┌─────────────────────┐       ┌──────────────────────────┐  │
│  │     Declaration     │       │          Codex           │  │
│  │ snapshot / goal     │──────►│ reasoning / decomposition│  │
│  │ mode / objective    │       │ tool & search choice     │  │
│  │ output/evidence req │       │ interpretation / stopping│  │
│  │ prior plan          │       └────────────┬─────────────┘  │
│  └─────────────────────┘                    │                │
│                                             ▼                │
│  ┌─────────────────────┐       ┌──────────────────────────┐  │
│  │  Tool Registration  │◄─────►│ Runtime / Resources /   │  │
│  │ Engine capabilities │       │ Evidence                │  │
│  │ composite shortcuts │       │ budgets / cancellation  │  │
│  │ scoped read/search  │       │ pinned resources        │  │
│  └─────────────────────┘       │ EvidenceLedger / trace  │  │
│                                └──────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

A `DecisionSession` is the concrete runtime instance connecting these blocks for **one user/product request**, bound to one immutable snapshot. Multiple related DecisionSessions may share the same snapshot. `DecisionSession` is not a fourth peer architecture block.

## 5.3 BridgeEngine component map

BridgeEngine remains component-based. The following is a **common computation relationship**, not a mandatory workflow and not a three-layer taxonomy:

```text
                      rules / legality
                           │
                           ▼
visible state ──► constraints / BeliefModel ◄── explicit scenario
                           │
                           ▼
                     DealSampler
                           │
                           ▼
                    DealSampleSet
                           │
               ┌───────────┴───────────┐
               ▼                       ▼
              DDS               scoring / objective
               │                       │
               └───────────┬───────────┘
                           ▼
                 CandidateEvaluator
                           │
                           ▼
                qualified Engine result
                  + diagnostics/limits
```

Other supported computations, such as exact combinatorics, hidden-feature estimation, or future bidding/contract analysis, may use a different subset/order of Engine components.

The key invariant is component ownership and evidence semantics, not one universal pipeline.

## 5.4 Decision-time loop

```text
create DecisionSession from frozen Declaration
        ↓
Codex receives authorized context + registered capabilities
        ↓
Codex reasons
        ↓
zero / one / many:
    Engine tool call
    or agreement/knowledge search/read
        ↓
Runtime / Resources / Evidence records observable activity
        ↓
Codex decides whether more work is useful
        ↓
structured BridgeExpertResult
        ↓
application checks freshness / legality if executable
```

Postmortem truth, raw experience, and eval-answer material remain outside ordinary blind-decision access.

# 6. Responsibility boundary

## Codex must own

Codex should primarily perform:

- strategic bridge reasoning;
- identifying decision-critical uncertainty;
- decomposing a strategic problem into explicit questions that available Engine capabilities or resource search/read can answer;
- choosing which registered tool to call next;
- choosing and refining knowledge/agreement search terms;
- deciding which retrieved material is relevant and how it applies;
- hypothesis generation and retractable soft inference proposals;
- candidate/action generation;
- planning and replanning;
- deciding whether more evidence is likely to change the judgment;
- qualitative tradeoff reasoning;
- interpreting Engine evidence and its stated limitations;
- teaching, uncertainty expression, and postmortem explanation;
- final strategic judgment.

Codex should be made explicitly aware that curated bridge knowledge, current agreement material, and Engine analytical capabilities exist. It should use them when they can materially reduce decision-critical uncertainty rather than relying only on memory, without ritual tool use.

## Declaration must own

Declaration defines the frozen decision/run contract visible to the reasoning system. It includes or resolves the equivalent of:

- immutable `DecisionSnapshot`;
- goal/request intent;
- run mode;
- official `DecisionObjective`;
- output contract;
- evidence requirement;
- prior `PlanState` where applicable **after cross-session inheritance authorization under Section 7.6**;
- authoritative agreement identity/effective material-set identity;
- authorized knowledge snapshot identity;
- capability/resource permissions.

Declaration does not contain strategic conclusions and does not mutate during the DecisionSession.

## Tool Registration must own

Tool Registration defines what Codex can invoke/access for the session:

- stable meaningful BridgeEngine analytical capabilities;
- proven composite convenience capabilities;
- thin transport/schema adapters where required;
- scoped native read/search surfaces for pinned knowledge/agreement material when supported;
- capability metadata/descriptions sufficient for Codex to know what exists and when it is useful.

Tool Registration does **not** invent bridge hypotheses, rewrite search queries, choose the strategic order of calls, or duplicate Engine algorithms.

## Runtime / Resources / Evidence must own

This block owns the mutable operational state around the frozen Declaration:

- DecisionSession lifecycle/status;
- budgets, timeout, cancellation, retries, and stale-session handling;
- binding to pinned agreement and knowledge resource views;
- resource authorization and observable read/search provenance;
- `EvidenceLedger` and analysis lineage;
- preservation of comparable sample/evidence basis across repeated calls;
- `SessionEvent` / trace of observable runtime activity;
- exclusion of eval answers, raw experience, and postmortem truth in blind mode;
- structured handling of tool/resource/runtime failures.

It does not judge bridge strategy.

## BridgeEngine must own

BridgeEngine owns deterministic/statistical bridge computation and supporting semantics, including:

- card identity, uniqueness, hand sizes, turn order, and reusable legality/rules;
- deterministic bridge constraints;
- `BeliefModel` construction from mechanical/authorized inputs;
- explicit scenario representation, consistency checks, and baseline protection;
- deal generation / `DealSampler` / `DealSampleSet` mechanics and diagnostics;
- DDS invocation and DDS-version semantics;
- scoring and `DecisionObjective` calculation semantics;
- hidden-feature/distribution computations where implemented;
- candidate/action evaluation and aggregation;
- sample comparability, weighting/target-distribution semantics, and diagnostics;
- computation-version identities and deterministic caching.

BridgeEngine does not own Codex orchestration or resource search.

## BridgeDomain must own

BridgeDomain owns the shared bridge language/state model: cards, suits, seats, hands, calls, auction, contract, vulnerability, actions, facts/events, decision perspective, visible state, snapshots, input status, objective types, agreement references/snapshots, and other domain values.

Domain may contain small intrinsic deterministic logic, but not sampling, DDS, LLM orchestration, or document retrieval.

## Agreements, Knowledge, Experience, and Evals

- Agreement identity/effective material set is authoritative configuration; detailed content is read/interpreted by Codex from the pinned authorized view.
- Knowledge is curated external bridge memory; Codex decides when/how to search/read it.
- Raw experience is not available to ordinary blind decisions; postmortem/learning modes may read authorized experience and produce structured learning artifacts.
- Eval answers are never an ordinary production decision-time source.

## Local boundary checks, not a standalone Validator

Do not create a general `Validator` component that attempts to prove Codex reasoning correct.

Checks occur at the boundary that can determine them, for example:

- JSON/tool schema decoding at transport/adapters;
- Engine input invariants inside Engine;
- scenario representability/mechanical consistency inside Engine;
- resource-version authorization before read/search;
- evidence ID existence and support-tuple matching in evidence bookkeeping;
- snapshot freshness and legality immediately before an executable action;
- output-schema decoding at the product/runtime boundary;
- cancellation/budget state in DecisionSession runtime.

Strategic explanation correctness, plan quality, and bridge judgment remain evaluation concerns.

## Hybrid responsibilities

### Hidden-hand inference

Codex decides which soft inference is worth investigating. It may keep an inference as commentary, revise/withdraw it, or submit an explicit typed scenario/condition for Engine analysis.

Engine checks only what it can determine mechanically: representability, consistency with authorized facts/hard constraints, feasible-set validity, and support for the requested computation.

A model inference does not become a mechanical fact merely because model confidence is high.

### Candidate generation

Codex proposes strategically meaningful candidate actions. Programmatic bridge rules remove illegal/duplicate actions where needed; Engine tools may compare precisely defined legal actions.

Do not expose a vague `compare_two_lines` capability until a machine-checkable conditional-line object and information-respecting evaluation semantics exist.

### Decision evaluation

Engine computes and labels objective evidence. Codex interprets that evidence and may disagree with a top computational ranking when it has a concrete reason. Differently conditioned/scored evidence must not be treated as directly comparable without acknowledging the difference.

# 7. DecisionSession and model-led capability loop

One **user/product request** defines one `DecisionSession`.

A DecisionSession is bound to exactly one immutable `DecisionSnapshot`, one frozen Declaration, one authorized Tool Registration/resource view, and one run budget/status lifecycle. The same snapshot may support multiple related DecisionSessions—for example an initial plan request followed by a separate request that asks for a different output contract or requires additional Engine evidence.

A single DecisionSession may contain many Codex reasoning turns, Engine tool calls, and resource searches/reads while handling that one request. It does **not** absorb later user/product requests merely because the board snapshot is unchanged.

Conceptually:

```text
DecisionSnapshot S42
    ├── DecisionSession A: "give me a declarer plan"
    ├── DecisionSession B: "compare these current cards with Engine evidence"
    └── DecisionSession C: "explain why line X is inferior"
```

Each session has its own Declaration, budgets, status, result contract, evidence requirement, and observable run history. Related sessions may explicitly reference safe prior artifacts after inheritance checks; they do not share authority implicitly through thread memory.

## 7.1 Lifecycle

```text
App receives one user/product request against immutable DecisionSnapshot
        ↓
Bridge Expert resolves/finalizes one Declaration
        ↓
create fresh DecisionSession
        ↓
pin resource versions + permissions + Tool Registration + budgets
        ↓
Codex receives authorized context + capability/resource descriptions
        ↓
Codex reasons
        ↓
zero / one / many within this request:
    registered Engine tool
    and/or scoped agreement/knowledge read/search
        ↓
Runtime / Resources / Evidence records result/provenance/lineage
        ↓
Codex decides whether more work is useful
        ↓
structured BridgeExpertResult
        ↓
session enters a terminal delivery state
```

The loop may contain **zero, one, or many** tool/resource operations.

## 7.2 Stopping

Codex decides when remaining uncertainty is unlikely to change its recommendation.

Program-owned runtime sets hard ceilings such as wall time, tool-call count, Engine compute budget, sampling budget, resource-read budget, and cancellation state.

When a budget is exhausted, the session must produce a clearly qualified incomplete result or fail; it must not pretend missing evidence/material was obtained.

## 7.3 Zero-computation answers

Zero Engine calls are allowed.

A model-only answer is valid when the Declaration's evidence requirement permits it. Provenance must remain distinguishable from Engine-supported evidence.

If the product/user explicitly requires Engine evidence, Codex may not lower that requirement simply because it prefers to stop early.

## 7.4 Follow-up requests and terminal sessions

A follow-up user/product request creates a **new DecisionSession**, even when it targets the same immutable snapshot.

The new session may identify a prior session as related/parent context and may request explicit inheritance of safe artifacts, but it receives its own:

```text
goal / request identity
output contract
evidence requirement
budgets
status / cancellation lifecycle
final result
```

A completed, cancelled, timed-out, failed, or stale session is never "reopened" into an executable run. A new request creates a new session.

Whether the Codex runtime reuses an underlying conversation/thread is an implementation choice. Thread reuse never grants authority to unstated prior content and never replaces explicit cross-session artifact checks.

## 7.5 State, objective, or authoritative-resource change

A DecisionSession is bound to one immutable snapshot and one pinned authoritative resource configuration.

Decision-relevant board-state change creates a new snapshot and therefore any new executable request uses a new session.

A formal change to the official objective, agreement effective material set, knowledge snapshot, or run-mode permission that changes decision semantics also requires a new session/configuration identity.

Public state should be re-projected from the authoritative board record rather than copied from old free-form conversation summaries.

## 7.6 Cross-session continuity and inheritance authorization

Continuity is explicit, not conversational.

Any inherited `PlanState`, evidence reference, explanation/summary, or other decision artifact must retain enough provenance to determine whether it is legal in the target session. The exact storage schema is not frozen, but the system must be able to recover the equivalent of:

```text
source session / snapshot
source decision perspective
source decision controller / action seat where relevant
visibility basis / effective information time
assumptions / scenario / objective relevant to the artifact
authorized public-vs-private inputs used to create it
```

The program must reject or safely re-project inheritance that would reveal information unavailable in the target session.

Required examples:

- a defensive plan created for East using East's private hand must not automatically enter West's later defensive session;
- declarer continuity from declarer's own hand to dummy play is allowed when the same `decisionController` remains authorized to see both relevant hands at the target snapshot;
- after play advances, prior public information may remain usable, but newly visible information must come from the new authoritative snapshot rather than from an unrestricted old summary;
- after undo/redo to an earlier information time, artifacts that depend on later-revealed cards, later public events, or later private context must not be inherited merely because they belong to the same board;
- evidence may be referenced only when its inputs, perspective/visibility basis, scenario, temporal semantics, and objective remain authorized and meaningful for the target session.

When a free-form artifact cannot be safely decomposed into public and private contributions, default to the source artifact's full visibility restriction rather than assuming it is safe to share more broadly.

Correctness must never depend on a long-lived Codex thread remembering unstated prior state or privately learned information.

# 8. Codex app-server runtime strategy

Use Codex app-server as the **native reasoning harness and transport**, not as the authoritative bridge runtime.

The application should not build a second generic `while tool_call` agent framework around Codex. Bridge Expert declares the run, registers bridge-specific capabilities/resources, and owns runtime/resource/evidence invariants while Codex's own harness controls the reasoning/tool loop.

## 8.1 Transport-independent Tool Registration

Tool Registration is semantically independent of transport.

Conceptually:

```text
Bridge Expert Tool Registration
        │
        ├─ app-server dynamic-tool adapter
        ├─ local MCP adapter, if needed
        └─ in-process/test adapter
```

The same Engine capability semantics and session envelope should survive transport changes.

## 8.2 Existing client gap

The current `CodexJSONRPCClient` handles client-originated requests and server notifications but rejects server-originated JSON-RPC requests. If app-server dynamic tools are used, Milestone 0 must implement/prove bidirectional request handling, tool-call lifecycle, cancellation, late-result rejection, and typed result return.

This is an implementation spike, not an architectural reason to restore application-controlled fixed reasoning passes.

## 8.3 Scoped native read/search spike

Milestone 0 must test whether the actual Codex/app-server runtime can expose **only** the authorized, version-pinned agreement and knowledge views while preserving observable search/read provenance.

Requirements include:

- no traversal into eval answers, raw experience, postmortem truth, unrelated repo files, or alternate mounts;
- no resolution against a newer backing-file version than the session declared;
- search/read events observable enough for session audit/eval;
- normal Codex query refinement remains available.

If native access cannot satisfy these invariants, use the thinnest scoped fallback that can. Do not add retrieval intelligence merely because a wrapper is required for safety.

## 8.4 Decision / analysis run

A blind Bridge Expert run should:

- create a fresh DecisionSession bound to one immutable snapshot and one frozen Declaration;
- register only capabilities/resources permitted by the run mode;
- expose no postmortem truth, raw experience, or eval-answer surface;
- allow Codex to perform zero or more Engine tool calls and authorized resource reads/searches;
- preserve evidence/resource provenance in Runtime / Resources / Evidence;
- end with structured output satisfying the declared output/evidence contract.

## 8.5 Screenshot recognition run

Preserve existing strong isolation. It extracts candidate facts from an image and has no bridge-decision role.

## 8.6 Teaching / follow-up

Each new user/product follow-up creates a new related `DecisionSession`, even when the immutable snapshot is unchanged. The follow-up may explicitly inherit authorized prior artifacts under Section 7.6. Conversation/thread history is not authoritative state, and a completed/cancelled/timed-out session is never reopened merely to answer the follow-up. Runtime thread reuse is optional and must not bypass session identity, budget, evidence, or visibility rules.

## 8.7 Postmortem / learning run

Use a separate authorized context after the relevant decision/board is finished. It may receive full hidden hands, actual outcome, prior session trace/evidence, and authorized experience. It must never be reused as a blind context for the same decision.

Learning writes must remain structured: episode metadata, annotations, candidate lessons, validation status, etc. Do not grant arbitrary filesystem mutation as the learning architecture.

## 8.8 Progressive disclosure

Progressive/deferred capability disclosure may be used if evaluation shows it improves model behavior and the runtime supports reliable semantics.

It is an optimization, not an architecture invariant. A simple V1 may register all useful capabilities if the catalog remains manageable.

## 8.9 Runtime isolation must be tested, not assumed

Create negative tests using sentinel content and attempts through workspace files, built-in tools, inherited configuration, plugins/MCPs, old thread context, retrieval, cached summaries, raw experience, and evaluation-answer files.

The acceptance criterion is that forbidden information is unavailable to the blind DecisionSession while required Engine/resource capabilities still work.

# 9. Domain state and input model

Do not simply rename `DeclarerPlanDraft`.

The domain must support bidding, declarer, defense, partial information, continuous play, and review while maintaining one authoritative accepted fact/event entry point.

The input model must distinguish at least:

```text
confirmed visible fact
confirmed but not yet visible fact
true hidden bridge information
missing App input
unconfirmed recognition candidate
contradictory input
user-provided conditional assumption
postmortem truth
```

These states have different consequences. In particular, a missing card from the player's own hand is not ordinary hidden information and must not be silently filled by sampling.

# 10. Canonical bridge record

Introduce an authoritative board representation based on accepted facts and events.

Possible conceptual structure:

```swift
struct BridgeBoardRecord {
    let boardID: UUID
    let version: Int
    let dealer: Seat?
    let vulnerability: Vulnerability?
    let scoring: ScoringContext
    let auction: AuctionRecord
    let contract: Contract?
    let cardEvents: [CardPlayEvent]
    let facts: [BridgeFact]
    let agreementReference: AgreementReference?
}

struct BridgeFact {
    let payload: BridgeFactPayload
    let provenance: FactProvenance
    let confirmation: ConfirmationStatus
    let visibleTo: VisibilityAudience
    let visibleFrom: VisibilityPoint
}
```

The exact Swift shape should be repo-grounded before implementation, but the semantic rule is fixed:

> **The application has one accepted fact/event entry point; other state objects are projections, snapshots, simulations, or adapters rather than competing mutable truths.**

A stored fact does not automatically become decision-visible merely because it exists.

# 11. Separate postmortem truth

If Bridge Coup possesses complete hidden hands or other truth after the fact, store or expose it behind a separate access boundary.

```text
Decision-visible records
≠
Postmortem truth
```

Recommended logical distinction:

```swift
DecisionFactStore
PostmortemTruthStore
```

During a blind decision run, the reasoner, sampler, evaluator, retrieval, summaries, and caches may receive only information valid for that decision perspective and visibility time.

Decision traces should reference postmortem truth by identifier rather than embedding future truth directly into the blind-decision record.

# 12. DecisionSnapshot

Every actual expert recommendation must be based on an immutable snapshot.

```swift
struct DecisionSnapshot {
    let snapshotID: UUID
    let boardID: UUID
    let boardVersion: Int
    let phase: BridgePhase
    let actionSeat: Seat
    let decisionController: Seat
    let perspective: DecisionPerspective
    let visibleState: VisibleState
    let scoring: ScoringContext
    let objective: DecisionObjective
    let agreements: AgreementSnapshot
    let inputStatus: DecisionInputStatus
    let legalActions: [BridgeAction]
}
```

`actionSeat` is the seat whose card/call is taken. `decisionController` is the player who controls the decision; these differ when declarer plays from dummy.

`DecisionInputStatus` must distinguish sufficient input from missing, unconfirmed, contradictory, or only-conditionally-specified input.

Once created, the snapshot must not mutate. If accepted board state or decision-relevant configuration changes, create a new snapshot and make the old result non-executable.

# 13. DecisionPerspective and VisibleState

Refine the earlier `PlayerView` concept so “who owns the action”, “who decides”, and “what is visible now” are not conflated.

```swift
struct DecisionPerspective {
    let decisionController: Seat
    let actionSeat: Seat
    let phase: BridgePhase
}

struct VisibleState {
    let ownOrControlledHands: [Seat: PartialHand]
    let dummy: VisibleDummyState?
    let auction: AuctionRecord
    let publicExplanations: [AuctionExplanation]
    let contract: Contract?
    let publicPlayHistory: [CardPlayEvent]
    let currentTrick: TrickState
    let knownVoids: [Seat: Set<Suit>]
    let agreements: AgreementSnapshot
    let scoreContext: ScoringContext
}
```

Rules:

- before dummy is exposed, declarer does not receive dummy merely because the App knows it;
- when declarer plays from dummy, `actionSeat` is dummy but `decisionController` is declarer;
- a defender never receives partner's hidden hand in a blind decision;
- bidding sees own hand, public auction/explanations, scoring context, and permitted agreement information;
- `PartialHand` must distinguish hidden/unknown information from App input that should have been known but is missing;
- the LLM should reason from the structured visible projection rather than reconstructed conversation prose wherever practical.

## 13.1 Temporal reference for hand-derived constraints and features

Bridge constraints/features that describe a hand must be unambiguous about **which information time the statement refers to**.

At minimum, the semantics must distinguish concepts equivalent to:

```text
original deal / original holding
    the cards or derived hand features at the start of the deal

current snapshot / remaining holding
    the cards or derived features still held at the current DecisionSnapshot

specified public event / historical snapshot
    the holding or feature value at an explicitly identified earlier/later public decision point
```

The exact type/API name is not frozen. The semantic distinction is.

Examples that must not be conflated:

```text
West originally held 5+ hearts
≠
West currently has 5+ hearts remaining

West original HCP
≠
HCP represented by cards still remaining now

West was void in clubs at public event E
≠
West was originally void in clubs
```

Public play history lets the program mechanically translate between an original complete-world holding and the remaining holding at a later snapshot. Codex should not have to repair this ambiguity in prose on every tool call.

Consequences:

- constraints/scenarios must preserve their temporal reference;
- feature-estimation tools must make the temporal meaning explicit in the feature type or parameter contract;
- sampling must interpret original-holding constraints against the original complete deal even after cards have been played;
- current-remaining constraints must apply after subtracting publicly played cards at the target snapshot;
- evidence records/replay must preserve the temporal semantics of the analyzed feature/condition;
- no ambiguous default such as bare `suitLength(West, hearts)` is acceptable unless the capability contract defines exactly one unambiguous meaning.

# 14. BeliefModel and DealSampleSet

Do not make one object simultaneously mean “what we believe” and “the sampled deals generated in one computation”.

## BeliefModel

Represents what the system knows, assumes, or is testing about hidden information.

```swift
struct BeliefModel {
    let hardConstraints: [BridgeConstraint]
    let scenarioAssumptions: [ScenarioAssumption]
    let inferenceMetadata: [InferenceRecord]
    let version: BeliefModelVersion
}
```

V1 baseline belief should primarily use mechanical/deterministic constraints. Important semantic inferences can be represented as explicit scenarios without pretending they are calibrated posterior probabilities.

## DealSampleSet

Represents one concrete sampling computation.

```swift
struct DealSampleSet {
    let beliefModelVersion: BeliefModelVersion
    let configuration: SamplingConfiguration
    let targetDistribution: SamplingDistribution
    let seed: UInt64
    let deals: [WeightedDeal]
    let diagnostics: SamplingDiagnostics
    let samplerVersion: String
}
```

The same `BeliefModel` may produce different sample sizes, baseline/scenario-conditioned sets, future weighted samples, or samples from different sampler implementations.

A `DealSampleSet` is a computational artifact, not the belief itself.

# 15. Constraint taxonomy

## Hard mechanical constraints

Examples include card uniqueness, hand sizes, played-card exclusion, known voids from failure to follow suit, and public bidding/play legality. These are program-owned. Any hand-composition/shape/HCP/suit-length constraint must preserve the temporal reference defined in Section 13.1 rather than silently switching between original and remaining holdings.

## Explicit agreement semantics

Examples include our 1NT range, opponent public explanations, and our carding agreements. These come from versioned agreement/explanation data, not generic model memory.

Agreement meaning and actual holding inference remain separate: a convention describes intended meaning, not proof of the exact holding.

## Soft bridge inference / scenarios

Examples include opening-lead interpretation, approximate suit length from auction, signal interpretation, or honor-location likelihood.

Each model-proposed inference must include:

```text
claim
basis / evidence
scope
strength category
withdrawal condition
```

V1 must not turn soft inference into a hard filter solely because the model reports high confidence.

# 16. InferenceProposal

The LLM should not directly edit `BeliefModel`.

```swift
struct InferenceProposal {
    let targetSeat: Seat
    let dimension: InferenceDimension
    let claim: ConstraintExpression
    let evidence: [EvidenceReference]
    let scope: InferenceScope
    let rationale: String
    let withdrawalCondition: String?
}
```

Codex owns the strategic decision to investigate an inference. It may keep an inference as commentary, explicitly request a scenario conditioned on it, revise it, or withdraw it.

BridgeEngine does **not** judge whether an inference is persuasive bridge reasoning or “worth promoting.” When Codex submits an explicit typed scenario/condition, Engine may only perform program-owned checks such as:

- whether the condition is representable by the supported constraint/scenario model;
- whether it is mechanically consistent with the authorized visible facts and existing hard constraints;
- whether the requested analysis is supported;
- whether the condition would make the feasible deal set empty or otherwise invalidate the computation.

Engine then computes the requested scenario or returns a typed inconsistency/unsupported error. A future calibrated weighting model may map explicitly supported evidence into weights, but that is a separate Engine capability rather than an automatic promotion of model confidence.

Internal consistency proves only that an inferred world is possible; it does not prove the inference is correct.

The session/evidence layer should also detect repeated use of the same evidence so one fact is not accidentally counted multiple times as independent support.

# 17. Deal Sampler

The sampler is a first-class Bridge Engine component.

```swift
protocol DealSampling {
    func sample(
        visibleState: VisibleState,
        belief: BeliefModel,
        scenario: ScenarioID?,
        configuration: SamplingConfiguration
    ) throws -> DealSampleSet
}
```

V1 sampler goals:

- complete genuinely unknown hidden hands;
- never invent information that the decision controller should know but the App failed to capture;
- obey hard card, hand-size, void, shape, HCP, and specific-card constraints using their declared temporal semantics;
- support reproducible random seeds for sampler replay;
- detect impossible constraint sets;
- distinguish “constraints proven contradictory” from “sampling budget exhausted without finding a sample”;
- produce useful diagnostics.

Do not optimize prematurely. A basic constrained/rejection sampler is acceptable initially if it supports the first vertical evaluation workload.

## 17.1 V1 baseline target distribution

A sampler must define not only **which complete hidden deals are feasible**, but also **the target distribution over those feasible deals**.

For V1, the baseline target is:

> **Uniform over complete hidden-card assignments that satisfy the baseline `BeliefModel` hard/mechanical constraints and the authorized visible state.**

Complete feasible deal assignments are the elementary outcomes of this baseline model. This does **not** mean that suit shapes, HCP buckets, or other derived features are uniformly distributed.

For an explicit scenario that adds a supported condition, the default V1 target is uniform over complete deals satisfying:

```text
baseline hard/mechanical constraints
+
explicit scenario condition
```

unless a different distribution is explicitly selected and documented.

Agreement semantics, auction interpretation, opening-lead interpretation, signals, model confidence, or other soft bridge inference do not silently change the baseline probability measure. They affect computation only when represented by an explicitly supported baseline rule, an explicit scenario, or a future calibrated weighting model.

If a sampling implementation uses a constructive proposal process that is not itself uniform over the declared target distribution, it must either:

- correct the proposal bias with valid weights / importance correction; or
- declare a different target distribution and expose that semantic difference in the result.

Sampling outputs and percentage estimates must identify the target distribution. They are estimates **under that model**, not automatically calibrated real-world posterior probabilities.

# 18. Sampler diagnostics

Every evaluation should expose enough information to judge sample quality.

Return information such as:

```text
requested samples
generated samples
attempt count / rejection count
constraint conflicts
sampling-budget exhaustion
effective sample size where weighting exists
weight concentration where weighting exists
scenario identifier
target distribution / weighting semantics
seed
sampler version
```

Do not use unique-deal count as a universal reliability metric; whether duplicate samples are problematic depends on the sampling algorithm and target distribution.

If only a very small or biased sample survives, the system must not report apparently precise percentages without qualification.

# 19. Soft inference, scenarios, and future weighting

V1 should use a conservative inference model.

```text
BeliefModel baseline
= mechanical facts + explicit hard constraints
target distribution
= uniform over complete deals satisfying that baseline, unless an explicitly versioned alternative model is selected
```

For important uncertain inferences, prefer scenario-conditioned sensitivity analysis:

```text
Baseline result
Scenario A: if West has 5+ hearts
Scenario B: if East holds the missing honor
```

This avoids circular confirmation where the model guesses X, the sampler keeps only X worlds, DDS prefers an action inside X worlds, and the system then claims DDS validated X.

Later versions may approximate `P(deal | auction, play, signal, tendencies)` with calibrated weighting. Do not put uncalibrated arbitrary numeric model weights on the V1 critical path.

# 20. Existing DDS abstraction

Preserve the current `DoubleDummySolving` functionality.

The current helper already calls DDS `SolveBoard` and returns legal moves/equivalent-card information for one complete sampled world. Therefore, first exploit one solve per complete position rather than assuming a separate solve per candidate card.

A future `DoubleDummyBatchSolving` interface may be added if whole-decision benchmarks justify it. Initial sampled evaluation may loop over the existing solver.

Only introduce a persistent helper or DDS batch API after measurement shows material process-spawn or throughput cost.

# 21. Candidate Evaluator

The reasoner should not manually aggregate hundreds of DDS outputs.

```swift
protocol CandidateEvaluating {
    func evaluate(
        snapshot: DecisionSnapshot,
        candidates: [BridgeAction],
        samples: DealSampleSet,
        objective: DecisionObjective
    ) async throws -> CandidateEvaluationSet
}
```

All candidates for one decision should use a **comparable shared sample set** whenever possible.

Conceptually:

```text
one sampled complete world
      ↓
DDS once for current position
      ↓
values for legal candidate moves

repeat over the same DealSampleSet
      ↓
aggregate candidate evidence
```

Solver failures and candidate/sample coverage must be recorded rather than silently dropped.

## Evidence semantics

Sampled DDS is not a proof of the best real-world imperfect-information policy. DDS sees the complete sampled deal and may choose future actions with information the real player will not possess, creating strategy-fusion/future-information bias.

Therefore:

- DDS aggregation is **decision evidence under an explicit double-dummy continuation assumption**;
- a next-card comparison does not prove an entire declarer/defensive plan;
- the final explanation should expose important later choices that still depend on hidden information;
- targeted evals should determine whether more sophisticated imperfect-information search is needed later.

# 22. CandidateEvaluation

Possible structure:

```swift
struct CandidateEvaluation {
    let action: BridgeAction
    let sampleCount: Int
    let coveredSampleCount: Int
    let expectedDeclarerTricksUnderDD: Double?
    let sampledDoubleDummyMakeFraction: Double?
    let expectedDuplicateScoreUnderDD: Double?
    let doubleDummyResultDistribution: [ContractDelta: Double]
    let pairwiseSwing: [ActionID: SwingEstimate]
    let continuationAssumption: ContinuationAssumption
    let diagnostics: EvaluationDiagnostics
}
```

Avoid bare names such as `makeProbability` when the metric is only the fraction of sampled deals that are makeable under double-dummy continuation.

The UI and final explanation should preserve the same distinction. Do not report false precision when sample quality or scenario assumptions are weak.

# 23. IMP semantics and DecisionObjective

Without a known comparison result or a model of the comparison distribution, absolute expected IMP is not directly defined.

Introduce an explicit `DecisionObjective` that records at least:

```text
beneficiary / side
primary metric
comparison reference if any
fallback objective
sign convention
```

V1 should prefer well-defined quantities such as sampled DD contract-make fraction, expected duplicate score under stated assumptions, expected tricks under stated assumptions, contract-delta distributions, and pairwise score/IMP swings against a defined reference.

Do not create mathematically misleading “expected IMP” numbers merely because the event is scored at IMPs. Declarer and defense must not accidentally optimize metrics with opposite sign conventions.

# 24. Matchpoint semantics

True expected matchpoints require a field / score distribution model.

V1 may initially provide score distributions under stated continuation assumptions, overtrick distributions, probabilities of exceeding explicit thresholds, and candidate-to-candidate duplicate-score comparisons.

Full field MP expectation must remain explicitly unsupported until a field model exists. `DecisionObjective` must say which fallback objective is being used.

# 25. Play decision and analysis lifecycle

Declarer and defense share one BridgeEngine and the same model-led Bridge Expert architecture.

There is no single mandatory sequence such as “generate candidates, sample, evaluate, synthesize” for every request.

Typical lifecycle:

```text
1. accept/rebuild authoritative board state
2. create immutable DecisionSnapshot
3. construct DecisionPerspective + VisibleState
4. verify input sufficiency and legal action set
5. resolve the Bridge Expert Declaration and create the DecisionSession
6. Codex reasons about objective, threats, plan, candidate actions, and uncertainty
7. Codex may decompose an uncertainty into one or more explicit Engine calls and/or scoped agreement/knowledge searches
8. Bridge Expert binds the frozen session context/permissions; thin adapters route Engine calls while native scoped read/search resolves only against pinned authorized resources
9. session evidence/history records Engine results, resource accesses, assumptions, sample basis, versions, and limitations
10. Codex receives the result/material and either investigates further or finalizes
11. if a final result contains an executable action, the application checks freshness/action legality at execution time
12. persist/derive the session trace and any durable DecisionTrace
```

Engine use is optional unless the request's evidence requirement says otherwise.

An Engine computation or authorized knowledge/agreement search/read is not itself a new workflow. It is a Codex-chosen capability inside the same model-led reasoning session.

Do not create a vague tool that accepts an arbitrary multi-step “line” unless a precise line/plan representation and evaluation semantics have been defined.

## Lightweight PlanState

Continuous play needs more than `plan: String` but does not require a full policy tree in V1.

```swift
struct PlanState {
    let objective: String
    let immediateAction: BridgeAction?
    let keyNextSteps: [PlannedStep]
    let observableBranches: [ObservableBranch]
    let replanTriggers: [ReplanTrigger]
    let validationScope: PlanValidationScope
}
```

Branch conditions must depend on information the player can observe when the branch occurs.

Each new decision may retain or revise a previous `PlanState` only after the artifact is authorized for the target DecisionSession under Section 7.6. Every revision should identify its basis: newly visible legal information, an explicitly revised assumption, newly retrieved relevant knowledge/agreement detail, or new computational evidence/correction derived from the authorized state.

`PlanValidationScope` describes what parts of a plan, if any, received computational support. It does not imply a program can validate the strategic correctness of the entire plan.

# 26. Declarer-specific reasoning

Declarer reasoning should explicitly support concepts such as:

- count winners / losers;
- entries;
- communication;
- danger hand;
- trump management;
- suit establishment;
- avoidance;
- safety play;
- timing;
- transportation;
- ducking;
- hold-up;
- elimination;
- endplay;
- squeeze prerequisites;
- probability vs contract safety;
- IMP vs MP objectives.

These should initially be reasoning expectations, not hundreds of hardcoded rules.

Knowledge cards may later support them.

---

# 27. Defense-specific reasoning

Defense uses the same state / belief / sampling / evaluator infrastructure but different strategic reasoning.

Support:

- opening lead interpretation;
- partnership signals;
- count;
- attitude;
- suit preference;
- declarer distribution inference;
- partner distribution inference;
- active vs passive defense;
- cashing winners;
- avoiding giving declarer tempo;
- forcing declarer;
- trump promotion;
- uppercut;
- communication with partner.

Defense must never receive partner's hidden cards merely because the application knows them postmortem.

---

# 28. Bidding architecture

Bidding shares the domain state, agreement model, and hidden-state infrastructure but should not be forced through the card-play evaluator or a fixed bidding pipeline.

A bidding decision may involve several analysis dimensions:

```text
own hand
auction so far
partnership system / opponent explanations
    ↓
possible needs, chosen by Codex as relevant:
    - interpret one or more calls
    - derive partner/opponent constraints
    - evaluate hand / fit / risk
    - generate candidate calls
    - inspect agreement details
    - sample plausible deals where useful
    - later: evaluate auction continuations
    ↓
recommended call / explanation
```

This diagram describes **available reasoning/evidence dimensions**, not mandatory sequential steps.

Codex owns the strategic decomposition and decides which Engine analytical capabilities and/or scoped agreement searches/reads are useful for the current bidding question.

V1 should support useful bidding recommendations before full continuation simulation exists.

# 29. Partnership and opponent agreement model

A **minimal versioned agreement snapshot belongs in the foundation layer**, because declarer inference and defense already depend on auction meaning, leads, signals, and public explanations.

Conceptually:

```swift
struct AgreementSnapshot {
    let version: AgreementVersion
    let ourPartnership: PartnershipAgreementSet
    let opponentKnownAgreements: OpponentAgreementSet?
    let publicExplanations: [AuctionExplanation]
    let effectiveMaterials: AgreementMaterialSet
    let precedence: AgreementPrecedence
    let unknowns: [AgreementUnknown]
}
```

Exact field names are not frozen. The required semantics are.

The model must distinguish our agreements, opponent agreements we actually know, public alerts/explanations, generic bridge knowledge, and unknown opponent methods.

Do not automatically apply our own system to the opponents.

## 29.1 Mandatory agreement context

Every DecisionSession receives enough agreement identity/version and decision-relevant public explanation context to avoid interpreting the current bridge world from generic model memory alone.

Agreement identity/version is authoritative configuration.

## 29.2 Effective material set and precedence

The session must bind the **complete material set that is authoritative for the current run**, not merely a profile name.

That material set may include:

```text
base convention/system notes
+ partnership addenda
+ seat/vulnerability/competition-specific supplements
+ explicit overrides/exceptions
+ known opponent method material
+ public explanations/alerts
```

The program does not need to understand the natural-language bridge content, but it must know which resources belong to the current version and the precedence/override relationship among them.

For example, if a base note says `1NT = 15–17` and an authoritative supplement says `third seat non-vulnerable = 14–16`, the session must expose both under a deterministic precedence rule rather than leaving Codex to guess which file is authoritative.

Our partnership material, known opponent material, and public explanations remain separately identified.

## 29.3 Native scoped search/read

Large system notes need not be injected in full.

Prefer allowing Codex to use native read/search against the **session-pinned effective agreement material set**. Codex controls search wording, query refinement, which files/clauses to open, and the bridge interpretation.

The program must guarantee:

- reads/searches cannot escape the authorized agreement material set;
- every result corresponds to the session-declared version/material snapshot;
- base/addendum/override provenance and precedence are available to Codex;
- observable searches/reads can be included in the session trace;
- mutable backing files cannot silently switch the session to a newer version.

If native access cannot guarantee this, provide a thin scoped read/search adapter or immutable mounted/materialized view. Do not add a deterministic semantic interpreter merely to mediate file search.

When no authoritative agreement material resolves a question, preserve the state as **unknown/unspecified** rather than silently substituting generic model memory as if it were the partnership agreement.

## 29.4 Agreement meaning is not hidden-card truth

A convention describes intended/public meaning, not proof of exact holding. Agreement access and BridgeEngine must preserve the difference among:

```text
raw auction fact
agreement interpretation
mechanical inference
soft scenario inference
actual hidden holding
```

The current agreement version/material set and relevant read/search provenance must become part of traces and cache/evidence dependencies.

# 30. Bidding V1

Do not attempt full world-class auction rollout immediately.

First bidding milestone:

- legal calls;
- versioned agreement snapshot rather than prompt-only system memory;
- current auction interpretation;
- hand evaluation;
- candidate bid generation;
- explanation of meaning;
- partner constraints;
- opponent constraints without silently assuming our system;
- system consistency;
- qualitative comparison;
- basic deal sampling where useful;
- explicit `DecisionObjective` and scoring context.

Bidding may use a phase-specific planning representation rather than the play-oriented `PlanState`.

# 31. Bidding V2

Introduce candidate continuation evaluation.

Possible future approach:

```text
candidate bid
      ↓
sample plausible partner/opponent hands
      ↓
simulate continuation using bidding policy
      ↓
distribution of final contracts
      ↓
double-dummy contract potential
      ↓
score / risk evaluation
```

This is materially harder than play evaluation.

Do not pretend DDS alone solves bidding.

---

# 32. Bridge Expert request, Declaration, session, and result contract

The public Expert contract should describe the **goal, authoritative decision context, access mode, and delivery requirements**, not prescribe the model's reasoning workflow.

Conceptually:

```swift
struct BridgeExpertRequest {
    let snapshot: DecisionSnapshot
    let goal: String
    let runMode: BridgeRunMode
    let outputContract: BridgeOutputContract
    let evidenceRequirement: EvidenceRequirement
    let priorPlan: PlanState?   // candidate inherited artifact; authorization still required
}
```

The request is resolved by Bridge Expert into the session's **Declaration**. The exact Swift implementation may use `BridgeExpertRequest`, `BridgeExpertDeclaration`, or another type split; the architecture does not require one exact class name.

The Declaration must freeze/resolve the equivalent of:

```text
snapshot identity and visible state
goal
run mode / permissions
official DecisionObjective
output contract
evidence requirement
authorized prior PlanState / related-session artifacts, if any
active agreement/effective-material identity
knowledge snapshot identity
allowed capability/resource classes
```

The effective agreement/knowledge resource bindings may be resolved from application configuration rather than supplied directly by the caller. The invariant is that they are pinned **before** Codex begins decision reasoning.

A request may identify a related/parent prior session or candidate artifacts to inherit. Supplying such a reference is **not** authorization. Before the new Declaration is frozen, Bridge Expert must apply the cross-session visibility/provenance rules in Section 7.6 and either accept, safely re-project, or reject the inherited artifact.

`goal` may be natural language and need not be a rigid enum such as `declarerPlan`, `choosePlay`, or `explainDecision`. Product surfaces may still use typed convenience constructors.

`outputContract` may be typed because the UI may require a specific result shape, for example:

```text
analysis + PlanState
executable BridgeAction + explanation
bidding recommendation + meaning
conditional advice
postmortem report
```

`runMode` controls information/capability boundaries such as blind decision vs postmortem/learning.

`evidenceRequirement` expresses minimum qualification such as:

```text
model judgment allowed
Engine evidence preferred
Engine evidence required
specific evidence required by the product surface
```

The session ends in an application-level `BridgeExpertResult`.

There is no architecture-level `propose()` / `synthesize()` pair and no requirement for a particular number of model turns, Engine calls, or resource lookups.

# 33. Tool Registration, Engine capability exposure, and scoped resource access

`Tool Registration` is the canonical Bridge Expert block responsible for making useful capabilities available to Codex. It does **not** redefine BridgeEngine and it does not own bridge algorithms.

## 33.1 Default exposure principle

Stable, meaningful BridgeEngine analytical capabilities should generally be registrable for Codex.

Do not artificially restrict the catalog to a tiny number of high-level composite tools merely to make the surface look simple. A catalog of roughly ten, twenty, or a few dozen clear capabilities is acceptable if evaluation shows it is useful and manageable.

An Engine operation should normally remain internal only when there is a concrete reason, such as:

- it is implementation plumbing rather than an analytical operation;
- independent invocation has no coherent bridge/evidence semantics;
- it would bypass an invariant/authorization boundary;
- it exposes raw mutation/caching/randomness/process controls that the session/Engine should own;
- a safer analytical operation provides the same useful power without losing meaningful flexibility.

Likely internal-only examples include:

```text
raw constraint-builder plumbing
mutate baseline BeliefModel in place
draw one arbitrary sampler-internal random deal
invoke raw DDS for one private sampler iteration
manually aggregate raw DDS rows
cache mutation / cache-key management
unscoped seed/process control
```

## 33.2 Engine capability inventory is component-based

The candidate analytical surface should be derived from the actual Engine components and use cases, not from an invented Engine layer taxonomy.

Useful capability families may include, where implemented and semantically well-defined:

```text
rules / legality
    inspect or confirm legal actions where not already supplied by the snapshot

belief / constraints / scenarios
    inspect current modeled assumptions
    check an explicit scenario for representability/mechanical consistency
    explain which visible facts/constraints are mechanically modeled vs not modeled

hidden-state analysis
    estimate a precisely defined hidden feature
    estimate a distribution / joint feature
    summarize a sampled population without exposing misleading raw cherry-pickable detail

play / decision evaluation
    evaluate explicit current legal actions on a comparable evidence basis
    compare score/trick/contract-delta distributions under a declared objective

analysis/evidence
    inspect an evidence record
    extend an existing analysis/sample basis
    request diagnostics / coverage / limitations

scoring / exact computation
    score an explicit contract result
    compare a defined score/IMP swing against a reference
    exact combinatorics where supported

DDS / complete-position analysis
    solve an explicitly authorized complete position with clear blind-vs-postmortem provenance

future capabilities
    contract analysis / bidding support once their semantics are implemented and tested
```

Exact names and schemas are not frozen by architecture; implementation tickets and evals should refine them.

## 33.3 Composite analytical tools are encouraged when semantics are proven

A high-value convenience tool may encapsulate a stable composition such as:

```text
current BeliefModel / scenario
      ↓
shared DealSampleSet
      ↓
DDS over sampled worlds
      ↓
qualified aggregate action evidence
```

For example, a future `evaluate_play_actions(...)` style capability may be a good composite operation.

Composite tools are **shortcuts, not mandatory workflows**. Their existence does not justify hiding lower-level analytical capabilities that have independent value.

Codex chooses the abstraction level appropriate to the question.

## 33.4 Good and bad tool boundaries

A good registered tool has:

- a clear computational object;
- typed/question-specific parameters;
- known assumptions and authorization requirements;
- a testable result meaning;
- explicit provenance/limitations where it produces evidence.

Illustrative examples:

```text
inspect_belief(...)
check_scenario(condition = suitLength(West, hearts, time = originalDeal) >= 5)
estimate_hidden_feature(feature = cardLocation(DQ, West, time = originalDeal), scenario = baseline)
estimate_distribution(feature = suitLength(West, hearts, time = currentSnapshot), scenario = baseline)
evaluate_play_actions(actions = [play(C4), play(DA)], scenario = baseline)
extend_evidence(evidence_id = E17, additional_budget = ...)
inspect_evidence(evidence_id = E17)
score_contract_result(...)
solve_known_position_dd(... authorized complete position ...)
```

Avoid pseudo-typed tools whose real semantics are still vague. For example:

```text
compare_two_lines("establish diamonds", "take club finesse")
```

is not a sound V1 tool unless the system first defines a machine-checkable conditional-line object, legal future information at each branch, and information-respecting evaluation semantics.

Until then, Codex should decompose the strategic question into explicit quantities/actions/scenarios that existing Engine capabilities can compute.

## 33.5 Shared session envelope across every Engine entry point

Whether Codex calls a lower-level analytical capability or a composite evaluator, the operation must inherit the same DecisionSession envelope.

The model should not manually re-send session-owned context on every call. Bridge Expert binds, where relevant:

- immutable `DecisionSnapshot` and authorized history;
- official `DecisionObjective`;
- active agreement identity/effective material set/version;
- knowledge snapshot/version where relevant to provenance;
- baseline `BeliefModel` identity;
- explicit scenario identity/conditions;
- prior `PlanState`;
- run-mode permissions;
- existing analysis/evidence identity when extending prior computation;
- budget/cancellation/staleness state.

The model supplies question-specific parameters; the session supplies authoritative ambient context and invariants.

## 33.6 More entry points must not weaken shared guarantees

Opening additional analytical capabilities must not create bypasses.

Examples:

- checking/defining a scenario never mutates the baseline silently;
- subsequent analyses conditioned on that scenario preserve the same scenario identity;
- all Engine calls consume the same session/run budgets and cancellation state;
- all durable results use the same evidence identity/lineage rules;
- evidence extension is explicit and does not mutate prior evidence in place;
- objective/scenario/sample-basis differences remain visible;
- hand-derived constraints/features preserve their temporal reference (`originalDeal`, current snapshot/remaining holding, or another explicit public time basis);
- blind-session complete-position analysis may use only an explicit hypothetical complete position constructed/supplied from authorized inputs, never application-held hidden truth.

These guarantees belong in shared Engine/session infrastructure, not in instructions that Codex must remember.

## 33.7 Thin adapters only where transport requires them

When a Swift Engine capability must become a Codex/app-server tool, the adapter should be as close to a schema/context bridge as practical:

```text
Codex typed call
      ↓
thin adapter
  decode
  bind DecisionSession context
  enforce shared envelope
  call BridgeEngine capability
  encode result
  record event/evidence
      ↓
Codex
```

Do not duplicate Engine algorithms or add strategic interpretation in adapters.

## 33.8 Knowledge and agreement access should normally be native scoped read/search

`knowledge/` and the session-authorized agreement material are document/resource domains, not necessarily custom registered tools.

When the runtime supports the required isolation/version/audit guarantees, prefer:

```text
knowledge/                       read/search only
agreements/<effective material> read/search only
```

using Codex's native search/read capabilities.

Codex owns search wording, refinement, file selection, and semantic interpretation. Declaration/Runtime own the authorized resource set, pinned versions, precedence metadata, and access boundary.

Do not require custom `search_bridge_knowledge`, `open_bridge_knowledge`, or `lookup_agreement` tools merely for architectural symmetry. A thin scoped adapter remains acceptable if native access cannot satisfy the invariants.

## 33.9 Codex must be explicitly aware of available capabilities

Strong model autonomy only works if the model knows what it can use.

At session start, Declaration/instructions plus registered capability descriptions should clearly communicate, without prescribing workflow, that Codex can:

```text
use BridgeEngine analytical tools for explicit computations;
search/read curated bridge knowledge;
search/read the active versioned agreement material;
inspect existing evidence and extend analysis when useful.
```

The behavioral instruction should be roughly:

> Identify decision-critical uncertainty. When an available Engine capability or authoritative agreement/knowledge resource can materially reduce that uncertainty, use it rather than relying only on memory. Do not call tools or retrieval ritualistically when they are unlikely to matter.

This is capability awareness, not workflow orchestration.

# 34. Runtime / Resources / Evidence

`Runtime / Resources / Evidence` is the third canonical programmatic block inside Bridge Expert.

It groups concerns that belong to the live DecisionSession but are not strategic reasoning and are not Tool Registration.

Conceptually:

```text
Runtime / Resources / Evidence
    Runtime
        status / budgets / timeout / cancellation / retries / staleness
    Resources
        pinned agreement material / precedence
        pinned knowledge snapshot
        authorization and read/search provenance
    Evidence
        EvidenceLedger / analysis identity / lineage
    Observable history
        SessionEvent[] / trace
```

The exact storage model is not frozen. An implementation may use an append-only event stream plus projections, separate stores, or another design, provided the semantics below hold.

## 34.1 Runtime state

Runtime state must represent enough to enforce:

- run status;
- tool/compute/resource-read budgets;
- cancellation and timeout;
- bounded retry where appropriate;
- stale-session state;
- late-result rejection;
- incomplete/failure semantics when required evidence cannot be obtained.

Codex decides whether additional reasoning is useful; Runtime enforces hard ceilings and state validity.

## 34.2 Resource state

A DecisionSession must bind reproducible resource views.

Agreement resource state includes:

- active profile/version;
- complete effective material set;
- applicable supplements/overrides/exceptions;
- deterministic precedence metadata;
- ownership/source classification: our agreement, known opponent agreement, public explanation, or unknown.

Knowledge resource state includes a pinned snapshot/version/manifest sufficient to make search/read provenance auditable and to prevent a running session from silently switching to newer backing content.

Observable resource reads/searches should record enough source/version identity for audit/eval without storing private chain-of-thought.

## 34.3 EvidenceLedger required semantics

The `EvidenceLedger` separates what was actually computed/retrieved from what Codex merely reasoned about.

Each durable Engine evidence record must preserve enough semantics to reconstruct what was actually computed and under which conditions. Field names/storage shape are not frozen, but the record must recover the equivalent of:

```text
evidence_id / analysis_id
snapshot_id
Engine capability / analysis object / question-specific parameters
temporal reference for any hand-derived condition/feature
actual analysis objective used for the computation
snapshot/session official objective remains separately identifiable
baseline-or-scenario identity and explicit scenario conditions
BeliefModel version
target distribution / weighting semantics
DealSampleSet / sample range / evidence basis
relevant Engine component versions
result summary or immutable artifact reference
coverage / diagnostics
limitations
parent / extension lineage
```

The **actual analysis objective** is required because the same DecisionSession may investigate an alternate objective without mutating the session's official decision objective.

Knowledge/agreement retrieval records use a lighter contract but must preserve at least query/lookup semantics, authorization scope, resource identity/version/provenance, and returned item identities needed for audit/replay.

## 34.4 Comparable evidence and immutable meaning

Comparable baseline analyses should reuse the same sample basis whenever practical.

Published evidence is immutable in meaning. Once an evidence record has been returned to Codex or persisted, later sampling must not mutate that record's sample range, result, assumptions, target distribution, objective, or scenario in place.

If Codex asks for more sampling, Engine should normally extend the existing evidence basis and create a new linked evidence record/version, for example:

```text
E1: first 100 samples → 61%
E2: first 1000 samples → 58%, parent = E1
```

Reopening `E1` must still reproduce the original 100-sample evidence semantics/result.

Repeated presentation of the same evidence does not count as independent support.

Lineage and immutable records prevent silent sample replacement and incompatible evidence mixing; they do **not** prove Codex will narratively summarize every result without selection bias. Selective interpretation remains an evaluation concern.

## 34.5 Changed assumptions or objectives

Changing a material scenario, assumption, analysis objective, or computation setting creates an explicit new analysis identity/lineage.

A DecisionSession may investigate an alternate objective as an analysis question, but that does not mutate the Declaration's official objective. A formal change to the official decision objective/configuration that affects the executable decision requires a new Declaration/session identity.

Percentages/rankings from materially different conditions must not be combined as if directly comparable.

## 34.6 Context completeness vs computation completeness

A tool call may be bound to the full authorized auction/play/agreement context while V1 computation still uses only mechanical baseline constraints.

Results should distinguish what information was:

```text
available to Codex in the session
resolved through authoritative agreement material
incorporated mechanically into Engine computation
used only as an explicit scenario
not yet modeled by Engine
```

“Context was available” must never be presented as “all semantic implications were mechanically modeled.”

## 34.7 SessionEvent / trace

Observable session history should record enough for debugging, evaluation, and postmortem, such as:

```text
session created / Declaration identity
model/effort/runtime chosen
tool registered/invoked/result returned or failed
resource search/read + pinned resource identity
evidence record created/extended
budget/cancellation/status changed
final structured output returned
session completed/failed/staled
```

Do not store private chain-of-thought. Observable requests, results, structured outputs, public rationales, and provenance are sufficient.

# 35. Final result, evidence qualification, and executable actions

The application-level result may be:

```swift
enum BridgeExpertResult {
    case recommendation(BridgeDecision)
    case analysis(BridgeAnalysis)
    case conditionalAdvice(ConditionalBridgeAdvice)
    case needsInput(NeededInput)
    case incomplete(IncompleteBridgeResult)
    case failure(BridgeExpertFailure)
}
```

Exact cases may evolve, but the following semantics are required.

## 35.1 Evidence provenance

A final result should distinguish, where relevant:

```text
model-only judgment
knowledge-supported reasoning
agreement-grounded interpretation
Engine-supported evidence
postmortem truth
```

Model-only conclusions are allowed when the Declaration permits them. They may not be labeled computed/verified.

The UI should prefer displaying actual structured evidence records over parsing numeric claims back out of model prose.

## 35.2 Evidence qualification is structural, not a reasoning validator

There is no general component whose job is to determine whether Codex's strategic reasoning/explanation is “correct”.

When a structured result claims Engine support for a conclusion/action/quantity, the referenced evidence must match the relevant support tuple, including as applicable:

```text
snapshot
analysis object / action / feature
actual analysis objective
baseline vs scenario conditions
evidence/sample coverage
```

A request that explicitly requires Engine evidence can check whether qualifying evidence exists in the session ledger.

If Codex misinterprets a real piece of matching evidence, that is a reasoning/teaching quality failure for eval/postmortem rather than something a generic Swift validator can prove away.

## 35.3 Executable actions

If a result contains an action intended for execution:

- final action must be legal for the exact current state;
- action seat / decision controller must match;
- the originating snapshot/session must still be current;
- execution must be exactly-once from the application's perspective;
- timeout, cancellation, stale session, or late results cannot produce an action.

These checks belong at the execution/application boundary.

## 35.4 BridgeDecision

A recommendation may use a structure like:

```swift
struct BridgeDecision {
    let action: BridgeAction
    let alternatives: [RankedAlternative]
    let planState: PlanState?
    let reasoning: String
    let assumptions: [DecisionAssumption]
    let uncertainties: [DecisionUncertainty]
    let evidence: [DecisionEvidence]
    let evidenceQualification: EvidenceQualification
    let snapshotID: UUID
    let engineVersion: EngineVersion?
    let agreementVersion: AgreementVersion?
}
```

The exact object may evolve with the UI. The invariant is that decision state, evidence references, and provenance remain explicit rather than recoverable only from prose.

# 36. Session history, durable DecisionTrace, and postmortem extension

The live `DecisionSession` contains its own event/history stream. Durable records may persist a summarized/normalized `DecisionTrace` after the session completes.

A durable trace should preserve enough observable information for debug, evaluation, replay, and postmortem without recording private model chain-of-thought.

Conceptually:

```text
DecisionTrace
    identity
        decision_id / session_id / related-or-parent-session refs / snapshot_id / board_id / state_version
    runtime
        requested_model / actual_model / effort / runtime version
    request
        user goal / run mode / output contract / evidence requirement
        perspective / visible-state hash / agreement & knowledge versions
        inherited artifact refs + authorization/projection outcome where applicable
    tool interaction
        tool calls / arguments after decoding
        tool results / errors / timing
        knowledge/agreement retrieval references
    evidence
        EvidenceLedger record refs / lineage
    final output
        selected action / plan / structured result / evidence qualification
    run state
        budget use / cancellation / timeout / stale state / failure
```

Postmortem truth should live in a separate linked record:

```text
PostmortemRecord
    decision_id / board_id
    actual hidden deal
    actual result
    counterfactual evidence
    error classification
    candidate lessons
```

Do not store private model chain-of-thought. Structured tool activity, results, decisions, public/auditable rationales, and provenance are sufficient.

# 37. Error taxonomy

At minimum, distinguish errors such as:

```text
STATE_ERROR
INPUT_COMPLETENESS_ERROR
VISIBILITY_ERROR
AGREEMENT_ERROR
KNOWLEDGE_ERROR
INFERENCE_ERROR
SAMPLER_ERROR
CANDIDATE_OMISSION
EVALUATION_ERROR
CONTINUATION_ASSUMPTION_ERROR
OBJECTIVE_ERROR

TOOL_ARGUMENT_ERROR
TOOL_UNSUPPORTED
TOOL_TRANSPORT_ERROR
TOOL_RESULT_ERROR
EVIDENCE_LINEAGE_ERROR
INHERITANCE_VISIBILITY_ERROR
BUDGET_EXHAUSTED

EXPLANATION_ERROR
EXECUTION_STALENESS_ERROR
RUNTIME_ERROR
```

Postmortem classification should distinguish a rational ex-ante decision that lost on the actual layout from a genuinely bad decision process.

It should also distinguish:

```text
Codex decomposition / tool-selection failure
from
Bridge Expert session/context/transport failure
from
Engine computation/modeling failure
from
Codex evidence-interpretation failure
```

This separation is useful for evals and debugging even though the programmatic Bridge Expert support does not judge strategic correctness.

# 38. Knowledge architecture and lazy retrieval

Knowledge is important but should not be injected wholesale into every decision.

Use three tiers.

## Tier 1 — structured operational context

Always available where appropriate.

Examples:

- active partnership agreement identity/version/material set;
- defensive agreement identity/version;
- scoring rules;
- core ontology.

Operational agreement **content** remains versioned under `agreements/`; knowledge infrastructure may reference it but must not blur agreements with general bridge knowledge.

## Tier 2 — knowledge cards

Curated topics such as:

```text
restricted choice
safety play
avoidance play
loser-on-loser
Lebensohl
Jacoby 2NT
Smith echo
```

Each card should eventually include:

```text
topic
conditions
reasoning
failure conditions
examples
source
validation status
```

## Tier 3 — original source material

Books / extracted text / examples may be available privately for:

- detailed explanation;
- exceptions;
- provenance;
- knowledge-card creation;
- difficult lookup.

Copyrighted source material need not live in the Git repository. The repository may store extracted/curated knowledge, metadata, provenance, and internal references while source files remain in an authorized private location.

## Lazy retrieval rule

Do not preload large knowledge context.

Codex decides when extra bridge knowledge would materially help and controls its own search wording, refinement, and source selection.

Prefer native scoped read/search over the session-pinned `knowledge/` view. A custom retrieval tool is optional transport, not the architectural owner of query intelligence.

Simple cases may use no knowledge retrieval.

## Knowledge version binding

A DecisionSession must bind a reproducible knowledge snapshot/version/manifest. Native search/read during that session must resolve to that pinned view even if backing knowledge files are updated concurrently.

Observable search/read activity and source/version provenance must be recordable in `SessionEvent` / durable trace.

# 39. Knowledge retrieval / search strategy

Do not introduce semantic RAG merely because documents exist.

Baseline should exploit the simplest search/read facilities that work well with Codex and the actual corpus:

```text
native/full-text search
+ path/folder scoping
+ metadata filters
+ bidding-system tags
+ phase tags
+ topic tags
+ direct file reads
```

Codex may issue multiple searches with different wording and open selected results.

Evaluate recall and downstream bridge quality.

Only add embeddings / semantic retrieval if evaluation demonstrates a meaningful gap. If added later, it remains another scoped retrieval capability over the same pinned knowledge snapshot rather than a replacement for Codex-owned query formulation.

Progressive/deferred result disclosure may be evaluated separately from retrieval quality. It is not required for correctness.

# 40. Knowledge, agreement, evaluation, experience, and postmortem isolation

Access is run-mode dependent.

For an ordinary **blind decision**:

```text
knowledge/                    scoped read/search allowed
active agreement material     scoped read/search allowed
raw experience                unavailable
eval answers                  unavailable
postmortem truth              unavailable
unrelated repository files    unavailable unless separately justified
```

For an authorized **postmortem / learning** workflow:

```text
knowledge/                    read allowed
agreement material            read allowed
experience                    read allowed as appropriate
postmortem truth              allowed as appropriate
candidate lesson/annotation   structured write allowed
eval answers                  still isolated from production reasoning unless the eval harness explicitly owns the run
```

Read-only access is still information access. Runtime isolation must enforce these scopes across native files/search, built-in tools, MCP/plugins, caches, summaries, inherited context, and any alternate path.

Book examples that overlap evaluation cases must be marked. Evaluation must distinguish retrieval ability from independent bridge reasoning.

Raw experience is evidence, not normal decision-time knowledge. Promoted/validated lessons may enter normal Knowledge through the learning process defined below.

# 41. Learning architecture

Do not allow a completed hand to directly rewrite expert rules.

```text
episode
   ↓
postmortem
   ↓
candidate lesson
   ↓
independent validation
   ↓
human decision
   ↓
promoted / rejected / withdrawn knowledge change
```

The same boards used to discover a lesson must not also be treated as independent evidence proving that lesson.

Partnership agreements and general bridge knowledge are separate versioned domains: promoting a general lesson must not silently modify an agreement, and changing an agreement must not silently rewrite general knowledge.

Codex may propose candidate lessons/annotations during an authorized postmortem/learning run, but persistent writes should use structured episode/lesson contracts rather than unrestricted editing of `experience/` files.

# 42. Experience record

Persist structured episodes.

Example:

```text
board
snapshot
decision
belief
candidate set
candidate evaluation
actual action
actual result
full postmortem deal
counterfactual
lesson candidates
```

Raw episodes are evidence, not instructions.

Normal runtime traces/episodes should be produced programmatically from authoritative session/board data. Authorized postmortem/learning workflows may attach structured annotations or candidate lessons. Blind production sessions do not search raw experience.

# 43. Candidate lesson

```swift
struct CandidateLesson {
    let claim: String
    let scope: LessonScope
    let discoveryEpisodes: [EpisodeID]
    let independentValidationEvidence: [EvidenceID]
    let counterexamples: [EpisodeID]
    let sourceReferences: [SourceReference]
    let validationStatus: ValidationStatus
}
```

Possible statuses: `candidate`, `validated`, `rejected`, `withdrawn`.

V1 promotion should be human-reviewed. Every promoted knowledge/retrieval/agreement version must support rollback, and regressions should be checked on independent holdout/regression sets.

# 44. Evaluation system

Evals begin before Engine implementation and serve two purposes:

1. **development evidence** — guide architecture and implementation;
2. **release evidence** — verify that a frozen product version meets predeclared criteria.

Create categories for state, visibility, input sufficiency, bidding, declarer, defense, continuous play, sampling, evaluator behavior, explanation, runtime isolation, tool-use/decomposition quality, knowledge retrieval, and regression.

Freeze the evaluation protocol early.

Do not invent a numerical “expert threshold” before baseline/pilot evidence exists. Establish baselines and a development set first; then freeze release thresholds **before** evaluating the final held-out release set so thresholds are neither arbitrary nor post-hoc.

# 45. State evals

Test:

- card uniqueness;
- legal turn;
- follow suit;
- auction legality;
- state rebuild;
- stale version rejection;
- undo / redo;
- deterministic replay.

---

# 46. Visibility, session-binding, and runtime-isolation evals

## Hidden-deal invariance

Construct two boards with identical decision-visible information but different hidden hands.

Fix the authorized visible state, typed Engine request, agreement/objective configuration, random seed, sampling/computation configuration, and relevant component versions. Then vary only unauthorized hidden truth stored elsewhere in the application.

For blind analysis, both the deterministic computation inputs **and the deterministic computation outputs / returned evidence** must remain identical. In particular, the generated sample artifact under the fixed seed/model and all deterministic evidence values derived from it must not change merely because a hidden truth store contains a different actual deal.

The stochastic Codex run does not need to choose the same tool path or produce byte-identical prose across independent runs; this invariance test targets the programmatic blind-analysis boundary and deterministic Engine behavior.

## Frozen session binding

During one `DecisionSession`, tool calls must bind to the session's immutable snapshot, never to a later “current board” state.

A DecisionSession corresponds to one user/product request. A second request creates a new related session even if the same snapshot is reused. Changing accepted board state creates a new snapshot and any new executable request uses a new session.

## Cross-session inheritance isolation

Explicitly test artifact carry-forward across related sessions:

- East defender session → West defender session: East-private plan/evidence/summary content must not leak;
- declarer own-hand action → declarer controlling dummy: continuity may be preserved where the target perspective/controller authorizes the same information;
- forward play to a later snapshot: public information is re-projected from authoritative state and safe prior artifacts retain provenance;
- undo to an earlier snapshot/information time: later-revealed cards, later public events, and later private conclusions must not survive through inherited PlanState/evidence/summary content;
- completed/cancelled/timed-out sessions remain terminal and cannot become executable again through a follow-up.

A new session alone is not sufficient isolation; inherited artifacts themselves must pass the target-session visibility/provenance rules.

## Frozen resource binding

Bind a session to an agreement material set/version/precedence and a knowledge snapshot/version, then mutate or replace the backing files outside the session. Reads/searches in the running session must continue resolving to the pinned authorized resource view, or fail explicitly if that view is unavailable; they must never silently observe newer contents.

Test base/addendum/override precedence and our-vs-opponent material separation. Search/read provenance must identify the resource version actually used.

## Timing and controller cases

Cover opening lead before dummy exposure, declarer playing from dummy where action seat and decision controller differ, each defender perspective, and public information becoming visible mid-board.

## Review isolation

A board that has already been postmortem-reviewed must still be analysable blind in a fresh `DecisionSession` without hidden information leaking from previous context.

## Negative tool-access tests

Place sentinel content in forbidden surfaces and attempt to access it through files, built-in tools, inherited config, old thread context, retrieval, other MCPs/plugins, raw experience, summaries, and answer files.

Passing JSON/schema parsing or successfully registering a tool catalog is not evidence that isolation works.

# 47. Sampler and inference evals

Test known-card correctness, genuine hidden-card completion, card uniqueness, hand sizes, void/HCP/shape constraints, impossible constraints, budget exhaustion without proof of impossibility, conflicting inferences, repeated evidence, rare feasible holdings, and baseline-vs-scenario sensitivity.

Also test temporal constraint/feature semantics across continuous play. A scenario such as “West originally held 5+ hearts” must retain that meaning after West has publicly played hearts; it must not silently become “West currently has 5+ hearts remaining.” Cover original suit length/HCP/shape, current remaining holdings, voids at a specified public event, and undo/redo to an earlier information time.

Also test the declared sampling distribution. Use toy/miniature states that can be enumerated exactly to verify that the sampler converges to the stated V1 baseline/scenario distribution, and verify any weighting correction when the proposal generator is non-uniform. A sampler that generates only feasible deals but the wrong distribution must fail this evaluation.

The evaluator should show when a recommendation is robust across plausible scenarios and when it depends heavily on one uncertain assumption.

# 48. DDS and sampled-evaluation evals

Keep existing DDS integration tests and add:

- repeated-position correctness;
- one-solve legal-move coverage;
- equivalent-card expansion correctness;
- batch-vs-single equivalence if batching is introduced;
- sampled-position integration;
- shared-sample candidate comparison;
- partial trick, defender-to-act, all strains, and solver-failure coverage.

Add targeted strategy-fusion/future-information cases where hidden worlds require different later choices that the real player cannot yet distinguish. Compare model explanation, sampled-DDS ranking, and a feasible information-respecting policy/result.

The goal is to learn where sampled DDS is useful evidence and where its continuation assumption materially distorts a plan-level conclusion.

# 49. Expert bridge eval corpus

Start with roughly 20–30 declarer decisions, 20–30 defense decisions, 20–30 bidding decisions, several full-plan analysis cases, and several multi-trick continuous-play sequences. Quality matters more than size.

Each case should contain decision-time information, user goal, output contract, expected input sufficiency, acceptable actions/plans, severe errors where known, expert explanation, relevant concepts, scoring/objective context, agreement context, whether Engine/knowledge use is useful or required, and provenance.

Evaluate **playing quality and teaching quality separately**:

- action / plan quality and acceptable-action set;
- severe errors;
- explanation consistency with visible facts;
- agreement/system consistency;
- uncertainty/calibration behavior;
- continuity across decisions;
- runtime stability.

Also evaluate **agentic decomposition and capability-use quality**:

- did Codex recognize the decision-critical uncertainty?;
- did it decompose the strategic problem into an explicit computable/retrievable question when appropriate?;
- did it choose an available Engine capability whose semantics actually match the question?;
- were tool arguments well formed and bridge-relevant?;
- did it use an Engine tool when computation materially mattered?;
- did it search/read authoritative agreement or knowledge material when that materially mattered?;
- did it avoid needless tool/retrieval ritual on obvious cases?;
- did it stop too early?;
- did it repeatedly seek redundant evidence?;
- did it distinguish baseline, scenario, model-only, knowledge-supported, agreement-grounded, and Engine-supported claims?;
- did it make productive use of query refinement when needed?;
- did Bridge Expert bind the correct frozen state/resource context without adding strategic interpretation?;
- when both lower-level and composite Engine tools were available, did Codex choose an effective level of abstraction without bypassing evidence/scenario rules?

Do not expose answer files to the decision runtime. Public book problems may have appeared in model training; mark this limitation and do not treat them alone as proof of independent expert capability.

Private/licensed book problems can be useful internal eval sources when stored outside the normal production knowledge scope.

# 50. Ablation and architecture evaluation

The architecture should allow comparison of:

```text
model only, no external Engine/resource use
fixed two-pass baseline from v0.3
model-led Codex + active agreements only
model-led Codex + Engine tools
model-led Codex + Engine + Knowledge
model-led Codex + broad Engine analytical surface
model-led Codex + only selected composite Engine tools
model-led Codex + scenario sensitivity
full current Bridge Expert
```

This tells us what actually improves bridge strength and teaching quality, whether broad analytical access helps or distracts, and whether particular composite shortcuts are useful.

For semantic inference, compare baseline mechanical sampling with scenario-conditioned analysis so the contribution of an assumption is visible rather than silently baked into the sample distribution.

For model-led capability use, compare quality, latency, Engine-call count, compute, resource-read/search volume, and failure modes under comparable run budgets.

# 51. Stochastic model, capability-loop, and continuous-play evaluation

A single LLM run is insufficient.

For important benchmark cases, run each version multiple times and record:

```text
selected action / plan
problem decomposition
Engine tool-call sequence
knowledge/agreement searches and reads
Engine analyses requested
EvidenceLedger lineage
stop point / budget use
PlanState consistency
latency and compute
final evidence qualification
```

Track quality and stability separately.

Explicitly test:

- model stops before obtaining decision-critical evidence;
- model fails to decompose a strategic question into an available precise Engine capability;
- model chooses a tool whose semantics do not answer the question;
- model overuses lower-level capabilities when a stable composite would be more reliable/efficient;
- model blindly trusts a composite result when inspecting a lower-level assumption would materially matter;
- model repeatedly asks equivalent questions;
- model changes scenarios/objectives and accidentally compares incompatible numbers;
- model obtains Engine evidence but ignores or misstates it;
- model answers correctly without tools on an obvious case;
- model fails to search/read known available knowledge/agreement material when it matters;
- Bridge Expert context binding omits an important auction/play/agreement/resource fact;
- a tool or native resource access resolves against a different version than the session declared;
- tool transport/context binding succeeds but Engine does not mechanically model all semantic implications, and the result correctly discloses that boundary;
- a real evidence ID exists but was computed for a different action/feature, objective, scenario, sample basis, or snapshot, and structural delivery checks reject or de-qualify the mismatched support claim without attempting to judge the full bridge explanation.

For continuous play, use paired boards/fixed opponent configurations where practical so one lucky or unlucky layout does not dominate conclusions. Measure whether plans remain coherent across multiple tricks and preserve required entries/communication.

When a plan changes, require a concrete auditable basis: newly visible legal information, an explicitly revised assumption, retrieved authoritative agreement/knowledge detail, or new computational evidence/correction derived from the authorized state. Replanning must not use unauthorized hidden information or change repeatedly without a stated reason.

# 52. Model strategy

Do not hardcode one model identity into bridge-domain code.

The existing model-selector approach should remain.

Record:

```text
requested model
actual model
reasoning effort
Codex runtime version
```

with each durable session trace.

V1 uses one primary Codex reasoner inside Bridge Expert plus deterministic programmatic session/tool/evidence support.

Do not add a specialist Expert LLM merely because multi-agent architecture is possible. The default assumption is that strategic bridge decomposition belongs to the strongest primary Codex model and that adapters/session infrastructure remain deliberately non-intelligent.

Reconsider a specialist only if evaluation reveals a genuinely separable reasoning task whose quality cannot be achieved cleanly with the primary Codex model plus explicit Engine capabilities and scoped resource access.

Initially prioritize quality over cost for expert evaluation. Later evaluate model/effort selection for different request surfaces while preserving the same Domain/Engine/DecisionSession contracts.

# 53. Canonical repository target structure

This section defines the **expected module-level logical destination**, not a frozen per-file tree. It is the repo-shaped view of the canonical project architecture in Section 5.1.

Milestone 0 must inspect the real dependency graph before creating or renaming Swift targets. Physical targets, subfolders, classes, or even some module boundaries may be adjusted when implementation evidence supports a cleaner result, but responsibility ownership and information boundaries must remain recognizable or be changed through an explicit architecture revision.

```text
bridge-coup/
│
├── Sources/
│   │
│   ├── BridgeDomain/
│   │     shared bridge language and state
│   │     cards / auction / contract / facts-events
│   │     visibility / snapshots / objectives / agreement refs
│   │
│   ├── BridgeEngine/
│   │     rules / legality
│   │     constraints / BeliefModel / scenarios
│   │     sampling / DealSampleSet
│   │     DDS integration
│   │     scoring / objectives
│   │     candidate-action evaluation
│   │     analytical results / diagnostics / statistical semantics
│   │
│   ├── BridgeExpert/
│   │     Declaration
│   │     Tool Registration
│   │     Runtime / Resources / Evidence
│   │     (Codex-facing bridge-specific support; no second reasoner)
│   │
│   ├── BridgeTeacherCore/
│   │     existing reusable application/core code during migration
│   │
│   └── BridgeTeacherMac/
│         UI / application composition
│         Codex app-server transport + dynamic-tool callbacks
│         runtime-specific scoped resource integration where required
│
├── Native/
│   └── DDSHelper/
│
├── agreements/
│     versioned system / lead / signal material
│     effective-set manifests / precedence metadata
│
├── knowledge/
│     curated bridge knowledge
│     provenance / version / indexing metadata
│
├── experience/
│     schemas / fixtures / structured learning artifacts
│     raw runtime data may live outside Git
│
├── evals/
│     development / holdout / rubrics
│     never visible to ordinary production decision runs
│
├── Tests/
├── Scripts/
├── AppResources/
└── docs/
```

The dependency intent is:

```text
BridgeTeacherMac
      │
      ├────────► Codex app-server/runtime transport
      │
      ▼
BridgeExpert
      │
      ├────────► pinned agreements/ + knowledge/ access
      │
      ▼
BridgeEngine
      │
      ▼
BridgeDomain

BridgeEngine ───────► Native/DDSHelper
```

`BridgeDomain` is shared by Engine/Expert/application code as appropriate; the downward drawing above emphasizes ownership rather than prohibiting normal typed dependencies that the package graph explicitly allows.

`evals/` are outside the production decision capability boundary. Raw `experience/` is likewise outside blind-decision access.

Do not create a detailed folder/file hierarchy merely to make the diagram look complete. Exact physical boundaries should follow the repo-grounded dependency analysis while preserving this responsibility map.

# 54. Migration of current types

Migration rule:

> **Reuse existing deterministic bridge behavior through adapters where it is sound; do not create a second mutable source of truth merely to match the target diagram.**

## `BridgePlaySession`

Keep its deterministic legality/play-progression behavior. It is useful for complete-deal simulation and existing UI progression, but its complete-four-hand premise does not make it the blind-decision visible state.

## `AuctionRecord`

Likely reusable as the auction primitive. Extend only for legality, alerts/explanations, agreement semantics, or decision-time visibility.

## `OriginalHandFacts`

Treat primarily as input/provenance data, not automatically as the universal canonical decision state.

## `DeclarerPlanDraft`

Treat as current UI/teaching input representation. Create adapters into the new accepted-state/snapshot/request model rather than expanding it into a universal domain model.

## `DeclarerTeachingRuntime`

Replace/supersede with a general Bridge Expert request/session facade. Do not indefinitely add specialized bidding/defense workflow methods.

## `DoubleDummyVerification`

Preserve current functionality. First verify how much current `SolveBoard` output already covers before adding per-candidate work.

Preserve the Engine's component-based responsibilities—rules/legality, constraints/BeliefModel/scenarios, sampling/DealSampleSet, DDS, scoring/objectives, candidate/action evaluation, diagnostics/statistical semantics, and related analytical components—while adding well-defined Codex-facing analytical entry points where useful. Do not reorganize Engine to mirror Bridge Expert's three support blocks, do not wrap every internal function, and do not hide useful analytical capabilities merely to force one composite path.

## `CodexAppServer`

Split/clarify generic app-server transport, screenshot recognition, Bridge Expert decision-session/Engine-tool integration, and scoped resource-access setup.

The current JSON-RPC client rejects server-originated requests; Milestone 0 must add or wrap bidirectional request handling if dynamic Engine tools are used. Cancellation must propagate to the Codex turn and in-flight Engine work where supported, and late results must be rejected after session cancellation/staleness.

Milestone 0 must separately validate the native read/search path for pinned knowledge/agreement resources and its auditability/isolation.

## `BridgeTeacherApplicationModel`

Remain primarily UI composition/application state and call Bridge Expert services rather than implementing expert reasoning or Engine orchestration.

## Archive / saved reviews

Preserve compatibility where practical through schema/version adapters. Do not force old archives to masquerade as new blind-decision snapshots if required provenance did not exist.

# 55. Vertical implementation milestones

Implementation work should be organized around **runnable vertical milestones**, not “finish all Domain, then all Engine, then all Expert”. Every milestone must state what part of the total 2.0 spec it covers and what remains incomplete.

## Milestone 0 — Architecture/runtime validation and technical spikes

No large production refactor.

Deliver:

- dependency/truth-source inventory and current/target architecture diagrams using the canonical `Bridge Expert` naming only;
- explicit mapping/inventory of existing/new Engine responsibilities by concrete component (rules/legality, constraints/BeliefModel/scenarios, sampling/DealSampleSet, DDS, scoring/objectives, evaluation/analysis, diagnostics/caching as applicable);
- minimal `DecisionSession` / snapshot/resource-binding proof demonstrating one user/product request per session, multiple related sessions on the same snapshot, and terminal-session non-reopening;
- cross-session artifact-inheritance proof covering source snapshot/perspective/visibility provenance, defender seat changes, declarer-to-dummy continuity, and undo to an earlier information time;
- temporal constraint/feature proof distinguishing original holding from current remaining holding across played cards and undo/redo;
- an initial inventory of stable meaningful Engine analytical capabilities, classified as `expose`, `expose via analytical wrapper/composite`, or `keep internal plumbing`;
- at least two Engine analytical capabilities exposed through thin model-facing adapters, preferably at different abstraction levels where this is semantically useful;
- Codex app-server multi-tool spike using experimental dynamic tools if supported by the packaged runtime;
- local MCP or another supported Codex tool mechanism as fallback comparison if dynamic tools are insufficient;
- bidirectional tool request handling and structured result return;
- multiple typed Engine calls inside one turn/session;
- lower-level + composite capability coexistence without bypassing shared scenario/evidence/budget rules;
- tool failure followed by continued Codex reasoning;
- structured final output;
- cancellation/timeout/late-result handling across Codex + Engine work;
- scoped native read/search spike for pinned `knowledge/` and effective agreement material;
- proof that agreement vN cannot silently read vN+1 contents and that override/precedence metadata is visible;
- observable logging of native knowledge/agreement searches/reads with source/version identity;
- runtime isolation negative tests covering forbidden experience/evals/postmortem/unrelated repo paths and alternate built-in/MCP/plugin routes;
- whole-decision DDS baseline and confirmation of one-`SolveBoard` legal-move coverage/equivalent cards;
- explicit V1 sampler target-distribution contract plus a miniature/enumerable distribution test;
- minimal DecisionSession evidence/history proof including immutable evidence extension/lineage;
- hidden-deal invariance proof that compares deterministic Engine evidence as well as request semantics;
- minimal eval scaffold including model-led vs fixed-two-pass baseline.

Do **not** commit to dynamic tools vs MCP, or native filesystem search vs a thin scoped read/search adapter, as permanent transports before these spikes.

Do **not** freeze a tiny final Engine tool list during Milestone 0. Freeze semantic exposure principles first; use evals/implementation evidence to refine the inventory.

## Milestone 1 — First real model-led declarer-analysis vertical slice

Use the existing declarer-analysis UI as the first product surface.

```text
existing App input / user asks for declarer analysis
      ↓
accepted facts/events adapter
      ↓
DecisionSnapshot + DecisionSession
      ↓
Codex receives authorized state + goal + Engine capability catalog
     + active agreement/knowledge resource awareness
      ↓
Codex reasons / decomposes
      ↓
zero or more actions chosen by Codex
      ├─ Engine analytical tool call(s)
      ├─ scoped agreement search/read
      └─ scoped knowledge search/read
      ↓
DecisionSession evidence/history
      ↓
Codex final declarer plan
      ↓
PlanState + explanation in existing teaching UI
```

Also include minimal versioned `AgreementSnapshot` with effective material set/precedence, pinned knowledge version, `DecisionObjective`, durable trace, evidence qualification, one-request-per-DecisionSession semantics, safe related-session continuity metadata, temporal feature/constraint semantics, a feature flag against the legacy declarer teacher, and an initial benchmark.

The first slice should include at least:

- one case requiring Engine evidence;
- one case where a correct answer can be delivered without Engine use;
- one case where authoritative knowledge/agreement search materially helps;
- one case where a lower-level Engine analytical capability is useful;
- one case where a composite evaluator is useful.

This milestone is **not** Bridge Coup 2.0 completion.

## Milestone 2 — Current-play recommendation and continuous declarer play

Add executable next-card recommendation and extend across multiple tricks with `PlanState` retention/revision, fresh DecisionSessions per changed snapshot, stale-action rejection, cancellation/timeout/budget handling, evidence-lineage continuity, continuity evaluation, and complete-board latency measurement.

## Milestone 3 — Defense

Reuse shared state/visibility/belief/sampling/DDS/evaluator/objective/session infrastructure and add defense-specific perspective, agreements/signals, inference, planning, explicit Engine capability needs, explanation, and benchmarks.

## Milestone 4 — Bidding

Add legal-call support, current auction interpretation, active versioned agreement material, Codex native agreement search/read, candidate bidding, hand evaluation, explanation, sampling where useful, bidding-specific Engine capabilities where semantics are clear, and evals before advanced rollout/policy work.

## Milestone 5 — Knowledge

Populate/version curated knowledge cards and supporting metadata, improve native/indexed search only where evals show need, add provenance/rollback, measure retrieval recall/downstream quality, and expand the corpus after the decision architecture is working.

## Milestone 6 — Experience and learning

Add structured episode store, authorized postmortem/learning reads, candidate lessons, independent validation, human promotion/rollback, and regression checks.

Do not expose raw experience to ordinary blind decision sessions.

## Milestone 7 — Bridge Coup 2.0 product hardening and release

Satisfy the whole-product DoD in Section 66 across bidding, declarer, defense, continuous play, teaching, review, knowledge, evaluation, isolation, runtime robustness, backwards compatibility, and measured latency.

## Milestone 8 — Xinrui / external player adapter (post-2.0 integration)

Integrate the same Bridge Expert through an external adapter and test misread, reconnect, timeout, duplicate action, stale action, and result reconciliation.

This milestone is important but **does not block Bridge Coup 2.0 release**.

## Ticketing rule

Do not create one giant “Build Bridge Expert” ticket. Each ticket should state goal, non-goals, vertical milestone, likely files, migration/design approach, tests, acceptance criteria, observability/benchmark if relevant, and remaining scope.

# 56. Cross-cutting testing requirements

Every implementation ticket should include appropriate tests.

Prefer:

```text
unit test
integration test
architecture / leakage test
benchmark where appropriate
```

Never rely only on prompt inspection.

---

# 57. Backwards compatibility requirement

At every intermediate stage:

- existing Bridge Coup should build;
- existing core tests should remain green unless intentionally migrated;
- screenshot review should continue working;
- current review archives should remain readable where practical;
- current DDS verification UI should remain functional;
- current ChatGPT login should remain functional.

Large migrations should be incremental.

---

# 58. Feature flags

New expert behavior should initially be gated.

Examples:

```text
legacy declarer teacher
fixed-two-pass baseline (evaluation only, if retained)
model-led Bridge Expert declarer
```

This allows A/B evaluation and safe rollback without making the obsolete two-pass path part of the permanent product contract.

# 59. Observability

Record at least:

```text
DecisionSession start/end
snapshot / visible-state identity
user goal / run mode / output contract / evidence requirement
model / effort / runtime
Engine tool surface/version exposed to Codex
authorized agreement material-set/version/precedence identity
authorized knowledge snapshot/version
Engine tool-call sequence
decoded tool parameters + bound session context identity
knowledge/agreement search queries
knowledge/agreement opened/read resource identities + versions
Engine analysis IDs / lineage
sample/candidate/scenario counts
DDS startup/solve time
Engine aggregation time
evidence extensions / scenario branches
model turn/tool/read latency
capability/resource-access failures and retries
budget use / budget exhaustion
cancellation / stale-result drops
final evidence qualification
```

For DDS/sampled evaluation, report performance at the level of a **complete Engine analysis and complete user request**, not only isolated solver calls.

Optimization should follow observed bottlenecks.

# 60. Performance philosophy and run budgets

Do not set arbitrary product latency budgets before measuring.

Baseline the real vertical path from snapshot/session/resource binding through Codex reasoning, zero or more Engine tool calls, knowledge/agreement search/read, final response, and UI delivery. Also measure repeated use across a complete board and report typical/tail latency.

The system still needs hard safety ceilings from the beginning, even before product targets are tuned. A DecisionSession may bound:

```text
wall-clock duration
Engine tool-call count
Engine compute time
sample budget
resource-search/read volume
returned knowledge/agreement content volume
```

These ceilings prevent runaway loops; they are not a fixed reasoning workflow.

After measurement, define separate practical budgets for interactive action recommendation, richer declarer/defense teaching analysis, bidding analysis, and background postmortem/learning work.

Potential optimizations include DDS batching/persistent helper, sampler optimization, evidence caching, deferred Engine-tool loading, indexed/resource-result progressive disclosure, and model-effort selection. Do not optimize merely because code looks inefficient before whole-request profiling shows material cost.

# 61. Caching and evidence-reuse rules

Cache deterministic computation only when its key reflects the computation's real semantic dependencies.

```text
DDS cache:
complete equivalent position + DDS version

sampling artifact:
BeliefModel version + scenario + target distribution/weighting semantics + sampling config + seed + sampler version

candidate/action evaluation:
visible-position semantics + DealSampleSet identity + objective + evaluator version

hidden-feature estimate:
BeliefModel/scenario + feature definition + evidence basis + estimator version

knowledge search/read cache:
query/path/read locator + pinned knowledge snapshot/version + authorization scope + retrieval implementation version where relevant

agreement search/read cache:
effective agreement material-set/version + precedence/override identity + query/path/read locator + authorization scope
```

DecisionSession evidence reuse follows stronger rules than generic caching:

- comparable repeated Engine requests should reuse or extend the same baseline evidence basis where possible;
- scenario/objective changes create explicit new analysis lineage;
- incompatible cached percentages must not be merged into one ranking;
- a repeated call/read does not become independent supporting evidence merely because it was requested twice;
- cached resource content must never cross agreement/knowledge version or authorization boundaries.

Snapshot/state versioning answers a different question: whether an old recommendation is still executable in the current live board.

# 62. Reproducibility and replay

Distinguish deterministic evidence replay from resource replay, stochastic model rerun, and capability-path replay.

## Deterministic evidence replay

Record the snapshot/visible state, objective, active agreement material-set/version/precedence, knowledge snapshot/version, `BeliefModel`, scenario, declared target distribution/weighting semantics, sampling configuration, seed, sampler version, necessary sample evidence/sample range, DDS version, evaluator/analysis-service version, analysis ID, and lineage.

## Resource replay

A replay should be able to identify the exact agreement/knowledge material searched/read during the original run. Replaying against newer mutable files is not the same run.

## Model / agent rerun

Re-calling a stochastic model later is not guaranteed to reproduce the same decomposition, Engine tool path, search wording, file selection, or final output merely because deterministic evidence/resources are replayable.

Record requested/actual model, reasoning effort, runtime version, instruction/template version, output contract, Engine tool-surface/version, observable Engine calls/results, resource searches/reads, and final structured result so the original interaction is auditable.

A replay mode may feed stored tool results/evidence/resource excerpts back to a model for debugging without recomputing/re-reading, but that is different from proving that a fresh Codex run would choose the same path.

The system should be explicit about whether it is replaying stored evidence/resources, recomputing Engine evidence, or rerunning Codex.

# 63. Security and leakage

Required controls include:

- decision-time data physically or capability-wise separated from postmortem truth;
- held-out answers unavailable to the decision process;
- raw experience unavailable to ordinary blind decisions;
- fresh blind context after any postmortem exposure;
- native read/search restricted to the session-authorized pinned agreement/knowledge views;
- native read/search unable to escape through symlinks, alternate mounts, inherited workspace access, built-in tools, plugins/MCPs, or cached summaries;
- state passed through a visibility projection;
- visibility audience/effective time represented in the domain model;
- versioned immutable snapshots and snapshot-bound DecisionSessions;
- Engine calls bound by application/session context rather than trusted model-supplied board IDs;
- summaries/retrieval/caches subject to the same visibility/resource-version boundary;
- run/tool/compute/read budgets and cancellation;
- observable session traces including authorized resource access;
- negative runtime tests on the actually supported app-server configuration.

### Blind-mode complete-position / DDS rule

Blind-mode known-position or DDS capabilities must **never** read application-held hidden truth.

They may analyze an explicit hypothetical complete position only when that hypothetical was supplied or constructed solely from information authorized for the blind session, and the returned evidence must preserve hypothetical provenance.

A hypothetical position that happens to equal the real deal is allowed if it was independently constructed from authorized inputs. Reading the actual hidden deal from a truth store and merely labeling it “hypothetical” is forbidden.

Actual full-deal truth belongs only to a separately authorized full-information/postmortem context.

Read-only access is not the same as no read access.

If app-server cannot enforce the required boundary, treat that as an explicit blocker and evaluate a different capability boundary/runtime rather than declaring the problem solved by prompt wording.

# 64. Why Agents SDK is not required

The target product intentionally uses **Codex app-server and Codex's own harness** rather than treating Codex as a raw LLM inside an application-owned generic agent loop.

Bridge Coup needs:

```text
one primary strong Codex reasoner
+ Bridge Expert DecisionSession / runtime support
+ meaningful typed BridgeEngine analytical tools
+ scoped pinned Agreement / Knowledge read-search access
+ deterministic BridgeEngine
```

Adding Agents SDK now would create a second agent-runtime abstraction without solving the hardest bridge problems and could obscure the product goal of leveraging the Codex harness directly.

The fact that Codex performs multiple Engine calls and resource searches/reads is **not** by itself a reason to move to Agents SDK; that model-led capability use is part of the intended Codex/app-server architecture.

# 65. Runtime re-evaluation triggers

Reconsider the runtime/transport only when measured requirements cannot be met cleanly.

Re-evaluate Codex app-server tool transport if:

- dynamic tools / MCP cannot reliably support multi-tool continuation in the packaged runtime;
- bidirectional request lifecycle or cancellation is too fragile to maintain;
- required visibility/tool isolation cannot be enforced;
- tool discovery/disclosure behavior materially harms bridge quality and has no practical workaround;
- compatibility burden across Codex releases becomes disproportionate.

Reconsider a second specialist LLM only if future evaluation identifies a genuinely separable reasoning role that should not remain with the primary Codex model. Do not add one merely to compensate for vague tool interfaces; improve the tool semantics first.

Reconsider Agents SDK only if the project intentionally moves away from Codex's native harness and needs an application-owned generic agent runtime for reasons supported by evaluation/maintenance evidence.

Reconsider Agents API if cloud-hosted durable jobs become a requirement, long-running autonomous sessions must survive client shutdown, or local execution is no longer desirable.

Do not migrate merely because another runtime is theoretically more powerful.

# 66. Bridge Coup 2.0 definition of done

This section defines **whole-product completion**, not the first engineering milestone.

Bridge Coup 2.0 is complete only when the agreed in-App expert product satisfies the following.

## Core architecture

- BridgeDomain is logically separate from UI/runtime composition;
- BridgeEngine is logically separate from Codex runtime types and retains the agreed component responsibilities for legality, constraints/belief, scenarios, sampling, DDS, scoring/objectives, evaluation, diagnostics, and statistical semantics;
- Bridge Expert is the single canonical expert-subsystem name;
- Codex is the reasoning brain inside Bridge Expert rather than one of multiple competing expert components;
- Bridge Expert programmatic support remains organized around Declaration, Tool Registration, and Runtime / Resources / Evidence; DecisionSession is the per-run instance rather than a fourth competing architecture layer;
- one user/product request creates one DecisionSession; multiple related sessions may bind the same immutable snapshot, but terminal sessions are never reopened into executable runs;
- cross-session `PlanState`/evidence/summary inheritance preserves source snapshot, perspective/visibility provenance, and information time, and rejects unsafe defender-seat changes or undo-to-earlier-state leakage;
- one accepted fact/event entry point exists;
- immutable snapshots and visibility projection are used for expert actions;
- postmortem truth cannot leak into blind decisions through input, summaries, retrieval, caches, tools, raw experience, or runtime access.

## Model-led capability use and evidence

- Codex may use zero, one, or multiple Engine tools/resource reads per session;
- Codex, not deterministic Swift code, decomposes strategic bridge questions into computational/retrieval questions;
- stable meaningful Engine analytical capabilities are broadly available unless a concrete implementation/invariant reason justifies hiding them;
- implementation plumbing is not exposed merely because it exists;
- lower-level analytical capabilities and proven composite tools may coexist;
- composite tools are conveniences, not mandatory workflows;
- every Engine entry point shares the same session context, permissions, scenario identity, budgets, cancellation/staleness, evidence identity, and lineage semantics;
- model-only answers are allowed only when the request permits and are distinguishable from Engine-supported results;
- requests requiring Engine evidence cannot be silently downgraded;
- Engine-facing tools have explicit typed semantics rather than vague strategic natural-language contracts;
- hand-derived constraints/features distinguish original holding, current remaining holding, and other explicit public information times; this temporal reference is preserved through Engine calls, sampling, evidence, replay, and undo/redo;
- V1 sampled Engine evidence declares and obeys a defined baseline/scenario target distribution rather than treating “feasible” deals as an unspecified probability model;
- DecisionSession evidence lineage and immutable evidence records prevent silent sample replacement or incompatible evidence mixing across repeated sampling/scenario/objective changes, while selective narrative interpretation remains an eval concern;
- session history is auditable without storing private chain-of-thought.

## Knowledge and agreements access

- active agreement profile/version is authoritative session context;
- the session binds the complete effective agreement material set, including applicable supplements/overrides/exceptions and deterministic precedence metadata;
- our agreements, known opponent agreements, public explanations, and unknowns remain distinct;
- knowledge and agreement material may be searched/read natively by Codex only through the pinned authorized view;
- backing-file mutation cannot silently change a running session's resource version;
- resource searches/reads have traceable source/version provenance;
- Codex is clearly instructed that knowledge/agreement resources exist and may be useful, without forcing ritual retrieval;
- when no authoritative agreement material resolves a question, the system preserves unknown/unspecified status rather than fabricating a partnership rule.

## Bidding

- expert next-call decisions work from the correct bidding snapshot;
- legal calls are program-enforced;
- agreement snapshot/material set is explicit/versioned;
- our methods, known opponent methods/public explanations, and unknown methods remain distinct;
- Codex can search/read detailed agreement material under the correct pinned profile/version/precedence;
- result can be recommendation, analysis, conditional advice, needs-input, incomplete, or failure;
- system adherence and explanation quality meet the frozen release protocol.

## Declarer play

- expert plans/recommends from correct decision-time information;
- declarer analysis can produce a complete `PlanState` without forcing unnecessary Engine work;
- hidden information is modeled through belief/sampling when computation requires it rather than silently revealed;
- sampled DDS evidence is correctly qualified;
- Codex can choose among useful lower-level and composite Engine capabilities and search/read knowledge/agreement material when useful;
- a full board can be played with coherent PlanState, fresh snapshots/sessions, stale-state protection, and failure recovery.

## Defense

- defenders never receive partner hidden hand in blind play;
- valid defensive agreements/signals are available through the authorized agreement material;
- correct defender perspective/objective is used;
- Codex can investigate defense-specific uncertainty through supported capabilities without hidden-hand leakage;
- continuous defensive decisions and explanations meet release criteria.

## Teaching and explanation

- teaching quality is evaluated separately from action quality;
- explanations do not contradict visible facts;
- uncertainty/evidence limits are appropriate;
- user can distinguish model judgment, agreement/knowledge grounding, Engine evidence, and postmortem truth.

## Review, experience, and postmortem

- full truth is available only after the appropriate boundary;
- decision-time trace/evidence ledger and postmortem record are linked but access-separated;
- raw experience is unavailable to blind production decisions;
- postmortem/learning can read authorized experience and emit only structured episode/annotation/candidate-lesson writes;
- actual outcome is not confused with ex-ante decision quality;
- error taxonomy can distinguish model decomposition/capability-use, Bridge Expert context/transport/resource access, Engine, evidence interpretation, and execution failures.

## Knowledge and learning quality

- knowledge infrastructure is versioned/in use with provenance/rollback;
- Codex can refine knowledge queries when useful;
- promoted experience requires independent validation and human approval;
- knowledge/agreement changes are rollback-capable;
- held-out answers remain inaccessible to ordinary production decisions.

## Evaluation and release evidence

- development and held-out sets exist;
- action quality, plan quality, severe errors, teaching quality, consistency, uncertainty behavior, problem decomposition, capability-use quality, continuous play, and runtime stability are evaluated;
- broad-vs-narrow Engine tool surfaces and composite-vs-lower-level usage can be ablated where useful;
- fixed-two-pass and/or model-only baselines exist where useful for attribution;
- release thresholds are frozen after baseline/pilot work and before final held-out evaluation;
- regressions are visible;
- actual packaged-App scenarios pass, not only mocks/unit tests.

## Product operation

- existing primary UI remains usable;
- login/runtime discovery remains functional;
- save/reopen/archive behavior works or has an explicit migration path;
- decisions cannot execute after becoming stale;
- perspective, missing input, evidence scope, incomplete runs, and stale status are visible as needed;
- continuous in-App bridge operation is usable at measured, accepted latency.

## External adapters

Xinrui / external autonomous play is **not** part of the Bridge Coup 2.0 release gate. It is a subsequent Bridge Expert integration milestone.

# 67. First Bridge Expert engineering milestone definition of done

This defines the first meaningful **model-led declarer-analysis vertical milestone**, not Bridge Coup 2.0 completion.

### Architecture

- minimal accepted-state adapter exists;
- immutable snapshot and decision-perspective/visible-state projection exist;
- Bridge Expert is logically separate from UI; a DecisionSession instantiates one frozen Declaration plus authorized Tool Registration and Runtime / Resources / Evidence state;
- `Bridge Expert` is the canonical name; no second formal “environment” subsystem is introduced;
- BridgeEngine is logically separate from Codex runtime and its component ownership remains explicit without imposing a new layer taxonomy;
- an initial Engine analytical capability inventory exists with broad-exposure vs internal-plumbing rationale;
- at least two precise Engine capabilities are usable by Codex through thin adapters, with at least one composite path if the semantics justify it;
- no deterministic semantic broker or standalone reasoning validator is introduced;
- Expert does not impose a fixed Pass A / Pass B reasoning workflow.

### Runtime

- intended ChatGPT login path works through app-server;
- Codex can perform multiple typed Engine tool round-trips in one decision session when needed;
- dynamic-tool path is validated or a transport-independent fallback is proven;
- server-originated request handling, tool result return, cancellation, and late-result rejection work;
- scoped native knowledge/agreement read/search is validated, or a thin scoped fallback is proven;
- resource version pinning and observable search/read provenance work;
- runtime isolation assumptions are negatively tested on the supported runtime.

### Declarer analysis

- one real existing declarer-analysis request runs through the full model-led path from partial information;
- a case requiring Engine evidence is handled through Codex decomposition → one or more Engine capabilities → shared session context/evidence rules → structured evidence → Codex;
- a simple case can finish correctly without forced Engine work when the evidence contract permits;
- missing known input is distinguished from hidden cards;
- active agreement identity plus effective material set/version/precedence is available;
- Codex can search/read agreement and knowledge material and refine its own queries;
- Codex is explicitly aware that advanced bridge knowledge is available for use when material;
- final declarer plan uses lightweight `PlanState` and accurate evidence qualification.

### Reliability

- immutable snapshot/session/resource identity and stale-result protection exist;
- session evidence lineage is saved and already-returned evidence is immutable in meaning;
- session event/history trace includes Engine calls and authorized resource accesses;
- V1 sampler target-distribution semantics are explicit and covered by at least one enumerable/toy distribution test;
- repeated sampling cannot silently replace prior sample evidence or mix incompatible baseline/scenario/objective evidence;
- evidence qualification rejects at least one case where a real evidence record exists but does not match the claimed action/feature/objective/scenario;
- hidden-deal invariance tests compare deterministic Engine outputs/evidence, not only request construction;
- agreement/knowledge version invariance tests prove a running session cannot silently read newer backing content;
- related-session inheritance tests cover defender-seat changes, declarer-to-dummy continuity, and undo to an earlier information time;
- temporal feature/constraint tests prove original-holding and current-remaining semantics do not silently swap during continuous play;
- leakage tests pass for the milestone path;
- cancellation/failure/budget exhaustion cannot masquerade as evidence/material that was never obtained.

### Evaluation

- declarer development/holdout structure exists;
- legacy/model-only/fixed-two-pass baseline and model-led results can be compared where useful;
- action/plan and teaching quality can be scored separately;
- basic decomposition/Engine-tool/resource-use metrics exist;
- broad-vs-overly-narrow tool-surface regressions are visible.

Current-play execution, defense, bidding, richer knowledge, experience learning, and full continuous-product acceptance remain later milestones.

# 68. Spec authority map, provenance, and handoff discipline

This section exists specifically to prevent architecture drift while the spec is long and implementation evolves.

## 68.1 Canonical architecture source of truth

When wording elsewhere is ambiguous, use the following authority map:

```text
Expected whole-project architecture / project mental map  Sections 1 and 5.1
Canonical terminology / top-level responsibility rules         Sections 3–6
Bridge Expert three programmatic blocks                 Sections 3.4, 5.2, 6
DecisionSession lifecycle / follow-ups / inheritance    Section 7
Codex app-server/runtime boundaries                     Section 8
Domain/state/visibility/snapshots/temporal semantics    Sections 9–13
BridgeEngine component semantics                        Sections 14–24 + Section 6
Play/declarer/defense/bidding behavior                  Sections 25–31
Bridge Expert Request → Declaration/result contract      Section 32
Tool Registration / capability exposure                 Section 33
Runtime / Resources / Evidence                          Section 34
Final result / evidence support / execution              Section 35
Trace/postmortem/error taxonomy                          Sections 36–37
Knowledge/agreement/experience/learning/evals            Sections 38–51
Repository target                                        Section 53
Milestones / implementation/release gates               Sections 55–67
Security/leakage                                         Section 63
First implementation flow                                Section 69
Final architecture thesis                                Section 70
```

## 68.2 Historical labels that are not current architecture

The following may appear in older specs/history but are **not** canonical Spec 1.3 architecture terms:

```text
Bridge Decision Coordinator        historical v0.x orchestration design
fixed Pass A → Engine → Pass B     evaluation baseline / historical workflow only
Bridge Research Environment        superseded naming; use Bridge Expert
Capability Broker / semantic compiler
                                   rejected extra-intelligence layer
standalone reasoning Validator     rejected
three-layer BridgeEngine           accidental Spec 1.2 drift; rejected
```

Do not reintroduce these merely because an older document or comment contains them.

## 68.3 Preserved vs intentionally changed architecture

Preserved from the earlier agreed platform design:

- BridgeDomain/state/visibility/snapshot principles;
- BridgeEngine's component responsibilities around rules, belief/constraints, sampling, DDS, evaluation, scoring/objectives, diagnostics/statistical semantics;
- separation of `BeliefModel` and `DealSampleSet`;
- sampled-DDS qualification and strategy-fusion caveat;
- PlanState, evidence/replay, postmortem isolation, learning/eval disciplines;
- current DDS implementation as the native solver foundation.

Intentionally changed in the later model-led design:

- fixed application-controlled proposal/evaluation/synthesis is no longer the production reasoning contract;
- Codex now chooses zero/one/many analytical/resource operations;
- Bridge Expert is minimal and has three programmatic support blocks around Codex;
- stable meaningful Engine capabilities are broadly registrable rather than artificially compressed into a tiny tool surface;
- knowledge/agreement retrieval is preferably Codex-native scoped read/search rather than an intelligent retrieval broker.

This distinction should be used when reviewing future changes: do not accidentally treat an intermediate wording change as an architecture decision.

## 68.4 Implementation handoff rule

Before changing a responsibility boundary, a ticket/PR should state:

```text
which canonical responsibility is changing
why current implementation/evaluation evidence justifies the change
which sections/diagrams require revision
what tests prove the new boundary
```

Ordinary class names, file names, or transport details do not require spec changes if responsibility ownership remains intact.

# 69. First implementation principle

Proceed vertically and prove the model-led Bridge Expert on the existing declarer-analysis product surface before building every subsystem horizontally.

```text
existing declarer analysis UI
      ↓
accepted-state adapter
      ↓
DecisionSnapshot
      ↓
Bridge Expert Declaration
      ↓
DecisionSession
      │
      ├─ Codex reasoning / decomposition
      │
      ├─ registered BridgeEngine analytical capabilities
      │      lower-level and/or composite as useful
      │
      └─ scoped active-agreement / knowledge read-search
      ↓
Runtime / Resources / Evidence
      EvidenceLedger + resource provenance + SessionEvent trace
      ↓
Codex final plan
      ↓
BridgeExpertResult / PlanState + explanation
      ↓
existing UI
```

This proves the new architecture end-to-end.

Do not require a tool call merely to exercise the mechanism. The slice must include representative cases where computation materially helps and cases where it does not.

Do not create a vague high-level “compare plans” tool merely to make the vertical slice easy. Do not hide meaningful analytical capabilities merely because a composite path exists.

Knowledge/agreement access should prove Codex-owned query refinement against pinned authorized resource views, not a deterministic semantic retrieval broker.

The first vertical slice should also prove that the three Bridge Expert programmatic blocks remain distinct in responsibility even if their initial physical implementation shares files/targets.

Only after this works should the system expand to executable current-play decisions, continuous declarer, defense, bidding, richer inference/weighting if justified, knowledge expansion, experience learning, and external adapters.

Every milestone should ship a runnable scenario and regression evidence and state which parts of the total 2.0 Definition of Done remain incomplete.

# 70. Final architecture thesis

Bridge Coup should be understood first as a **bridge application + platform**, not as Bridge Expert alone. The expected architecture is:

```text
Bridge Coup
├── Bridge App
├── Bridge Platform Core
│   ├── BridgeDomain
│   ├── BridgeEngine
│   └── BridgeExpert
├── Bridge Assets
│   ├── agreements/
│   ├── knowledge/
│   ├── experience/
│   └── evals/
├── Native / DDSHelper
└── Engineering Support
```

This is a responsibility map, not a frozen physical tree. Implementation may adjust folder/target boundaries when repo-grounded evidence supports a better structure, but responsibility ownership and information boundaries should not drift silently.

Within that platform, Bridge Expert should **not** become a giant prompt plus bridge books plus DDS, and it should **not** become a giant deterministic workflow that dictates every reasoning step to an increasingly capable model.

## Bridge Expert

```text
Bridge Expert
│
├── Codex
│     owns bridge reasoning and judgment
│
├── Declaration
│     owns the frozen decision/run contract
│
├── Tool Registration
│     exposes useful Engine capabilities and authorized resources
│
└── Runtime / Resources / Evidence
      owns run control, pinned resources, evidence lineage, and trace
```

## Bridge Engine

```text
BridgeEngine
    rules / legality
    constraints / BeliefModel / scenario mechanics
    DealSampler / DealSampleSet
    DDS
    scoring / DecisionObjective
    candidate / action evaluation
    hidden-feature / distribution analysis where implemented
    diagnostics / statistical semantics / deterministic caching
```

BridgeEngine is component-based computational infrastructure. It is **not** organized as the same three-part structure as Bridge Expert.

## Supporting platform domains

```text
BridgeDomain
    authoritative bridge language / facts / snapshots / visibility

agreements/
    pinned, versioned, precedence-aware authoritative material

knowledge/
    pinned curated bridge knowledge

experience/
    isolated from blind decisions; structured learning/postmortem flow

evals/
    development/holdout/rubrics isolated from production decision access
```

## Runtime relationship

```text
Authoritative Bridge State
        ↓ immutable DecisionSnapshot
Bridge Expert Declaration
        ↓
DecisionSession + Codex
        ├─ registered Engine tools ─────► BridgeEngine
        └─ scoped read/search ──────────► agreements/ + knowledge/
        ↓
Runtime / Resources / Evidence
        ↓
BridgeExpertResult
        ↓
application/UI execution boundary
```

Central session rule:

> **One user/product request is one DecisionSession. Related sessions may share a snapshot and explicitly inherit only artifacts that remain authorized under the target session's perspective, visibility time, assumptions, and objective semantics.**

Central temporal rule:

> **Hand-derived constraints and features must distinguish original holding from current remaining holding (or another explicit public information time); Engine and evidence semantics may not silently switch that reference.**

Central naming rule:

> **Bridge Expert is the whole expert subsystem. Codex is its reasoning brain. Declaration, Tool Registration, and Runtime / Resources / Evidence are the three programmatic support blocks.**

Central control rule:

> **Program owns invariants; model owns judgment.**

Central Engine rule:

> **BridgeEngine owns bridge computation through concrete components; Tool Registration may expose stable analytical capabilities broadly, but tool exposure does not redefine Engine architecture.**

Central capability rule:

> **Expose useful stable analytical capabilities by default; keep implementation plumbing private; allow composite shortcuts without forcing Codex through them.**

Central resource rule:

> **Codex owns knowledge/agreement search and interpretation; Declaration/Runtime own which pinned versioned material is authoritative and readable.**

Central evidence rule:

> **Simulation and DDS are structured evidence under explicit assumptions, not proof that an imperfect-information policy is optimal. Evidence records preserve actual analysis objective, scenario, sample basis, versions, limitations, and immutable lineage.**

Central state rule:

> **Stored truth, decision-visible information, model belief, sampled worlds, evidence records, versioned resource views, and postmortem truth are different objects and must not be silently collapsed into one another.**

Central product rule:

> **Bridge Coup 2.0 is the complete in-App expert product. External autonomous-play adapters come afterward and do not block the 2.0 release.**

That is the Spec 1.4 target system and the implementation baseline to use unless development evidence justifies an explicit architecture revision.
