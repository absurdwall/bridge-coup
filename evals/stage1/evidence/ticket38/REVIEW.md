# Ticket 38: independent saved-output evaluation

Issue 38 implementation uses the approved Python Eval seam. It adds one standard-library Python entry, rubric and structured grading contract, ten public tests, and durable calibration/evidence files. No playing model was rerun; no playing instructions or runtime code were changed. Baseline is integration commit 3515a48, including the approved preparation docs. This is a grading checkpoint, not stage 1 playing acceptance.

## Final results and independent review

Final contract: `stage1-basic-v2`; requested grader gpt-6.1-sol / medium, codex-cli 0.160.0. Calibration uses the original six authored answers A–F, not new player outputs. Both repeat requests use the same final rubric, schema and runtime configuration.

| Evidence | Mechanical result | Independent quality result | Duration |
| --- | --- | --- | --- |
| calibration-v2-r1 | E fails ownership/follow-suit; other current cards legal; authored answers not executed | A/B pass, C/D/E/F fail, 6/6 matches reviewed labels | 21.576 s |
| calibration-v2-r2 | Same | A/B pass, C/D/E/F fail, 6/6 matches reviewed labels | 19.809 s |
| saved-decisions-v2: live2 | DA is absent from acting North; runtime rejected it | Fail: invents North's DA and an impossible opening play | Shared request 11.253 s |
| saved-decisions-v2: live3 | Legal D3 actually executed once | Fail: D8 cannot beat DQ; selected D3 conflicts with plan/reason D8 | Same request |
| saved-decisions-v2: live1 | Pre-inference schema/runtime failure retained; no answer to grade | Quality uncertain, explicitly runtime_failure; never sent to grader | No grading request for this item |

The root agent independently read every final calibration and actual-output finding. Review agrees with the concrete facts: A has a feasible low-club-to-Q route; B can cash AK, cross to Q, then lead a low heart to HA to cash the established clubs. B is not rejected for choosing a different route. C invents SJ; D requires six opposing clubs although only five are missing; E acts from the wrong holding and fails to follow diamonds; F treats an unknown distribution as proven. Live2's nonexistent DA and live3's false winner/action disagreement are material product defects. The original bad playing attempts remain failures.

Authored C–F are deliberate calibration errors, not four newly observed product defects. Their generic `product_error` attribution identifies answer-side rather than evaluator-side error; their authored provenance is in `calibration/answers.json`, and no live runtime identity or execution is claimed. The mechanical summary reports absence of execution in its per-check `uncertain` entry. Legal current-card checks do not grade the prose.

No unresolved alternative-line dispute was promoted to pass. These six answers and repeat grades do not establish broad grader reliability. The final judgments are independently reviewed agent judgments, not claimed human expert review.

## Saved-output and boundary checks

The runner reads actual `decision.json`, RPC request/completion and actual execution or failure evidence. Deterministic checks cover output shape, actor/controller association, card ownership, follow-suit, immutable action binding and exact one-card event advancement. It checks the saved request/output occurs in actual RPC evidence. Grading includes actual authorized input, playing instructions, raw answer, effective plan, visible snapshot and mechanical facts; expected labels and hidden defender holdings are excluded. A snapshot containing defender hands is rejected before packaging.

`regrade` reparses the saved grader output without invoking either model. `saved-decisions-v2-offline/evaluation.json` is exactly equal to the original final evaluation, including live1 runtime failure. Grader exit failures, attempted tools, missing results and absent citations cannot turn into product quality passes. A grader failure keeps quality uncertain/evaluator_issue while any known mechanical failure remains overall fail. Public regressions cover these distinctions.

`pre-inference-runtime/` demonstrates a no-answer failure with an intentionally unavailable grader executable: no grading call occurs. TDD red/green logs are in `tdd/`; the final ten-test run passed. No Swift source changed, so the already-verified 206-test Swift baseline was not redundantly rerun for this Python-only change.

## Corrections preserved

- `infrastructure-node-path/`: the initial grader launch could not find Node in the restricted PATH and exited 127 before inference. The adapter now explicitly includes the selected executable's directory. This is evaluator infrastructure failure, not player quality evidence.
- `calibration-r1/`: v1 grading itself gave the reviewed labels, but the adapter mistook CLI diagnostic `item.type=error` entries for tools and marked evaluator_issue. `calibration-r1-reprocessed/` is an intermediate artifact from the original overly permissive offline parser, superseded by `calibration-r1-reviewed/` with explicit review provenance. Offline regrade now preserves actual runtime/tool failures; its narrow documented parser-fix option only handles that exact diagnostic classification error after review. The four matching notices are visible in `calibration-r2/public-events.jsonl`.
- `calibration-r2/`: v1 six-answer grades and cited reasoning retained. The CLI reported ignored `base_instructions` and `tools.view_image` settings; both ineffective settings were removed from the final config. A disabled code-mode-host notice and skip-host-skill-discovery warning remain honestly recorded.
- `saved-decisions/`: v1 grader correctly failed both actual answers, but combined separate passages into one quote string. The exact-contiguous citation validator marked evaluator_issue. Root independently verified those passages and factual findings. The final schema uses an explicit `quotes[]` array with individually exact, contiguous excerpts. V2 was calibrated twice after this grader-only contract change, and the same saved playing answers were graded with v2. No fuzzy citation repair, playing rerun or playing prompt change occurred.
- `calibration/preparation-revision-log.md` and `source-case-corrections.md`: prior material corrections preserved, including the club-count inference time, malformed Walker hand counts and Pavlicek information time. These are evaluator resources, not playing knowledge or a completed ticket 41 corpus.

## Identity and isolation

Each grader uses a separate `codex exec`, fresh temporary HOME/CODEX_HOME/cwd and only a copied authentication file, deleted on completion. Saved evidence contains no authentication or private reasoning text. No inherited project AGENTS, repository files, skills, expectations, hidden hands or playing thread state is supplied. Public JSONL, command identity/configuration and timing are preserved; reasoning items are discarded rather than saved.

The saved v1 audit request was forwarded byte-for-byte through the existing transparent proxy. `saved-decisions-wire/request-0.json` confirms gpt-6.1-sol with medium effort and no skills or shell/file-reading/Engine/Knowledge/MCP tool surface. It also shows the catalog still advertises standard exec/wait/user-input/collaboration built-ins; exec's nested definitions contain apply_patch and clock only, and code-mode host is disabled. Therefore this is not a literally empty advertised tool catalog. No tool invocation occurred in any successful recorded grading run; a real observed tool item makes that run evaluator_issue. The proxy's routing override is recorded in its capture config; it did not rewrite the payload.

The audited upstream response reports model string gpt-6.1-sol. Final v2 ordinary CLI JSONL does not independently expose resolved service-side model/effort identity; run.json records that limit. Neither an acknowledged/requested name nor CLI success establishes the service's internal implementation identity. The final v2 change from the captured request is confined to the citation contract, and the ignored config entries were removed before the audited request.

Continuous play, representative teaching corpus, complete-board runs and the finite stage-quality gate remain tickets 39–42.
