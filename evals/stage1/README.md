# Stage 1 evaluation

Current bounded acceptance is recorded in [the Stage 1 reports](../../docs/acceptance/stage1/README.md). Complete native records and historical experiments have moved to [the recoverable archive](../../docs/archive/README.md). Run output must be outside the source checkout; use a shared `--artifact-store` for a batch. Persistent catalog evidence uses SHA-256 objects and relative per-role links; move the store with the batch.


Stage 1 remains subject to quality acceptance. The current reviewed pipeline implements the amendments in issues #46/#48 through tickets #49–#52; the original #36 requirements remain where those amendments do not replace them. Historical ticket 37 demonstrated an initial decision/execution path and preserved severe model-quality failures; see [its review](../../docs/archive/README.md "Original archive path: evidence/ticket37/REVIEW.md"). Historical execution results and current runtime tests do not establish stage acceptance.

Build and run an initial decision with a new evidence directory:

```sh
swift build --product bridge-play
.build/debug/bridge-play \
  --fixture evals/stage1/fixtures/synthetic-initial.json \
  --output /tmp/bridge-initial-attempt-unique \
  --codex /absolute/path/to/codex \
  --timeout 180
```

The fixture contains environment-only complete holdings. Only declarer/dummy holdings and actual public events enter Expert. Current authentication comes from `$CODEX_HOME/auth.json`, falling back to `~/.codex/auth.json`; the adapter copies it into a temporary isolated runtime, then removes that runtime on disposal. Saved evidence contains no authentication. Both the player and independent runtime reviewer request and verify gpt-6.1-sol / medium; unavailable or mismatched identities fail visibly. The acceptance grader runs separately from both live roles.

Before starting a playing thread, the adapter reads the installed runtime's bundled catalog with `codex debug models --bundled`, under the same request deadline. It preserves the complete metadata and changes only Sol's `tool_mode`, `experimental_supported_tools`, `apply_patch_tool_type` and `shell_type` to disable tools. The runtime config also disables question tools and time reminders. There is no tool-enabled fallback if catalog discovery fails. Each role saves `runtime-bundled-catalog.json`, `runtime-model-catalog.json` and `runtime-config.toml` (player at the run root, independent review attempts under `reviewer/REQUEST-ID/`); the offline production-boundary regression checks that the actual HTTP request contains `additional_tools.tools: []`. This changes the tool surface, not the playing instructions or continuing reasoning-history policy.

For exact effective-request auditing, start the optional transparent proxy separately:

```sh
python3 Scripts/capture-playing-wire.py \
  --codex /absolute/path/to/codex \
  --output /tmp/bridge-wire-attempt-unique
```

Pass its printed wrapper path as the driver's `--codex` value. Keep the proxy running for that attempt and stop it afterward. The local proxy forwards unchanged Responses payload bytes to the official ChatGPT Codex endpoint, saves the payload and public response metadata, and stores no headers or reasoning stream. It explicitly changes provider routing to observe the request; capture-config.json records that difference. The model/effort remains unchanged. The proxy binds only to loopback. Use unique output directories to preserve each attempt.

`ExpertSession.decide` is the public Expert boundary. It prepares an execution-authorized pending candidate after runtime review; `BoardDriver.advance` applies the canonical rules and commits the exact candidate's card and matching plan once. Domain/Engine have no Codex or UI dependencies. Continuous turns and complete-board execution use this path. Independent acceptance grading remains separate: legality, reviewer approval and contract result do not establish delivered quality. Earlier failed quality evidence remains preserved.

## Saved-output evaluation

Issue 38 introduced the Python saved-output entry. The current evaluator reads saved Expert decisions and actual RPC/execution evidence, including reviewed proposals and final execution disposition; it never invokes the playing model. The examples below also support preserved historical decisions. From the repository root:

```sh
python3 -m pip install -r evals/stage1/requirements-test.txt
python3 -m unittest discover -s evals/stage1/tests -v
python3 evals/stage1/evaluate.py grade \
  --decision "$BRIDGE_ARCHIVE_ROOT/recovered/ticket37/live2" \
  --decision "$BRIDGE_ARCHIVE_ROOT/recovered/ticket37/live3" \
  --output /tmp/bridge-saved-grade-unique
python3 evals/stage1/evaluate.py grade \
  --answers evals/stage1/calibration/answers.json \
  --output /tmp/bridge-calibration-unique
python3 evals/stage1/evaluate.py regrade \
  --run /tmp/bridge-saved-grade-unique \
  --output /tmp/bridge-offline-regrade-unique
```

Each `grade` makes an independent `codex exec` request for gpt-6.1-sol / medium. It saves the rubric and actual authorized input, original answer, mechanical checks, schema, isolated configuration, command, runtime version, timing and public grader output. No expected labels or complete hidden deal enters its package. The grader runs in a new independent thread and its output never returns to Expert. `regrade` repeats local parsing/adjudication of those saved grades without any model call; to get a fresh independent judgment of the same player output, repeat `grade` with a new output directory. Nonzero grader exit, timeout, actual tool use, bad result structure and invalid citations remain evaluator issues with uncertain quality, preserving separately observed mechanical failures. Unresolved uncertainty requires review.

The current citation contract is rubric `stage1-basic-v4`: every status requires at least one finding with `quotes: ["one exact contiguous excerpt", ...]`. Each excerpt must occur verbatim in the actual raw or decoded public answer. Separate excerpts remain separate strings. Historical v2/v3 outputs and legacy v1 single-contiguous `quote` fields remain readable for reprocessing; original grades retain their original contracts. See the [Eval correction review](../../docs/archive/README.md "Original archive path: evidence/correction-eval/REVIEW.md") for the schema/validator mismatch, preserved failures and pending live validation. The narrow `--reviewed-parser-fix REASON` option only supersedes the recorded initial bug that misclassified CLI `item.type=error` notices as tools, provided the original CLI exited zero and every recorded tool item was exactly `error`; it cannot override real tools or a failed exit. Such review provenance is saved.

The evaluator reads historical v1–v4 records and current v5 (`stage1-full-snapshot-v5`). Card decoding and action association remain localized in `deterministic_checks`; original failed attempts retain their own contract versions. The approved input amendment is tracked in [issue #46](https://github.com/absurdwall/bridge-coup/issues/46).

See [ticket 38 review](../../docs/archive/README.md "Original archive path: evidence/ticket38/REVIEW.md") for calibration, live-output judgments, evaluator corrections and isolation limits. Authored calibration failures are intentional bad examples, not new observed product defects. Six reviewed answers and two repeat grades establish only a small calibration checkpoint.


## Continuing short runs

Historical ticket 39 introduced the public `BoardDriver.advance` one-action entry and continuing `ExpertSession`; [its review](../../docs/archive/README.md "Original archive path: evidence/ticket39/REVIEW.md") distinguishes working execution from failed basic model quality. The current #46/#48 path uses complete authorized snapshots, program-owned plan provenance and one frozen pending position across review and revision.

```sh
.build/debug/bridge-play \
  --fixture evals/stage1/corpus/boards/synthetic.json \
  --output /tmp/bridge-continuation-unique \
  --codex /absolute/path/to/codex \
  --timeout 180 --decisions 8 --opponent conserve-high
```

`--decisions` bounds delivered model-controlled decisions (1–26, default 1), not player proposals, reviewer calls or technical attempts. A delivered decision can include several player revisions and reviews. All dummy and declarer decisions use the same Expert/player thread; `--sole-legal true` permits later sole-legal mechanics while still requiring the initial model plan. Fixtures may supply ordered `initialEvents` for a reachable mid-board state. Each multi-decision run saves `decision-NNNN/decision.json` and its immediate post-action `events.json`. Player RPC stays at the run root; independent reviewer RPC is saved under `reviewer/REQUEST-ID/`. The authoritative per-action `trace.json` includes role-attempt evidence. Invalid proposals and exhausted recovery preserve their raw outputs and failure evidence without executing a substitute card. Valid revise/uncertain judgments use the bounded in-product feedback loop.

Historical ticket 39 used wire version `stage1-plan-publicReason-selectedCard-v2`: `plan`, `publicReason`, then the single `selectedCard`, mapped to internal `currentCard`. Saved v1 evidence remains readable. Evaluation's exact-citation check also accepts excerpts of the actual retained effective plan on keep turns, because it is prior model advice from the same run. A parser regrade never calls a playing model.

Historical evidence: the three first developmental continuity attempts are preserved, including illegal cards and serious plan/reason failures. They were concurrent across boards and sequential within each board; their durations are exploratory resource conditions, not final sequential board timings. No stage quality pass is claimed.


## Complete-board driver (ticket 40)

```sh
.build/debug/bridge-play \
  --fixture evals/stage1/corpus/boards/synthetic.json \
  --output /tmp/bridge-full-development-unique \
  --codex /absolute/path/to/codex \
  --full-board true --sole-legal true --opponent conserve-high \
  --timeout 180 --run-timeout 1800
```

Full mode continues through all 52 actual plays, including any opponent play after the final controlled decision. The first controlled action always requests an initial plan, even with a sole legal card. Later sole-card mechanics are labeled `forced` and enter the next complete snapshot as actual plays. No nonforced action comes from the driver, policy, or free-text plan. Short mode still stops at `--decisions` (default 1).

Current wire contract `stage1-full-snapshot-v5` sends a complete authorized JSON snapshot at each new pending decision, with the prior active plan carried verbatim as `effectivePlan`. Revisions use feedback envelopes containing the unchanged canonical snapshot and actual prior candidate/reviewer feedback. Engine supplies remaining hands, actual trick history and winners. Expert loads the fixed [player instructions](../../Sources/BridgeExpert/Resources/DeclarerInstructions.txt) for the continuing player thread and [reviewer instructions](../../Sources/BridgeExpert/Resources/ReviewerInstructions.txt) for independent review. Player output order is plan → selectedCard → publicReason; replace requires nonblank text, keep/withdraw require explicit null, and an initial proposal requires replace even during revision. The player receives legal choices through its response-schema enum; the reviewer receives `legalCurrentCards`. Engine checks ownership, turn, follow-suit and snapshot freshness at execution. An active plan may be review-approved or released as contested play; its status does not imply approval. Independent evaluation grades delivered advice and execution, retaining rejected drafts diagnostically. Serious reasoning or plan errors still fail quality. Historical failures remain unchanged.

For joint inspection, launch `Scripts/step-playing.sh --fixture FILE --output DIR --codex EXECUTABLE` directly from a live terminal. The launcher preserves terminal input, enables interactive stepping with capacity for 26 decisions, and rejects missing terminal input before starting a board. After each delivered model decision, `next` requests one more reviewed decision in the same player thread; `stop` ends the run. Manual stepping pauses count toward the run protection limit. Recoverable human needs-input waiting is recorded separately and excluded from automatic runtime; this is distinct from a manual `next` pause. Build bridge-play before launching.

`trace.json` separates actual player request attempts (including revisions), reviewer attempts, valid semantic reviews, technical reviewer retries, delivered model actions, forced mechanics and opponent actions. `modelRequests`/`playerRequests` count player attempts; they do not count delivered decisions. Late observations reuse their request UUID and are excluded from attempt counts. Counts in `steps` cover only actions after driver entry; `initialEvents`, `initialControlledActions` and `initialOpponentActions` cover the supplied prefix. Actual app-server `turn/start` and upstream HTTP counts are audited separately because startup failures can occur before a native turn and the runtime can make internal transport attempts.

Trace evidence includes first/later delivered-decision latencies covering both roles and revisions, per-role attempt timings and observed token usage, failed-request latency, total elapsed and automatic runtime, human needs-input waiting, overhead, trick totals and failure. Missing usage remains unknown. Native per-turn and upstream HTTP token totals are separate observations and must not be added together. The clock starts at exposure/driver setup and includes runtime startup. Last-controlled-action timing includes forced actions; full driver elapsed can also include trailing opponents.

Each pending decision permits at most five valid semantic reviews, including the initial review. An approved exact candidate executes once; after a fifth valid unresolved judgment, a current structurally valid legal candidate may execute once as contested play with its matching plan. Preserve the actual reviewer verdict. Each candidate review permits one initial technical attempt plus at most three retries. Technical failures consume no semantic round; exhausted technical recovery stops without contested release. Invalid player replies, identity/state failure or session loss stop without a fresh player conversation or replacement card.

Operational protection limits are 180 seconds per native request and 1,800 seconds of automatic runtime per board, covering both roles, retries, revisions, startup and processing. A lower configured or remaining limit takes precedence. The adapter sends termination at the request deadline, then SIGKILL after 0.2 seconds if necessary; observed process teardown adds a small scheduling/cleanup margin. Late results cannot execute. Explicit human needs-input waiting is measured separately. These protection limits introduce no three-minute quality or speed gate. A fresh diagnostic run needs a new output directory; acceptance attempts follow the fixed schedule below.

The limited `pavlicek-entry` environment policy implements the frozen short-5 manifest: East ducks a low diamond under North's first DK/DQ while retaining DA/DJ, and covers North D9 with DJ when held. Other choices use the legal state-aware conserve-high policy. It is a teaching-case policy, not a general defense platform. Engine's basic trick-winner rule is shared with this policy. Historical ticket 40 did not run the reserved board; the formerly reserved acceptance board has since been exposed and is now labeled regression evidence in the frozen corpus.

## Finite final acceptance

Freeze acceptance with the native Codex executable as `--codex` to attest the actual runtime binary. The supplied executable hash and bundled catalog hash are checked before each attempt, and the attempt's discovered catalog must match the frozen one. Supplying a launcher remains supported, but its hash alone does not attest its native child; the candidate records this limitation.

`acceptance.py` freezes one committed candidate and executes the corpus's 22 predeclared attempts sequentially. Use a freshly built production `bridge-play` binary from that source commit. It refuses changed source/binary/runtime or a changed run schedule; it never rerolls an attempt or resumes an already started matrix. Bounded in-product revisions and technical reviewer retries remain part of that original attempt. The fixed matrix is six short scenarios three times each plus two complete notrump boards twice each. At most three substantive frozen-candidate validation cycles are authorized by #48; failures are preserved rather than replaced or combined across versions.

```sh
python3 evals/stage1/acceptance.py freeze --binary /absolute/path/to/bridge-play --codex /absolute/path/to/bin/codex --output /absolute/new/evidence-directory
python3 evals/stage1/acceptance.py run --output /absolute/new/evidence-directory
```

Each attempt saves an exact-byte wire audit for both roles, production trace and all proposals/reviews, independent replay, original independent grade of delivered advice, per-role timings/costs and summary. The top-level report includes every attempt and all four full-board durations. Complex trigger predicates remain pending independent review. A completed board or a legal selected-card enum does not imply correct public plans/reasons; no-go and disputed results remain visible. An operationally interrupted matrix is incomplete evidence and cannot be restarted over its existing attempt directories.

## Reviewed case execution conditions

`case-execution.json` is the versioned source for per-case execution options, frozen in candidate metadata and the exact schedule. In `stage1-reviewed-case-execution-v1`, only short-3's three repetitions disable mechanical sole-legal skipping. The other nineteen attempts retain it. Corpus v2, rubric v4, all board bytes, the 22-attempt matrix and short-3's twelve delivered-decision bound stay unchanged. A sole legal card now consumes a reviewed model delivery in that case, increasing model work and potentially reaching the bound after fewer actual plays. This is not a prompt-only controlled comparison.

The short-3 coverage screen records both event-only and actual model windows before the other defender's **first club show-out**. A third club discarded on another suit can provide the same public count inference. Eligibility alone does not prove semantic use: independent adjudication must verify all three core tasks/quality and at least one correctly used eligible pre-show-out model window in the prescribed cohort. Prior equivalent public deductions and every unexercised window stay explicit. No extra repetition, forced route or bound extension is permitted to obtain coverage. Historical candidate-1 predicates/summaries remain unchanged; the [material revision log](corpus/revision-log.md) records the impact.
