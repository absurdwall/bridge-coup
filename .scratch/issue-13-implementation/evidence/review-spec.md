# Spec review — PR #22

Read-only review of `3676ca66c56d6b1d3462b0d6ef4f41970e2c7878...9fa410a03be0ee5811906f35704bd4df5f9c7e60`, against fetched issues #13–#21 and fixed A prototype handoff. No tests run or product files changed. Native acceptance remains a separate root review boundary.

1. **[P2] Restore the actual auction table in the corner.** `Sources/BridgeTeacherMac/AuctionTableView.swift:105–121` renders only a title, expand button and number of calls when `isCornerSummary` is true; `PlayWorkspaceView.swift:36–38` selects that mode. With any recorded auction, users cannot inspect even a short four-seat call sequence directly on the play table. Issue #17 line 17 requires: “采用已确认本轮 A 角落叫牌小表，可展开长记录和查看备注”. The fixed handoff also explicitly confirms “A 角落小表”. Replace the count-only summary with compact call rows, retaining unknown/partial seat semantics and expansion for long records/notes. Root native QA corroborated the count-only rendering.

2. **[P2] Validate the current teaching projection in the play warning.** `Sources/BridgeTeacherMac/BridgeTeacherMacApp.swift:1224–1230` validates `workflow.draft` (original hands) against `keyPlayWorkflow.draft` (current trick). After a visible player legally plays a card, switching to key-play teaching shows “本墩已出牌…仍在可见手牌中”, because the original hand still contains that played card. Actual generation correctly uses `currentTeachingDraft` (`BridgeTeacherApplicationModel.swift:388`), so the warning falsely declares a valid position erroneous. Issue #17 line 19 requires: “当前局面通过现有教学入口提供对应剩余手牌及已知出牌，保留可见性投影”. Use the same current projection for UI validation as for submission; verify one visible-seat card in a partial trick produces no duplicate-held-card warning.

No additional scope-creep finding identified. DDS numerical/native proof and real Runtime/model identity acceptance are not inferred from source or mocked tests.

## Follow-up — aggregate `2824db804ed226774a5e3a1cd84b7114b3e21935`

Read-only recheck of `9fa410a...2824db8` and the recorded fix disposition. Both original P2 source findings are resolved:

- **Corner table:** `AuctionTableView.swift:156–205` now renders the latest two auction rows in four seat columns using the existing seat projection. Earlier-row and partial indicators remain explicit; unknown seat assignments use a labeled sequence. `cornerCall` reuses the occurrence-specific note/correction popover, while expansion retains all calls. This meets the missing small-table behavior in source; final native density/interaction acceptance remains root QA.
- **Current-position warning:** `BridgeTeacherMacApp.swift:1236–1238` now uses `model.keyPlayInputWarning`; `BridgeTeacherApplicationModel.swift:86–91` validates `currentTeachingDraft`, matching actual submission. The original-hand/current-trick inconsistency is removed.

Also inspected the single root alert host and outer window minimum fixes, plus the shared archive/history compatibility check. The root alert preserves staged edits until explicit confirm/cancel and retains review-error dismissal; the window minimum is now exposed outside the `GeometryReader`. No additional introduced spec defect identified in this bounded diff. These source checks do not certify native alert presentation or minimum-size rendering. No tests run or product files changed during this review.
