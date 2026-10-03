# Bridge Coup working agreements

- Make every repository change on a `codex/` topic branch, then open a pull request targeting `main`. Merge the PR after appropriate review and validation; keep the local `main` synchronized with `origin/main`.
- Never commit directly on `main`, push commits directly to remote `main`, or bypass the local hooks or GitHub branch protection. These rules also apply to website, documentation, and release changes.
- Enable the checked-in local guards in each clone with `git config --local core.hooksPath .githooks` before committing. After a PR is merged, remove its topic branch when its work and any worktree contents are preserved.

## Agent skills

### Issue tracker

Specs and tickets live in GitHub Issues for `absurdwall/bridge-coup`.
Before issue operations, read `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default triage labels.
Before triage, read `docs/agents/triage-labels.md`.

### Domain docs

Use a single-context layout.
Before codebase exploration, read `docs/agents/domain.md`.
