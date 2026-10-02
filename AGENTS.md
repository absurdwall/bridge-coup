# Bridge Coup working agreements

- Make every repository change on a `codex/` topic branch, then open a pull request targeting `main`. Merge the PR after appropriate review and validation; keep the local `main` synchronized with `origin/main`.
- Never commit directly on `main`, push commits directly to remote `main`, or bypass the local hooks or GitHub branch protection. These rules also apply to website, documentation, and release changes.
- Enable the checked-in local guards in each clone with `git config --local core.hooksPath .githooks` before committing. After a PR is merged, remove its topic branch when its work and any worktree contents are preserved.
