# Ticket 40: legal complete-board execution, failed model quality

The full-board engineering path is implemented. **The fresh v3 development board fails basic quality. Ticket/stage quality acceptance is not complete.** No reroll, repair, alternate playing model, controlled nonforced substitute or reserved-board playing attempt occurred.

## Source and rules

Integration baseline `0c2a60c`, branch `codex/stage1-ticket40`. Source stayed unchanged from the final Swift/Python checks through the live invocation and saved-source hashes. `source-manifest.json` records hashes after that invocation; it is not a signed pre-invocation freeze. Documentation/evidence were added afterward.

Engine derives the complete legal choices into the immutable Domain snapshot. Expert constrains its single selectedCard field with that exact enum, preserving the existing concise English instructions and plan → publicReason → selectedCard order. This is wire v3; it establishes constrained legal selection, not unconstrained model rule recall. Engine execution still validates actual holdings, turn, follow-suit and freshness. Old v1/v2 failed evidence is unchanged. A legal card with bad prose executes and can fail the independent grader.

Independent literal rule cases cover NT off-suit aces, trump superiority, higher trumps, and an opponent's S9 versus South's permitted S3 undertrump, CA discard or SJ overtrump. Follow-suit and wrong-turn rejection preserve state. A literal NT 13-trick sequence consumes all 52 cards with EW 13; complete public driver tests verify both NT and trump consumption. Initial sole-legal dummy play still gets a model plan; subsequent sole-card actions are mechanical and actual forced events reach later requests. The basic Engine trick-winner function is shared with the limited opponent policy rather than duplicated in it. Pavlicek policy tests use actual current legal states for ducking DK/DQ and covering D9, without fixed controlled play.

Public driver/request boundaries are the user-confirmed test seams. Schema test red and driver trace test red precede the corresponding implementations; rule tests verify already-present behavior. The Pavlicek branch test exposed the incorrect assumption that North must have led the current trick; the corrected policy checks North's actual most recent play. The initial Python-subprocess timeout-red build hit an incompatible compiler/SDK before reaching its assertion; this infrastructure failure is preserved and is not claimed as behavioral red evidence. The final timeout regression executes an external runtime that ignores TERM.

Validation: **221 Swift tests, 10 existing DDS-related skips, zero failures; 17 Python tests pass.** `focused-tests.log`, `full-swift-tests.log`, `python-tests.log` and `tdd/` preserve results. No UI or DDS scope was added.

## Bounded failures and measurement

CLI full mode runs to the 52nd actual event, including trailing opponents after the last controlled decision. Short mode remains decision-bounded. `trace.initialEvents` and its explicit controlled/opponent counts account for the prefix separately from driver steps. `modelRequests` counts attempted Expert requests; actual transport turn/start count is audited separately. Startup failure can make these counts differ.

Production request deadlines include runtime/version startup and are capped by remaining run budget. TERM is followed by SIGKILL after 0.2 seconds if needed; teardown adds a small scheduling/cleanup margin, so this is not a zero-tolerance real-time guarantee. A TERM-ignoring external runtime with a 1-second request limit and a 0.05-second run budget fails in under 0.6 seconds without executing a card. The late-result test preserves an unexecuted original decision. Failed runs preserve authorized input, actual events, timings and failures and cannot retry. A full run has a finite 1800-second budget; 180 seconds is the per-request bound, not a product target.

Trace reports initial/subsequent/failed request latency, exposure/driver-start to last controlled action including forced actions, full driver duration, real overhead and zero retries. Initial requests include runtime startup. The three-minute experience goal remains separate.

## Exactly one fresh v3 live board

`run-configuration.json`, `development-v3/`, `development-v3-wire/`, `wire-audit-summary.json` and `independent-replay.json` preserve actual configuration, decisions, event history, payloads and checks.

- Real requested Luna Medium; Codex CLI 0.160.0. Runtime acknowledgement records gpt-6-luna; it is not proof of hidden service internals.
- One continuing thread, 20 distinct turns and DecisionSessions. Twenty model requests/executed nonforced controlled actions, six later forced actions, 26 controlled actions. Twenty-five driver opponent actions plus one opening-prefix opponent action.
- All 52 unique cards consumed, 13 tricks, NS 7 / EW 6. Independent Python corpus.replay of initialEvents + driver steps confirms empty hands, legal progression and the same result.
- Initial request 10.377 seconds; subsequent latencies preserved individually. Last controlled action/full driver 90.507 seconds; real overhead 0.282 seconds; no retries or runtime failures. These are one development-board measurements, not the final four-board acceptance matrix.
- Twenty actual payloads match the exact complete Engine legal enum, plan/reason/action order, English user inputs/public outputs, initial position and retained real prior user/public assistant history.

Effective request audit has the same known limitation as v2: Codex still injects catalog-selected built-ins and collaboration role/mode despite the disabled-feature configuration. No Engine/Knowledge tool, hidden defender holding, grader/rubric or case material enters the authorized play inputs; no tool invocation was observed. Whole forwarded runtime history also includes opaque encrypted reasoning items with empty summaries; they were not decrypted or treated as readable reasoning evidence. We do not claim a fully empty effective tool list or public-only whole runtime input. The transparent wire proxy's provider-routing difference is recorded in its capture config; payload bytes were forwarded unchanged.

## Independent quality review: fail

`development-v3-grade/` grades all 20 saved decisions once with requested Sol Medium and frozen full-development case/rubric. It uses no playing call, exits zero, invokes no tools, has no evaluator error and takes 90.322 seconds. All 20 mechanical decisions pass; **14 quality pass and six quality fail**. The grader cites actual public text/retained plans in decisions 1, 2, 6, 7, 16 and 18.

The reviewed findings match the saved visible state:

- Decisions 1/2 propose/retain a nonexistent diamond finesse against West's DQ lead opposite South DA/DK. Playing low and winning outright does not constitute that finesse.
- Decision 6 plays CQ beneath South CK while C7 remains available, consuming a separate winner and falsely suggesting the remaining low club is established.
- Decision 7 uses declarer's own dummy D5 as evidence that West's queen may be singleton; that controlled choice supplies no such information.
- Decision 16, with six tricks won, sends H3 to dummy HK before cashing established South C64. Dummy H7 outranks South H6, so the claimed retained club control has no return entry. Cashing both clubs before HK secures nine tricks.
- Decision 18 proposes establishing S8/S6 with outstanding defender SQ/SJ/ST/S7 and no subsequent dummy entry; the actual remaining lengths/honors do not support that route.

The winner-preservation and entry failures alone establish the quality no-go; finishing legally or the score cannot erase them. Every original failed answer remains saved. No policy/prompt/rubric change or second live sample was attempted after this result. The remaining final matrix belongs to ticket 42 and is not claimed here.
