# Bound declarer review while preserving execution provenance

On 2026-10-23, we confirmed independent review of each model-controlled
stage-one declarer proposal. Revisions stay in the board's continuing player
conversation, with the actual position and prior active plan unchanged while
review remains pending. An approval authorizes the exact reviewed proposal.

After at most five valid semantic review rounds, execution may instead release
the latest validated legal proposal as contested play, applying its matching
plan operation. Preserve the real reviewer verdict and distinguish it from
execution authorization. We chose this bounded override so reviewer disagreement
does not indefinitely prevent play; independent acceptance grading still judges
the delivered advice and cards by the original quality standard.

Technical recovery is separate: allow up to three reviewer retries after the
initial failed request, without consuming semantic rounds. Exhausted technical
recovery stops the run rather than triggering contested execution. Runtime review
and independent acceptance grading retain different responsibilities. This records
agreed design, not completed integration.
