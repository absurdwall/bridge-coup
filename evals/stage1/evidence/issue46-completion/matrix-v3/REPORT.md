# Stage 1 finite acceptance

**NO-GO.** 22 of 22 predeclared attempts recorded.

Candidate source commit: `7129ffd352ee332c50b08db9d71a62d069afaaeb`. The exact source, executable, instructions, schema template, corpus, rubric, requested configurations and runtime hashes were recorded before play in [candidate.json](candidate.json). Later evidence/document commits do not change that candidate.

All attempts use the production public Expert/driver through Codex app-server, requested gpt-6-luna / medium. Grading uses independent gpt-6.1-sol / medium with the frozen case/rubric. These names describe requested and observable identities; internal service resolution is not independently proven. Playing calls and graders run strictly sequentially, with no answer repair, manual controlled substitute or playing retry.

## Every attempt

| Attempt | Task | Legal | Quality | Trigger | Requests attempted / RPC / HTTP | Model / forced / opponents | Tricks | Evidence |
|---|---|---|---|---|---|---|---|---|
| short-1-r1 | True | pass | pass | covered | 1 / 1 / 1 | 1 / 0 / 0 (+0 controlled, 1 opponent prefix) | [0, 0] | [saved](short-1-r1/summary.json) |
| short-1-r2 | True | pass | pass | covered | 1 / 1 / 1 | 1 / 0 / 0 (+0 controlled, 1 opponent prefix) | [0, 0] | [saved](short-1-r2/summary.json) |
| short-1-r3 | True | pass | pass | covered | 1 / 1 / 1 | 1 / 0 / 0 (+0 controlled, 1 opponent prefix) | [0, 0] | [saved](short-1-r3/summary.json) |
| short-2-r1 | True | pass | fail | pending | 8 / 8 / 8 | 8 / 0 / 6 (+0 controlled, 1 opponent prefix) | [3, 0] | [saved](short-2-r1/summary.json) |
| short-2-r2 | True | pass | fail | pending | 8 / 8 / 8 | 8 / 0 / 6 (+0 controlled, 1 opponent prefix) | [3, 0] | [saved](short-2-r2/summary.json) |
| short-2-r3 | True | pass | fail | pending | 8 / 8 / 8 | 8 / 1 / 7 (+0 controlled, 1 opponent prefix) | [3, 1] | [saved](short-2-r3/summary.json) |
| short-3-r1 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 1 / 11 (+0 controlled, 1 opponent prefix) | [6, 0] | [saved](short-3-r1/summary.json) |
| short-3-r2 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 2 / 12 (+0 controlled, 1 opponent prefix) | [5, 1] | [saved](short-3-r2/summary.json) |
| short-3-r3 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 1 / 11 (+0 controlled, 1 opponent prefix) | [6, 0] | [saved](short-3-r3/summary.json) |
| short-4-r1 | True | pass | pass | pending | 16 / 16 / 16 | 16 / 1 / 15 (+0 controlled, 1 opponent prefix) | [8, 0] | [saved](short-4-r1/summary.json) |
| short-4-r2 | True | pass | fail | pending | 16 / 16 / 16 | 16 / 1 / 15 (+0 controlled, 1 opponent prefix) | [8, 0] | [saved](short-4-r2/summary.json) |
| short-4-r3 | True | pass | fail | pending | 16 / 16 / 16 | 16 / 2 / 16 (+0 controlled, 1 opponent prefix) | [7, 1] | [saved](short-4-r3/summary.json) |
| short-5-r1 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 1 / 12 (+2 controlled, 2 opponent prefix) | [4, 3] | [saved](short-5-r1/summary.json) |
| short-5-r2 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 3 / 14 (+2 controlled, 2 opponent prefix) | [5, 3] | [saved](short-5-r2/summary.json) |
| short-5-r3 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 3 / 15 (+2 controlled, 2 opponent prefix) | [5, 3] | [saved](short-5-r3/summary.json) |
| short-6-r1 | True | pass | fail | pending | 12 / 12 / 12 | 12 / 2 / 13 (+0 controlled, 1 opponent prefix) | [3, 4] | [saved](short-6-r1/summary.json) |
| short-6-r2 | True | pass | fail | uncovered | 12 / 12 / 12 | 12 / 4 / 15 (+0 controlled, 1 opponent prefix) | [2, 6] | [saved](short-6-r2/summary.json) |
| short-6-r3 | True | pass | fail | uncovered | 12 / 12 / 12 | 12 / 2 / 13 (+0 controlled, 1 opponent prefix) | [2, 5] | [saved](short-6-r3/summary.json) |
| full-development-r1 | True | pass | fail | covered | 19 / 19 / 19 | 19 / 7 / 25 (+0 controlled, 1 opponent prefix) | [7, 6] | [saved](full-development-r1/summary.json) |
| full-development-r2 | True | pass | fail | covered | 20 / 20 / 20 | 20 / 6 / 25 (+0 controlled, 1 opponent prefix) | [10, 3] | [saved](full-development-r2/summary.json) |
| full-reserved-r1 | True | pass | fail | covered | 23 / 23 / 23 | 23 / 3 / 25 (+0 controlled, 1 opponent prefix) | [12, 1] | [saved](full-reserved-r1/summary.json) |
| full-reserved-r2 | True | pass | fail | covered | 21 / 21 / 21 | 21 / 5 / 25 (+0 controlled, 1 opponent prefix) | [10, 3] | [saved](full-reserved-r2/summary.json) |

Driver retries are counted separately from actual HTTP attempts. Per-attempt wire summaries preserve HTTP statuses, transport errors and missing responses; an RPC may cause multiple upstream HTTP attempts inside the runtime. The runner does not equate driver retries=0 with no internal runtime transport retry.

Quality pass is provisional until independent review of cited facts. Trigger coverage is separate from task bounds and quality. Pending means the mechanical event predicate needs review; an avoided trigger remains uncovered. Contract result cannot erase a factual, entry or consistency failure.

## Four full-board timings

| Attempt | First request s | Later requests n / median / range s | Last controlled action s | Full driver s | Environment overhead s | Failed request s | Retries |
|---|---|---|---|---|---|---|---|
| full-development-r1 | 7.7916319370269775 | 18 / 3.455 / 2.215–6.169 | 75.21407699584961 | 75.21407699584961 | 0.31833910942077637 | None | 0 |
| full-development-r2 | 2.975260019302368 | 19 / 3.783 / 2.282–10.466 | 88.00904297828674 | 88.01713001728058 | 0.32687294483184814 | None | 0 |
| full-reserved-r1 | 9.042263984680176 | 22 / 3.411 / 1.709–8.858 | 106.96079993247986 | 106.97069692611694 | 0.3883002996444702 | None | 0 |
| full-reserved-r2 | 10.032011985778809 | 20 / 3.375 / 1.778–6.281 | 79.5945919752121 | 79.60358893871307 | 0.3824652433395386 | None | 0 |

The time origin is dummy exposure/driver start immediately before the first request; last controlled action includes mechanical forced actions. Initial fixture prefix is counted separately. Full driver time includes trailing opponents after the last controlled action. Request limit 180 s, run limit 1800 s, independent grader limit 600 s. Three minutes is an experience goal, not a hard gate. Every individual subsequent latency and failed request is preserved in each trace.

## Review and limits

Every non-pass grade, original cited text, evaluator error and coverage predicate is preserved in per-attempt summary.json and grade/. An independent review must decide disputed/uncertain findings before any stage-complete claim. The runner never feeds grading results into the player.

Corpus v2 keeps the formerly reserved board as used regression material: it has already been played and inspected for correction. It is not fresh held-out evidence. These finite samples do not prove broad bridge strength or general grader reliability.

Wire captures preserve exact forwarded payload bytes, no authentication headers and no decrypted reasoning. The installed bundled model catalog is frozen and checked before each attempt; each playing run preserves the source and effective catalogs. The Luna entry changes only tool routing, experimental tools, apply-patch type and shell type to disable tools. Runtime configuration also disables question tools and time reminders. The public runtime-boundary regression confirms an empty additional_tools list; verify final captures independently. Opaque encrypted reasoning history can remain in continuing requests; this does not claim a wholly public-only runtime history.

Rule and dependency review evidence, concrete failure adjudication, achieved/unachieved criteria and the final stage recommendation are recorded separately in REVIEW.md. Until then this report is a captured result, not acceptance approval.
