# Rule-derived current winning play candidate

Pre-call hypothesis: even with explicit rank rules, notation candidate3337f37 decision6 incorrectly says CQ may win while partner CK is already in the trick. Adding the current highest public play as an Engine-derived fact should reduce this specific winner confusion. This is not a quality pass or a claim of general causation.

Only playing change from3337f37: Domain snapshot optional currentWinningPlay, populated from existing Engine winningPlay(currentTrick), and one concise Expert line 'Current winning play so far: Seat Card.' It is provisional, public and purely a basic rule result. No new model-facing strategic computation, candidate ranking, hidden information, Engine tools or full-hand repetition. Model/effort/instructions/schema/opponents unchanged. Historical snapshots decode the missing optional field as nil.

Public Expert regression independently expects WestDQ at opening and partner SouthCA later, without repeating holdings: proper RED has two missing-fact assertions and no unexpected failures; GREEN26Swift tests. The initial test fixture's unavailable West card was corrected before valid RED; setup log retained separately. Python43 tests pass. New source built before freezing.

Evaluator v4 corrected material G/H/I distinctions have independent coordinator review. Corrected eight-case calibration matches8/8 twice (round3/round4); original two batches with internally inconsistent authored I are separately retained/invalidated. No labels are fed into play.

First affected live attempt: eight normal-continuation decisions via the production public Expert/driver on the frozen candidate, sequential one attempt, no retries. If satisfactory, validate entries/hold-up/used-reserve regression before final22; any confirmed failure drives a changed, versioned candidate rather than rerolling this one. Keep every attempt. PR45 remains draft/unmerged.
