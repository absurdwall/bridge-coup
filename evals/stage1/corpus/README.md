# Stage 1 finite cases

`manifest.json` is the frozen `stage1-finite-v1` candidate. The shared semantic rubric remains the independently calibrated `stage1-basic-v2`; case facts supplement it through the public Eval entry. Six short scenarios require three independent runs each; two complete boards require two runs each. Scenario counts and model request counts are separate. #41 prepares and verifies material; real continuous execution and final acceptance belong to #39, #40 and #42.

```sh
python3 evals/stage1/evaluate.py validate-corpus --output /tmp/stage1-material-check
python3 evals/stage1/evaluate.py grade --case short-3 --decision PATH_TO_DECISION --output NEW_OUTPUT_DIRECTORY
```

Use repeated `--decision` arguments for a continuous run's actual decisions. Attach the matching case ID. The entry checks the full environment against actual history and visible remaining hands before attaching case facts. Grader packages contain only authorized decision records and an allowlist of properties, alternatives, severe errors and trigger conditions. They contain neither complete environment hands nor expected labels. The full fixture is solely an environment input; do not append it, the manifest, source review, or this document to player input.

Cases 1–4 share the independently checked synthetic board; their observations differ. Suggested driver bounds are 1, 8, 12 and 16 requests. Case 5 starts after the completed first spade trick through `initialEvents`; case 6 starts after SK. Their suggested bounds are 12 requests each. Use the declared legal opponent policy: `conserve-high` normally, including continuation of the opening suit; case 5 uses `pavlicek-entry`. That limited profile ducks low under a first-round high North diamond when East still holds DA and DJ, but covers North D9 with DJ. It reacts to actual legal play; it does not control declarer or dummy. The two branches need driver-level tests before specialty coverage can be claimed. These counts are finite observation bounds, not instructions for controlled plays. Any initial event prefix is visible history, not an authored previous plan. All subsequent previous plans and plays must come from the same live run.

For each run, review the declared coverage trigger against the actual event trace and record `covered`, `uncovered`, or `pending_review`, with event sequences and explanation. A good answer with no trigger may still be a quality pass, but cannot count as specialized coverage. Do not stretch a short run or substitute controlled cards until a desired trigger occurs. Normal continuations can keep a plan; new information can justify keeping or replacing it. Neither case prescribes a plan update token in isolation. No fixed demonstration is an oracle for model sequence.

`boards/reserved-acceptance.json` differs from every short/development board. Evaluators may inspect it and verify legality; its first playing attempt belongs to #42 acceptance. Do not use it for targeted prompt development. If a failure leads to targeted repair, subsequent use is regression evidence. No reserved-board player call was made by #41.

`synthetic-demonstration.json` preserves the original legal authored 13-trick example, 10:3. It is neither playing-model performance nor a unique reasonable line. The independent material checker verifies ownership, chronological turns, follow-suit, trick winners, full consumption, counts and distinct reserved holdings. This checker is evaluator material validation; the Swift Domain/Engine remains the playing rules authority.

`frozen-sha256.json` binds exact manifests, board inputs, demonstration and shared rubric bytes. On a material correction, record the error and affected evidence in `revision-log.md`, revise the case/corpus version, independently review and regenerate these hashes. A changed hash is a material issue, not a playing defect. Changing corpus or rubric invalidates only affected evidence after explicit assessment; do not silently combine candidates.

The calibration answers A–F are authored, independently reviewed examples. #38 already graded them twice under the shared rubric. #41 additionally grades the same six once with the synthetic case facts attached, retaining raw grader evidence. Agreement is bounded calibration support, not source-case strategy certification, human review, a live playing run or broad grader reliability.
