# Expert correction: contract enforcement and current-action context

This is a bounded implementation correction, **not evidence that Stage 1 playing quality passes**. Original outputs, grades, reviewed overlays and 21 failed / one pending / zero accepted attempts remain unchanged. No playing or grading model was called here. Issues 36–42 remain open; review does not authorize merge or stage acceptance. Explicit user approval is required.

## Diagnosis and change

[Read-only diagnosis](DIAGNOSIS.md) ties each proposed change to the exact original effective request, visible position, public answer and plan. The four historical keep-with-text outputs were valid under the actual transmitted strict schema but invalid at the public Expert boundary. That mismatch is a confirmed program contract defect. Text-before-update key ordering may contribute to generation; it is not a proven cause.

Wire `stage1-plan-variants-v4` binds each plan operation to its payload through nested `anyOf`: replace requires a nonblank string (`pattern: \\S` in serialized JSON); keep and withdraw require explicit null. The first request permits only replace. Current-card authority, exact-key decoding, trimmed-string validation, invalid-output failure, no retry/repair and plan provenance remain intact. A defensive replay of all four original bad replies still yields `invalidOutput / ambiguousPlan` with the exact raw answer and an ended session. No historical answer is reinterpreted as valid.

The stable instruction now gives one positive bridge task: form a concrete route from available winners, establishment, timing and entries, then derive the current explanation/card from that route and actual current position. Initial authorized holdings use explicit card tokens, e.g. `diamonds: DA DK`, once. A continuing input primarily supplies actual new events and concise current-turn facts: acting seat/role, lead versus ordinal in the trick, and legal current choices. It repeats neither both remaining hands, old plans/reasons nor a full transcript. The legal-choice line is the same Engine-derived set already provided in the output enum; at a new lead it necessarily equals the remaining acting hand. This is a deliberate current-action salience tradeoff under #36, not a claim that the old input omitted true facts. No hidden holding, strategic ranking, Engine analysis, Knowledge or second reasoner is added.

## Public-boundary TDD evidence

The confirmed seams are `ExpertSession.decide` and the actual serialized app-server `turn/start` request used by `CodexPlayingTransport`. An external recorded app-server process uses real Python `jsonschema` validation on the received schema, not a private Swift helper or a hand-written validator. It validates all plan variants and all four exact historical invalid plan payloads, then supplies recorded initial → keep → replace → withdraw outputs for public lifecycle checks. This is an offline protocol fixture, not an additional runtime player or semantic reviewer.

Configure a Python interpreter with the test dependency:

```sh
python3 -m pip install -r evals/stage1/requirements-test.txt
export BRIDGE_TEST_PYTHON="$(command -v python3)"
```

`BRIDGE_TEST_PYTHON` selects the interpreter for the schema-checking external process; fallback is `python3`, with a clear dependency error when `jsonschema` is unavailable. The recorded run used Python 3.11.5 / jsonschema 4.26.0. Tests contain no developer-specific Python path.

Actual test invocations, with that environment set:

```sh
swift test --filter PlanContractTests.testSerializedAppServerSchemaExcludesAmbiguousPlansAndKeepsLifecycle
swift test --filter PlanContractTests.testPublicContextIdentifiesLeadAndThirdHandWithoutRepeatingHoldings
swift test --filter BridgePlayingTests
swift test
```

- [Schema red](schema-red.log): original transmitted schema accepts keep + new text, external boundary reports `plan contract mismatch`, public Expert fails. [Schema green](schema-green.log): joint variants plus initial restriction pass.
- [Whitespace red](whitespace-red.log): provisional minLength admitted a blank replacement the public decoder rejects. [Whitespace green](whitespace-green.log): supported nonwhitespace pattern excludes it. Final source does not use minLength.
- [Context red](context-red.log): historical South-lead and North-third-hand positions lack affirmative current-action/legal-choice text and explicit initial tokens. [Context green](context-green.log): the same public positions expose correct concise facts, without remaining holdings/old-plan copies.
- [Focused suite](playing-tests.log): **25 tests, zero failures**, including exact failed-answer replay with actual prior snapshots/events and no retry. This adds three public-boundary tests to the prior 22.
- [Full Swift suite](swift-all.log): **227 tests, 10 existing DDS-related skips, zero failures**. No DDS/UI integration claim follows from skipped checks.

## Impact and limits

Only Expert request construction/schema/version and necessary tests/dependency documentation changed. Domain, Engine, driver/opponents, Codex transport, grading/rubric/corpus and all historical evidence are unchanged in this correction. Original severe factual/physical/action–reason failures remain failures; this work does not repair their raw answers. Existing historical readers need v4 recognition without losing v1–v3 support, implemented separately by the eval correction.

Offline validation demonstrates structural schema semantics and public request/lifecycle behavior. It does **not** establish that the live Codex/provider accepts this nested schema or that Luna Medium follows the clearer factual context. Nested anyOf and string pattern support were checked against official Structured Outputs documentation, but the actual provider still needs bounded observation. Root must freeze the combined candidate, review impact/reachable cases, run affected cases once and preserve/stop on failures. Only a candidate surviving those checks should enter the specified once-only 18-short/four-full matrix; no rerolls or merge are authorized by these tests.
