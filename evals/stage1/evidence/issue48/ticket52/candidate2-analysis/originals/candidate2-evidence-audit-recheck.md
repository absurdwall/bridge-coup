# Candidate 2 evidence audit: targeted fix recheck

**Clear. The original P2 preservation finding is resolved.** This report supplements, and does not rewrite, `candidate2-evidence-audit.md`.

Inspected only the changed preservation/inventory regression scope. `verify_preservation.py:22–26` now compares the complete actual relative-file set with manifest paths, rejects duplicate manifest rows, and validates the declared file count and byte total before hashing every original file. The former false-positive path for an additional unlisted raw file is closed.

`check_lifetime_portability.py:20–25` now creates an owned temporary candidate directory containing per-file symlinks, rather than symlinking the candidate root. Its `:48–55` sentinel is therefore owned by the temporary test, is rejected with the precise inventory-mismatch assertion, and is removed in `finally`; it cannot write the sentinel through a root-directory symlink into actual raw evidence.

Targeted execution passed: the real preservation verifier reports **3,300 files / 495,286,544 bytes** unchanged; a fresh owned temporary replica with all 3,300 listed file symlinks plus one unlisted sentinel is rejected with `raw file set differs from preservation manifest`. The sentinel was cleaned up and no counterpart appeared in the actual candidate directory. No broad retesting was performed, and no repository source/raw/index files, model/native calls or GitHub state were changed.

The fix satisfies the originally cited #52 acceptance criterion 1 (preserve each frozen candidate/original failures) and #48 fixed-candidate/no-reroll evidence obligations. No new actionable finding in this changed scope.
