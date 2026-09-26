# Standalone repository history

This repository was extracted from a larger Git monorepo into an empty GitHub repository. The active Bridge history was retained as a project-only chain: paths were moved from `bridge/` to the repository root, and commit hashes were rewritten to remove monorepo ancestry. Commit subjects, author attribution, and chronology were retained for the nine Bridge commits below.

| Source commit | Standalone commit | Subject |
| --- | --- | --- |
| `a07d32a` | `80d75f6` | feat(bridge): add native declarer plan slice |
| `29b9691` | `6c88e24` | refactor(bridge): share runtime error mapping |
| `c181588` | `407b83f` | feat(bridge): add versioned follow-up corrections |
| `87fff04` | `33dbc45` | fix(bridge): expire superseded follow-ups |
| `4b1b203` | `0b525e2` | fix(bridge): clarify stale follow-up history |
| `029c568` | `12b12d3` | feat(bridge): add key-play analysis mode |
| `c5ee560` | `d83b89f` | feat(bridge): add double-dummy verification |
| `b4d88e0` | `da2e418` | feat(bridge): save and reopen local reviews |
| `c4c25ca` | `5510ec8` | fix(bridge): preserve key-play results across modes |

The current source tree at `c4c25ca`, plus the Bridge-specific untracked design, specification, ticket, evidence, and feedback files, was exported as a new snapshot commit after these history commits. One non-Bridge source commit and all unrelated monorepo files and history were excluded.

The visual prototype from source commit `b27def74a42385989fea48f31ad8aa4ed443ac8a` is preserved as a snapshot on the separate `archive/bridge-ui-prototype` branch. Its monorepo ancestry is not included, and its files are absent from `main`.

A superseded screenshot-workflow commit `81d014a` was found as an unreferenced object from a cleaned temporary branch. It was not imported: the current source tree contains the later screenshot workflow and evidence through `b4d88e0` (standalone `da2e418`).

The publication excludes `.build/` outputs and caches, credentials, tokens, and unrelated user files. The source and destination were not modified to create a nested repository or change the original monorepo remote.

## Visual repair cycle import

The Bridge-only commit sequence below extends `main` after the published `c4c25ca` snapshot. Selected source commit metadata retains the original author and chronological dates; hashes differ because `bridge/` paths become repository-root paths and the commits are rebased onto the published standalone history.

| Source monorepo commit | Standalone commit | Subject |
| --- | --- | --- |
| `8e5d0ea1040825cf0376ea46636ff137e665d3c0` | `126fc7126bcbc41480b1dcb65b9c7553ad6818bb` | Implement compact Bridge Coup deal table |
| `9f209b91f43a4f4fd39fd6bd92deece98da3955c` | `ecbb37693bb82920108b1697f18be0590f29ba73` | Refine compact table acceptance evidence |
| `e397a0959104525dba5744bf3002a842e1807a74` | `664307106b85f6c2057974a0ef4b3631d20669da` | Implement first-screen Bridge Coup workspace |
| `8b73fca918d07b81162cba6a84f8d4e2d7f4925e` | `102d33d373fff3cf2550ef6f3edbcac549c2079f` | feat(bridge): add compact Bridge Coup settings header |
| `6b6721805eadec1f7ebf0f57241162cf613a1a16` | `0bc8183f89370129b9f60e2bbe8b2c16e4b15b28` | docs(bridge): complete Bridge Coup visual review (private artifacts filtered) |

For source commit `6b67218`, the full visual-review report and screenshots 05–07 were not imported because they contain or may retain private saved-review state. The public tree contains only the prototype, empty-state, synthetic matched-deal, and prototype-settings captures 01–04, plus a text-only public summary and a text-only install summary. The published issue links were adjusted to the project-level `DESIGN.md`. No `.build/` outputs, credentials, unrelated files, or monorepo ancestry were included. The local closeout commit follows this imported sequence.

## Local closeout mapping

| Source monorepo commit | Standalone commit | Subject |
| --- | --- | --- |
| `f0b30bedce211828b6f7ab4319bfc547b4457e5f` | `0e7e8a87c1425b3c5b493d078e8edf782bcb8251` | docs(bridge): close visual repair cycle and queue follow-ups |

This mapping is recorded in a standalone-only metadata commit because a Git commit cannot contain its own hash. The metadata commit adds no project content.
