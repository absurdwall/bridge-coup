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

For source commit `6b67218`, the full visual-review report and screenshots 05–07 were not imported because they contain or may retain private saved-review state. The public tree contains only the prototype, empty-state, synthetic matched-deal, and prototype-settings captures 01–04, plus a text-only public summary and a text-only install summary. The published issue links were adjusted to the project-level `DESIGN.md`, ticket 04 links only to the public summary, and local filesystem paths in acceptance notes were removed. No `.build/` outputs, credentials, unrelated files, or monorepo ancestry were included. The local closeout commit follows this imported sequence.

## Local closeout mapping

| Source monorepo commit | Standalone commit | Subject |
| --- | --- | --- |
| `f0b30bedce211828b6f7ab4319bfc547b4457e5f` | `0e7e8a87c1425b3c5b493d078e8edf782bcb8251` | docs(bridge): close visual repair cycle and queue follow-ups |

This mapping is recorded in a standalone-only metadata commit because a Git commit cannot contain its own hash. The metadata commit adds no project content.

## Contract grid, Markdown, and runtime catalog follow-up

These Bridge-only source commits are rebased onto the live standalone `main` after commit `5d5fa8f`. The `bridge/` prefix was removed, while source author metadata, subjects, and chronology were retained.

| Source monorepo commit | Standalone commit | Subject |
| --- | --- | --- |
| `0678ec2278d80288ac2448aa0886f0dba9c2184e` | `cf89295e777b2a5a9655fd852f52b1b9c2777a55` | feat(bridge): add atomic contract selection grid |
| `1c6c864092dc84bf0aecba46f0638bd710e3e316` | `d773043a0509cbd83d41cb63c49b12229a4233e9` | fix(bridge): complete contract grid access and reset |
| `e7421de071f8716d722bad638b06f806e8a43811` | `f9fd76d9fe6f135814c44c8f03e1eeb9a6153d2f` | feat(bridge): render saved analysis markdown |
| `4a7c6a42930e198040523bec6ad5f00ec7bdbde2` | `ad77630b13b4ee6ba17e09934815314087bb6abe` | fix(bridge): filter runtime to GPT-6 models |
| `1c00b20b864f97470f57a2f586583864c9df5235` | `8fd95237b60bb2df9c437b8b5cca44b3a9e2c3e0` | fix(bridge): restrict model IDs to supported families |

The companion acceptance snapshot is sanitized and contains only Bridge project files, ticket status, model-capability fields, and synthetic screenshots. It excludes local install paths, saved-review data, credentials, and unrelated monorepo files. Its mapping is recorded in the following standalone-only metadata commit.

## Installed acceptance snapshot mapping

| Source monorepo commit | Standalone commit | Subject |
| --- | --- | --- |
| `4ea6b7070f8f6c4e520963d762e28dee8ecfd508` | `b6e5723992251a6724da4415a64fb0da147da9ef` | docs(bridge): record final installed acceptance |

This standalone-only metadata commit records the mapping for the preceding public acceptance snapshot. It adds no project content.

## Visual-repair closeout documentation snapshot

The following documentation-only snapshot reflects the canonical Bridge files after the listed source commits. It exports the corrected partial status for issue 07, sanitized narrow-window evidence and its synthetic screenshot, the final runtime catalog notes, and the design memo. It contains no product-code changes, local filesystem paths, saved-review content, or credentials.

| Source monorepo commits | Standalone snapshot commit | Subject |
| --- | --- | --- |
| `cce26848dc617559ec57f1eca0311adb164d8f58`, `764263aa97759583bd45ac9bd95cb5df1066b505` | `61b3241fcf0388ab2baba38aeed68f96387002f8` | docs: prepare sanitized visual closeout export |

The snapshot preserves the retired Ticket 06 state and confirms that no Ticket 09 or 10 was added.

## Bridge Coup refinement planning and screenshot-record removal

The following Bridge-only source commits were exported as a sanitized documentation snapshot. The export adds the refinement spec, approved ticket index and tickets not already present on standalone `main`, plus a historical visual-audit report and its synthetic app screenshots. It contains no product-code changes.

| Source monorepo commit | Subject |
| --- | --- |
| `bd2ceaad0413afdb2dfb1f9a599ffff3b79c70a5` | docs(bridge): preserve planning and prototype artifacts |
| `c0a30a921773cd433fb0529f9456b250618f36d4` | docs(bridge): remove private screenshot-derived example |
| `f75ced063fc8bd959795889f433d8d91c2fbf545` | docs(bridge): record closeout dispatch boundary |

The same snapshot removes the screenshot-derived recognition record from the current public tree and removes its live links. Earlier commits are unchanged; no Git history rewrite was performed. The standalone snapshot commit is recorded by the immediately following metadata commit.

| Standalone snapshot commit | Source commits |
| --- | --- |
| `8644cfbb92bb96352c96e4c3a16007979c5ce9f4` | `bd2ceaad0413afdb2dfb1f9a599ffff3b79c70a5`, `c0a30a921773cd433fb0529f9456b250618f36d4`, `f75ced063fc8bd959795889f433d8d91c2fbf545` |

Before export, the remaining source artifacts were compared with standalone `main`. The scratch index, first-version feedback and issues 01, 05 and 06, plus `CONTEXT.md`, already matched. The standalone first-version index/spec and root design documents contain newer or sanitized material and were retained. The prototype source remains on `archive/bridge-ui-prototype`; it was not duplicated onto `main`. The already-published contract-grid issue was preserved, with its related refinement index and historical report added in this snapshot.
