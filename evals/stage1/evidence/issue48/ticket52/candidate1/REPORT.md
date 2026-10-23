# Stage 1 finite acceptance

**NO-GO.** 22 of 22 predeclared attempts recorded.

Candidate source commit: `ca0b1a32cb67110773d21baef1ec3ea981868544`. Both instruction sources, role configurations, schemas, runtime/capture code, fixtures, rubrics and binary/native-runtime hashes were frozen in [candidate.json](candidate.json).

Production player and independent runtime reviewer both request gpt-6.1-sol / medium with empty additional_tools. The separate acceptance grader requests gpt-6.1-sol / medium. Requested/observable identities do not prove hidden service internals. Every attempt runs strictly sequentially; the bounded product loop permits five semantic reviews and four technical attempts per review round. There are no board rerolls, manual controlled substitutes or grader feedback into live play.

Only delivered advice is graded. Rejected drafts are diagnostic. Review approval and contested execution are authorization dispositions, never bridge-quality labels. Canonical snapshots establish public facts; feedback envelopes preserve actual prior reviewer assertions as non-authoritative provenance.

| Attempt | Task | Legal | Quality | Trigger | Player / reviewer / RPC / HTTP attempts | Model / forced / opponent plays | Tricks |
|---|---|---|---|---|---|---|---|
| [short-1-r1](short-1-r1/summary.json) | True | pass | pass | covered | 1 / 1 / 2 / 2 | 1 / 0 / 0 | [0, 0] |
| [short-1-r2](short-1-r2/summary.json) | True | pass | pass | covered | 1 / 1 / 2 / 2 | 1 / 0 / 0 | [0, 0] |
| [short-1-r3](short-1-r3/summary.json) | True | pass | pass | covered | 1 / 1 / 2 / 2 | 1 / 0 / 0 | [0, 0] |
| [short-2-r1](short-2-r1/summary.json) | True | pass | pass | pending | 8 / 8 / 16 / 16 | 8 / 0 / 6 | [3, 0] |
| [short-2-r2](short-2-r2/summary.json) | True | pass | pass | pending | 8 / 8 / 16 / 16 | 8 / 0 / 6 | [3, 0] |
| [short-2-r3](short-2-r3/summary.json) | True | pass | pass | pending | 8 / 8 / 16 / 16 | 8 / 1 / 7 | [4, 0] |
| [short-3-r1](short-3-r1/summary.json) | True | pass | pass | pending | 12 / 12 / 24 / 24 | 12 / 0 / 10 | [5, 0] |
| [short-3-r2](short-3-r2/summary.json) | True | pass | pass | pending | 12 / 12 / 24 / 24 | 12 / 1 / 11 | [6, 0] |
| [short-3-r3](short-3-r3/summary.json) | True | pass | fail | pending | 12 / 12 / 24 / 24 | 12 / 1 / 11 | [6, 0] |
| [short-4-r1](short-4-r1/summary.json) | True | pass | pass | pending | 16 / 16 / 32 / 32 | 16 / 0 / 14 | [7, 0] |
| [short-4-r2](short-4-r2/summary.json) | True | pass | pass | pending | 16 / 16 / 32 / 32 | 16 / 2 / 16 | [8, 0] |
| [short-4-r3](short-4-r3/summary.json) | True | pass | pass | pending | 16 / 16 / 32 / 32 | 16 / 1 / 15 | [8, 0] |
| [short-5-r1](short-5-r1/summary.json) | True | pass | pass | pending | 13 / 13 / 26 / 26 | 12 / 0 / 11 | [4, 2] |
| [short-5-r2](short-5-r2/summary.json) | True | pass | pass | pending | 14 / 14 / 28 / 28 | 12 / 1 / 12 | [4, 3] |
| [short-5-r3](short-5-r3/summary.json) | True | pass | fail | pending | 13 / 13 / 26 / 26 | 12 / 0 / 11 | [4, 2] |
| [short-6-r1](short-6-r1/summary.json) | True | pass | fail | pending | 12 / 12 / 24 / 24 | 12 / 3 / 13 | [4, 3] |
| [short-6-r2](short-6-r2/summary.json) | True | pass | pass | pending | 12 / 12 / 24 / 24 | 12 / 2 / 12 | [3, 3] |
| [short-6-r3](short-6-r3/summary.json) | True | pass | pass | pending | 12 / 12 / 24 / 24 | 12 / 3 / 13 | [4, 3] |
| [full-development-r1](full-development-r1/summary.json) | True | pass | pass | covered | 23 / 23 / 46 / 46 | 23 / 3 / 25 | [10, 3] |
| [full-development-r2](full-development-r2/summary.json) | True | pass | pass | covered | 23 / 23 / 46 / 46 | 22 / 4 / 25 | [10, 3] |
| [full-reserved-r1](full-reserved-r1/summary.json) | True | pass | pass | covered | 21 / 21 / 42 / 42 | 21 / 5 / 25 | [12, 1] |
| [full-reserved-r2](full-reserved-r2/summary.json) | True | pass | pass | covered | 20 / 20 / 40 / 40 | 20 / 6 / 25 | [13, 0] |

Every initial fixture prefix is counted separately in summary.json. Native request attempts exclude late outcome observations; HTTP attempts include runtime-internal retries and are not interchangeable with technical retries. Missing usage is unknown, never zero.

## Timing

| Attempt | First decision or failed request s | Later n / median / range s | Automatic board s | Human wait s | Full-board complete |
|---|---|---|---|---|---|
| short-1-r1 | 94.99803495407104 | 0 / unavailable | 95.0079380273819 | 0 | short |
| short-1-r2 | 93.65022003650665 | 0 / unavailable | 93.65749502182007 | 0 | short |
| short-1-r3 | 90.31234395503998 | 0 / unavailable | 90.31971800327301 | 0 | short |
| short-2-r1 | 74.00402903556824 | 7 / 12.415 / 9.394–20.894 | 166.8472239971161 | 0 | short |
| short-2-r2 | 68.67588996887207 | 7 / 16.482 / 9.553–19.702 | 175.38697397708893 | 0 | short |
| short-2-r3 | 77.27325701713562 | 7 / 14.154 / 8.204–39.537 | 195.42987895011902 | 0 | short |
| short-3-r1 | 44.43485701084137 | 11 / 10.757 / 7.406–15.308 | 164.2820770740509 | 0 | short |
| short-3-r2 | 68.49945998191833 | 11 / 12.496 / 7.093–17.579 | 208.81161499023438 | 0 | short |
| short-3-r3 | 77.22746205329895 | 11 / 16.075 / 7.911–21.893 | 236.94379794597626 | 0 | short |
| short-4-r1 | 61.40730595588684 | 15 / 10.819 / 7.812–23.270 | 253.2653579711914 | 0 | short |
| short-4-r2 | 78.01680195331573 | 15 / 11.786 / 6.838–26.198 | 274.9517329931259 | 0 | short |
| short-4-r3 | 58.047391057014465 | 15 / 9.805 / 6.708–15.717 | 208.05924999713898 | 0 | short |
| short-5-r1 | 142.86040806770325 | 11 / 14.189 / 10.790–28.998 | 344.77659702301025 | 0 | short |
| short-5-r2 | 249.7328770160675 | 11 / 22.887 / 12.011–31.960 | 491.84792697429657 | 0 | short |
| short-5-r3 | 105.98403596878052 | 11 / 18.578 / 14.499–118.845 | 410.61836194992065 | 0 | short |
| short-6-r1 | 52.291263937950134 | 11 / 12.551 / 9.967–45.132 | 239.4613310098648 | 0 | short |
| short-6-r2 | 45.088070034980774 | 11 / 13.940 / 8.291–23.580 | 202.50630807876587 | 0 | short |
| short-6-r3 | 47.000094056129456 | 11 / 13.252 / 8.557–17.853 | 191.67263293266296 | 0 | short |
| full-development-r1 | 59.774624943733215 | 22 / 9.525 / 7.106–26.047 | 337.31708800792694 | 0 | True |
| full-development-r2 | 64.47998297214508 | 21 / 10.052 / 6.375–59.172 | 354.9672249555588 | 0 | True |
| full-reserved-r1 | 47.675353050231934 | 20 / 11.974 / 6.802–18.127 | 280.79288601875305 | 0 | True |
| full-reserved-r2 | 66.99731397628784 | 19 / 13.591 / 7.787–27.329 | 350.0888569355011 | 0 | True |

All 4 of four scheduled full-board durations appear above, including incomplete failures. Each first/later decision duration includes both roles, revisions and retries; failed requests and environment overhead remain separately saved. The automatic 1,800 s board budget includes processing; the native request cap is 180 s. Human needs-input waiting is reported separately. There is no three-minute quality or speed gate.

## Role costs and outcomes

| Attempt | Role | Native attempts / seconds | Native observed total tokens / unknown attempts | HTTP attempts / observed total tokens / unknown attempts |
|---|---|---|---|---|
| short-1-r1 | player | 1 / 70.40601599216461 | 3755 / 0 | 1 / 3755 / 0 |
| short-1-r1 | reviewer | 1 / 24.58588993549347 | 2478 / 0 | 1 / 2478 / 0 |
| short-1-r2 | player | 1 / 73.61231303215027 | 3829 / 0 | 1 / 3829 / 0 |
| short-1-r2 | reviewer | 1 / 20.032805919647217 | 2407 / 0 | 1 / 2407 / 0 |
| short-1-r3 | player | 1 / 67.27609395980835 | 3704 / 0 | 1 / 3704 / 0 |
| short-1-r3 | reviewer | 1 / 23.030704021453857 | 2447 / 0 | 1 / 2447 / 0 |
| short-2-r1 | player | 8 / 76.12345910072327 | 44506 / 0 | 8 / 44506 / 0 |
| short-2-r1 | reviewer | 8 / 90.6147233247757 | 18334 / 0 | 8 / 18334 / 0 |
| short-2-r2 | player | 8 / 73.43237721920013 | 45415 / 0 | 8 / 45415 / 0 |
| short-2-r2 | reviewer | 8 / 101.79029607772827 | 18372 / 0 | 8 / 18372 / 0 |
| short-2-r3 | player | 8 / 86.59646511077881 | 46736 / 0 | 8 / 46736 / 0 |
| short-2-r3 | reviewer | 8 / 108.70943796634674 | 19141 / 0 | 8 / 19141 / 0 |
| short-3-r1 | player | 12 / 70.29389071464539 | 84902 / 0 | 12 / 84902 / 0 |
| short-3-r1 | reviewer | 12 / 93.79620432853699 | 28327 / 0 | 12 / 28327 / 0 |
| short-3-r2 | player | 12 / 90.39004790782928 | 88145 / 0 | 12 / 88145 / 0 |
| short-3-r2 | reviewer | 12 / 118.20865213871002 | 28273 / 0 | 12 / 28273 / 0 |
| short-3-r3 | player | 12 / 99.02995705604553 | 91188 / 0 | 12 / 91188 / 0 |
| short-3-r3 | reviewer | 12 / 137.73240327835083 | 29809 / 0 | 12 / 29809 / 0 |
| short-4-r1 | player | 16 / 91.24901807308197 | 145597 / 0 | 16 / 145597 / 0 |
| short-4-r1 | reviewer | 16 / 161.56462788581848 | 38830 / 0 | 16 / 38830 / 0 |
| short-4-r2 | player | 16 / 115.67214369773865 | 149978 / 0 | 16 / 149978 / 0 |
| short-4-r2 | reviewer | 16 / 158.84708499908447 | 39478 / 0 | 16 / 39478 / 0 |
| short-4-r3 | player | 16 / 97.52834796905518 | 150345 / 0 | 16 / 150345 / 0 |
| short-4-r3 | reviewer | 16 / 110.0899715423584 | 38626 / 0 | 16 / 38626 / 0 |
| short-5-r1 | player | 13 / 121.44547593593597 | 130085 / 0 | 13 / 130085 / 0 |
| short-5-r1 | reviewer | 13 / 223.07907605171204 | 34951 / 0 | 13 / 34951 / 0 |
| short-5-r2 | player | 14 / 181.71376621723175 | 174696 / 0 | 14 / 174696 / 0 |
| short-5-r2 | reviewer | 14 / 309.8553396463394 | 40944 / 0 | 14 / 40944 / 0 |
| short-5-r3 | player | 13 / 126.02350902557373 | 132776 / 0 | 13 / 132776 / 0 |
| short-5-r3 | reviewer | 13 / 284.35655403137207 | 36890 / 0 | 13 / 36890 / 0 |
| short-6-r1 | player | 12 / 77.79373013973236 | 89775 / 0 | 12 / 89775 / 0 |
| short-6-r1 | reviewer | 12 / 161.31936490535736 | 30467 / 0 | 12 / 30467 / 0 |
| short-6-r2 | player | 12 / 73.47414088249207 | 90654 / 0 | 12 / 90654 / 0 |
| short-6-r2 | reviewer | 12 / 128.72932612895966 | 30127 / 0 | 12 / 30127 / 0 |
| short-6-r3 | player | 12 / 69.26400077342987 | 90211 / 0 | 12 / 90211 / 0 |
| short-6-r3 | reviewer | 12 / 122.16088211536407 | 30051 / 0 | 12 / 30051 / 0 |
| full-development-r1 | player | 23 / 133.19637775421143 | 313556 / 0 | 23 / 313556 / 0 |
| full-development-r1 | reviewer | 23 / 203.19751596450806 | 61026 / 0 | 23 / 61026 / 0 |
| full-development-r2 | player | 23 / 144.92466604709625 | 312403 / 0 | 23 / 312403 / 0 |
| full-development-r2 | reviewer | 23 / 209.15832614898682 | 59151 / 0 | 23 / 59151 / 0 |
| full-reserved-r1 | player | 21 / 100.23586189746857 | 264578 / 0 | 21 / 264578 / 0 |
| full-reserved-r1 | reviewer | 21 / 179.71047413349152 | 54547 / 0 | 21 / 54547 / 0 |
| full-reserved-r2 | player | 20 / 147.4484348297119 | 245844 / 0 | 20 / 245844 / 0 |
| full-reserved-r2 | reviewer | 20 / 201.8042129278183 | 52751 / 0 | 20 / 52751 / 0 |

Native per-turn usage and upstream HTTP usage are separate observations of cost; never add the two totals. Failed attempts count when usage is observable. Input, cached input, output and reasoning tokens remain in each role summary. Grader durations and observed usage remain separately in grade/run.json and each summary. Monetary cost is unavailable without an attested applicable price schedule.

| Attempt | Semantic reviews | Feedback / clarification | Technical retries | Approved / contested delivered | Stop outcome |
|---|---|---|---|---|---|
| short-1-r1 | 1 | 0 / 0 | 0 | 1 / 0 | short-bound-complete |
| short-1-r2 | 1 | 0 / 0 | 0 | 1 / 0 | short-bound-complete |
| short-1-r3 | 1 | 0 / 0 | 0 | 1 / 0 | short-bound-complete |
| short-2-r1 | 8 | 0 / 0 | 0 | 8 / 0 | short-bound-complete |
| short-2-r2 | 8 | 0 / 0 | 0 | 8 / 0 | short-bound-complete |
| short-2-r3 | 8 | 0 / 0 | 0 | 8 / 0 | short-bound-complete |
| short-3-r1 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-3-r2 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-3-r3 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-4-r1 | 16 | 0 / 0 | 0 | 16 / 0 | short-bound-complete |
| short-4-r2 | 16 | 0 / 0 | 0 | 16 / 0 | short-bound-complete |
| short-4-r3 | 16 | 0 / 0 | 0 | 16 / 0 | short-bound-complete |
| short-5-r1 | 13 | 1 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-5-r2 | 14 | 2 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-5-r3 | 13 | 1 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-6-r1 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-6-r2 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-6-r3 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| full-development-r1 | 23 | 0 / 0 | 0 | 23 / 0 | board-complete |
| full-development-r2 | 23 | 1 / 0 | 0 | 22 / 0 | board-complete |
| full-reserved-r1 | 21 | 0 / 0 | 0 | 21 / 0 | board-complete |
| full-reserved-r2 | 20 | 0 / 0 | 0 | 20 / 0 | board-complete |

## Quality and coverage limits

The original serious-error standard and 22-attempt schedule are unchanged. Legal completion, contract result and reviewer approval cannot erase a material final error. Every raw grade, evaluator error and dispute is retained. A cited grader pass is provisional until independent review of the facts; unresolved grades remain pending. Coverage predicates are conservative: actual hold-up/communication and entry opportunities require independent explanation, and an avoided or unobserved trigger remains uncovered.

The formerly reserved board is already used regression material. These finite samples do not establish broad bridge strength. Original failed candidates, two historical HTTP metadata gaps, and older grader disputes remain history rather than newly accepted results.

Exact HTTP request bytes, metadata and sanitized public RPC outputs are preserved without credentials or decrypted reasoning. Both role catalogs are checked against the frozen native catalog. The runtime preserves opaque encrypted conversation history; that does not grant hidden bridge holdings or strategic tools.

The independent evidence/adjudication overlay and final per-issue met/unmet ledger are recorded separately. Until those are resolved, this report is captured evidence, not acceptance approval, main delivery, issue-closure authority or permission to merge.
