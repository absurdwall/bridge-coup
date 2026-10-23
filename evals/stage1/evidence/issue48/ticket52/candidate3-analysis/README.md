# Audit candidate 3 saved evidence

Use the cycle [REPORT.md](REPORT.md) and central
[acceptance report](../../ACCEPTANCE-REPORT.md) for the final **NO-GO** and
obligation status. These commands audit preserved bytes and public bindings;
they do not infer acceptance from legal completion, a raw grade or review approval.

The original runner recorded all 22 predeclared slots once, without interruption,
resumption or supplemental attempts. Its genuine finish marker and all per-board /
grader process returns establish matrix completion. The detached orchestrator's
OS exit status remains **unknown**; PID disappearance does not establish exit zero.
Cycle 3 exhausts the maximum three substantive frozen candidates. These are saved
artifact audits, not authorization for another model/native execution.

Set `REPO` to a checkout containing the committed evidence and `ANALYSIS` to
`$REPO/evals/stage1/evidence/issue48/ticket52/candidate3-analysis`. Use Python 3 and
set `PYTHONDONTWRITEBYTECODE=1` to avoid creating cache files in the artifact tree.

```sh
python3 "$ANALYSIS/verify_preservation.py" --repo "$REPO"
python3 "$ANALYSIS/verify_public_windows.py" --repo "$REPO"
python3 "$ANALYSIS/verify_public_counterbranch.py" --repo "$REPO"
python3 "$ANALYSIS/originals/candidate3-short-5-r2-public-proof.py" --repo "$REPO" --proof "$ANALYSIS/originals/candidate3-short-5-r2-public-proof.json"
python3 "$ANALYSIS/originals/check_candidate3_walker_coverage.py" --repo "$REPO" --reports "$ANALYSIS/originals" --proof "$ANALYSIS/originals/candidate3-short6-coverage-environment-proof.json"
python3 "$ANALYSIS/audit_native_plan_encoding.py" --candidate "$REPO/evals/stage1/evidence/issue48/ticket52/candidate3"
python3 "$ANALYSIS/aggregate.py" "$REPO/evals/stage1/evidence/issue48/ticket52/candidate3"
python3 "$ANALYSIS/check_lifetime_portability.py" --repo "$REPO"
```

The lifetime command also replays all three `check_candidate3_short3_rN_public.py`
proofs, both development `candidate3-full-development-rN-public-replay.py` proofs,
and both `check_candidate3_full_reserved_rN_public.py` proofs, with explicit
`--repo` and colocated `--proof` arguments. Their default mode compares saved
proofs; do not supply `--write`. The short-5-r1 original script unconditionally
writes a hard-coded proof path: retain it as provenance and use only
`verify_public_counterbranch.py`, which maps its one public input read and
intercepts its final write for exact-byte comparison. It executes the original
hash-bound script unchanged and never rewrites the historical proof.

All checks use saved records, the standard library and the archived source blobs.
They require no Git repository, installed Codex executable, network, current
source parity or `.build`. The lifetime regression changes every current frozen
source file in an owned temporary skeleton, with no build/native runtime, and
requires these audits to pass. A separate negative case adds one owned unlisted
raw sentinel to a per-file-symlink replica and requires rejection before removing
only that sentinel. Optional `--check-current-source` is a freeze-era comparison;
it must reject that changed skeleton and may fail after later source changes.

`raw-aggregate.json` deliberately omits independent adjudication rather than
encoding missing judgments as zero; `aggregate.json` adds the final separate
22-row overlay. They describe the same underlying calls, not additive runs.
Native RPC and HTTP token counts overlap and must not be added. Cached and
reasoning token fields are subsets. Unknown data remains unknown.

`originals/` preserves external reports, proofs, generation scripts, draft
checkpoints and resolutions verbatim, including historical limits and dissent.
The external manifest maps their original paths to portable copies and hashes;
path remapping is separate from unchanged raw manifests and captured requests.
The short-3 public proof establishes eligible windows only, not distinct semantic
use. Walker's hidden environment replay verifies material coverage only after
public reports are final. Completed full plays can reconstruct holdings for
legality replay, never as earlier decision-time quality facts. Hypothetical
public-compatible branches are not actual environment coverage or later-outcome
justification. Rejected/pending drafts remain diagnostic and cost evidence.

Saved auditing differs from running the historical native candidate again. A new
execution would additionally require the exact executable and adjacent Swift
resource bundle in `runtime/candidate3-runtime.tar.gz`, compatible macOS, the
separately installed native Codex matching the frozen hash/version/catalog,
credentials/service availability and all frozen source/configuration/material.
The native Codex binary is identified by hash, not redistributed. Service outputs
are nondeterministic. No additional execution is authorized by this package or
the completed three-cycle budget. Candidate1/2 evidence remains unchanged.
