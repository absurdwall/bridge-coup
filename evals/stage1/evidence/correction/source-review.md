# Independent correction review

Pinned source review at05efe5d, README-only resolution at1d0fae4. Fixed main b2fb9b1. No acceptance or merge authorization.

## Standards

# Standards review — pinned correction source

Reviewed `b2fb9b1d0433357dcdb6e09e4e06fe7736539fb6...05efe5d476dfe498e7f4832fc5011bcc0aaf3a93`, with the correction delta from preserved `be0cad0632244dafa6f975a09a7c4d24c8743e2b` separated from restoration. Verified the reported restoration/capture/Expert/Eval/merge commit sequence in Git.

## Documented rules

No actionable breach of AGENTS, CONTEXT, domain/issue/triage guidance, or ADR 0001/0002 found in the reviewed source. The explicit user-approval merge clause is present. Runtime dependency direction keeps Domain/Engine independent of Expert/Codex/UI; current-action additions expose authorized rule facts without strategy ranking. Plan variants preserve explicit keep/replace/withdraw semantics and visible rejection. No second playing reasoner, hidden-hand input, Knowledge injection, answer repair or policy DSL was introduced. Git comparisons show zero changes to historical ticket37–42 evidence, including original outputs and grades. Reopened dependency issues are being corrected under the user's explicit instruction, not treated as accepted delivery.

## Maintenance finding

**[P3, heuristic] Refresh duplicated current-version documentation.** `evals/stage1/README.md:51` still calls `stage1-basic-v2` the “final citation contract”; line 53 calls wire v3 “current”; line 90 again calls v3 current and says “Stable instructions are unchanged.” The correction now uses rubric v3 and wire v4 with revised instructions (`evaluate.py`, `Expert.swift`). Label these paragraphs historical or update the current overview and link the correction review. This is documentation drift from duplicated contract descriptions, not a violation of a documented coding rule or a live-quality failure.

Reviewed all requested baseline smells (naming, duplication, feature envy, clumps/primitives, repeated switches, scattered/divergent change, speculative generality, chains/middlemen and refused bequest); no additional actionable code smell warrants a change in this bounded correction. Existing small boundary adapters are justified by runtime isolation and testability.

No tests, model calls, repository edits or GitHub operations performed. Saved review logs were inspected, not independently rerun. This report does **not** establish provider-schema compatibility, grader reliability, playing quality, specialty coverage or stage acceptance; those remain pending evidence. Draft status and explicit user approval remain required.

## P3 resolution — 1d0fae4

Inspected `05efe5d...1d0fae4e1b3044b31ebf9f47425645c5e545c985`; its only changed file is `evals/stage1/README.md`. The three affected paragraphs now describe rubric v3, wire v4 and explicit plan variants, distinguish historical v1–v3 evidence, acknowledge revised instructions/current-action facts, and link the correction reviews with live validation still pending. The P3 finding is resolved; no remaining actionable Standards finding. No tests or model calls were needed for this documentation-only delta. This resolution neither accepts the Spec nor authorizes merge.

## Spec

## Spec

Reviewed pinned `05efe5d476dfe498e7f4832fc5011bcc0aaf3a93` against reverted main `b2fb9b1d0433357dcdb6e09e4e06fe7736539fb6`, including commit log, restored core and focused corrections since `be0cad0`. Sources: live snapshots of #36–#42, CONTEXT, ADRs 0001/0002 and the user's correction/approval boundary. No tests, model calls, edits to repository files or GitHub writes performed.

**Known unmet requirements — acceptance remains blocked:**

1. #36 requires “All required short runs satisfy their tasks without predeclared severe defects” and four full runs “without severe factual, feasibility or consistency failures”; #42 requires “每个必需运行完成任务且没有预定义严重错误”. Original 21 failed/one pending/zero accepted attempts remain failures. No corrected live quality evidence or final matrix exists at this revision. Offline structural checks cannot establish these requirements.

2. #36 requires grader calibration “each graded twice” with verdicts **and explanations** validated, and #41 requires specialized cases to “实际触发目标能力”. Revised grader/provider compatibility and fixed-configuration saved-answer calibration are pending. Walker's authored legal two-duck/DA-loss witness establishes reachability, not observed player communication skill; original three runs bypassed it. Short-4 entry opportunity remains limited/pending; short-3's precise pre-discard window had a forced card rather than a model decision. These limits are accurately disclosed and cannot be counted as passing coverage.

**New implementation/report defects: none identified.** Nested plan variants exclude the four observed keep-with-text failures while retaining replace/keep/withdraw semantics and initial replacement; historical failures remain immutable. Current-action text repeats legal choices, which can equal the acting hand at a new lead, but does not replay both remaining hands, plans or full history; the documented, narrow current-turn context fits #36's “primarily … actual events … plus concise current-turn identification.” Capture persists terminal metadata before observable completion; original two unknown statuses stay unknown. Citation minima repair the 45 demonstrated empty-findings schema mismatch; independent runtime validation remains pending. Simultaneous mechanical/evaluator failures retain both attributions. Corpus v2 preserves deals/counts, identifies used reserve as regression, and does not force one reference line.

No unrequested capabilities found. Explicit approval is required even after passing review; PR must remain draft, #36–#42 open. **Spec is NOT SATISFIED: two known pending requirement groups; zero new actionable code/report findings.**


Totals: Standards0 documented breaches /1 P3 documentation finding resolved; Spec2 known unmet requirement groups /0 new actionable code findings. Source review does not establish live quality.
