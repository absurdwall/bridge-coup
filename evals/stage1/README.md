# Stage 1 App-independent playing core

The six-ticket stage is still in progress. Ticket 37 demonstrates one actual decision/execution path and preserves severe model-quality failures; see [its review](evidence/ticket37/REVIEW.md). No stage acceptance is claimed.

Build and run an initial decision with a new evidence directory:

```sh
swift build --product bridge-play
.build/debug/bridge-play \
  --fixture evals/stage1/fixtures/synthetic-initial.json \
  --output /tmp/bridge-initial-attempt-unique \
  --codex /absolute/path/to/codex \
  --timeout 180
```

The fixture contains environment-only complete holdings. Only declarer/dummy holdings and actual public events enter Expert. Current authentication comes from `$CODEX_HOME/auth.json`, falling back to `~/.codex/auth.json`; the adapter copies it into a temporary isolated runtime, then removes that runtime on disposal. Saved evidence contains no authentication. The playing configuration is fixed to gpt-6-luna / medium and fails visibly when unavailable.

For exact effective-request auditing, start the optional transparent proxy separately:

```sh
python3 Scripts/capture-playing-wire.py \
  --codex /absolute/path/to/codex \
  --output /tmp/bridge-wire-attempt-unique
```

Pass its printed wrapper path as the driver's `--codex` value. Keep the proxy running for that attempt and stop it afterward. The local proxy forwards unchanged Responses payload bytes to the official ChatGPT Codex endpoint, saves the payload and public response metadata, and stores no headers or reasoning stream. It explicitly changes provider routing to observe the request; capture-config.json records that difference. The model/effort remains unchanged. The proxy binds only to loopback. Use unique output directories to preserve each attempt.

`ExpertSession.decide` is the public Expert boundary for future driver and UI use. Domain/Engine have no Codex or UI dependencies. Runtime checks card legality; semantic quality evaluation remains separate, so legal-card execution alone is never a quality pass. Continuous turns, the Python evaluation runner, full-board play and final acceptance remain later tickets.
