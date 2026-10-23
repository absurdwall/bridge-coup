# Ticket 52 implementation checkpoint

This is the evaluator/runner code checkpoint before independent review and any
frozen quality candidate. No new player, reviewer or grader call was made for
this ticket. The ticket-49 native smoke and ticket-50 natural correction remain
separate diagnostics. **Zero of the maximum three frozen quality cycles spent.**

The existing public saved-decision / acceptance-runner seams now distinguish the
exact final player request from its canonical complete snapshot. Deterministic
checks independently derive each plan operation from the prior active plan;
validate all candidate/reviewer/feedback/round associations; bind actual player
and reviewer RPC outputs to their true identities and schemas; require exact
approval or unresolved legal round-five contested authorization; and check
cross-decision plan/thread continuity. Case binding independently verifies public
completed winners and current winning play against actual event replay.

The separate acceptance grader receives only delivered advice as quality targets.
It retains actual feedback request provenance with an explicit authority warning:
reviewer assertions and rejected drafts are non-authoritative, canonical public
facts govern, and approval/contested disposition is no quality label. Unexecuted
failed authorized candidates remain failure evidence, not extra graded advice.
Historical authored/saved calibration records without execution retain their
original diagnostic path; none become current accepted plays.

Freeze includes both instruction resources, both schemas/configurations, runtime
and capture source, fixed corpus/rubric and all promoted regression assets.
Preflight verifies the source inventory and each source hash against its pinned
Git commit, along with binary/native-runtime/catalog hashes. The original
six-short x3 and two-full x2 schedule and serious-error/coverage rules remain
unchanged. The native runner checks both role catalogs and the saved HTTP
requests against role instructions, schema templates, identities and empty tools.

All role attempts, including failed technical attempts, are reported from the
board journal. Late observations supplement missing usage without being counted
as additional attempts. Native per-turn usage and upstream per-HTTP usage are
separate cost observations; missing remains unknown. Decision, role and complete
board timing, retries, feedback, clarification, approved/contested counts, human
waiting and grader cost are preserved. Reports remain conservative until
independent cited-quality/coverage adjudication resolves every required gate.

The eleven fixed historical assets under `regressions/reviewed-play` were copied
byte for byte and SHA256 checked. Their public-only late-club branch proof was
independently replayed with the existing corpus reducer: C5 yields eleven tricks
against both East choices; CT allows ten. Current adjudication explicitly
supersedes the historical second-round-spade “overblocking” label. These assets
are supporting offline regressions, never extra matrix attempts or live labels.

Tests use vertical red/green slices for request binding, grader authority, freeze
inventory, role cost accounting, wire identity/tools, report semantics, complete
board journal/plan continuity, and independently derived public winners. Additional
regressions reject altered final candidates/requests/plans, sixth semantic rounds,
invalid contested release, and attempts to treat runtime authorization as quality.
Synthetic adapters of saved captures are explicitly labeled; old raw captures
and their known omitted-null defect are unchanged.

Offline validation: 254 Swift tests (10 existing skips), 66 Python tests, zero failures, run sequentially; public proof and diff checks pass. Independent source/spec review precedes freeze. The final
acceptance report, independent adjudication overlay and per-issue obligation
assessment remain pending until the authorized frozen matrix actually runs.
