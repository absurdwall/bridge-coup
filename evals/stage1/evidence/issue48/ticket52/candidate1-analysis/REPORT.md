# Issue 52 — frozen cycle 1 acceptance report

**NO-GO. One of the maximum three substantive frozen validation cycles is spent.**
All 22 prescribed attempts completed and executed legally, but independent review
finds five failed attempts and 22 seriously defective delivered decisions. The
unchanged raw grader reported three failed attempts and 14 failed decisions.
The two additional failed attempts are documented semantic false passes, not new
model runs. No later candidate, source repair, instruction change or reroll is
included here.

## Frozen source and evidence

The production source is `ca0b1a32cb67110773d21baef1ec3ea981868544`.
Integration's later `c6de45b79e4ff857fd86d4de959c5210733f4fa9` adds only two code
review recheck reports; it does not alter the candidate. The code was independently
reviewed along Standards and Spec axes; evidenced nonblocking findings were repaired
and both changed-hunk rechecks were clear. The validated baseline had 254 Swift
tests, 10 existing skips and 66 Python tests, with no failures, run sequentially.

The [freeze](../candidate1/candidate.json), [22-attempt schedule](../candidate1/plan.json)
and [cycle authorization](../candidate1/cycle.json) precede live requests. Both
production roles and the separate acceptance grader requested `gpt-6.1-sol` with
`medium` effort. Production roles expose empty additional tools. Native version
was `codex-cli 0.160.0`. Requested and observable identities do not prove hidden
service internals.

| Frozen object | SHA256 |
|---|---|
| Player instructions | `7216835b26ad7b9aa8c00fb9870d1c7a95837953059927623c1d6800efbebf90` |
| Reviewer instructions | `6abfef19977a81a426a48afe12430e7bcc9f7170faef43a298d8313b6dbc9b37` |
| bridge-play executable | `213dbcc711a436812c8e858b9f1707e13a974adb94abd7f3d2ad7f0164d4a6db` |
| Native Codex executable | `112fae7a5a1223e673c8a1791d32338f37df8b527ff1159bb8adac6c4dbf1b4b` |
| Preserved executable + adjacent resource bundle archive | `c9d3d6613aee44695a26816581d39c3fa2fa0816844a0365ef53e327c1b14004` |

The [raw preservation manifest](raw-preservation.json) covers 3,377 unchanged
files / 499,753,621 bytes. Original absolute paths in requests, grades and raw
manifests remain intact. The [external preservation map](external-preservation.json)
copies 37 original files: reports, proofs, addenda, the starting obligation
ledger and explicitly provisional repair memos byte for byte, with hashes and original-to-portable paths. The
[runtime archive](runtime/candidate1-runtime.tar.gz) retains the exact executable
and its adjacent Swift instruction bundle together, so future worktree cleanup
cannot silently replace the historical binary/resources. A separate deterministic
source archive (`d7ddce0a8b908d5389b0e13dc4e81d0cc0201ea6983f9ea387435e1624d25ea8`)
retains all 46 source blobs directly from the pinned Git commit. Historical audit
helpers load that reducer/fixture archive rather than current checkout files.
The [lifetime regression](lifetime-portability-verification.json) passes with all
current source bytes deliberately changed in a temporary skeleton and no `.build`
or native executable. The [README](README.md) distinguishes saved-evidence audits
from a new execution of the old native candidate.

## Delivered quality and material coverage

The [final independent index](originals/candidate1-adjudication-index.json) records
17 passing / five failing attempts and 247 passing / 22 failing delivered
decisions, with zero uncertain grades. All 269 delivered decisions were runtime
`reviewApproved`; that authorization did not establish quality. No contested
execution occurred in this matrix. Rejected drafts remain diagnostic and never
become extra delivered grades. Exact canonical snapshots remain separate from
actual final player feedback requests; reviewer assertions are non-authoritative
prior feedback, never public bridge facts or acceptance answers.

| Failed attempt | Independently failed decisions | Delivered defect |
|---|---|---|
| [short-1-r1](originals/candidate1-short1-review.md) | 1 | The stated East 5–0 safety rule plays C8 under the non-honour C9 and promises four clubs; a legal public-consistent counterexample gives only three. Raw grader missed it. |
| [short-3-r3](originals/candidate1-short3-r3-review.md) | 1–8 | After three club rounds, five initial South clubs cannot leave CK plus two small cards. The still-live conditional inventory remains false under keep. |
| [short-5-r2](originals/candidate1-short5-r2-review.md) | 1–7 | The named duck–DK-win–DQ-loss branch leaves two North diamonds after CA entry, not the promised three future winners. Raw grader missed it. |
| [short-5-r3](originals/candidate1-short5-r3-review.md) | 1 | The initial K-first/heart-return route can exhaust South's diamonds and the only side entry before accessing established North diamonds. A later replacement retires the defect, leaving eleven passing decisions. |
| [short-6-r1](originals/candidate1-short6-r1-review.md) | 7–11 | Selecting HJ conflicts with the unchanged unfinished HK–HQ–HJ-to-HA entry instructions. A feasible later transfer does not repair the active contradictory route. |

These are specific delivered conditional counts, feasibility or continuity errors.
They do not imply that every alternative route is unsound or that the actual
boards necessarily go down. The original serious-error standard is unchanged;
legal play, made contracts and reviewer approval do not erase those errors.

All 22 core coverage judgments are resolved by cited independent reviews. The
separate **third-club-first actual model-use facet remains unexercised**: one
short-3 run has no qualifying window; the other two encounter it on a forced
sole-legal card, not a model decision. The [coverage diagnosis](originals/short3-coverage-diagnosis.md),
[predicate refinement](originals/short3-coverage-predicate-refinement.md) and
[authored legality witness](originals/short3-discarded-third-witness.json) remain
post-cycle diagnostics. They do not change this frozen corpus, policy or result.
The authored discard witness is not proof that the production opponent policy
reaches that route. Walker hidden-environment replay is explicitly evaluator-only
coverage evidence, separate from public-input quality judgment and all live roles.
The formerly reserved full board is already used regression material.

## Execution, cost and timing

The [raw runner report](../candidate1/REPORT.md) preserves every attempt and its
original pending coverage classification. The separate [aggregate](aggregate.json)
reports all roles/revisions and preserves the distinction between request attempts
and late observations. There were no early stops, technical retries, clarification
requests, late observations or human waiting in these samples. Those product paths
are covered by public production-seam regression tests, not claimed live here.

| Observation | Result |
|---|---|
| Prescribed attempts / task-complete / independently legal | 22 / 22 / 22 |
| Delivered model actions / mechanical actions | 269 / 33 |
| Player / reviewer / semantic reviews | 274 / 274 / 274 |
| Feedback revisions / technical retries | 5 / 0 |
| Actual RPC / captured HTTP attempts | 548 / 548 |
| Player observed tokens / role elapsed | 2,702,678 / 2,187.130 s |
| Reviewer observed tokens / role elapsed | 697,427 / 3,172.374 s |
| Automatic driver total / human waiting | 5,367.012 s / 0 s |
| First decision n / median / range | 22 / 68.588 s / 44.435–249.733 s |
| Later decision n / median / range | 247 / 12.885 s / 6.375–118.845 s |
| Separate grader elapsed / observed input / output tokens | 1,187.126 s / 1,865,375 / 41,694 |

All 548 role attempts have observable usage in both native and HTTP records;
these are overlapping observations and must not be added together. Unknown usage
would remain unknown, never zero. Cached input/reasoning token details remain in
the aggregate. Monetary cost is unavailable without an attested price schedule.
The 180 s cap applies to each role request, while a full decision may include
multiple roles/revisions; the 1,800 s board budget includes all automatic work.
There is no added three-minute speed gate.

| Complete board | Driver time | Actual tricks | Model / forced | Independent quality |
|---|---:|---|---|---|
| full-development-r1 | 337.317 s | 10–3 | 23 / 3 | pass |
| full-development-r2 | 354.967 s | 10–3 | 22 / 4 | pass |
| full-reserved-r1 | 280.793 s | 12–1 | 21 / 5 | pass |
| full-reserved-r2 | 350.089 s | 13–0 | 20 / 6 | pass |

The [native plan audit](native-plan-encoding.json) verifies all 274 raw player
rounds decode exactly to their pending candidates and all 274 actual reviewer
wire candidates agree: 35 replace and 239 keep operations, every keep explicitly
`text:null`. No natural withdraw was observed. Offline keep/withdraw contract
regressions remain applicable; no live withdraw event is invented. The older
natural-correction capture's omitted-null defect remains immutable history.

## Acceptance conditions and issue status

| Issue 52 condition | Status / evidence |
|---|---|
| Freeze both roles, schemas/configs, source/runtime/capture, corpus/rubric and failures | met for cycle 1; freeze, 46 source hashes, raw manifest and binary+bundle archive verified |
| True final request/candidate/plan/execution binding | met by deterministic public-seam regressions and actual saved-output checks; canonical facts separate from feedback |
| Independent grader, no live answer/grade feedback | met; isolated grader artifacts, separate independent textual overlay, no extra player calls |
| Exact 18 short + four full schedule | met; strictly sequential, no rerolls/mixing; all 22 task/legal complete |
| Original serious-error/material coverage quality gate | **unmet**; five failed attempts; separate third-club-first model facet unexercised |
| Full timings, roles, tokens, retries/stops and finite limits | met as observed, with absent live edge cases explicitly bounded |
| Offline tests, independent code review and evidenced repairs | met for frozen implementation; 254 Swift/10 skips, 66 Python; two-axis clear rechecks |
| Explicit final met/unmet report and approval boundaries | this report; whole #48 acceptance remains incomplete; no closure/merge authority |

| New / retained issue | Implemented or preserved | Still unmet / delivery status |
|---|---|---|
| #36 | Domain/Engine/Expert/Driver boundaries, NT/trump legality regressions, ordinary IMP rubric, authorized facts, finite native matrix | Basic delivered quality gate fails; main delivery and owner acceptance pending. Superseded Luna/delta/no-review clauses are not counted as current requirements. |
| #37 | Initial English concrete plan/card/reason, full actual role configuration/tools evidence, exact proposal binding | Initial short-1-r1 delivered guarantee fails; initial probe alone was never acceptance. |
| #38 | Deterministic saved evaluator, independent grader, calibration/alternative handling, immutable raw grades plus saved-output adjudication | Two current semantic false passes retained openly; broad grader reliability is not established. |
| #39 | One continuing player thread, fresh identities, exact actual events, keep/replace/withdraw lifecycle, revision plan continuity | Serious continued-plan inventory/entry errors remain; continuous quality not accepted. |
| #40 | Legal state-aware opponents; forced moves distinct; four full native NT boards, 52 cards/13 tricks, timing and bounded automatic execution | Full samples pass but do not erase short-run defects or establish broad play strength; merge pending. |
| #41 | Unchanged sourced corpus, reachable public snapshots, material/environment separation, coverage audits and used-regression labeling | Third-club-first actual model-use facet absent; prospective predicate refinement is diagnostic only. |
| #42 | Both-role freeze, immutable old/new failures, exact 22 schedule, finite budget and independent source/evidence review | Acceptance is NO-GO; one of three cycles spent, no stitching/reroll/standard weakening. |
| #46 | Complete initial/update facts, public winningPlay, exact effectivePlan, canonical-vs-feedback distinction; #47 inheritance retained | Underlying delivered-plan quality fails; #45/#47 remain unmerged and reintegration/closure unapproved. |
| #48 | Pending review protocol, final-only commit, role evidence, reviewed instructions and finite cycle accounting | Whole delivery goal incomplete because actual quality/remaining material facet fails; no acceptance approval. |
| #49 | Two-phase public Expert/Driver path and separate native reviewer; immutable native smoke and source evidence | Integrated implementation; broader acceptance depends on #52 and is currently NO-GO. |
| #50 | Same-thread revise/clarify, five semantic rounds, exact round-five contested release, missing-fact needs-input; natural revise→approve capture; reviewed instruction diff | Implemented/tested; live candidate 1 has five revisions but no uncertain/contested/withdraw event. No claim that source tests prove quality. |
| #51 | Separate four-attempt technical guard, absolute budgets, pending resume, Unicode and late/request journals; public-seam regressions | Implemented/tested; no live retry/late/needs-input sample in candidate 1. General process-restart recovery remains excluded. |
| #52 | Operational evaluator/freezer/native runner, this full raw+independent report, portable proof/runtime preservation | **Quality acceptance unmet**; implementation/report completion does not close the issue or parent goal. |

The full [retained obligation ledger](legacy-obligations-at-start.md) records each
older retained/replaced clause; this table supplies the cycle-1 completion status.
Historical original 21-fail/one-pending and structured-v3 four-pass/17-fail/one-pending
matrices, their metadata gaps/disputes, and the #49/#50 diagnostics remain separate.
No PR was merged, no acceptance/reintegration issue was closed, and this agent made
no GitHub writes. Any candidate 2 requires the coordinator's bounded diagnosis,
reviewed repair and new freeze; provisional repair memos do not authorize it.
