# Reproduce cycle-1 evidence checks

Read [REPORT.md](REPORT.md) for the final **NO-GO**, and the immutable
[runner report](../candidate1/REPORT.md) for raw grades before independent overlay.
`originals/` retains original absolute paths verbatim; `external-preservation.json`
maps each source to its colocated copy. Supply any checkout containing this
commit as `REPO`; no `/tmp` or original ticket worktree is needed.

```sh
python3 "$REPO/evals/stage1/evidence/issue48/ticket52/candidate1-analysis/verify_preservation.py" --repo "$REPO"
python3 "$REPO/evals/stage1/evidence/issue48/ticket52/candidate1-analysis/verify_adjudication_proofs.py" --repo "$REPO"
python3 "$REPO/evals/stage1/evidence/issue48/ticket52/candidate1-analysis/audit_native_plan_encoding.py" --candidate "$REPO/evals/stage1/evidence/issue48/ticket52/candidate1"
python3 "$REPO/evals/stage1/evidence/issue48/ticket52/candidate1-analysis/aggregate.py" "$REPO/evals/stage1/evidence/issue48/ticket52/candidate1"
```

All commands are read-only and make no model calls. They do not require the
current checkout's instructions, corpus, implementation or `.build` to match the
historical candidate. `verify_preservation.py` verifies the 46 pinned source
blobs from `runtime/candidate1-source.tar.gz`; `verify_adjudication_proofs.py`
executes only that archived reducer and reads archived fixtures. The archive was
created from Git objects at `ca0b1a3`, with every member checked against the
original immutable freeze. `--check-current-source` is an optional separate
freeze-era comparison and is expected to fail after later candidates change
source. Omit that option for historical saved-evidence audits.

The saved-evidence lifetime regression can be rerun without editing any actual
source:

```sh
python3 "$REPO/evals/stage1/evidence/issue48/ticket52/candidate1-analysis/check_lifetime_portability.py" --repo "$REPO"
```

It creates a temporary checkout skeleton whose current source is deliberately
different and whose `.build`/native executable are absent, audits the preserved
raw evidence successfully, and confirms the optional current-source check rejects
those changed bytes. Proof verification separates
public-consistent counterfactual quality evidence, actual hidden-environment
coverage evidence and authored predicate-only diagnostics. It does not convert
any of them into actual live play or independently decide textual materiality.

Auditing saved evidence requires Python's standard library, these committed
artifacts and the verified source/runtime archives. It does not require Git,
network access, native Codex, current source parity or the original worktree.

Running the old native candidate again has additional requirements: the exact
historical `bridge-play` plus adjacent Swift resource bundle in `runtime/`, a
compatible macOS environment, the separately installed native Codex matching the
freeze's hash/version, credentials/service availability, and frozen role/config,
fixture and capture bytes. This is a new live execution, with nondeterministic
service output, not a saved-evidence audit or a replay of the original result.
Any authorized new run must use a separate output directory; the original matrix
and its no-reroll accounting remain immutable.

The binary archive in `runtime/` contains the historical executable plus adjacent Swift
resource bundle. Extract them into the same directory to preserve bundle lookup.
Its recorded native-Codex dependency is identified by hash in the raw freeze;
the proprietary native executable itself is not copied. No new live call is
required to verify the archive/member hashes. Files under `originals/` that are
named candidate2 are **provisional diagnosis/repair memos only**, not a frozen
candidate or permission to run one.
