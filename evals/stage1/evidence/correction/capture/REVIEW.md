# Capture completion ordering correction

This is one deduplicated infrastructure defect. It does not resolve the failed Stage 1 playing-quality gate, and it does not establish the cause of either historical missing metadata file. Those two historical HTTP statuses remain unknown; historical outputs and grades are unchanged.

## Reproduction and hypotheses

The public capture CLI runs as a real child process and forwards a real local HTTP response. Only outbound HTTP is replaced at the external boundary. The fixture emits `response.created` and `response.completed`, then withholds upstream EOF for 30 seconds. No live player, remote model, credentials or arbitrary correctness sleep is involved. The client requires metadata as soon as it observes completion, then terminates the still-active proxy. A second case splits the terminal event across chunks.

The first run failed in 0.079 seconds: `Client received response.completed before metadata was durable` (`red-terminal.log`). This matches the coordinator's independent 3/3 reproduction of the completion/shutdown boundary.

Ranked hypotheses, recorded before testing repairs:

1. Metadata waits for upstream EOF. Persisting before forwarding terminal bytes should pass even while EOF remains blocked.
2. Terminal event parsing misses split chunks. Splitting the event should still fail after an ordering-only repair if this is a separate defect.
3. An active upstream handler prevents bounded proxy cleanup. Immediate termination after client completion should exceed the existing cleanup deadline if true.

The first hypothesis was confirmed. Both whole and split event tests pass after the ordering repair, and both active-handler processes terminate within one second. The existing runner already terminates the proxy, waits at most five seconds, then kills it; no new graceful-drain protocol or sleep is necessary when completion evidence is published before completion becomes observable.

## Change and evidence

`Scripts/capture-playing-wire.py` now publishes known HTTP status before response headers and publishes updated public response identity/status/usage before forwarding the chunk that exposes them. An atomic rename keeps readers from observing a partially written metadata file. Request payloads and forwarded response bytes remain unchanged; headers and private reasoning are not persisted.

- `python3 -m unittest discover -s evals/stage1/tests -p test_capture.py -v`: two offline regressions pass, including split terminal completion, immediate shutdown with delayed EOF, and preservation after process exit.
- `python3 -m unittest discover -s evals/stage1/tests -v`: 33 tests pass, zero failures (`python-tests.log`).
- The coordinator's original reproduction was rerun against the corrected script with only source/output paths redirected. All three trials preserve the request and response metadata after immediate termination (`reproduction/proxy-shutdown-results.json`).

## Impact and limits

Only capture persistence ordering and its offline tests change. `acceptance.py`, player instructions, output schema, Expert behavior, grader, corpus, model configuration and all original evidence remain unchanged. A new candidate must include the new capture hash. The offline regression proves this loss window is repaired; it neither upgrades prior unknown records nor validates model quality. These tests cover normal and split `response.completed` SSE events followed by delayed EOF, rather than arbitrary upstream failures or power-loss durability. No live model call was made. Correction PR review and explicit user approval remain required before merge or issue closure.
