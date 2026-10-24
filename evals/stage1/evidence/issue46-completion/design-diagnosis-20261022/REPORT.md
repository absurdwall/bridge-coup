# Luna Medium design and failure diagnosis, 2026-10-22

**Unresolved; not an acceptance run or a production fix.** The user chose to retain Luna Medium and investigate design/failure causes. No production player source, fixed instructions, output schema, model, effort, or one-board/one-thread behavior changed. One generic instruction variant was tested only in diagnostic requests and was not adopted. PRs #45 and #47 remain draft and unmerged; the original quality gate remains failed.

## Exact symptom and first occurrence

The original v4 short-6-r1 trace is authoritative. The temporary `check_saved.py` was run and returned nonzero on both exact witnesses, binding the saved request/output to the same model turn:

- d6: North HA43 and South HKQJ, three hearts each; the replacement plan claims four heart tricks. Both hands must follow for three rounds, so four heart tricks are impossible from these holdings. This is a new error, subsequently carried by keeps through d10.
- d11: North acts second to West CQ and is void clubs; South still has CAJ and acts fourth. The replacement plan calls CQ West's winner. This is the first false club-finality conclusion, distinct from the earlier heart count.
- d12: actual plays CQ, H3, C9; South is last with CAJ and legal CA/CJ. The model chooses CJ and retains the wrong plan. The current public winner really is CQ so far; it is not the final winner if South plays CA.

At d12, North retains DKQJT and HA4, South has CAJ, D543 and HKQ, DA has been played, and the contract is NT. A visible seven-trick route exists: CA now; HK with North H4; HQ with North HA; North's four diamonds, South following three times and discarding CJ last. This wins every remaining trick regardless of hidden defender holdings. Ducking now cannot recover that lost trick. The direct rank-error reasons and the unsupported loss of a sure trick are separate observations.

The exact inputs contain the relevant cards, plays and ranks. No snapshot corruption, illegal enum, parse fault or execution mismatch was found. Existing instructions already say later cards can change winningPlay, actual plays establish facts, and unfinished plans must be reassessed.

## Fixed diagnostic batches: all 42 requests retained

All player calls request **gpt-6-luna / medium**, native **0.160.0**, no tools, through the real production `CodexPlayingTransport`. These are bounded counterfactual probes, not continuing-board acceptance. Each condition/sample was scheduled before its batch, with no retries, fallback, answer repair or selected passing runs. The two direct-fact tasks intentionally change task/schema as competence controls; they are not autonomous-play passes. A correct card alone is not a complete plan/reason grade.

| Batch | Calls | Main observations |
|---|---:|---|
| Fresh-context factors | 18 | Original d12 current request chooses CA 2/2. Six plan-null / winningPlay-omission variants also choose CA. Fresh d11 makes the false future-CQ-winner conclusion 1/2. Direct heart count is 3 in 2/2; direct club-winner answer is CA in 2/2. Normal d6 probes do not explicitly regenerate the four-heart count. |
| Original-history replay | 10 | At d12 full history chooses CJ 2/2; public-only history CA 2/2; fresh CA 2/2. d6 full/fresh do not regenerate the explicit four-heart count. |
| Reasoning-window controls | 8 | At d12 full history CJ 2/2; public-only CJ 2/2; latest reasoning only CA 1/CJ 1; all reasoning except latest CJ 2/2. All public history is retained in the partial-reasoning arms. |
| Generic memory-rule sentence | 6 | Same full history: sentence-only candidate CJ 3/3; concurrent unchanged controls CJ 2/3 and CA 1/3. No observed improvement; candidate not adopted. |

For the original unmodified d12 current input, pooled fresh context chooses **CA 4/4**. Pooled unchanged full-history controls choose **CJ 6/7, CA 1/7**. Public-only is **CA 2/CJ 2**. These small, sequential samples suggest a context effect but are not population failure rates. The full-history condition is not deterministic. The first four full-history controls happened to be CJ 4/4; the later correct control is retained and included here.

The candidate sentence says to treat earlier assistant responses/reasoning as fallible and derive current facts anew before retaining conclusions. One candidate reason explicitly says CJ overtakes CQ. The other two keep the old plan and give up the present sure winner to preserve CA. Three failures do not prove the wording can never help, but provide no evidence for promoting it. The original production instructions remain unchanged.

## What has and has not been isolated

1. **Knowledge versus application:** the model can answer the isolated count/rank questions, but does not reliably apply those facts in combined planning and continuity. This is not proof that it understands every state or that a fact-only preflight fixes play.
2. **History can reinforce errors:** with the same current snapshot and same false effectivePlan, fresh and full-history requests behave differently in this bounded sample. The wrong effectivePlan alone does not force CJ. History selection also changes length, earlier actions and explanations, so the experiment does not isolate content from length or a specific erroneous sentence.
3. **Opaque reasoning is not the sole identified cause:** public-only history also fails in a later block. Latest-only and all-but-latest controls do not isolate a reliable responsible reasoning item. Encrypted contents are not decrypted or semantically inspected.
4. **A first error can occur without history:** fresh d11 still predicts West's final club win once. History filtering therefore cannot by itself resolve initial two-hand trick forecasting.
5. **The heart root remains unresolved:** its original explicit overcount is verified, but not reproduced in the new normal-play probes. Direct count controls are correct. Do not claim the club-history finding explains the heart count.
6. **No token-exhaustion or zero-thinking explanation established:** the original d12 input was 12,541 tokens, well below the catalog's 272,000-token context window, and reported 163 reasoning tokens. In the original-history-study pair, correct public-only probes used 53/103 new reasoning tokens; incorrect full-history probes used 151/71. Later public-only reasoning-window probes reported zero and chose CJ. More new thinking tokens alone do not establish correctness. This does not rule out attention effects as context grows.

## Request-level audit and replay limits

Fresh probes compare actual HTTP developer text, current user text and schema to each frozen variant. Every replay probe compares the actual model input to the expected original selected history, current user snapshot, schema, model, effort and tool parameters. The comparison removes only item IDs and normalizes absent/null optional reasoning.content. All public text, item ordering and opaque encrypted_content remain exact. Catalog files are deduplicated by SHA-256 in the archive; no captured request/output has been rewritten.

All 42 actual requests have HTTP 200, completed output and an empty `additional_tools.tools` array. `all_turns` remains requested. A missing top-level tools key alone is not the no-tools evidence. Per-thread routing/cache IDs and new sampling/time can vary. Audit metadata uses `httpStatus`; the earlier completed-state label is not mistaken for an HTTP status.

The installed native generated experimental schema supplies **thread/inject_items**, with raw ResponseItems. A temporary relay appends only the real original authorized prefix on a new diagnostic thread, confirms the RPC acknowledgment, then forwards the unchanged production turn/start. It neither invents an ideal answer nor sees future/hidden cards. The actual HTTP audit, not RPC success alone, establishes what reached the model. There are **20 seeded and 22 fresh requests**: history-study has six seeded and four fresh; reasoning-window has eight seeded; memory-rule has six seeded; the initial study has 18 fresh. No seed replay is claimed to reproduce the identity of the original live thread.

Two initial offline relay dry runs used an incorrect camelCase method and failed before any model turn; the corrected underscore method was acknowledged in an offline dry run, also with zero model requests. These harness startup failures are not model failures and are not hidden rerolls. Their full temporary records remain under /tmp/bridge46-design-diagnosis-20261022/dry-history*. The local API excerpts are in local-api/. Official general thread documentation does not establish this experimental endpoint's precise behavior.

## Design implications and next boundary

Keep the complete authoritative snapshot and verbatim effectivePlan contract. They make discrepancies inspectable; this study does not show a JSON parser or state-reducer defect to repair.

Treat raw conversation history as fallible model evidence, not a verified board memory. The explicit plan can be superseded, while old assistant statements and opaque reasoning still remain in the thread. The current design asks the model to resolve that conflict. A generic extra warning failed this focused check.

The next substantive design question is how to make reassessment of the current trick and remaining line operational, rather than append more generic prose. Two distinct problems must be addressed: deriving a correct new two-hand line, and preventing disproven old conclusions from governing later decisions. A structured fact/plan verification stage is a design candidate, not an implemented capability or a proven fix. It would need evaluation at the original d11/d12 sequence and the heart-count witness, without injecting fixture-specific answers.

Do not silently replace the approved one-continuing-thread-per-board design with fresh threads and call it equivalent. The local turn/start schema shows no verified simple per-turn history exclusion switch; thread/inject_items appends rather than filters, and compaction is another model operation. A curated-history or fresh-context architecture would reopen that session/continuity contract and needs an explicit design decision. Even such a change would not solve the demonstrated fresh d11 failure on its own.

There is no justified production fix from this diagnostic batch, and no new full matrix was run. Keep Luna Medium fixed, preserve failures, and keep issues open. Stage 1 remains incomplete.

## Evidence and offline inspection

- PLAN.json, hypotheses.json, runtime-freeze.json: initial frozen study, predictions and native/source hashes.
- results.json and wire-audit.json: initial 18 calls; history-study/, reasoning-window-study/, memory-rule-study/: each later plan/results/audit and original runs.
- Each run contains the actual wire request, response metadata, raw public output, RPC transcript, identity and timing. Shared catalogs and ARCHIVE-MANIFEST.json preserve deduplicated mappings.
- independent-original-trace-review.md, independent-comparison-review.md, independent-final-addendum.md: Luna Max read-only reviews; no player/model substitution.
- Probe.swift and diagnostic Python sources are historical harnesses, not production code or an automatically executable acceptance suite. They retain the actual /tmp and worktree paths used. The compiled probe and generated executable wrappers are omitted; sources are retained.

Offline audits require Python 3 and the original trace under development-v4/short-6-r1. In this checkout, `python3 .../design-diagnosis-20261022/audit_fresh.py`, audit_history.py, audit_window.py and audit_memory.py read saved files and make no model calls. The historical request/seed path pointers still identify the temporary execution location. To execute a new live study, create a new predeclared study directory and rebuild Probe.swift against the frozen Swift build's BridgeCodex/BridgeExpert/BridgeDomain objects; do not rerun a historical driver in place or treat new samples as replacements for these results.
