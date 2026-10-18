# Stage 1 App-independent playing core

The six-ticket stage is still in progress. Ticket 37 demonstrates one actual decision/execution path and preserves severe model-quality failures; see [its review](evidence/ticket37/REVIEW.md). No stage acceptance is claimed.

Build and run an initial decision with a new evidence directory:

```sh
swift build --product bridge-play
.build/debug/bridge-play \
  --fixture evals/stage1/fixtures/synthetic-initial.json \
  --output /tmp/bridge-initial-attempt-unique \
  --codex /absolute/path/to/codex \
  --timeout 180
```

The fixture contains environment-only complete holdings. Only declarer/dummy holdings and actual public events enter Expert. Current authentication comes from `$CODEX_HOME/auth.json`, falling back to `~/.codex/auth.json`; the adapter copies it into a temporary isolated runtime, then removes that runtime on disposal. Saved evidence contains no authentication. The playing configuration is fixed to gpt-6-luna / medium and fails visibly when unavailable.

For exact effective-request auditing, start the optional transparent proxy separately:

```sh
python3 Scripts/capture-playing-wire.py \
  --codex /absolute/path/to/codex \
  --output /tmp/bridge-wire-attempt-unique
```

Pass its printed wrapper path as the driver's `--codex` value. Keep the proxy running for that attempt and stop it afterward. The local proxy forwards unchanged Responses payload bytes to the official ChatGPT Codex endpoint, saves the payload and public response metadata, and stores no headers or reasoning stream. It explicitly changes provider routing to observe the request; capture-config.json records that difference. The model/effort remains unchanged. The proxy binds only to loopback. Use unique output directories to preserve each attempt.

`ExpertSession.decide` is the public Expert boundary for future driver and UI use. Domain/Engine have no Codex or UI dependencies. Runtime checks card legality; semantic quality evaluation remains separate, so legal-card execution alone is never a quality pass. Continuous turns are implemented in ticket 39 with preserved failed quality evidence; full-board play and final acceptance remain later tickets.

## Saved-output evaluation

Issue 38 adds a standard-library Python entry. It reads saved Expert decisions and actual RPC/execution evidence; it never invokes the playing model. From the repository root:

```sh
python3 -m unittest discover -s evals/stage1/tests -v
python3 evals/stage1/evaluate.py grade \
  --decision evals/stage1/evidence/ticket37/live2 \
  --decision evals/stage1/evidence/ticket37/live3 \
  --output /tmp/bridge-saved-grade-unique
python3 evals/stage1/evaluate.py grade \
  --answers evals/stage1/calibration/answers.json \
  --output /tmp/bridge-calibration-unique
python3 evals/stage1/evaluate.py regrade \
  --run /tmp/bridge-saved-grade-unique \
  --output /tmp/bridge-offline-regrade-unique
```

Each `grade` makes an independent `codex exec` request for gpt-6.1-sol / medium. It saves the rubric and actual authorized input, original answer, mechanical checks, schema, isolated configuration, command, runtime version, timing and public grader output. No expected labels or complete hidden deal enters its package. The grader runs in a new independent thread and its output never returns to Expert. `regrade` repeats local parsing/adjudication of those saved grades without any model call; to get a fresh independent judgment of the same player output, repeat `grade` with a new output directory. Nonzero grader exit, timeout, actual tool use, bad result structure and invalid citations remain evaluator issues with uncertain quality, preserving separately observed mechanical failures. Unresolved uncertainty requires review.

The final citation contract is rubric `stage1-basic-v2`, with `quotes: ["one exact contiguous excerpt", ...]` for every finding. Each excerpt must occur verbatim in the actual raw or decoded public answer. Separate excerpts remain separate strings. Legacy v1 single-contiguous `quote` fields remain readable for historical reprocessing. The narrow `--reviewed-parser-fix REASON` option only supersedes the recorded initial bug that misclassified CLI `item.type=error` notices as tools, provided the original CLI exited zero and every recorded tool item was exactly `error`; it cannot override real tools or a failed exit. Such review provenance is saved.

The playing contract consumed here is `currentCard`, `plan`, `publicReason`, version `stage1-currentCard-plan-publicReason-v1`. Card decoding and action association are localized in `deterministic_checks`; a later playing wire-contract change must update/revalidate that boundary, retaining all original failed attempts.

See [ticket 38 review](evidence/ticket38/REVIEW.md) for calibration, live-output judgments, evaluator corrections and isolation limits. Authored calibration failures are intentional bad examples, not new observed product defects. Six reviewed answers and two repeat grades establish only a small calibration checkpoint.


## Continuing short runs

Ticket 39 adds the public `BoardDriver.advance` one-action entry and continuing `ExpertSession`, with fresh snapshot-bound DecisionSessions, actual-event deltas and program-owned plan provenance. [The ticket 39 review](evidence/ticket39/REVIEW.md) distinguishes working execution from failed basic model quality.

```sh
.build/debug/bridge-play \
  --fixture evals/stage1/corpus/boards/synthetic.json \
  --output /tmp/bridge-continuation-unique \
  --codex /absolute/path/to/codex \
  --timeout 180 --decisions 8 --opponent conserve-high
```

`--decisions` bounds model requests (1–26, default 1). All dummy and declarer decisions use the same Expert; `--sole-legal true` permits later sole-legal mechanics while still requiring the initial model plan. Fixtures may supply ordered `initialEvents` for a reachable mid-board state. Each multi-request run saves immutable `decision-NNNN/decision.json` and its immediate post-action `events.json`; shared thread RPC and the authoritative per-action `trace.json` stay at the run root. Illegal selected cards preserve their unexecuted decision and failure. Unreadable/transport failures preserve raw evidence and stop; no automatic answer repair occurs.

The current wire version is `stage1-plan-publicReason-selectedCard-v2`: `plan`, `publicReason`, then the single `selectedCard`, mapped to internal `currentCard`. Saved v1 evidence remains readable. Evaluation's exact-citation check also accepts excerpts of the actual retained effective plan on keep turns, because it is prior model advice from the same run. A parser regrade never calls a playing model.

The three first developmental continuity attempts are preserved, including illegal cards and serious plan/reason failures. They were concurrent across boards and sequential within each board; their durations are exploratory resource conditions, not final sequential board timings. No stage quality pass is claimed.
