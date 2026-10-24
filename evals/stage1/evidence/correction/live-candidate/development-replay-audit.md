# Independent first development-attempt evidence audit

Audited existing files only at correction source `1d0fae4e1b3044b31ebf9f47425645c5e545c985`. No repository edits, model calls, GitHub operations or test-suite run. This is a mechanical/provenance audit, not semantic adjudication or stage acceptance.

## Frozen candidate and identity

- All 22 frozen source/material/config hashes match current bytes. Binary SHA-256 remains `943973fed52c50f81def4181258d5dc1c45bfd8b4241514d2ab0cea832df8913`; Codex executable hash also matches. Recorded isolated wrapper probe succeeds at `codex-cli 0.160.0`; every decision records the same runtime version and requested Luna/medium identity.
- Preflight checks these hashes before the attempt. Matching post-run bytes and unchanged source support the same frozen candidate, but no per-request hash snapshots were recorded: this is not continuous filesystem attestation. Hidden service resolution remains outside independently established identity.
- Exactly eight recorded decisions, RPC turn/start requests, completed turns, HTTP request payloads and response metadata files. All eight metadata files record HTTP 200, completed and gpt-6-luna. One board and one playing thread, eight distinct turn IDs and eight distinct DecisionSession IDs. Completion IDs match saved decision identities.
- Original plan variants obey replace/nonblank text or keep/null; all selected cards match public actions and legal sets. No structural failure file, retry, missing metadata or extra request was found. This verifies this run, not general reliability.

## Independent legal replay and counts

Replayed from the original synthetic full deal using separate audit logic for turn, ownership, follow suit, NT winner and trick progression. All 17 cards are unique and legal, with NS/EW tricks 3:1 and one card of the next trick played. Driver steps contain eight model actions, one sole-legal forced action and seven opponent actions; the opening West DQ is a separate one-opponent prefix. Board is incomplete, consistent with the declared eight-decision development bound.

The eight requests preserve frozen instructions and wire v4. Raw evaluation reports two pass/six fail, with all eight mechanical checks passing and no evaluator-contract error. Those are raw grader labels; this audit does not endorse or replace independent semantic review.

## Timing and call accounting

- CLI elapsed: **49.350977 s**; last controlled action: **49.349229 s**. They differ by **0.001748 s** and must not be called exactly equal. Requests total 49.306613 s; recorded environment overhead 0.044364 s accounts for the remainder. Outer proxy/startup wall measure is separately 49.681 s.
- First request: 17.743037 s; seven later requests are individually preserved in trace. Grading occurs separately and is excluded from these playing measures.
- Four actual independent grader executions exist, all requested Sol/medium, exit zero and no observed tool items: calibration-r1 six answers (26.092 s), calibration-r2 six (24.178 s), saved original former-reserve 21 (64.343 s), and new development eight (48.600 s). Total grader elapsed **163.213 s**; 41 graded rows across four calls, distinct from eight playing requests.
- Only development-normal has an attempt directory. Entries, former reserve and Walker are merely predeclared; no further development attempt started. No final matrix was run or completed here.

## Preservation and limits

No modified/deleted tracked file exists under historical eval evidence relative to restoration `0cfa39f`; original ticket42 tracked bytes are unchanged. New artifacts and reviewed overlays are separate. No metadata/reporting discrepancy was found beyond the small total-versus-last-controlled timing distinction above. Pending coverage and semantic failures still require independent review; no issue closure, merge, release or user approval follows.

Machine-readable audit totals are in `/tmp/bridge-stage1-correction/development-replay-audit.json`.
