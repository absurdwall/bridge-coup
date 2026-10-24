# Stage 1 finite acceptance

**NO-GO.** 22 of 22 predeclared attempts recorded.

Candidate source commit: `826694746507e5e8e19b40d8238716fbbbd9acb9`. The exact source, executable, instructions, schema template, corpus, rubric, requested configurations and runtime hashes were recorded before play in [candidate.json](candidate.json). Later evidence/document commits do not change that candidate.

All attempts use the production public Expert/driver through Codex app-server, requested gpt-6-luna / medium. Grading uses independent gpt-6.1-sol / medium with the frozen case/rubric. These names describe requested and observable identities; internal service resolution is not independently proven. Playing calls and graders run strictly sequentially, with no answer repair, manual controlled substitute or playing retry.

## Every attempt

| Attempt | Task | Legal | Quality | Trigger | Requests attempted / RPC / HTTP | Model / forced / opponents | Tricks | Evidence |
|---|---|---|---|---|---|---|---|---|
| short-1-r1 | True | pass | fail | covered | 1 / 1 / 1 | 1 / 0 / 0 (+0 controlled, 1 opponent prefix) | [0, 0] | [saved](short-1-r1/summary.json) |
| short-1-r2 | True | pass | fail | covered | 1 / 1 / 1 | 1 / 0 / 0 (+0 controlled, 1 opponent prefix) | [0, 0] | [saved](short-1-r2/summary.json) |
| short-1-r3 | True | pass | fail | covered | 1 / 1 / 1 | 1 / 0 / 0 (+0 controlled, 1 opponent prefix) | [0, 0] | [saved](short-1-r3/summary.json) |
| short-2-r1 | True | pass | fail | pending | 8 / 8 / 8 | 8 / 1 / 7 (+0 controlled, 1 opponent prefix) | [4, 0] | [saved](short-2-r1/summary.json) |
| short-2-r2 | True | pass | fail | pending | 8 / 8 / 8 | 8 / 0 / 7 (+0 controlled, 1 opponent prefix) | [2, 2] | [saved](short-2-r2/summary.json) |
| short-2-r3 | True | pass | fail | pending | 8 / 8 / 8 | 8 / 0 / 6 (+0 controlled, 1 opponent prefix) | [3, 0] | [saved](short-2-r3/summary.json) |
| short-3-r1 | True | pass | fail | covered | 12 / 12 / 12 | 12 / 2 / 12 (+0 controlled, 1 opponent prefix) | [5, 1] | [saved](short-3-r1/summary.json) |
| short-3-r2 | False | pass | fail | uncovered | 5 / 5 / 5 | 4 / 0 / 4 (+0 controlled, 1 opponent prefix) | [1, 1] | [saved](short-3-r2/summary.json) |
| short-3-r3 | True | pass | fail | covered | 12 / 12 / 12 | 12 / 0 / 10 (+0 controlled, 1 opponent prefix) | [5, 0] | [saved](short-3-r3/summary.json) |
| short-4-r1 | False | pass | fail | uncovered | 11 / 11 / 11 | 10 / 2 / 11 (+0 controlled, 1 opponent prefix) | [3, 3] | [saved](short-4-r1/summary.json) |
| short-4-r2 | True | pass | fail | uncovered | 16 / 16 / 16 | 16 / 1 / 15 (+0 controlled, 1 opponent prefix) | [4, 4] | [saved](short-4-r2/summary.json) |
| short-4-r3 | False | pass | fail | uncovered | 2 / 2 / 2 | 1 / 0 / 1 (+0 controlled, 1 opponent prefix) | [0, 0] | [saved](short-4-r3/summary.json) |
| short-5-r1 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 3 / 14 (+2 controlled, 2 opponent prefix) | [3, 5] | [saved](short-5-r1/summary.json) |
| short-5-r2 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 3 / 14 (+2 controlled, 2 opponent prefix) | [5, 3] | [saved](short-5-r2/summary.json) |
| short-5-r3 | False | pass | fail | pending | 5 / 5 / 5 | 4 / 0 / 4 (+2 controlled, 2 opponent prefix) | [2, 1] | [saved](short-5-r3/summary.json) |
| short-6-r1 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 2 / 12 (+0 controlled, 1 opponent prefix) | [5, 1] | [saved](short-6-r1/summary.json) |
| short-6-r2 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 3 / 13 (+0 controlled, 1 opponent prefix) | [2, 5] | [saved](short-6-r2/summary.json) |
| short-6-r3 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 2 / 13 (+0 controlled, 1 opponent prefix) | [3, 4] | [saved](short-6-r3/summary.json) |
| full-development-r1 | True | pass | fail | covered | 20 / 20 / 20 | 20 / 6 / 25 (+0 controlled, 1 opponent prefix) | [8, 5] | [saved](full-development-r1/summary.json) |
| full-development-r2 | True | pass | fail | covered | 20 / 20 / 20 | 20 / 6 / 25 (+0 controlled, 1 opponent prefix) | [7, 6] | [saved](full-development-r2/summary.json) |
| full-reserved-r1 | True | pass | fail | covered | 21 / 21 / 21 | 21 / 5 / 25 (+0 controlled, 1 opponent prefix) | [10, 3] | [saved](full-reserved-r1/summary.json) |
| full-reserved-r2 | True | pass | fail | covered | 19 / 19 / 19 | 19 / 7 / 25 (+0 controlled, 1 opponent prefix) | [9, 4] | [saved](full-reserved-r2/summary.json) |

Driver retries are counted separately from actual HTTP attempts. Per-attempt wire summaries preserve HTTP statuses, transport errors and missing responses; an RPC may cause multiple upstream HTTP attempts inside the runtime. The runner does not equate driver retries=0 with no internal runtime transport retry.

Quality pass is provisional until independent review of cited facts. Trigger coverage is separate from task bounds and quality. Pending means the mechanical event predicate needs review; an avoided trigger remains uncovered. Contract result cannot erase a factual, entry or consistency failure.

## Four full-board timings

| Attempt | First request s | Later requests n / median / range s | Last controlled action s | Full driver s | Environment overhead s | Failed request s | Retries |
|---|---|---|---|---|---|---|---|
| full-development-r1 | 10.319600105285645 | 19 / 3.881 / 3.538–7.871 | 97.72994804382324 | 97.72994804382324 | 0.2644091844558716 | None | 0 |
| full-development-r2 | 10.301484942436218 | 19 / 3.800 / 3.490–7.166 | 91.58005499839783 | 91.58005499839783 | 0.29451000690460205 | None | 0 |
| full-reserved-r1 | 13.364804983139038 | 20 / 3.998 / 3.595–6.225 | 97.65663492679596 | 97.66412591934204 | 0.3034719228744507 | None | 0 |
| full-reserved-r2 | 14.01872205734253 | 18 / 3.941 / 3.682–5.459 | 88.0402479171753 | 88.0402489900589 | 0.27358198165893555 | None | 0 |

The time origin is dummy exposure/driver start immediately before the first request; last controlled action includes mechanical forced actions. Initial fixture prefix is counted separately. Full driver time includes trailing opponents after the last controlled action. Request limit 180 s, run limit 1800 s, independent grader limit 600 s. Three minutes is an experience goal, not a hard gate. Every individual subsequent latency and failed request is preserved in each trace.

## Review and limits

Every non-pass grade, original cited text, evaluator error and coverage predicate is preserved in per-attempt summary.json and grade/. An independent review must decide disputed/uncertain findings before any stage-complete claim. The runner never feeds grading results into the player.

The separate reserved board is first played in this finite acceptance. No targeted repair is performed here; these finite samples do not prove broad bridge strength or general grader reliability.

Wire captures preserve exact forwarded payload bytes, no authentication headers and no decrypted reasoning. The inherited runtime catalog may contain built-ins/collaboration and opaque encrypted reasoning history. This is not a claim of an entirely empty runtime tool list or a wholly public-only runtime history. Engine analysis/Knowledge tools are absent from the playing surface; verify actual captures and invocation records in independent review.

Rule and dependency review evidence, concrete failure adjudication, achieved/unachieved criteria and the final stage recommendation are recorded separately in REVIEW.md. Until then this report is a captured result, not acceptance approval.
