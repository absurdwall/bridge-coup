# Ticket 50 — pending-decision review loop

Implementation extends integration `d4b4f86bae786ab8ec4d49b0c2f22f03cd549c97`
without restarting the existing player, changing the immutable position or
adopting intermediate plans. Review-approved or fifth-round contested advice
uses the existing canonical once-only BoardDriver execution/Expert commit.
Reviewer verdicts remain unchanged. Technical retries and complete failure
publication are the dependent ticket 51; acceptance is ticket 52.

## Public behavior and evidence

- A revise/uncertain verdict returns the actual proposal and exact raw feedback
  to a new turn in the same player conversation. A feedback envelope contains
  the unchanged full snapshot and prior active plan, candidate, proposed plan,
  actual raw candidate/review, and parsed review. Uncertainty requests checking
  and restating authorized public facts while defender holdings remain unknown.
- At most five valid semantic reviews include the initial review. Approval
  releases its exact candidate; otherwise the valid fifth candidate is released
  as contested, with its own keep/replace/withdraw operation. Neither an illegal
  fifth candidate nor an absent/malformed fifth review releases prior advice.
- Program-detectable incomplete/conflicting authorized holdings, history or
  legal choices produce needs-input before a semantic round or execution.
  Ordinary reviewer uncertainty at a complete position still consumes a round
  and permits contested release at five.
- DecisionRecord retains canonicalInput separately from the actual final input,
  every ReviewRound's player input/output/identity/timing and bound candidate /
  review, and executionDisposition. ExpertFailure retains completed review
  rounds even when a later player/reviewer request fails. Ticket 51 extends
  technical-attempt/failure publication, deadlines and costs.
- Review status is separate from the working active plan. Instruction baseline
  snapshots, hashes, exact diff and independent writing-for-agents review are
  under `instructions/`. Planning guidance, objective and schemas are unchanged.

## Tests

The authorized seam is public ExpertSession through BoardDriver, with synthetic
recorded external transports. These offline tests are not natural model runs.
Test-first cycles preserved under `tests/` establish revise-to-approve (red1),
five-round contested release (red2), needs-input (red3), and explicit null
candidate serialization (red4), followed by passing checks. Other public
regressions cover clarification without invented holdings, unchanged prior plan,
matching final candidate, all contested plan operations in the next real
snapshot, invalid fifth output, absent fifth judgment, stale identities and
single-use execution.

Final validation: **246 Swift tests, 10 existing skips, zero failures; 53 Python
tests, zero failures**, run sequentially with the declared Python dependencies.
The bridge-play product builds. Logs are retained under `tests/`.

## One bounded natural correction diagnostic

`run_natural_correction.py` predeclared the real Walker fixture, at most 12
model-delivered decisions, and immediate stop after the first natural
revise-to-approve sequence. Both roles used native gpt-6.1-sol / medium with empty
additional_tools through production Codex transport, Expert and BoardDriver.
No proposal/review was seeded; no board or request was rerun.

The single diagnostic stopped after **four delivered decisions, five player
proposals, five reviewer judgments and ten upstream requests** in **127.297 s**
of driver time. Decision 4 had a natural revise then approve. Its first proposal
discarded H3 and claimed four heart tricks; reviewer established that the
remaining HA4 forces HA on South's second heart honor, invalidating the proposed
unblocking/count. The same player thread changed to C4/keep, retaining the
original three-heart/nine-trick route, and reviewer approved. The board advanced
once using C4; the rejected replacement plan was never installed.

**The native audit also found a serialization gap, preserved rather than hidden:**
Swift's synthesized optional encoding omitted plan.text for keep/withdraw in
candidate JSON, although actual raw player outputs retained the required null.
This affected the recorded keep proposals at decisions 2, 3 and final round of
4. `native-correction/audit.json` explicitly reports this gap and does not call
the capture a fully conforming final-candidate validation. The audit allows only
this identified omitted-null normalization when comparing the historical
candidate records; raw requests, replies and metadata are unchanged.

A subsequent explicit PlanChange encoder preserves text:null. Its public
red/green regression verifies exact candidate JSON in both reviewer requests and
player feedback, for both keep and withdraw. The precise post-capture source
patch and before/after hashes are retained as `post-capture-null-repair.*`.
The captured source snapshot under `native-correction/source/` reproduces the
original hashes. There was **no repeat native diagnostic**. Ticket 52 must
live-verify repaired candidate encoding in its final candidate.

This diagnostic establishes the observed natural correction sequence and its
runtime/feedback provenance, subject to the explicit serialization defect above.
It is not the 22-attempt acceptance matrix or independent delivered-advice quality
grading. Legal execution or reviewer approval establishes no quality pass.

Re-audit the saved capture without model calls:

```
python3 evals/stage1/evidence/issue48/ticket50/audit_natural_correction.py
```
