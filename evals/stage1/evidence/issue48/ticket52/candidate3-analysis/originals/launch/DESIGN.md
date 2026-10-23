# Candidate 3 fresh strict-22 detached launch design

Prepared outside the repository before source review/integration. **Not launched, built or frozen.** The current proposal and integration hashes are deliberately not substituted for the future reviewed integration tip. The root must authorize that exact source before any build, freeze or live execution. This is the third/final substantive candidate, not a new budget or recovery of candidate2.

## Files and launch boundary

- `launch_candidate3.py`: read-only validation by default; `--launch` performs one `Popen` of the **original** frozen `evals/stage1/acceptance.py run --output …/candidate3` command. No child wrapper/supervisor, alternate attempt loop, board resume, rerun, retries or automatic restart.
- `test_detachment.py`, `detachment-validation.json`: harmless temporary Python-child lifecycle test. It does not invoke project acceptance, native Codex or a model.
- Future `execution/detached-registry.json` and `execution/runner.stdout-stderr.log`: exclusive-created external operational records. They do not exist yet. The registry reserves the one launch before spawning; any later invocation fails instead of resuming.

The eventual command, after root authorization, source integration, actual rebuild, freeze, archive and validation, is:

```sh
PYTHONDONTWRITEBYTECODE=1 /tmp/bridge-coup-issue48-context/venv/bin/python /tmp/bridge-coup-issue48-context/candidate3-launch/launch_candidate3.py --repo /Users/tingranwang/.codex/worktrees/issue52-reviewed-acceptance/bridge-coup --expected-source REVIEWED_INTEGRATION_SHA --launch
```

Omitting `--launch` validates only. `REVIEWED_INTEGRATION_SHA` is a mandatory explicit argument, not an inferred branch tip. The exact runner child argv uses the same isolated interpreter, `-u`, the checkout's original `acceptance.py`, `run`, and the new candidate3 output. It creates no candidate1/2 writes. The original runner owns schedule verification, all per-attempt preflights, the fixed sequential22 loop, existing native capture/role identities, unchanged grading, bounds and final markers. There are no extra acceptance/model calls around it.

## Required order before launch

1. Finish source Standards/Spec/WFA reviews and any bounded repairs; merge the reviewed source into integration. Root authorizes the actual tip. Merge that tip into the #52 worktree. Do not use the current source proposal hash as though integration already contained it.
2. Rebuild the actual `bridge-play` executable at that reviewed tip. Current host requires explicit `SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk`; retain toolchain/build observations, change no project config or installation. Build before any dependent Python execution.
3. Check tracked frozen source clean; freeze a **new** candidate3 with original `acceptance.py freeze`, native executable and exact reviewed config. Preserve its complete22 plan before calls. No change to corpus/rubric/repetitions/bounds; case-executionv1 short3 mechanical=false only. Verify both instruction/resource hashes, model/config/schema/runtime/catalog hashes.
4. **Before any model call or future rebuild**, preserve exact built executable plus adjacent Swift resource bundle in `candidate3-analysis/runtime/candidate3-runtime.tar.gz` with `candidate3-runtime-verification.json`, and every frozen source Git blob in `candidate3-source.tar.gz` plus `candidate3-source-archive.json`. Metadata follows candidate2's format: archive bytes/hash, exact member hash maps; source metadata also contains source commit. Independently compare blobs/binary/resources to freeze.
5. Run the external launcher's read-only validation; root may inspect its attestation. Then invoke `--launch` once. Return from the launcher immediately, record PID/PGID/session and exact argv/launcher/interpreter hashes, and separately inspect the live PID identity/log. Never hold the long original runner in an attached tool session.

The launcher validates the reviewed SHA against HEAD/candidate, all frozen source hashes and clean tracked paths; absent attempt directories and all run markers; exact22 ID order; fixed case options, identities/empty tools,5semantic/4technical caps and180/1800s bounds; binary/native bytes; source/runtime archive inventories and hashes; and both installed adjacent instruction-resource bytes. Native version/catalog/source attestation are also enforced by the unmodified runner's existing preflight immediately before its first attempt and every later attempt. Validation invokes no native executable itself.

## Detachment and evidence

`Popen(start_new_session=True, stdin=DEVNULL, stdout=log, stderr=STDOUT, close_fds=True)` creates PID=PGID=session distinct from the launcher's group. No shell, inherited tool pipe or parent wait. The registry is flushed/fsynced before and after spawn; only safe selected environment settings are recorded, never credentials. Both streams use an exclusive log file. PID/PGID/session, actual command/cwd, launcher path/hash, exact interpreter path/resolved path/hash, binary/source/archive/instruction/native attestations, plan hash and launch UTC are retained. `actual_exit` starts unknown; neither launcher exit nor PID disappearance means acceptance success.

The harmless lifecycle test proves that the launcher returns while its child is alive; the child is reparented after launcher exit, has its own session/group, sees stdin EOF, and finishes its log after the launcher is gone. A second exclusive-registry launch is rejected. This protects against ordinary attached-tool/turn process-group cancellation. An explicit OS/session-wide kill, host shutdown or app-level descendant kill may still terminate a detached process; no claim of immunity or product restart support is made.

If launch/preflight fails, the reserved registry remains and no automatic second spawn occurs. If metadata writing fails after spawn, inspect the exact reserved command/process before any action; never silently spawn again. If the runner disappears, preserve its actual artifacts/state/unknowns and report the discontinuity. Do not restart/resume/reroll any started slot. A completed22 runner still requires independent quality/coverage adjudication and final owner boundaries. Progress reports read completed-attempt metadata only, without semantic feedback into live roles.

Candidate1/2 raw, source/runtime archives and committed evidence remain immutable. This outside design is operational provenance, not source modification, live calibration, recurring automation or permission for a general recovery feature.

## Prelaunch attestation supplement

The reviewed launcher bytes and design are preserved as `launch_candidate3.reviewed-12f619bd.py` and `DESIGN.reviewed-12f619bd.md`. `prelaunch-attestation.diff` and its hash record describe the narrow root-required supplement: cycle.json must bind integer cycle3/max3 to the exact source; the frozen original verify_schedule checks all manifest bounds; selected environment metadata records only SDKROOT plus the two literal Python runtime settings. No complete environment dump is retained.
