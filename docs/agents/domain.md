# Domain Docs

## Before exploring

- Read `CONTEXT.md` at the repository root.
- Read ADRs in `docs/adr/` that concern the area being explored.

If these files or directories are absent, proceed silently.
Create domain documentation lazily when terms or decisions are resolved
through domain-modeling.

## Layout

This is a single-context repository:

- `CONTEXT.md`: shared domain vocabulary.
- `docs/adr/`: architectural decision records.

Preserve the existing `CONTEXT.md`.

## Vocabulary

Use terms as defined in `CONTEXT.md` in issues, proposals,
hypotheses, and tests.

If a needed concept is missing, reconsider the term or note the gap
for domain-modeling.

## ADR conflicts

Explicitly identify any proposal that contradicts an existing ADR,
including the reason for reopening that decision.
