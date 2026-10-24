# Effective wire and capture audit — development-normal

Read-only audit of `evals/stage1/evidence/correction/live-candidate/development/development-normal`, frozen candidate `1d0fae4e1b3044b31ebf9f47425645c5e545c985`. Inspected all eight saved HTTP payload bytes, public metadata, RPC log, decision records and the real trace; did not rerun tests, player, grader or GitHub operations. No semantic-quality or acceptance judgment is made here.

## Serialized contract and visible context

All eight HTTP `text.format.schema` objects exactly equal their respective actual app-server `turn/start.outputSchema`. Request 0 permits only the replace branch; requests 1–7 carry replace/keep/withdraw joint variants, explicit null for keep/withdraw, `pattern: "\\S"` for replacement text, exact required keys and additional-properties rejection. Every selectedCard enum exactly equals that decision's saved Engine legalCards. The real service returned completed answers for all eight, establishing compatibility for these observed requests, not general schema reliability.

The initial latest-user message contains exactly the authorized South/North holdings (13 cards each), public West DQ, contract/scoring/objective and background. There is no East/West complete holding, expected answer, rubric or future event in the visible bridge input. Initial holding tokens match the public snapshot. For every request, the latest user message equals `DecisionRecord.input` and the RPC input; all earlier user messages and public assistant answers match prior saved inputs/raw outputs in order. Subsequent latest inputs give current acting role/ordinal or lead, complete legal choices, actual event delta, current trick and trick totals. Delta and trick strings match snapshot events exactly, including the mechanically forced South DA at sequence 11. They do not repeat remaining-hand blocks or plans in the new user input; prior plans/answers remain in same-thread history. The eight schemas and latest inputs therefore reached the observable HTTP boundary rather than merely existing as source constants.

## Identity and runtime limits

There is one thread, eight unique completed turn IDs and eight unique DecisionSessions. All actual HTTP model fields and all RPC requested models are `gpt-6-luna`; requested reasoning effort is medium throughout. Thread acknowledgement, decision identities and all HTTP response metadata identify Luna; runtime is `codex-cli 0.160.0`. This proves requested/observable identity only, not hidden service resolution.

The actual input still includes an inherited additional-tools catalog: functions exec/wait/input tools and collaboration tools, plus multi-agent developer boilerplate. It is not an empty tool surface. No Engine/Knowledge tool is present. Across all payloads, non-message items are only additional_tools and encrypted reasoning history; no function/tool calls or outputs appear. RPC contains ordinary initialization/catalog/thread/turn traffic and eight completions, without tool/approval roundtrips. Encrypted reasoning is opaque and was not decrypted; no claim is made that the whole history is public or that hidden internal behavior is independently observable.

## Capture and preservation

All eight `response-metadata-N.json` files exist with HTTP 200, unique response IDs, model Luna, status completed and usage. None is missing; proxy stderr is empty. The frozen/current capture script SHA-256 is `3ae9c13db5dd5f871af78239d82e7dbe4b4c36524c79a424da1189a425a0ebd0`. Its ordering persists parsed terminal metadata before forwarding terminal bytes. All metadata files precede the runner's post-proxy-wait `playing-outcome.json` marker; that marker records successful CLI exit. Combined with the frozen synchronous ordering and the earlier offline regression, this supports completion evidence being available before immediate proxy shutdown. There is no separate timestamped proxy-signal log, so exact signal timing is not reconstructed from filesystem times alone.

The two historical missing files remain absent: `ticket42/matrix/short-2-r1/wire/response-metadata-7.json` and `full-development-r2/wire/response-metadata-19.json`. Their statuses stay unknown; this new run and offline race reproduction do not establish their historical cause.

Payload SHA-256 identifiers (request index → first 12 hex characters): 0→89af91303727, 1→de84904aeabb, 2→5beb67e9961e, 3→f1a10c3d3545, 4→65d6c81f6ddb, 5→b0a87f776013, 6→ab987ad98965, 7→cc85dd9147a0. Full originals remain in the audited wire directory.

No wire/capture defect found in this attempt. Eight structurally completed requests and complete capture do not establish coherent plans/reasons, specialty coverage, Stage 1 acceptance or merge authorization.
