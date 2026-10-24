# Independent disposition of the frozen v3 matrix

**Stage 1 is not accepted.** Candidate `7129ffd352ee332c50b08db9d71a62d069afaaeb` completed all 22 prescribed attempts and all four 52-card boards legally. Legal completion did not establish basic reasoning quality.

## Captured results and review overlay

The original runner records **3 pass / 18 fail / 1 pending** across 22 attempts, with **266 player requests**, **135 pass / 122 fail / 9 uncertain** provisional per-decision Sol judgments. These per-decision counts include repeated retained-plan errors; they are not independent error incidents. No original output, grade, summary, case or rubric was edited.

The independent attempt-level disposition is **4 pass / 17 fail / 1 pending**:

- The three initial-plan attempts remain basic-quality passes on this limited first-decision test. They do not prove continuation quality.
- `short-4-r1` is a quality pass. Its actual sequence consumes CQ, uses H4 to HA, later H3 to HK, and C7 back to South's CA; a real consumed-honor/entry opportunity is covered. This satisfies only the predeclared basic facet. The stronger `post_two_honors` facet remains false, as recorded originally. See the independent report and unchanged original summary.
- `short-5-r2` is pending rather than a confirmed failure: the legal DK development play's phrase “cash” is ambiguous in context because the active plan explicitly anticipates DA; later route questions remain unresolved. This is not a pass.
- Every other failed attempt retains at least one concrete material defect under independent review. Some individual Sol findings were downgraded to uncertain where they depended on strategy, access after losing the lead, or ambiguous wording. No uncertain line was silently passed.

See [review-work](review-work/) for the original and corrected independent reports. Two reviewer rank mistakes were caught by the parent and explicitly corrected with version history: Q outranks J, and K is top once A is consumed. Independent review is evidence to inspect, not an automatic truth source.

## Confirmed failure families

1. Wrong known ranks/ownership: CQ treated as threatened by CJ; an opponent assigned HA while the authorized hand visibly owns it.
2. Incorrect counting or omitted established winners: seven listed winners plus one called nine; South's remaining clubs denied after all defender clubs are in public history; four heart tricks claimed from two three-card heart holdings.
3. Impossible timing/routes: choosing North's card after seeing East's later fourth-hand play; referencing consumed cards or a spade continuation when both authorized hands are void.
4. Material action/plan disagreement: overtaking a certain partner HK with HA without a useful entry or safety reason; later `keep` propagating an explicitly false remaining-card plan.

The exact quotes and decision-time facts are in the separate reports. These conclusions do not require hidden defenders' cards or an optimal reference sequence. Some merely inferior or strategically unresolved routes remain uncertain.

## Engineering and protocol evidence

- [Final wire/thread audit](review-work/final-wire-and-thread-audit.json): all 266 captured player requests request Luna Medium with `all_turns`, empty additional tools, and 266 HTTP 200 responses. No playing retry, substitute answer or manual controlled card. Each attempt uses one continuing thread; all 22 attempt threads are distinct. Public input/output text contains no CJK characters; encrypted internal reasoning language is not asserted.
- The actual output property order is `publicReason`, `plan`, `selectedCard` throughout this candidate. No source or binary changed during its run.
- Actual remaining hands, full public history, current winner and verbatim effective plans are present. Independent diagnosis found no confirmed snapshot, parsing or execution fault causing the cited model content errors.
- The bundled native runtime/model catalog and exact source, schema, corpus and rubric hashes are frozen in [candidate.json](candidate.json). The original request/response records remain available per attempt.

## Timing and limits

All four boards completed legally in **75.214, 88.017, 106.971 and 79.604 seconds**, respectively. Full individual initial/subsequent latencies and environment overhead appear in [REPORT.md](REPORT.md) and each trace. Three minutes is not a quality gate. The first board overlapped a 20.93-second, two-job local compile in a separate worktree; these are measured wall times on the actual host, not an idle-host performance benchmark.

The former reserved board is regression material, not a fresh holdout. Calibration was bounded and does not establish universal grader accuracy; the review disagreements above demonstrate that limitation.

## Disposition

The full matrix meets legal-execution and evidence-capture tasks but fails the required basic semantic-quality gate. Issues #36–42 and #46 remain open, and PR #47 remains draft. No PR is approved for merge.

A separate v4 correction aligns schema, existing enumeration and examples to plan → selectedCard → publicReason without adding strategy instructions or changing models/inputs/rubric. Its quality benefit is an unproven hypothesis and cannot retroactively repair this matrix. It requires separately versioned evidence.
