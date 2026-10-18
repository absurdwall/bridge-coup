# Ticket 37: one real decision path; model quality failed

Scope: Issue #37, under #36. Baseline includes the approved design commits af64e7a and c210962. This is an App-independent engineering milestone, not stage acceptance or a claim of basic model correctness.

## Actual attempts

| Attempt | Effective representation | Result |
| --- | --- | --- |
| live1 | Initial raw snapshot JSON | Infrastructure failure before inference: output schema lacked a closing brace. No `turn/start` was sent. Fixed with a failing public Expert request-schema test, then green. |
| live2 | Raw snapshot JSON, isolated home and disabled unrelated context | Real gpt-6-luna / medium returned DA for North's D8653 and claimed dummy held DA. Engine rejected `cardNotHeld`; board stopped. Severe factual/physical failure. 5.822 seconds including driver/transport startup. |
| live3 | Concise English seat-first holdings, controller/actor, actual public events once | Real gpt-6-luna / medium returned legal North D3, applied once. Reason claimed D8 beats DQ; plan prescribed winning with D8 and called North's 862 a spade stopper. Severe factual and action/reason/plan consistency failure. Board stopped after that controlled action. 10.126 seconds including transparent wire capture and driver/transport startup. |

No answer regeneration, semantic correction, replacement card or reroll-to-pass occurred. The sole intervening model-facing change after live2 made seat ownership and acting-hand roles easier to read; it supplied no bridge answer, winner count, club route or rubric. Both model-quality failures remain failures for subsequent regression and evaluation work. No complete board was attempted.

The CLI's successful exit in live3 means that a readable legal current card executed. The independent review above fails its quality; runtime deliberately does not reinterpret all model prose to decide whether to execute an otherwise legal card.

## Effective request and identity

`live3-wire/request-0.json` is the exact JSON payload forwarded unchanged to the official ChatGPT Codex Responses endpoint. `capture-config.json` records the transparent audit provider and routing override. The proxy stores no request or response headers, authentication, or reasoning stream. It preserves only requested payload and public response identity/usage in `response-metadata-0.json`.

Requested model/effort: gpt-6-luna / medium. Runtime: codex-cli 0.160.0. Thread/start acknowledges gpt-6-luna / medium; the upstream live3 response also reports gpt-6-luna. These observable names do not establish the remote service's internal model identity. The recorded live3 response reports zero reasoning tokens; no explanation of that count is inferred. Sorted wire-schema properties and actual output order are currentCard, plan, publicReason. Historical plan/reason-before-action guidance is an investigation pointer for a later contract version, not an established cause of these errors.

The playing runtime gets fresh temporary HOME, CODEX_HOME and cwd. Only the current auth file is copied; no project repository, AGENTS.md, user skills, hidden holdings, eval expectations, future events, archive, knowledge corpus, or grader output enters the prompt. Per-skill exclusions and orchestrator configuration remove generated system skill descriptions as observed in the captured request. The play instructions are the 477-character English paragraph in DecisionRecord and the payload.

The catalog-selected Codex runtime still injects its v2 collaboration role/mode and built-in tools. The captured `additional_tools` has functions.exec/wait/request_user_input and collaboration functions; exec's nested surface contains apply_patch and clock only. There is no shell/file-reading tool, MCP, Engine analysis tool, Knowledge retrieval or bridge calculation tool. No tool invocation occurred. Feature flags alone did not remove catalog-selected built-ins; this limitation is recorded rather than silently rewriting the catalog or payload.

Earlier local 400 capture probes performed no inference. Their role was to discover and remove inherited context before the real attempts; they are not model-quality samples. A first wrapper probe could not find Node in its deliberately restricted PATH, and a second tried a forbidden built-in provider override; neither reached inference.

## Boundaries and validation

BridgeDomain contains values, public events, immutable snapshots and program-owned current-action associations. BridgeEngine depends only on BridgeDomain and owns holdings, turn/follow-suit legality, trick advancement and fresh one-shot execution. BridgeExpert depends only on BridgeDomain; ExpertSession is the highest public playing entry. BridgeCodex adapts that entry to app-server without UI. The CLI owns full environment holdings and calls the same Expert entry future UI will use. No archived implementation was restored.

TDD logs record public legal-execution, Expert request/advice, strict output-readability and transport-timeout slices. The input-representation change is covered at the public Expert entry. A timeout also bounds the version probe, and transport failures retain actual input and elapsed duration. This ticket does not establish continuous thread recall, full-board success, advanced trump rules acceptance, grader calibration or the finite stage quality bar; those remain downstream work.

Final full Swift suite: 206 tests, 10 pre-existing DDS/runtime skips, zero failures. See full-tests.log. Skips do not establish stage acceptance.
