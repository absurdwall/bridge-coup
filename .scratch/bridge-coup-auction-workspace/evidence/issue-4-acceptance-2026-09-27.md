# Issue #4 acceptance — 2026-09-27

Implementation tickets #5–#11 were integrated at source revision `c565aabe4842a1e30aab53c5b269cdeb839b622a` (`feat: center compact auction table and editor`). This is the acceptance record for the final integrated Bridge Coup auction-workspace path. Later Spec review found and fixed incomplete-transcript seat inference; a retry-order review then found and fixed lost manual-edit tracking through the application model. Both follow-ups are documented below.

## Spec-review follow-up

The partial-transcript review fix was tested on ticket branch parent `08b4b8c77334b26760252b0218a4fb68f535d68b` plus the follow-up source diff. It adds a backward-compatible `isPartial` state to manual auctions and screenshot candidates. Old archives/candidates default to complete sequence behavior; a partial candidate keeps visible order and only per-entry seats that were explicitly provided. Complete records retain their existing sequential seat projection.

- Reran full `swift test`: **106 tests, 0 failures, 3 DDS-helper-dependent skips**.
- Built a separate QA package from the follow-up diff: `Bridge Coup.app`, version `0.4.0` (build `11.1`), bundle `app.absurdwall.bridge-coup.issue11-review-qa`. It used only `/tmp/bridge-coup-issue-11-review-qa-20260927/reviews` for review data. The package was ad-hoc signed after its QA-only plist changes; `codesign --verify --deep --strict --verbose=2` passed. It reused the pinned DDS 3.0.0 helper from ticket #10.
- Launched that exact QA bundle by app path. In the expanded editor, set the full-auction starting seat to West, marked a manual record as partial, then added `1♣` and `Pass`. The UI showed the partial-excerpt warning and “记录项 1 位置 / 记录项 2 位置,” both “未知位置”; it did not assign West/North from the starting seat or item index and did not insert omitted calls. No save or live request was made. Core and Mac tests separately verify sparse rows when all partial seats are explicit.
- The isolated package and temporary review store were removed after the check; the standard app and store were not used.

Remaining scope is unchanged: live service evidence below is synthetic-only, and this manual follow-up did not force a runtime late-response race or evaluate teaching quality on a real game.

## Application-model retry-order follow-up

On top of `b565d41c469f2c9d70d1242344d0b3b64cefbbf8`, `BridgeTeacherApplicationModel.updateReviewDraft` now sends changed drafts through its shared `ScreenshotReviewWorkflow` before the workflow updates the shared `DeclarerPlanWorkflow`. This lets recognition review record manual edits before the draft changes. A focused app-model regression first failed against the previous order: after an initial recognition failure, retry returned a recognized opening lead and repopulated the lead the user had cleared through `updateReviewDraft`. It passes with the corrected order and also verifies that the edit is retained in the screenshot-review archive. The test uses an injected deterministic recognition stub and no live service call.

- Focused `swift test --filter ScreenshotRecognitionRetryTests`: **1 test, 0 failures** after the fix; before the fix it failed because `♠2` replaced the user-cleared value and `.openingLead` was missing from archived manual edits.
- Full `swift test`: **107 tests, 0 failures, 3 DDS-helper-dependent skips**.
- `git diff --check`: passed.
- No new packaged/manual GUI run or live service request was made for this code-order correction; the packaged and synthetic-only service evidence above remains the acceptance evidence for those paths.

## Automated verification

`swift test` completed on the integration revision: **99 tests, 0 failures, 3 DDS-helper-dependent tests skipped**. The test worktree did not have its DDS helper built for those integration tests. The packaged GUI below used the pinned DDS 3.0.0 helper copied from the already-integrated ticket #10 build; this does not change the skipped-test count.

Relevant coverage includes:

- All four starting seats and unknown-seat handling; omitted auction/vulnerability remain unknown; blank holdings differ from confirmed voids.
- Screenshot candidate review, empty candidate records, explicit confirmed-no-auction archive round-trip, legacy archive defaults, repeated-call IDs with independent notes, and late screenshot response protection.
- Late declarer-plan response protection after auction/vulnerability corrections; long auction seat-column projection and unassigned partial auctions.
- Meaning notes as conditional user context, opening-lead normalization, and DDS result invalidation after a correction.

## Packaged Mac app

A QA-only source copy was made from the integration revision under `/tmp/bridge-coup-issue-11-qa-20260927/source`. It received only two acceptance-specific changes: a unique review-store directory at `/tmp/bridge-coup-issue-11-qa-20260927/reviews`, and a unique bundle identifier (`app.absurdwall.bridge-coup.issue11-qa`) with display name `Bridge Coup QA 11`. The Info.plist was re-signed after editing. The installed/formal Bridge Coup app and its store were not replaced or used for saving.

- Package: `Bridge Coup.app`, version `0.4.0` (build `11`)
- Bundle ID: `app.absurdwall.bridge-coup.issue11-qa`
- Platform: macOS 26.5.1, Apple Swift 6.3.3, arm64
- Signature: ad-hoc; `codesign --verify --deep --strict --verbose=2` passed.
- DDS helper: 3.0.0, SHA-256 `1f3e859bcb80a55af94c3887121d10391ca3458f1301868fbd069961bfef8e34`.

The GUI was launched and addressed by this unique bundle identifier. The isolated QA source, package, and local review records were temporary and are not part of the commit.

## Live service evidence (synthetic only)

No real-game/player screenshot was available. The only recognition input retained here is [synthetic-auction.png](synthetic-auction.png), generated for this acceptance run and containing no real player data.

One fresh screenshot-recognition request through the packaged app returned the 12 calls in that synthetic image and EW vulnerability, with a 3♥ result. The UI presented it as a candidate that required review; it did not silently treat the result as confirmed. After manual review/correction, the auction was expanded to a 20-call record. This is a synthetic service/schema smoke only and is **not evidence of real-game OCR accuracy**. Ticket #9's earlier synthetic service result was not reused as this run's response.

One live declarer-plan request succeeded using a manually supplied, internally consistent synthetic deal. It had West as the starting seat and declarer, EW vulnerable, a 5♥ contract, and ♠2 lead:

- North: ♠AKT972 ♥— ♦Q742 ♣Q84
- East: ♠43 ♥KQT7 ♦J65 ♣AJ92
- South: ♠J865 ♥964 ♦K ♣KT763
- West: ♠Q ♥AJ8532 ♦AT983 ♣5

The app returned a concrete Chinese plan. Afterward, changing South's spades from `J865` to `J86` immediately marked the displayed plan stale and required regeneration before further use. No second plan request was made.

## Packaged-app interaction results

The manual run exercised the continuous review path:

- Imported the synthetic screenshot, reviewed the recognition candidate, and edited the record before using it.
- Added a user-provided meaning note to one of two identical Pass calls. After save/open, the note remained attached to the selected call; selecting the other Pass showed an empty note.
- Expanded the 20-call history and checked seat-column alignment, call color, and the A marker. The four North/West/East/South hand areas remained arranged around the table. Compact history remained scrollable. The full contract grid was available, and lead text `S2` normalized to `♠2`.
- Confirmed the empty-record choices are distinct: `确认无叫牌` produced “已确认本局无叫牌”; `改为录入叫牌` returned to a blank, unconfirmed record with explicit “这不等于本局无叫牌” copy. Adding an unknown call without a starting seat showed “位置未知” and did not assign North.
- Inspected the vulnerability choices: unknown, neither side, NS, EW, and both sides are distinct. The temporary QA review was restored to EW vulnerability afterward.
- Opened the DDS disclosure below plan generation and confirmed its explanatory boundary: full-information verification is retrospective and excluded from teaching context.
- Saved to the unique temporary store, reopened the review, and verified that the auction, per-call note, hands, vulnerability, starting seat, contract, lead, and stale-plan state survived.

## Limits

- Recognition evidence is synthetic only. It cannot establish accuracy on a real deal, handwriting, camera crop, or noisy screenshot.
- The generated plan was evaluated only on the synthetic complete deal above. Bridge correctness on a real game was not independently established.
- Runtime late-response races were not forced manually; deterministic workflow tests cover late screenshot and plan responses after corrections.
- Three DDS-helper-dependent tests were skipped in `swift test`. The separate packaged DDS helper was verified and ticket #10 had already completed its DDS acceptance; this report does not convert those skipped tests into passes.
- No application screenshot was retained. The retained PNG is the sanitized synthetic recognition input, not a screenshot of a real game or an app result.
