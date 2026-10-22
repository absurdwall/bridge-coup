# Issue 46 completion evidence

This candidate applies the approved complete-snapshot protocol to the Stage 1 core. Historical failures remain unchanged. No stage acceptance is claimed by these preparatory results.

The playing model is gpt-6-luna / medium. Independent grading uses gpt-6.1-sol / medium; independent code review uses Luna / max. Model identities describe requested and observable identities only. PR #45 and this work require explicit user approval before merge.

## Fresh grader calibration

Two independent grades of the same six reviewed authored answers use the unchanged stage1-basic-v4 rubric and schema. Both runs classify A/B pass and C–F fail, with exact citations and no evaluator error. These are calibration answers, not player-performance samples. The original raw grades, runtime commands, inputs, public events and local adjudications are preserved in calibration-r1 and calibration-r2. The first temporary directory carried an obsolete v3 label; the saved rubric and result in both runs are v4.

Offline baseline before completing the production no-tools path: 231 Swift tests (10 preexisting skips), 48 Python tests, zero failures. This establishes the starting engineering baseline, not bridge quality.
