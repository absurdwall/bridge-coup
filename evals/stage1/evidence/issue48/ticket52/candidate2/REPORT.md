# Stage 1 finite acceptance

**PENDING INDEPENDENT REVIEW.** 12 of 22 predeclared attempts recorded.

Case execution configuration: `stage1-reviewed-case-execution-v1`. Only short-3 disables mechanical sole-legal skipping; its twelve delivered-decision bound is unchanged. More sole-card advice can increase model/reviewer work and stop after fewer actual plays. This is not a prompt-only controlled comparison.

The prescribed three-run cohort must demonstrate at least one eligible model window and correct semantic use before the other defender's first actual club show-out. Every unexercised window is reported. No forced reference route or reroll is permitted.

Candidate source commit: `0a307cbde5498ed24b73da0d781cb9113ce92180`. Both instruction sources, role configurations, schemas, runtime/capture code, fixtures, rubrics and binary/native-runtime hashes were frozen in [candidate.json](candidate.json).

Production player and independent runtime reviewer both request gpt-6.1-sol / medium with empty additional_tools. The separate acceptance grader requests gpt-6.1-sol / medium. Requested/observable identities do not prove hidden service internals. Every attempt runs strictly sequentially; the bounded product loop permits five semantic reviews and four technical attempts per review round. There are no board rerolls, manual controlled substitutes or grader feedback into live play.

Only delivered advice is graded. Rejected drafts are diagnostic. Review approval and contested execution are authorization dispositions, never bridge-quality labels. Canonical snapshots establish public facts; feedback envelopes preserve actual prior reviewer assertions as non-authoritative provenance.

| Attempt | Mechanical sole-legal | Task | Legal | Quality | Trigger | Player / reviewer / RPC / HTTP attempts | Model / forced / opponent plays | Tricks |
|---|---|---|---|---|---|---|---|---|
| [short-1-r1](short-1-r1/summary.json) | True | True | pass | pass | covered | 2 / 2 / 4 / 4 | 1 / 0 / 0 | [0, 0] |
| [short-1-r2](short-1-r2/summary.json) | True | True | pass | pass | covered | 3 / 3 / 6 / 6 | 1 / 0 / 0 | [0, 0] |
| [short-1-r3](short-1-r3/summary.json) | True | True | pass | pass | covered | 1 / 1 / 2 / 2 | 1 / 0 / 0 | [0, 0] |
| [short-2-r1](short-2-r1/summary.json) | True | True | pass | pass | pending | 8 / 8 / 16 / 16 | 8 / 0 / 6 | [3, 0] |
| [short-2-r2](short-2-r2/summary.json) | True | True | pass | pass | pending | 8 / 8 / 16 / 16 | 8 / 0 / 6 | [3, 0] |
| [short-2-r3](short-2-r3/summary.json) | True | True | pass | pass | pending | 8 / 8 / 16 / 16 | 8 / 1 / 7 | [4, 0] |
| [short-3-r1](short-3-r1/summary.json) | False | True | pass | pass | pending | 12 / 12 / 24 / 24 | 12 / 0 / 10 | [5, 0] |
| [short-3-r2](short-3-r2/summary.json) | False | True | pass | pass | pending | 12 / 12 / 24 / 24 | 12 / 0 / 10 | [5, 0] |
| [short-3-r3](short-3-r3/summary.json) | False | True | pass | pass | pending | 12 / 12 / 24 / 24 | 12 / 0 / 10 | [4, 1] |
| [short-4-r1](short-4-r1/summary.json) | True | True | pass | pass | pending | 17 / 17 / 34 / 34 | 16 / 1 / 15 | [8, 0] |
| [short-4-r2](short-4-r2/summary.json) | True | True | pass | pass | pending | 16 / 16 / 32 / 32 | 16 / 1 / 15 | [7, 1] |
| [short-4-r3](short-4-r3/summary.json) | True | True | pass | pass | pending | 16 / 16 / 32 / 32 | 16 / 1 / 15 | [8, 0] |

Every initial fixture prefix is counted separately in summary.json. Native request attempts exclude late outcome observations; HTTP attempts include runtime-internal retries and are not interchangeable with technical retries. Missing usage is unknown, never zero.

## Timing

| Attempt | First decision or failed request s | Later n / median / range s | Automatic board s | Human wait s | Full-board complete |
|---|---|---|---|---|---|
| short-1-r1 | 108.31920397281647 | 0 / unavailable | 108.32823300361633 | 0 | short |
| short-1-r2 | 290.3529359102249 | 0 / unavailable | 290.36175990104675 | 0 | short |
| short-1-r3 | 57.57149803638458 | 0 / unavailable | 57.57872402667999 | 0 | short |
| short-2-r1 | 93.95121705532074 | 7 / 16.195 / 9.588–30.788 | 228.16301906108856 | 0 | short |
| short-2-r2 | 66.54213297367096 | 7 / 12.264 / 8.659–16.106 | 153.24949300289154 | 0 | short |
| short-2-r3 | 86.92948198318481 | 7 / 17.131 / 8.658–22.112 | 195.88223505020142 | 0 | short |
| short-3-r1 | 78.37464499473572 | 11 / 12.567 / 8.074–35.057 | 264.2786109447479 | 0 | short |
| short-3-r2 | 79.57458293437958 | 11 / 11.781 / 6.660–23.002 | 229.5701459646225 | 0 | short |
| short-3-r3 | 82.6049530506134 | 11 / 12.753 / 8.825–34.603 | 260.34839701652527 | 0 | short |
| short-4-r1 | 128.85068595409393 | 15 / 7.820 / 5.945–25.681 | 282.4920449256897 | 0 | short |
| short-4-r2 | 43.09234297275543 | 15 / 9.207 / 6.859–18.689 | 203.64687991142273 | 0 | short |
| short-4-r3 | 41.7402960062027 | 15 / 9.581 / 6.323–16.307 | 195.1832299232483 | 0 | short |

All 0 of four scheduled full-board durations appear above, including incomplete failures. Each first/later decision duration includes both roles, revisions and retries; failed requests and environment overhead remain separately saved. The automatic 1,800 s board budget includes processing; the native request cap is 180 s. Human needs-input waiting is reported separately. There is no three-minute quality or speed gate.

## Role costs and outcomes

| Attempt | Role | Native attempts / seconds | Native observed total tokens / unknown attempts | HTTP attempts / observed total tokens / unknown attempts |
|---|---|---|---|---|
| short-1-r1 | player | 2 / 67.71223497390747 | 9051 / 0 | 2 / 9051 / 0 |
| short-1-r1 | reviewer | 2 / 40.59890699386597 | 5242 / 0 | 2 / 5242 / 0 |
| short-1-r2 | player | 3 / 155.15146696567535 | 19445 / 0 | 3 / 19445 / 0 |
| short-1-r2 | reviewer | 3 / 135.1922299861908 | 9734 / 0 | 3 / 9734 / 0 |
| short-1-r3 | player | 1 / 50.3877899646759 | 3421 / 0 | 1 / 3421 / 0 |
| short-1-r3 | reviewer | 1 / 7.177571058273315 | 2181 / 0 | 1 / 2181 / 0 |
| short-2-r1 | player | 8 / 83.57510793209076 | 47339 / 0 | 8 / 47339 / 0 |
| short-2-r1 | reviewer | 8 / 144.47064113616943 | 20726 / 0 | 8 / 20726 / 0 |
| short-2-r2 | player | 8 / 78.42431092262268 | 46859 / 0 | 8 / 46859 / 0 |
| short-2-r2 | reviewer | 8 / 74.69360566139221 | 19101 / 0 | 8 / 19101 / 0 |
| short-2-r3 | player | 8 / 90.62477922439575 | 53536 / 0 | 8 / 53536 / 0 |
| short-2-r3 | reviewer | 8 / 105.12529385089874 | 20775 / 0 | 8 / 20775 / 0 |
| short-3-r1 | player | 12 / 113.70319366455078 | 96402 / 0 | 12 / 96402 / 0 |
| short-3-r1 | reviewer | 12 / 150.3377469778061 | 31768 / 0 | 12 / 31768 / 0 |
| short-3-r2 | player | 12 / 96.24049496650696 | 92968 / 0 | 12 / 92968 / 0 |
| short-3-r2 | reviewer | 12 / 133.10330712795258 | 30527 / 0 | 12 / 30527 / 0 |
| short-3-r3 | player | 12 / 99.36107206344604 | 95437 / 0 | 12 / 95437 / 0 |
| short-3-r3 | reviewer | 12 / 160.75634920597076 | 32123 / 0 | 12 / 32123 / 0 |
| short-4-r1 | player | 17 / 121.53920471668243 | 202977 / 0 | 17 / 202977 / 0 |
| short-4-r1 | reviewer | 17 / 160.53146815299988 | 45923 / 0 | 17 / 45923 / 0 |
| short-4-r2 | player | 16 / 74.41232407093048 | 155181 / 0 | 16 / 155181 / 0 |
| short-4-r2 | reviewer | 16 / 128.8334754705429 | 41930 / 0 | 16 / 41930 / 0 |
| short-4-r3 | player | 16 / 80.4359849691391 | 143422 / 0 | 16 / 143422 / 0 |
| short-4-r3 | reviewer | 16 / 114.32897412776947 | 40080 / 0 | 16 / 40080 / 0 |

Native per-turn usage and upstream HTTP usage are separate observations of cost; never add the two totals. Failed attempts count when usage is observable. Input, cached input, output and reasoning tokens remain in each role summary. Grader durations and observed usage remain separately in grade/run.json and each summary. Monetary cost is unavailable without an attested applicable price schedule.

| Attempt | Semantic reviews | Feedback / clarification | Technical retries | Approved / contested delivered | Stop outcome |
|---|---|---|---|---|---|
| short-1-r1 | 2 | 1 / 0 | 0 | 1 / 0 | short-bound-complete |
| short-1-r2 | 3 | 2 / 0 | 0 | 1 / 0 | short-bound-complete |
| short-1-r3 | 1 | 0 / 0 | 0 | 1 / 0 | short-bound-complete |
| short-2-r1 | 8 | 0 / 0 | 0 | 8 / 0 | short-bound-complete |
| short-2-r2 | 8 | 0 / 0 | 0 | 8 / 0 | short-bound-complete |
| short-2-r3 | 8 | 0 / 0 | 0 | 8 / 0 | short-bound-complete |
| short-3-r1 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-3-r2 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-3-r3 | 12 | 0 / 0 | 0 | 12 / 0 | short-bound-complete |
| short-4-r1 | 17 | 1 / 0 | 0 | 16 / 0 | short-bound-complete |
| short-4-r2 | 16 | 0 / 0 | 0 | 16 / 0 | short-bound-complete |
| short-4-r3 | 16 | 0 / 0 | 0 | 16 / 0 | short-bound-complete |

## Quality and coverage limits

The original serious-error standard and 22-attempt schedule are unchanged. Legal completion, contract result and reviewer approval cannot erase a material final error. Every raw grade, evaluator error and dispute is retained. A cited grader pass is provisional until independent review of the facts; unresolved grades remain pending. Coverage predicates are conservative: actual hold-up/communication and entry opportunities require independent explanation, and an avoided or unobserved trigger remains uncovered.

The formerly reserved board is already used regression material. These finite samples do not establish broad bridge strength. Original failed candidates, two historical HTTP metadata gaps, and older grader disputes remain history rather than newly accepted results.

Exact HTTP request bytes, metadata and sanitized public RPC outputs are preserved without credentials or decrypted reasoning. Both role catalogs are checked against the frozen native catalog. The runtime preserves opaque encrypted conversation history; that does not grant hidden bridge holdings or strategic tools.

The independent evidence/adjudication overlay and final per-issue met/unmet ledger are recorded separately. Until those are resolved, this report is captured evidence, not acceptance approval, main delivery, issue-closure authority or permission to merge.
