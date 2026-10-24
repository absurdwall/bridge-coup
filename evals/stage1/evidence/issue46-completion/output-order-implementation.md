# Output-order alignment handoff

## Candidate and isolation

- Base: `7129ffd352ee332c50b08db9d71a62d069afaaeb`.
- Worker branch: `codex/issue46-output-order`.
- Worker checkout: `/tmp/bridge46-output-order` (canonical `/private/tmp/bridge46-output-order`).
- Commit: `bbcbd1b1c1b5e8364dcc5bbb98a90b615878c365`.
- Integration remains at `7129ffd352ee332c50b08db9d71a62d069afaaeb`; I did not edit its source, `.build`, matrix, corpus, rubric, or evidence. No integration merge or GitHub write was made. The worker checkout is clean.
- Local hooks enabled with `git config --local core.hooksPath .githooks`; commit passed the hook.

## Bounded change

The dynamic response schema now generates root properties as `plan`, `selectedCard`, `publicReason`, matching the existing decision process. Nested plan properties remain `update`, `text`. The instruction output-field enumeration and existing two illustrative JSON examples use the same root order. Every example value and every non-example instruction line is preserved; only ordering changes. The source comment now describes the matching process.

No strategic guidance, fields, validation rules, parser logic, card enum, objective, decision step, notation, plan semantics, playing model/effort, tools, history configuration, or answer repair was added/changed.

This is a process/schema consistency correction and an **unproven model-quality hypothesis**. It does not establish a fix for the observed arithmetic, rank, play-order, or card-state errors. Existing v3 failures remain valid evidence. A separately versioned live candidate is necessary to assess quality; no model calls were made here.

## TDD at the already-authorized public seam

The seam is the public `ExpertSession` through `CodexPlayingTransport` to a local external app-server test process, examining the actual serialized `turn/start.outputSchema`. It is the existing accepted contract boundary, not a private serializer test.

1. Extend that boundary regression to reject any root property order other than plan/card/reason; existing nested update/text checks remain.
2. RED: actual old request reported `['publicReason', 'plan', 'selectedCard']` through a structured external-process error.
3. Apply the minimal schema/comment/instruction-order changes.
4. GREEN: the same boundary regression passes all four initial/keep/replace/withdraw turns.
5. The complete `PlanContractTests` suite passes **4 tests, zero failures**, including historical ambiguous-plan rejection and complete snapshot/plan continuity.

Command: `env -u SDKROOT BRIDGE_TEST_PYTHON=/var/folders/1l/xh7kf4ss1rqg3vxjr17q9_0w0000gn/T/bridge-pr45-review-h8xadm03/env/bin/python swift test --jobs 2 --filter PlanContractTests`.

Build/test execution was strictly local/offline with two Swift jobs. The initial worker build took 20.93 seconds; this local compile overlapped the independently frozen matrix's first full-board run, so timing reports should not imply a deliberately idle host.

## Artifacts

- `/tmp/bridge46-implementation-handoff/output-order-red.log`: initial failing assertion (external process exited).
- `/tmp/bridge46-implementation-handoff/output-order-red-explicit.log`: clearer RED diagnostic identifying the old actual property order.
- `/tmp/bridge46-implementation-handoff/output-order-green.log`: GREEN target test.
- `/tmp/bridge46-implementation-handoff/output-order-plan-contract-suite.log`: all 4 contract tests GREEN.
- `/tmp/bridge46-implementation-handoff/output-order-diff.patch`: complete three-file diff (9 insertions, 6 deletions).
- `/tmp/bridge46-implementation-handoff/output-order-commit.txt`: exact commit.

`git diff --check` passed. A one-off non-mutating comparison confirms both parsed example objects are unchanged, their root ordering is plan/card/reason, and the non-example instruction lines are the same multiset. No additional test file or corpus edit was added.

## Integration

Root should have the merger integrate exact commit `bbcbd1b1c1b5e8364dcc5bbb98a90b615878c365` only after the frozen v3 matrix finishes. This handoff does not claim Stage 1 acceptance or authorize any PR merge.
