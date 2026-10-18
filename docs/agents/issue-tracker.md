# Issue tracker: GitHub

Specs and implementation tickets live in GitHub Issues for
`absurdwall/bridge-coup`. Use the `gh` CLI for tracker operations.

## Write pacing

Within this project's publication or update batch, serialize GitHub writes
and wait at least two seconds after each write finishes before starting the
next. This includes issue/PR creation, comments, edits, closures, label and
relationship changes, and, as a project convention, `git push`. Read-only
verification may run between writes.

Follow [GitHub's retry instructions](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api#exceeding-the-rate-limit)
if rate limited; two-second pacing does not override hourly limits or longer
server-requested waits. This per-project convention does not require a
cross-project queue or a local hourly write counter. See
[GitHub's write-pacing guidance](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api#pause-between-mutative-requests).

## Conventions

- Publish a spec as a GitHub issue.
- Publish approved implementation tickets as separate GitHub issues,
  linked to their parent spec.
- Read tickets with `gh issue view <number> --comments`.
- List tickets with `gh issue list`, including bodies and labels
  when needed.
- Create issues and comments with `--body-file` for multiline content.
- Apply or remove labels with `gh issue edit`.
- Resolve tickets with an evidence-backed comment and `gh issue close`.

Run inside this clone so `gh` infers the repository, or pass
`--repo absurdwall/bridge-coup` explicitly.

Existing `.scratch/` files remain historical planning and evidence.
This configuration establishes GitHub as the current issue tracker.

## Dependencies and readiness

Use GitHub sub-issues to link tickets to a parent spec. If unavailable,
use a task list in the parent and `Part of #<number>` in each ticket.

Use native GitHub issue dependencies for blockers. If unavailable,
record `Blocked by: #<number>` in the ticket body.

`ready-for-agent` means the ticket is sufficiently specified.
Before starting, also verify that all blockers are closed.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## Skill operations

When a skill says "publish to the issue tracker", create a GitHub issue.
When it says "fetch the relevant ticket", read the GitHub issue
and its comments.
