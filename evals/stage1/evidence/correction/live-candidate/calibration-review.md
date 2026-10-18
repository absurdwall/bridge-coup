# Independent revised-grader calibration review

Reviewed saved `correction/live-candidate/calibration-r1` and `calibration-r2`, the six authored calibration answers, authorized snapshots, evaluator-only reviewed expectations, raw grader findings, quotes/explanations, input packages and runtime records. This review made no model calls, regrades, tests, repository edits or GitHub writes. The independently reviewed labels were assessed against the actual bridge positions rather than accepted from filenames.

Both fresh Sol Medium runs return **A/B pass; C/D/E/F fail, 6/6 each**. Every row contains concrete, exact cited support. No substantive erroneous explanation or unsupported rejection of the reasonable alternative was found.

| Answer | Independent assessment of both grader explanations |
|---|---|
| A | Pass justified. Eight top tricks are SA, HA/HK, DA/DK, CA/CK/CQ. Low club to CQ, back to CA, then CK leaves South on lead with two established clubs on a conditional 3–2 break. Five clubs plus the other five winners give ten. D3 is a lawful North follow. |
| B | Pass justified. CA/CK while North follows low, then a club to CQ, is a physically feasible alternative. North retains H4/H7 to South HA; South's low hearts can subsequently reach HK. The two South long clubs and other winners remain accessible. D8 is lawful. Both explanations properly accept this route rather than demand CQ first. |
| C | Fail justified. South holds SA94, not SJ; the claimed ninth immediate trick and certain contract rely on an invented honor. Quotes identify that exact defect. |
| D | Fail justified. Five missing clubs cannot allow both defenders to follow three rounds, which requires six. The quoted condition is impossible under these authorized holdings. |
| E | Fail justified. North acts after West DQ and holds diamonds; CA belongs to South and is off-suit. The sound broad plan cannot rescue the illegal current action. The second run also correctly identifies disagreement with winning the diamond first. |
| F | Fail justified. Only DQ is observed, with no auction/lead agreements. It cannot establish a 3–2 club split or guarantee ten tricks; the lawful D5 itself is not the failure. |

All 12 rows pass the saved Python citation/shape checks with no evaluator error. Input packages contain rubric v3, actual authorized answers/snapshots and deterministic checks, without the evaluator-only expected-label document or defender holdings. Calibration uses historical v1 authored currentCard records; it does not establish Luna v4 playing-provider compatibility.

Run records show requested `gpt-6.1-sol` / `medium`, Codex CLI 0.160.0, exit 0 twice, no observed tool items, elapsed **26.092 s / 24.178 s**. Resolved service identity/effort remain unobserved. The revised grader schema was accepted by these two real executions. This is bounded calibration evidence, not broad grader reliability, improved playing quality, full-matrix acceptance or merge authorization. Original grades remain preserved. Any later real-answer batch requires its own explanation review.
