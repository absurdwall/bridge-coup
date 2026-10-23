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

All commands are read-only and make no model calls. Proof verification separates
public-consistent counterfactual quality evidence, actual hidden-environment
coverage evidence and authored predicate-only diagnostics. It does not convert
any of them into actual live play or independently decide textual materiality.

The archive in `runtime/` contains the historical executable plus adjacent Swift
resource bundle. Extract them into the same directory to preserve bundle lookup.
Its recorded native-Codex dependency is identified by hash in the raw freeze;
the proprietary native executable itself is not copied. No new live call is
required to verify the archive/member hashes. Files under `originals/` that are
named candidate2 are **provisional diagnosis/repair memos only**, not a frozen
candidate or permission to run one.
