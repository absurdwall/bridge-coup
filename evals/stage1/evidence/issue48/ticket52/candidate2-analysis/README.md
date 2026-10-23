# Audit candidate 2 saved evidence

Read `REPORT.md` for the cycle's final **NO-GO**. The original runner summary/report
still contain twelve completed attempts. Nine untouched scheduled attempts were
later run once through the frozen helpers as an explicitly reviewed operational
supplement. `short-5-r1` remains interrupted and incomplete; its three executed
final decisions were graded once separately. No normal outcome or matrix-finished
marker was fabricated. This is not an uninterrupted 22-attempt acceptance pass.

Set `REPO` to any checkout containing these committed artifacts, and `ANALYSIS` to
`$REPO/evals/stage1/evidence/issue48/ticket52/candidate2-analysis`:

```sh
python3 "$ANALYSIS/verify_preservation.py" --repo "$REPO"
python3 "$ANALYSIS/verify_public_windows.py" --repo "$REPO"
python3 "$ANALYSIS/verify_interrupted_cost.py" --repo "$REPO"
python3 "$ANALYSIS/originals/check_candidate2_walker_coverage.py" --repo "$REPO" --reports "$ANALYSIS/originals" --proof "$ANALYSIS/originals/candidate2-short6-coverage-environment-proof.json"
python3 "$ANALYSIS/originals/check_candidate2_full_reserved_r1_counterbranch.py" --repo "$REPO" --proof "$ANALYSIS/originals/candidate2-full-reserved-r1-counterbranch-proof.json"
python3 "$ANALYSIS/audit_native_plan_encoding.py" --candidate "$REPO/evals/stage1/evidence/issue48/ticket52/candidate2"
python3 "$ANALYSIS/aggregate.py" "$REPO/evals/stage1/evidence/issue48/ticket52/candidate2"
python3 "$ANALYSIS/check_lifetime_portability.py" --repo "$REPO"
```

These checks make no model calls and do not rewrite raw records or original
proofs. They require Python's standard library and the saved artifacts, not Git,
network access, an installed Codex executable, current source parity or `.build`.
The 50 source blobs in `runtime/candidate2-source.tar.gz` were read from pinned Git
commit `0a307cbde5498ed24b73da0d781cb9113ce92180` and checked against the original
freeze. The environment proof executes that archived reducer with archived
fixtures. Public-window and interrupted-cost checks read only saved records.
`--check-current-source` is an optional freeze-era comparison and is expected to
fail after later source changes; omit it for historical auditing. The lifetime
regression deliberately changes every current source file in a temporary skeleton
with no `.build`/native executable, while saved-evidence checks must still pass.

`originals/` retains outside reports, Spec dissent, coordinator resolution, public
proofs, environment-only coverage proof and operational interruption records
verbatim. `external-preservation.json` maps original paths to colocated files and
hashes. `path-remapping.json` maps captured absolute prefixes without editing raw
manifests, request/grade files or reports. Historical scripts with hard-coded
paths are preserved as provenance; use the portable commands above instead.
The operational wrapper/launcher are retained as execution provenance, not a
product resume feature or an instruction to rerun the historical matrix.

The short-3 public proof establishes eligible model windows and actual public
card counts, not observed semantic use. The final cohort resolution and its
independent Spec dissent remain separate and unchanged. Walker's complete hidden
environment proof verifies material coverage only; it is never a decision-time
public fact, live role input or quality label. Pending/rejected proposals count
for observable cost, never as extra delivered quality targets.

Auditing saved evidence differs from executing the old native candidate again.
A new native execution additionally requires the exact historical `bridge-play`
and adjacent Swift resource bundle in `runtime/candidate2-runtime.tar.gz`, a
compatible macOS environment, the separately installed native Codex matching the
freeze's hash/version, credentials/service availability, and frozen role/config,
fixture and capture bytes. The proprietary native Codex binary is identified by
hash rather than copied. Service outputs are nondeterministic. Any authorized
new execution uses a separate output directory; original matrix accounting and
no-reroll boundaries remain intact.
