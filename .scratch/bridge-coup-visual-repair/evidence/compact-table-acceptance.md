# Compact table acceptance

Date: 2026-09-25

## Packaged app and reference

- Built the real `.build/macos/BridgeTeacher.app` with `Scripts/build-macos-app.sh` after the SwiftUI change.
- Opened the approved prototype worktree at `prototype/bridge-coup-next/` with variant A selected.
- Captured the app and prototype directly from their visible windows, then cropped the prototype capture to the page viewport. `03-app-vs-prototype.png` places those source captures side by side at a matching content width.
- The app window was about 1320×900 points; the prototype browser window was about 1246×846 points, with a 1246×692-point page viewport after browser chrome. Both show the same sample:
  - 3NT, South declarer, ♠K opening lead.
  - North: ♠852 ♥74 ♦AKQJ10 ♣862.
  - South: ♠A93 ♥AK5 ♦742 ♣A953.
  - East and West remain unknown.

## Manual interaction checks

- Enter committed an edited holding into the live review draft.
- A duplicate card stayed in edit mode and displayed the existing validation message; Escape canceled the edit.
- `-` displayed as a confirmed void; clearing it and pressing Enter restored the unknown state.
- The board kept N at top, S at bottom, W left, E right, with no card overlap. Heart and diamond symbols remained red.
- No review was saved and no teaching request was generated during these checks.

## Automated checks

- `swift test --filter 'DeclarerPlanRequestBuilderTests|DeclarerPlanWorkflowTests|ScreenshotReviewWorkflowTests'`: passed 18 tests.
- `swift test`: passed all 38 tests.

## Screenshots

- [Packaged Mac app](01-packaged-app-a.png)
- [Approved prototype A](02-prototype-a.png)
- [Side-by-side comparison](03-app-vs-prototype.png)
