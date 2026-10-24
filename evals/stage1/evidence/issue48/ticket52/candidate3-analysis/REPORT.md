# Candidate 3 — final bounded-cycle NO-GO

**Acceptance failed. All 22 original scheduled tasks completed, but independent review finds 265 delivered decisions pass / 5 fail / 0 uncertain, with 21 passing attempts and one failing attempt.** All 22 core coverage targets are demonstrated; the separate stronger short-3 semantic-use facet remains unmet. This is cycle **3 of maximum 3**. No fourth candidate, reroll, source repair or additional model call follows this result.

The [central acceptance report](../../ACCEPTANCE-REPORT.md) and [obligation ledger](../../OBLIGATION-LEDGER.md) contain the final 13-issue disposition, all eight explicit supersessions and all 41 retained historical obligations. Both are verbatim copies of Spec's finalized outside documents, bound by [central-document hashes](central-document-bindings.json). The [final adjudication index](originals/candidate3-adjudication-index.json) preserves every review/proof hash; [aggregate.json](aggregate.json) separates raw and independent judgments. Code implementation, tested protocol behavior, legal completion and review approval do not establish accepted advice quality or main delivery.

## Confirmed failures

`short-5-r2` contains **five material delivered failures, decisions 7–11**. The retained show-out branch incorrectly says only one immediate diamond winner remains and treats DJ as outstanding. A legal public-compatible branch has East play DJ under DK while West shows out; D9 and D7 are then winners, with a feasible nine-trick route through the preserved CK/HA. Decision 12 repairs the plan, without erasing the earlier deliveries. The [independent review](originals/candidate3-short-5-r2-review.md), [public counterbranch proof](originals/candidate3-short-5-r2-public-proof.json) and [coordinator resolution](originals/candidate3-short5-r2-coordinator-resolution.md) retain the exact outputs and reasoning.

Raw grading remains **259 pass / 11 fail**, unchanged. Independent adjudication rejects six raw allegations: the defenders originally have six spades, and the initial favorable doubleton-ace examples are qualified possibilities rather than a guarantee for every ace layout. The final result is **265 pass / 5 fail**. Neither later actual outcomes nor reviewer approval resolve these judgments.

For short-3, r1/r2 have no eligible third-club-before-first-show-out MODEL window. R3 has a genuine eligible model decision at revision 18 after West's third club and before East's first show-out at 19. Basic quality passes for all 36 deliveries, but distinct observable semantic use of the new owner information is **not established**, under the [final cohort resolution](originals/candidate3-short3-cohort-coordinator-resolution.md), [independent facet check](originals/candidate3-short-3-r3-independent-facet-check.md) and preserved exact forecast comparison. This is separate from the five basic-quality failures. No keyword, forced plan replacement or inaccessible internal-reasoning claim substitutes for the fixed criterion. There are no extra short-3 trials.

## Original strict execution and timing

The original `acceptance.py run` executed the predeclared 18 short / 4 full schedule once, sequentially, from frozen source `3f0fc65470633dd90363ad0417b29a9f7f68be18`. Case-execution v1 disables sole-legal automation only for the three short-3 runs, retaining their twelve-delivery bound; all other 19 runs retain it. Corpus, rubric, repetitions, bounds, schemas and model configurations remain frozen. Candidate1/2 records are immutable and are not pooled into this cycle.

The original finish marker records 22 attempts. Every board process and grader process has an actual recorded exit code zero. The detached orchestrator PID disappeared after finishing, but its own **OS exit status remains unknown**, as recorded in [process observations](process-completion-observations.json). There was no interruption, resumption, supplement or inferred exit-zero claim. The reviewed original/final launchers, narrow attestation diff, harmless detachment tests, PID/PGID/session/argv registry, build environment and logs are retained in [launch originals](originals/launch/).

| Full board | Model / forced actions | Automatic seconds | Declarer–defence tricks | Independent advice quality |
|---|---:|---:|---:|---|
| development r1 | 23 / 3 | 292.618 | 10–3 | pass |
| development r2 | 22 / 4 | 275.451 | 10–3 | pass |
| used regression r1 | 21 / 5 | 264.044 | 12–1 | pass |
| used regression r2 | 21 / 5 | 252.703 | 13–0 | pass |

All four boards independently replay 52 distinct legal cards / 13 tricks. The former reserved material is now used regression material, not fresh held-out evidence. Reconstructing completed holdings verifies legality only; it does not supply earlier private quality facts. Public-compatible hypothetical 4–1 club branches in the development proofs are not actual 4–1 environment coverage.

The 22 driver automatic durations total **4,812.417 s**, with observed human waiting **0**. First-decision latency: 22 observations, median **64.761 s**, range **30.420–184.613 s**. Later-decision latency: 248 observations, median **10.907 s**, range **4.285–91.681 s**. The original UTC start/finish markers span **5,851.369 s**, including play, grading and per-attempt overhead; this is distinct from board-only automatic time and from OS exit status. Per-board first/later/environment timings remain in the original records.

## Actual requests and cost observations

The 270 final deliveries require **280 player attempts**, **280 valid semantic reviews**, **10 feedback revisions** and **0 technical retries**. There are **28 mechanical actions**, **560 play-pipeline native RPC starts / 560 captured HTTP attempts**, and 22 separate grader invocations. `modelRequests` includes revisions rather than counting only final deliveries. All 270 final dispositions are review-approved; live contested/uncertain/needs-input paths are not claimed from this sample.

| Role | Observed turns / invocations | Observed elapsed seconds | Input tokens | Output tokens | Reasoning subset | Cached-input subset |
|---|---:|---:|---:|---:|---:|---:|
| player | 280 | 1,803.833 | 2,865,836 | 41,369 | 18,627 | 41,344 |
| runtime reviewer | 280 | 3,000.817 | 688,417 | 69,872 | 58,646 | 0 |
| independent grader | 22 | 1,014.374 | 1,942,968 | 43,496 | 5,120 | 69,120 |

All 560 play-pipeline usage observations and all 22 grader observations are present; missing usage is never encoded as zero. Native and HTTP observations overlap and must not be added. Native reported totals are 2,907,205 player tokens and 758,289 reviewer tokens. Cached/reasoning fields are subsets, not extra tokens. Monetary cost is unavailable without attested prices; grader invocation count is not a claim about unobserved grader HTTP transport attempts.

[Native encoding audit](native-plan-encoding.json) binds all 280 actual reviewer wire candidates and all 280 saved player rounds: **40 replace / 240 keep**, with required explicit `text:null` for keep and no tools. No live withdraw was observed. Actual final player request/output, canonical full snapshot, final candidate/round/authorization and independently derived effective plan remain separately bound in saved evidence. Rejected drafts are diagnostic/cost observations, not additional final quality targets. Prior reviewer assertions in feedback are not authoritative public facts.

## Freeze and durable audit

Both live roles and the separate grader request `gpt-6.1-sol / medium`; live tools are empty. Requested/observable identities do not independently attest hidden service resolution. Native Codex is 0.160.0, SHA256 `112fae7a5a1223e673c8a1791d32338f37df8b527ff1159bb8adac6c4dbf1b4b`, with bundled-catalog hash preserved in `candidate.json`.

- Executable: `69fb6cee9a510470f600b90ce777579414615dae8c0d0ec827052da9d1e387c8`.
- Player instructions: `87df545b7fb9d9e443be3ab1c8e8183bfae0eb7965b927faa465cde75d8e18d8`.
- Reviewer instructions: `be4edb3055da50aab8299f10b890a5936a09ff09e9cfbf5f9489df8790e11fb3`.
- Exact executable + adjacent Swift resource-bundle [archive](runtime/candidate3-runtime.tar.gz): `186741545c0b3eb3590cec6297ff81a5a2c1e6facf38a43edf1c4ea75898ff5f`.
- All 50 pinned Git source blobs [archive](runtime/candidate3-source.tar.gz): `0bb2e7f987adae2c1c8923ddf10db6cda8e1045125667536ef34eda1aaab3206`.

The executable/resources/source were archived **before any model call or subsequent build**. The actual binary was rebuilt with command-scoped matched `SDKROOT`; no project config or installation changed. Reviewed source validation was **255 Swift tests (10 existing skips), 74 Python tests**, plus merger checks. The initial SDK mismatch and successful matched-SDK observations remain in the source repair evidence.

[Raw preservation](raw-preservation.json) seals **3,428 files / 515,356,364 bytes** with exact file-set equality, unique count, byte totals and every hash. The final [external manifest](external-preservation.json) seals **140 verbatim originals**, including all review/proof/generation/draft/root-checkpoint/tracker/launch/helper-audit assets and final master/ledger. The 117-input audit checkpoint remains historical provenance; final documents were appended and the final 140-input preservation/lifetime audits rerun successfully. Spec's fifteen-row drafts and index snapshot remain unchanged.

[Independent helper audit](originals/candidate3-evidence-helper-audit.md) reports **Standards 0 / Spec 0 findings**; all seven helper hashes remain pinned. [Final lifetime regression](lifetime-portability-verification.json) passes with every current frozen source file changed and no `.build`, native executable, Git or network. It reruns the public proofs/counterbranches, environment-only Walker archive replay, final aggregation/encoding, unlisted-raw sentinel rejection and optional-current-source negative check. The one historical script that unconditionally writes is replayed unchanged through a read-only redirect/compare wrapper. [Audit instructions](README.md) distinguish saved evidence audit from a new native run; [path mapping](path-remapping.json) preserves raw absolute paths rather than rewriting them.

Candidate1/2 preservation and lifetime checks also pass after this final source/build/run, with their original bytes unchanged. Their results are separate historical artifacts, not substituted passing slots. Final owner acceptance, main delivery, PR merge and legacy acceptance/reintegration closure remain unapproved. The [fresh saved tracker](originals/final-tracker-snapshot.json) and central ledger record scoped #49–51 separately from the still-unmet parent acceptance. This package performs no GitHub operation.
