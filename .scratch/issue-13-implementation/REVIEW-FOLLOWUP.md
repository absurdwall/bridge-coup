# Independent review follow-up — PR #22

Review scope: `3676ca6...62e226a`. The reviewer reproduced two state transitions not covered by the original179 passing tests. Both required changes. Latest code is `64d565219d96f33b133574ac1c6aa3bed5fcb3a1`;189 tests now pass with real DDS, zero failures/skips.

## Repairs and regressions

- **P1 independent DDS material loss:** automatic play/source synchronization overwrote unresolved legacy inputs and explicitly retained independent inputs. Optional persisted `DoubleDummyHandSource` now records shared, unresolved independent or reviewed independent ownership. Only shared inputs follow play/source changes. Save/reopen retains an explicit keep choice; only an explicit switch to original replaces independent materials. The first public-workflow regression failed with two exact preservation assertions before the fix. Expanded coverage includes play/history/restart, hand/confirmation/context edits, save/reopen and explicit original selection. [Implementer disposition](evidence/review2-disposition.md).
- **P2 recognition submission bypass:** the first recognition previously wrote the draft directly, revoked confirmation and advanced original version while retaining an old playable session. Recognition now proposes its merged draft through the same cancellable application reset boundary. Candidate/response metadata commits together with accepted facts, guarded by screenshot/request revision. Cancel retains facts, position/history and retryable recognition; confirm drops old play/history and requires review before restarting. Pending transitions reject play/collection/history changes; an unexpected direct source mutation drops an incompatible session and clears live results. The initial regression failed11 source/session/history/reset assertions before repair. Coverage includes in-flight recognition before play, manual corrections, switching records and stale-position rejection.
- **Native repeat-save failure:** opening and saving a screenshot-backed record copied its owned asset then deleted the file still referenced by the current workflow. A second save failed with a missing PNG. A public store regression reproduced this before repair. The store now reuses the existing safe owned asset when the supplied standardized URL matches and the file exists; external replacement still uses the transactional copy path. [Save disposition](evidence/review2-save-disposition.md).

Failure-first logs are retained locally under `/tmp/bridge-coup-issue13-context/review2-{dds,screenshot,save}-red.log`; matching focused/full green logs remain there.49 source/screenshot/history checks passed before the final store fix;11 archive checks passed afterward. [Final187-test summary](evidence/review2-final-tests.txt).

The exact original standalone probe was rebuilt against final debug modules using the selected Xcode compiler and explicit macOS SDK/arm64 macOS14 target. Its [original output](evidence/review2-original-probe.txt) and [fixed output](evidence/review2-original-probe-green.txt) show:

| Observation | Before | Final code |
| --- | --- | --- |
| Legacy DDS preserved after start/save | false | true |
| Recognition original/play version |3/2 |2/2, unchanged until confirmation |
| Undo remains available after recognition | false | true |
| Recognition reset pending | false | true |
| Next card accepted while reset pending | true | false |

## Additional packaged native acceptance

QA6 version0.13.0/build6 exports code `2b6dc165970f930344bf4625e8fa1fd8c9e020e0` (P1/P2). QA7 version0.13.0/build7 exports final `b81a5021636b6598e84b3e1211f71341c077823f` (also repeat-save fix). Both use separate bundle IDs, isolated synthetic review stores and only the existing review-store initializer injection as a QA source delta. Release builds and strict ad hoc signature verification passed. Normal unmodified `Scripts/build-macos-app.sh` also rebuilt final code successfully as version0.1.0/build1, and strict verification passed. [Package summary](evidence/review2-final-package.txt).

All following actions were performed through the native UI. Only synthetic fixtures and their screenshot assets were used.

1. **Unresolved legacy source:** opened a full original52-card record with independent North `AK1097` versus original `AK10972`. The conflict warning appeared. Started play, played North SA and saved the same record. Reopened it; the unresolved warning and independent DDS holding remained. QA7 repeated the start/play/save sequence and saved twice consecutively without failure. The complete independent DDS draft is unchanged after normalizing Swift dictionary encoding order, not merely the North holding. [QA7 saved record](evidence/review2-native-final-repeat-save.json).
2. **Explicit keep, main edit and reopen:** chose “保留独立 DDS 局面”, saved, revoked the main screenshot confirmation through the reset dialog, confirmed reset, saved twice again and reopened. No unresolved conflict alert appeared; confirmation remained false, play was cleared and independent DDS remained unchanged. Across five saves in QA7 the same owned PNG remained present, with no file restoration workaround. [QA7 saved state](evidence/review2-native-final-independent-edit.json).
3. **Explicit original source:** clicked “从原始手牌重置”. The source label returned to main version11 and DDS North changed from `AK1097` to `AK10972`. Saving recorded shared ownership. [QA7 saved state](evidence/review2-native-final-original-source.json).
4. **Actual recognition cancel:** opened a no-candidate screenshot record with manually supplied, confirmed52 cards; started and played North SA before clicking the still-available “识别截图”. The real official Runtime0.159.2, Luna Medium response presented the reset dialog. Cancel retained the true confirmation checkbox, East's turn and enabled undo. The recognition button remained available. Saving showed the same original/play version, one played card and idle screenshot state with no newly committed candidate/response. [Actual canceled state](evidence/review2-native-recognition-cancel.json).
5. **Actual recognition confirm:** repeated that actual Runtime request in a separate synthetic record. Confirming the reset removed old play and history, unchecked original confirmation and disabled start. Candidate and real Luna response were committed together. [Actual confirmed state](evidence/review2-native-recognition-confirm.json). These two real request scenarios ran in QA6; the only subsequent code change was the independently tested screenshot asset save fix. QA7 opened those actual saved outputs successfully as its isolated review fixtures.

QA6 first exposed the repeated-save defect; its temporary synthetic missing asset was restored only to continue examining DDS ownership before the fix. The final QA7 repeat-save scenario used distinct per-record assets and required no restoration. This distinction keeps the failed pre-fix run separate from final acceptance.

## Scope and remaining review

Optional Standards P3 shared delta-label formatting is deferred: it is a non-blocking maintenance suggestion and does not cause these source/reset failures. No broad coordinator or UI redesign was added. Fixed A prototype direction remains unchanged.

Original dirty requirements/prototype files and the original running app session were preserved. These results are local arm64 Mac acceptance; no production store migration or model-quality ranking is claimed. A fresh independent two-axis review is requested after the final evidence push. PR has not been merged and issues have not been manually closed.

## Fresh review: staged manual edit versus late recognition

Review at `d20cfae` independently passed187 tests and closed the original P1/P2 reproduction paths. It also reproduced one new P2: an in-flight first recognition could replace a manual edit pending play reset, because staging bypassed recognition revision invalidation.

Commit `64d565219d96f33b133574ac1c6aa3bed5fcb3a1` immediately invalidates existing recognition when either a manual key-input edit or screenshot replacement is staged. It advances the existing request revision without prematurely changing facts or manual-merge tracking; late recognized proposals also cannot replace a manual pending request. Cancellation retains facts, play and history. Confirmation applies only the user's staged input. Two public application regressions first failed31 assertions, then passed alongside25 focused and189 total tests, actual DDS with zero skips. They cover hands/contract/confirmation and screenshot replacement, each with cancel/confirm and no late metadata commit. [Disposition](evidence/review3-disposition.md), [validation summary](evidence/review3-final-tests.txt).

The reviewer's unchanged independent `/tmp/pr22-spec-race-probe.swift` was rebuilt against final debug objects. Before and after the response, pending remained manual and North remained the intended `KQJT98765432`; confirmation applied it (`intendedCorrectionPreserved=true`). [Exact probe output](evidence/review3-race-probe-green.txt).

QA8 version0.13.0/build8 packages64d5652 in another isolated synthetic store. Opened the earlier canceled-recognition record, played East S4 to add native undo history, and clicked first recognition using actual Runtime0.159.2/Luna Medium. While the UI still showed recognition in progress, toggled main confirmation to stage a manual reset. Canceled the native dialog. The UI showed retryable stale recognition, original confirmation true, South's turn and undo still available. Saved output retained original/play version10, North SA plus East S4 and no candidate/response. [Saved native state](evidence/review3-native-cancel.json). This native case establishes request invalidation and cancel preservation; exact suspended-response ordering and confirm/screenshot-replacement cases are established by the public automated regressions and independent probe, rather than claiming instrumentation of the real Runtime response arrival.

The normal unmodified release package was rebuilt from64d5652 and strict signature verification passed. Original20 dirty requirement/prototype hashes and `CONTEXT.md` diff still match the initial checkout. A new independent review is requested for this source; PR remains unmerged.
