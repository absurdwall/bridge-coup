# 02: Select a contract from the full grid

**What to build:** Let a user open the complete contract grid and choose a level/strain combination such as 4♠ or 3NT in one action. Apply it to the current review and mark prior analysis stale.

**Blocked by:** None

**Status:** complete

- [x] Show all 35 level/strain choices in one keyboard-accessible grid.
- [x] Highlight the current contract, close after selection, and preserve the current declarer and deal context.
- [x] Keep cancel non-mutating and invalidate old analysis when the contract changes.
- [x] Exercise the workflow in the Mac app and cover it with regression tests.

## Scope

This ticket adds a direct contract choice. It does not add a full auction, doubles/redoubles, or scoring features.

## Acceptance evidence — 2026-09-26

- The Release build exposed all 35 choices and identified the current 3NT selection. Cancel kept 3NT; Space confirmed the focused choice; selecting 4♠ updated the workspace and marked the previous plan as based on old information.
- Reloading the synthetic review restored its original 3NT contract and left the saved archive unchanged.
- `BridgeTeacherContractSelectionTests`, `DeclarerPlanWorkflowTests`, `DoubleDummyVerificationTests`, and `ReviewSessionArchiveTests` passed. See the [public packaged acceptance summary](../../bridge-coup-visual-repair/evidence/acceptance-summary-2026-09-26.md).
- No teaching request or double-dummy solver run was issued.

## Parent

[Project design](../../../DESIGN.md)
