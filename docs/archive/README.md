# Recoverable history outside the daily repository

Issue #54 separates source history from raw model runs. The source repository
keeps code, tests, selected small fixtures and acceptance summaries. Complete
original history and working files belong to the archive, never an archive branch.

## Archive location

The owner selected the existing external `archives/bridge-coup` root. This round
uses `2026-10-23-post-pr53`. Its public backup is the assets attached to
[the history archive release](https://github.com/absurdwall/bridge-coup/releases/tag/history-archive-2026-10-23).
Download those assets explicitly; normal clones do not need them.

The release tag identifies the lightweight source candidate. Raw history lives
inside the attached bundle, not behind that tag. Keep the downloaded checksums
and recovery instructions with the archive. Publication/restore status is
reported on [issue #54](https://github.com/absurdwall/bridge-coup/issues/54).

## Retrieving an original file

After verifying the asset checksums, restore in a separate directory:

```sh
git clone --mirror original-history.bundle recovered-history.git
git --git-dir=recovered-history.git show ORIGINAL_SHA:path/to/file
```

The original accepted main was `a17746980a19bf2e9c1d4bdda6dd11b4de58b07d`.
The reviewed PR #53 tip was `015579a60fbdc1be26b68127f60e9cf8f2c25b9b`;
its runtime candidate was `3f0fc65470633dd90363ad0417b29a9f7f68be18`.
These original identities remain meaningful inside the bundle, even when
filtered commits have different SHA values. The release includes a commit map.

Uncommitted files are not in a Git bundle. Restore them using the file manifest
and content objects in the working-files archive; preserve modes and symlink
targets. Patches and original worktree identities are retained separately.
The seven teaching files are historical learning material in that archive,
not current application instructions. Missing temporary references are disclosed.

## Acceptance and fixtures

[Current Stage 1 acceptance](../acceptance/stage1/README.md) preserves the owner
adjudication and explains how to retrieve original supporting material. Archived
FAIL and NO-GO records remain unchanged; moving evidence is not a new quality run.

Saved regression fixtures contain only the files actually consumed by the
offline tests, with original byte hashes and source paths. They do not include
the complete runs, runtime model catalogs or a new claim of playing strength.

## New runs

Write run output outside the repository. For a batch, give player and reviewer
the same `--artifact-store` outside the repository; the acceptance runner does
this automatically. Each catalog is stored once by SHA-256. Per-role relative
links retain exact associations and remain valid when the batch and its object
store move together. Preserve that store when archiving a batch.

Generated runs, Python caches and build artifacts are ignored and rejected by
the commit guard. Product website images and normal application resources remain.
