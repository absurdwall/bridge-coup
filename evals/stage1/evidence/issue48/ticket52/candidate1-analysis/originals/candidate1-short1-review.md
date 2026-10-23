# Independent delivered-quality overlay — candidate 1, short-1 x3

Read-only adjudication, 2026-10-23. Candidate artifacts are at:
`/Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup/evals/stage1/evidence/issue48/ticket52/candidate1/`.

**Disposition: r1 FAIL; r2 PASS; r3 PASS.** All three raw graders said pass. The
r1 override identifies a specific false conditional feasibility claim, not a
requirement to protect against 5–0, use optimal play, or reproduce a reference
line. The raw grader and runtime review records remain unchanged. No feedback
was delivered to live roles; no model call, rerequest, source edit, or change to
candidate artifacts occurred.

## Shared authorized facts and rubric

Each decision occurs after only West DQ, North to act, South controlling both
hands. North: S862/HK74/D8653/CQ72; South: SA94/HA63/DAK/CAK864. Defenders' remaining
holdings are unknown. D3 is legal in every attempt; eight top tricks and five
outside-club winners are correct. None of this establishes a hidden club split.

Read each actual `play/decision.json`, `grade/input.json` (including full rubric)
and `grade/evaluation.json`/`grader-output.json`. The rubric accepts sound
alternative routes and nonoptimal strategy, but fails material false facts,
incoherent conditions and explicit impossible resource/route claims. It states:
“a different feasible route does not validate an impossible route actually
stated.” This adjudication concerns final delivered active advice, not rejected
drafts or reviewer-approval labels.

## short-1-r1 — FAIL: claimed 5–0 safety is not supplied by its stated play

Actual delivered plan excerpts:

> If West shows out, lead a low club from dummy, covering an honor with an ace or king but otherwise playing the eight; retain the heart king as an entry to repeat this play if needed.

> This protects against either 5–0 club break.

The plan first directs low club to dummy's CQ before either CA/CK and ultimately
promises four club tricks. Against East CJT953 and West void, East can follow C3
to CQ and then play **C9** on dummy's C2. South's stated otherwise-C8 loses. Nine
is not an honour; the official definition lists ace, king, queen, jack and ten.
See [WBF Laws definitions](https://www.worldbridge.org/wp-content/uploads/2017/03/2017LawsofDuplicateBridge-paginated.pdf)
(terminology verification supplied by the coordinator during this review).

After that C9 trick, South has CAK6, North C7, East CJT5. Re-entering North with
HK, North C7–East CT–South CA follows the stipulated cover-an-honour play. Then
CK takes East C5 and South C6 loses to East CJ. Declarer gets CQ/CA/CK: **three
club tricks**, not the promised four. The single low spot C9 was sufficient to
expose the explicit defect. Treating every card above C8 as an “honor” would
rewrite the actual stated decision rule.

A concrete legal counterfactual is preserved in
`/tmp/bridge-coup-issue48-context/candidate1-short1-counterexample.json`, with
reproduction script
`/tmp/bridge-coup-issue48-context/check_candidate1_short1_counterexample.py`.
It uses the existing `corpus.replay` reducer to verify 32 legal events through
eight completed tricks, all clubs consumed, exactly three declarer club tricks.
The explicit full deal is synthesized solely from the authorized hands plus a
possible unseen layout; **the actual fixture's hidden split was not read**.
It is a counterfactual diagnostic, never an actual played branch or strategic
tool supplied to live roles.

The relevant club plays in order are:

| Round | Public play order | Winner |
|---|---|---|
| 1 | South C4, West S7, North CQ, East C3 | North CQ |
| 2 | North C2, East C9, South C8, West ST | East C9 |
| 3, after actual possible heart recovery | North C7, East CT, South CA, West SJ | South CA |
| 4 | South CK, West SQ, North S2, East C5 | South CK |
| 5 | South C6, West SK, North S6, East CJ | East CJ |

For comparison, the proof also verifies a legal altered branch that covers
East C9 with CA, uses HK to lead C7 through East CT to CK, concedes C8 to CJ,
and scores the established C6 over C5: CQ/CA/CK/C6 give **four clubs**. This
requires covering the nine despite its not being an honour. It supports a
specific correction to the stated condition; it does not retroactively repair
the delivered “otherwise playing the eight” advice or impose a mandatory safety
strategy on other initial plans. The comparison is another counterfactual only.

The raw grader correctly supports D3/counting but explicitly claims the
conditional 5–0 continuations are feasible, saying North's clubs/HK entry
support repeated leads through East. That misses the C9-over-C8 resource loss.
Thus there is both a delivered-product conditional feasibility defect and a
semantic false-pass in grading; the grader's cited facts/other findings are not
erased. Current runtime disposition is `reviewApproved`, which proves neither
this guarantee nor quality. No claim is made that the actual short attempt
played these club rounds or went down; only D3 was actually executed.

## short-1-r2 — PASS, with bounded scope

Actual plan: “Start clubs with the ace and, if both defenders follow, cash the
king and lead a club to dummy's queen.” It names five outside winners,
3–2 producing ten overall and a 4–1 concession before cashing the established
fifth club. After CA/CK/CQ, South has two clubs and the long defender one; a
South entry, concession and recovery produce four club tricks. DA/DK and both
major controls support the stated recovery while the plan directs preserving
entries. The chosen D3/low-diamond route is legal and consistent.

The plan explicitly says “If the first club reveals 5–0, reassess the directional
club play before continuing rather than automatically cashing the king; nine
tricks are then not assured.” There is no false blanket 5–0 guarantee to import
from r1. The full grader findings on counting, legal action and conditional
3–2/4–1 feasibility are supported. No serious defect found at this initial
position; this is one short initial-plan judgment, not continuous-quality proof.

## short-1-r3 — PASS, with bounded scope

Actual plan: “Cash CA, playing dummy's C2, then lead a low club to CQ, retaining
CK and C8 in South.” At that point South can retain CK86 opposite North C7.
On 4–1, the stated low C7/duck in South concedes to the long hand; CK subsequently
removes its last club and establishes the remaining South club. Either long
defender is compatible with that sequence. On 3–2, C7 to CK leaves two established
South clubs. The remaining diamond control and major controls give the obvious
recovery/crossing entries without needing a new unique prescribed sequence.

The raw grader's concrete remaining-holding/entry explanation agrees with this
account. The plan expressly reopens 5–0 rather than guaranteeing four clubs.
D3, winner accounting and plan/reason fit. No serious defect found; again this
does not prove later execution or full-board quality.

## Artifact identity / preservation

SHA256 of final delivered `play/decision.json`:

- r1 `02a51d79d04f86d88535e070f2a1eedcde4b98b47d410659f09123b3902ebeea`
- r2 `13a3dec7cd752f574ea033ceadc82c8694a5f4c121dd8968e9c80e7f9017c9f7`
- r3 `f30e332a01b89cc4f10a31ad589251564e4e95e8830013a082a20839828a3244`

SHA256 of unchanged `grade/evaluation.json`:

- r1 `9da7009fa6d636aa5acf7c8318ac441e6a054b09bacf8d222da6803d5c454912`
- r2 `4736c84e581a8ed9c08d5e0aa4a82338c25b45571321a67355b6211d904f8681`
- r3 `e87b1ac2b5cdf3d8a7a2219315c583e2f9e68a77ca452f9fc8cebd76aab643fc`

This overlay addresses these three delivered initial decisions only. It neither
replaces raw grades nor modifies the frozen matrix, its remaining runs or quality
standard. No acceptance/closure/merge authorization is implied.
