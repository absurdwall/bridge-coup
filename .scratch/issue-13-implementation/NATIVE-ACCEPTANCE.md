# Issue #13 packaged Mac acceptance — 2026-10-02

The following records the first delivery at `2824db8`. Independent review at `62e226a` subsequently found two uncovered transitions; the fixes, new failure-first regressions and additional native acceptance are recorded in [REVIEW-FOLLOWUP.md](REVIEW-FOLLOWUP.md). Latest code revision is `b81a502`, with187 passing tests.

Scope: parent #13 and dependency tickets #14–#21. Fixed prototype commit `7478abf51aa3346ba3f31b726739c99f8b5667fe`; accepted A corner auction, existing four-player table, brand and two-panel teaching workspace. Prototype numbers were not used as solver answers.

All native interactions below used packaged release executables on this arm64 Mac through Computer Use. The full user-controlled play and DDS sequence ran in QA3, containing all prerequisite tickets. QA4 verified integrated Runtime waiting; QA5 verified final review fixes and reopened the same completed play. These are distinct from automated request mocks or prototype demonstrations.

## Build identity and isolation

| Package | Version/build | Source commit | Native purpose |
| --- | --- | --- | --- |
| QA1 | 0.13.0/1 | `30dcc1ee9cee79ebf44498fcf37162cf69c6459b` | Runtime, catalog, screenshot/shared hands, actual teaching boundaries |
| QA2 | 0.13.0/2 | `106eed4192eec4c52041bbb423c7996af281572e` | Explicit play start and original20-cell table |
| QA3 | 0.13.0/3 | `39daaa4b0fd9c1221a78f67c1df2a6005a1cea25` | Integrated legal play,13 tricks, history, live results, Runtime recovery |
| QA4 | 0.13.0/4 | `9fa410a03be0ee5811906f35704bd4df5f9c7e60` | Successful actual Astra Ultra teaching; legacy records |
| QA5 | 0.13.0/5 | `2824db804ed226774a5e3a1cd84b7114b3e21935` | Final A corner table, current-position warning, reset dialogs, minimum window and saved-play restore |

QA packages use separate bundle IDs and `/tmp/bridge-coup-issue13-qa-N/reviews`. The only QA source difference is injection of that directory through the existing `LocalReviewSessionStore` initializer. Sources were exported with `git archive`, compiled with `swift build --configuration release`, and packaged with the real DDS helper and normal brand assets. Ad hoc signing and `codesign --verify --deep --strict` passed. No fake solver or fake Runtime was packaged.

The unmodified product packaging script also built the final code successfully as `.build/macos/Bridge Coup.app`, version0.1.0/build1 (the script's existing metadata), and strict signature verification passed. It was not launched over the user's already-running app with its unsaved session. The original working copy's dirty `CONTEXT.md` and20 requirement/prototype files were verified unchanged.

Runtime: official desktop executable `/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex`, version0.159.2. DDS:3.0.0, pinned upstream commit `37c8a79f4c67c55d1a309ccb66dd00cb58af464a`. Final source ran179 tests with0 failures and0 skips. See [test summary](evidence/final-test-summary.txt) and [package summary](evidence/final-package-summary.txt).

## Synthetic source and independent DDS results

[Imported screenshot](evidence/synthetic-full-deal.png) contains only this synthetic deal. Actual Luna Medium recognition returned all16 holdings correctly; the native review/confirmation step was completed. Auction and opening lead remained explicitly unknown.

| Seat | Spades | Hearts | Diamonds | Clubs |
| --- | --- | --- | --- | --- |
| North | AK10972 | — | Q742 | Q84 |
| East |43 | KQ107 | J65 | AJ92 |
| South | J865 |964 | K | K10763 |
| West | Q | AJ8532 | A10983 |5 |

Each hand has13 cards, with52 unique cards overall. Selected contract:5H West, EW vulnerable. Shared original hands fed the existing DDS panel without retyping. Initial North legal-card labels from real DDS were SA/SK `=`, S10/S9/S7/S2 `+1`, DQ `+2`, and the other cards `=`. Equivalent-rank results were expanded to their individual cards.

The independently solved original table was:

| Strain | North | South | East | West |
| --- | --- | --- | --- | --- |
| S |4S |4S | — | — |
| H | — | — |5H |5H |
| D | — | — |4D |4D |
| C |3C |3C | — | — |
| NT | — | — |1NT |1NT |

This table was opened before play and after the completed deal, with the same cells. Reopening after undo/redo reused the source result. Changing the selected contract from5H to5S left the original-table source/cache unchanged. A confirmed original-hand edit made the source invalid and removed the old table; restoring the missing card recomputed the correct20 cells for the new source version. Automated real-DDS fixtures also verify all20 cells with pure suits, slams, unmakeable entries and a5C case.

## Native scenario results

| Area | Actual actions and observation |
| --- | --- |
| Explicit start and legality | Start was enabled only for confirmed valid52 cards plus contract/declarer. North led SA, then East S4, South SJ, West SQ. Only the current seat's legal cards were clickable; following suit was enforced. Four cards remained on the table until explicit collect. NS then had1 trick and North led next. |
| Whole-deal play | User-controlled UI clicks and explicit collection completed all13 tricks. An independent winner calculation checked each clicked trick against the native scores.52 unique cards were played, final NS1/EW12, West12 tricks and `+1`; no further play was enabled. The original52-card source stayed intact. [Actual saved play](evidence/native13-saved-play.json) retains all13 completed tricks, empty remaining hands and those scores. QA5 reopened it and displayed `已收13墩·NS1·EW12` and `已恢复保存的自主推演`; history was correctly empty after opening. |
| History and branch | Restart, undo and redo restored complete positions. Undoing North SA and instead playing DQ cleared redo; East then had only diamonds legal, with results interpreted as `+2` relative to the same West contract. New state/results replaced the previous position. Original hands remained unchanged. |
| Current results | Toggle on showed labels directly under continuous ranks for the acting seat. Legal-card changes, undo/redo and branch updates yielded results for the new position; collecting/finished states did not retain obsolete labels. Toggle off hid results. Automated asynchronous generation/revision tests additionally cover rapid operations, canceled/stale completion and solver failure/retry. |
| A corner auction | QA5 showed actual latest two rows across four seat columns, with19-call history available through expansion. A West5H occurrence opened its own attached note. Partial unknown-seat records kept explicit sequence/uncertainty; a separate20-call partial fixture expanded and scrolled through the last call and long notes. |
| Current teaching position | Playing North SA then switching to key-play teaching showed no false “played card remains held” warning. UI validation and submission share the remaining-hand/public-play projection; the regression inspects that outgoing request. |
| Staged source/contract reset | With SA already played, editing North to AK1097 opened the reset confirmation. Cancel retained the original cards and East's turn. Changing5H to5S also opened the dialog; cancel retained5H and the play. Confirming the contract reset the play while leaving the original table intact. Confirming the missing-card source edit reset play, disabled start and invalidated old DDS answers; restoring the card enabled calculation again. |
| Density and minimum window | Default1320×900 points and enforced minimum1180×650 content points were inspected natively. Dragging smaller clamped the window; Retina capture at minimum was2360×1366 pixels including title bar. All four hand regions remained balanced, continuous ranks and their labels aligned, and vertical scrolling kept lower controls accessible. No B/C or brand redesign was introduced. |
| Partial-deal compatibility | A synthetic legacy-shaped record containing only East/West opened in QA5. Start was disabled with missing North cards explained; teaching remained enabled. An actual Luna Medium response explicitly acknowledged the supplied East/West hands. |
| Legacy DDS conflict | A synthetic old archive with no new optional fields and a separate North AK1097 DDS hand opened with an explicit conflict warning. Its materials and original North AK10972 were both retained. Choosing independent legacy DDS did not overwrite the original; choosing original source later repopulated DDS and produced the real results above. |
| Saved state | QA3 saved the complete13-trick session; final QA5 restored it. Other synthetic archives exercised absent optional fields, partial auctions, attached notes and original-hand provenance. Undo/redo stacks are intentionally memory-only. |

## Actual Runtime and model requests

- Automatic startup found the official desktop candidate while shell `which codex` had no result. Manual selection accepted a transparent wrapper that execs the same official Runtime. After that saved wrapper was renamed away, native re-search skipped the missing manual candidate, connected the desktop candidate, and showed candidate reasons with copy/reveal actions.
- A second wrapper ran the official Runtime with an empty isolated `CODEX_HOME`: the native status required ChatGPT login and teaching was unavailable. Manually selecting the connected Runtime recovered it. No user credential files were inspected or copied.
- The actual catalog exposed exact `gpt-6-luna`, `gpt-6.1-sol`, `gpt-6-astra`. Old `gpt-6-sol` was excluded. Native Luna showed Low/Medium/High/Extra High/Max; Astra also showed Ultra. Native Astra Ultra selection survived catalog refresh. Exact migration, missing capability and reported-identity mismatch handling are covered by service/catalog tests.
- A transparent forwarding wrapper captured only outgoing `thread/start` and `turn/start` synthetic requests. Two-hand teaching contained exact East/West and explicitly unknown North/South. Four-hand teaching contained all four exact hands. Neither payload contained DDS answers or the20-cell table even though DDS had already solved the source. Changing teaching visibility marked the old analysis stale. Both actual Luna Medium requests completed; a separate actual Sol Medium request completed with matching configured identity.
- An actual Astra Ultra bridge request exposed the old fixed180-second deadline. Replaying its identical synthetic prompt directly through the official protocol completed182.805 seconds after `turn/start`, with progress and answer streaming before the old timeout. The integrated fix uses180 seconds of inactivity for the matching thread/turn plus a finite900-second overall ceiling. Unrelated notifications cannot renew it; silence, failure and the cap have regression coverage. QA4 reran actual native Astra Ultra teaching successfully, showed `gpt-6-astra · Ultra`, and saved a fresh response bound to the same information version. The external182.805-second measurement is diagnostic evidence, not the timing of the later native run.
- Runtime completion may omit effective model/effort. Such absent fields stay absent; the UI/request identity comes from the start snapshot and an actual reported mismatch is rejected. No runtime identity was fabricated from completion omission.

These runs establish access, request identity and information boundaries. They do not certify every model's bridge answer or rank model quality; numerical acceptance above uses actual DDS independently.

## Review closure and limits

[Standards review](evidence/review-standards.md): no documented violations. Optional duplicated archive/history compatibility logic was unified; broad coordinator extraction was explicitly accepted as a deferred, non-blocking maintenance suggestion.

[Spec review](evidence/review-spec.md): the two P2 findings (count-only corner auction and original-hand warning during current-position teaching) were fixed and independently rechecked at final code revision. [Fix disposition](evidence/review-fixes-disposition.md) records source/test work; its pending native statements are completed by the QA5 scenarios above. Native reset-alert hosting and minimum-window issues discovered during integration were also repaired and checked in QA5.

The first acceptance exercised the scenarios above; it did not cover the two later independent-review reproductions. See the follow-up for their repair and verification. Evidence is from this arm64 Mac and ad hoc signed local packages; hosted CI has no configured checks. Native screenshots/AX observations are in the execution transcript, while this directory retains the synthetic source, actual completed-play payload, review reports and build/test summaries. No production review-store migration or other-platform acceptance is claimed. PR review/merge remains the next repository action; issues were not manually closed.
