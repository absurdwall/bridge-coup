# Stage 1 implementation and acceptance disposition

**Stage 1 is not complete. Do not merge PR #47 or PR #45.** The structured-input implementation and engineering checks are complete, but required basic playing quality is not established. The current PR remains draft and the originating issues remain open.

## What was implemented and corrected

- The approved full authorized JSON snapshot is generated from actual state at every decision, with contract doubling, scoring/vulnerability/controller, remaining hands, all public plays/winners, current turn/trick count and verbatim effectivePlan. Caller objective and publicBackground are preserved. Hidden defender holdings stay outside the playing context.
- One board/controller uses one continuing Codex app-server thread, with a fresh turn per decision. Initial plans replace null; keep/replace/withdraw retain their approved meanings. Legal actions remain constrained by the full current legal-card enum; prose is not executed as a future policy.
- The production runtime uses the installed bundled model catalog with only the necessary Luna tool-routing changes. The actual player tool surface is empty; startup does not silently fall back to a tool-enabled mode.
- The evaluator binds actual authorized input/output to the same thread/turn, handles saved evidence from interrupted runs, and compares omitted doubling as undoubled without ignoring explicit doubles/redoubles.
- A concise general unfinished-plan check and the Engine's existing current public winning play were added. The last correction aligns output generation and examples to plan → selectedCard → publicReason. No new strategy engine, model, policy fields, hidden answer, in-play reviewer or repair loop was added.

## Verification and versions

| Version | Verification | Result |
|---|---|---|
| Frozen v3, `7129ffd` | Six short scenarios ×3, two full boards ×2; 266 actual Luna Medium requests | All 22 tasks executed legally. Independent attempt disposition: **4 pass / 17 fail / 1 pending**. Quality gate failed. |
| Current v4 behavior, `8a0c518` | Three predeclared affected scenarios, once each; 36 actual Luna Medium requests | One basic-quality/coverage pass, one pending, one confirmed failure. Development only; no final 22-attempt acceptance claim. |
| Current engineering checks | Swift 234 tests (10 preexisting skips), Python 53 tests | Zero failures after synchronizing the existing native-boundary order expectation. |
| Independent source review | Separate Luna Max standards and spec reviews, including test-only follow-up | No remaining concrete source defect identified. This does not establish model quality. |

Both playing batches freeze source/native/runtime/catalog/schema/corpus/rubric/configuration hashes. Evidence/document commits after those source commits do not change their behavior. Every captured playing request requests Luna Medium with all_turns and empty additional tools. The v3 and v4 batches have 22 and 3 distinct per-board threads respectively; there are no playing retries, answer repairs or manual controlled substitutes. Public text has no Chinese characters. Internal encrypted reasoning language and hidden service-side routing are not independently proven.

## Why acceptance is still open

The original v3 Sol labels are 3 pass / 18 fail / 1 pending at attempt level. Independent review upgrades the basic consumed-honor/entry run, leaves a teaching route pending, and corrects individual overstrict or factually mistaken judgments. The original artifacts are unchanged; all revisions are separate overlays. Repeated keeps of one false plan are distinguished from new error roots. A successful contract or legal card does not erase a false plan/reason.

The latest v4 experiment is particularly useful because its first synthetic continuation has 12 sound decisions after the order change, while the hold-up teaching case still makes basic errors despite correct input:

1. North HA43 and South HKQJ are counted as four heart tricks, although both hands contain only three hearts.
2. West's CQ is described as a defensive winner while South visibly retains CAJ.
3. South then chooses CJ under CQ despite CA being legal and an explicit seven-trick remaining cashing route.

The other teaching case is pending rather than forcibly failed: its DJ wording may refer to history, and several diamond-entry/remaining-trick questions are unresolved. This uncertainty does not rescue the confirmed hold-up-case failure.

Independent diagnosis found no confirmed missing card, hidden-hand leakage, schema parse or execution fault causing these public content errors. The requests and instructions explicitly contain the relevant ranks, holdings, actual history and plan. The evidence supports a remaining reliability problem in this Luna Medium configuration; it does not prove every possible prompt will fail or that another model would pass. No model substitution is authorized by the current test condition.

## Timings and limits

The four complete v3 boards took **75.214 / 88.017 / 106.971 / 79.604 seconds**. All 52 cards were legally consumed in each. Final NS trick totals were 7 / 10 / 12 / 10; these outcomes are recorded independently of semantic grades. The first full board overlapped a 20.93-second, two-job compile in a separate worktree, so these are actual host timings, not an idle-host benchmark. Full initial/subsequent distributions and overhead are retained in the matrix report.

The three v4 durations are short scenarios, not full-board performance measurements. Three minutes is not a hard acceptance bar. The formerly reserved board has been used for repair and is regression material, not fresh held-out evidence. Grader calibration passed two rounds of six reviewed answers, but actual disagreements show its limits; unresolved questions remain pending.

## Ticket disposition and next boundary

The structural/core/evaluation work is implemented and tested. #40's quality requirement and #36/#42's final semantic gate remain unmet; #46 does not waive them. Issues #36–42 and #46 remain open. No stage-complete or merge approval is claimed.

The finite v3 matrix and separately versioned v4 check are preserved; passes from different candidates are not combined. A known-failing unchanged candidate was not rerolled into apparent acceptance. The user chose to retain Luna Medium and investigate design/failure causes. A subsequent 42-request bounded diagnosis is preserved separately; it does not change acceptance or justify a production prompt patch. The current instruction/schema order fix is retained as a consistency improvement, with no causal quality guarantee.

## Evidence map

- [v3 detailed acceptance](matrix-v3/REPORT.md), [independent disposition](matrix-v3/REVIEW.md), [wire/thread audit](matrix-v3/review-work/final-wire-and-thread-audit.json)
- [v4 development plan](development-v4/DEVELOPMENT-PLAN.json), [quality disposition and exact examples](development-v4/REVIEW.md), [wire/thread audit](development-v4/wire-and-thread-audit.json)
- [Standards review](standards-review-v4.md), [spec review](spec-review-v4.md), [offline red/green logs](tdd/)
- Earlier baseline/corrections/calibration remain indexed in [README.md](README.md). Original user worktrees, teaching notes and manual-session artifacts were preserved; only this task's clean integrated implementer worktrees are cleaned up.

## Subsequent design diagnosis

[2026-10-22 diagnosis](design-diagnosis-20261022/REPORT.md) separates first-error forecasting/counting from historical error persistence. Same-current-input fresh d12 chooses CA 4/4; full-history controls choose CJ 6/7 and CA 1/7. Public-only results are mixed, and a generic reassessment sentence failed 3/3. No production source/instruction change, model substitution, or acceptance rerun was made.
