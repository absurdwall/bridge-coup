# Issue 46 completion evidence

This candidate applies the approved complete-snapshot protocol to the Stage 1 core. Historical failures remain unchanged. No stage acceptance is claimed by these preparatory results.

The playing model is gpt-6-luna / medium. Independent grading uses gpt-6.1-sol / medium; independent code review uses Luna / max. Model identities describe requested and observable identities only. PR #45 and this work require explicit user approval before merge.

## Fresh grader calibration

Two independent grades of the same six reviewed authored answers use the unchanged stage1-basic-v4 rubric and schema. Both runs classify A/B pass and C–F fail, with exact citations and no evaluator error. These are calibration answers, not player-performance samples. The original raw grades, runtime commands, inputs, public events and local adjudications are preserved in calibration-r1 and calibration-r2. The first temporary directory carried an obsolete v3 label; the saved rubric and result in both runs are v4.

Offline baseline before completing the production no-tools path: 231 Swift tests (10 preexisting skips), 48 Python tests, zero failures. This establishes the starting engineering baseline, not bridge quality.

## Integrated engineering checks

After snapshot, runtime and evaluator integration:233 Swift tests (10 preexisting skips) and52 Python tests pass. Public-seam regressions cover preserved caller context, MP default objective, empty runtime tool catalog, frozen catalog mutation, same-turn request/output evidence and default doubling. Red/green logs are retained in tdd/.

## Development playing evidence

Development v1 completed8 legal Medium decisions in one thread; original case-dispatch failure remains preserved. Saved-output Sol grading after the contract-default fix is in development-v1/development-continuation/grade-after-contract-fix/. It reports6 pass and2 fail for an alleged missing ninth-trick route in a replacement plan; independent adjudication is pending. No playing answer was replaced. A separate full-board development run uses the same playing implementation, without instructions changes. No finite acceptance claim is made.

## Candidate v2

The general fact-checking refinement adds39 words to decision step2; exact diff and actual-wire diagnosis are retained. Final integrated offline checks:233 Swift tests (10 existing skips),53 Python tests, zero failures. Both independent Luna Max review axes find no new concrete implementation defect.

The complete development-v2 board takes117.316 seconds and completes legally, but Sol Medium reports19 passes and1 failure: an unnecessary HA overtake of partner HK, with a reason focused on lower opponent H8. The next correction will make the already-computed public current winner explicit in the complete JSON snapshot. The final22-attempt matrix is still not run; no acceptance claim.
