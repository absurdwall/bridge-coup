# Bridge Coup：连接设置、录牌体验与品牌落地

Status: ready-for-agent

本轮从既有第一版增量改进，使用已配置的本地 tracker。用户已确认功能方向，并在原型任务选定 A「独立座位卡」及叠牌图标。本文整理这些结论；实现 tickets 的拆分尚待用户确认，未开始本轮正式开发。

## Problem Statement

现有 Mac 应用已经具备第一版复盘功能，但用户缺少模型与 thinking effort 选择，定约输入需要分开选级别与花色，手牌录入的表单组织不符合实际牌桌的空间关系。界面需要更精致、易读，桌面应用还需要统一 Bridge Coup 名称和正式图标。

用户希望在保持现有复盘能力和浅色左右工作台的基础上，减少录牌动作，并能控制模型消耗。此轮不重新设计教学产品，不扩展新的桥牌求解能力。

## Solution

保留左侧牌局、右侧教学的 A 工作台。牌桌使用四个独立座位卡，北上、南下、西左、东右，每家按 ♠♥♦♣ 四行显示牌点；点击一行直接键盘编辑。桌心显示定约，展开后可从完整叫品表一次点选。

连接设置可选 Luna、Sol、Astra 与合法的 thinking effort，首次默认 Luna + Medium，记住上次选择。品牌统一为 Bridge Coup，使用用户选定的叠牌原图制作应用图标，独立保留已认可的图片字标，不把长文字缩进 Dock 图标。

## User Stories

1. As a player, I want Luna and Medium selected initially, so that my first review uses a moderate effort setting.
2. As a player, I want to select Luna, Sol or Astra where available, so that I can choose the model appropriate to my review.
3. As a player, I want to select a supported thinking effort, so that I can control reasoning depth and usage.
4. As a player, I want Max offered only for Luna and Ultra excluded, so that the controls match my preferences.
5. As a player, I want my last valid selection restored, so that I do not repeatedly configure the connection.
6. As a player, I want an explicit explanation when switching models changes effort, so that settings never change silently.
7. As a player, I want the actual request to use my selected configuration, so that the settings are functional rather than decorative.
8. As a player, I want a complete contract grid, so that I can choose 4 spades or 3NT with one selection.
9. As a player, I want the selected contract visible at the table center, so that I can stay oriented while reviewing.
10. As a player, I want contract changes to invalidate dependent analysis, so that old results are not mistaken for current advice.
11. As a player, I want North above, South below, West left and East right, so that the input matches a bridge table.
12. As a player, I want four suit rows per seat, so that I can scan and compare hands quickly.
13. As a player, I want to click a suit row and type card ranks in place, so that I can correct a hand without moving to a separate form.
14. As a player, I want Enter to commit and Escape to cancel, so that editing is predictable.
15. As a player, I want invalid or duplicate cards identified, so that mistakes do not enter confirmed analysis.
16. As a player, I want unknown holdings distinguished from a confirmed void, so that absence of information is not misinterpreted.
17. As a player, I want accepted edits reflected in the same review session, so that teaching and saved reviews use the corrected information.
18. As a player, I want a readable light workspace, so that cards and long explanations remain comfortable to use.
19. As a player, I want one clear hand-editing surface, so that duplicate forms do not compete for attention.
20. As a player, I want the app named Bridge Coup throughout its visible surfaces, so that I can recognize it consistently.
21. As a player, I want the chosen stacked-card image in Finder and the Dock, so that the app has a recognizable icon.
22. As a player, I want the approved wordmark displayed separately at a readable size, so that the small icon stays clear.
23. As a returning player, I want existing saved reviews and sign-in access preserved, so that the visual update does not lose my work.
24. As a player, I want the new controls verified in the actual Mac app, so that a working browser prototype is not confused with a delivered feature.

## Implementation Decisions

- **Incremental scope:** reuse the existing review workflow, state validation, model access, solver and storage boundaries. Integrate new controls with the real workflow; do not replace actual teaching with prototype text. Verify current owning modules before editing; no new application framework is selected by this spec.
- **A baseline:** light side-by-side workspace; pale table surface with four separate light seat cards and a distinct central contract. Suit rows use compact rank characters, not physical playing-card widgets. Red hearts/diamonds remain legible. Do not ship alternative B/C layouts or a variant switcher.
- **Responsive sizing:** prototype dimensions are a visual reference, not fixed production constraints. Keep all seats and the center distinct with readable ranks. Prefer coherent page scrolling over a cramped nested left-panel scroll region, while preserving access to teaching and follow-up in normal Mac windows.
- **Settings entry:** give connection settings a clear, compact entry point. Retain the supported existing Codex authentication flow. No custom OAuth rewrite, credential extraction or additional provider is required.
- **Model policy:** initially request Luna + Medium. Offer user-preferred Luna/Sol/Astra through actual runtime identifiers only when supported. The visible effort options are the intersection of runtime support and product policy: no Ultra; Max only for Luna. Do not infer that an account supports a model simply because the prototype lists it.
- **Selection recovery:** remember the last valid model/effort choice. When changing model, preserve effort if valid; otherwise prefer Medium if supported, else the supported default, and visibly explain the resulting choice. If there is no valid option, show unavailable state and prevent an invalid request rather than inventing support. If initial Luna is unavailable, explain and require a visible valid selection before submitting.
- **Request semantics:** snapshot model/effort when submitting a request; later control changes apply to subsequent requests, not an already running response. Preserve enough result provenance to explain which configuration produced a displayed analysis. Changing preferences alone does not change card facts or erase existing reviews.
- **Contract picker:** a 1–7 by ♣♦♥♠NT table selects the level and denomination atomically. The current selection is visible; selection closes the picker, cancellation keeps the previous value. Preserve existing declarer and other contract context; do not invent a new auction or scoring flow.
- **Inline editing:** click the desired suit row to edit ranks using the keyboard. Accept normal rank notation such as AKJ83 and 10, normalize display consistently with existing card parsing. Enter commits valid input; Escape restores the previous value. Moving focus cancels an uncommitted edit, avoiding accidental partial writes. Invalid Enter keeps the editor open with a useful explanation.
- **Unknown versus void:** empty input means unknown; an explicit dash means confirmed void, with a concise hint near editing. Maintain this distinction in session data, request preparation and reopen, rather than only styling it differently.
- **One hand editor:** the table's inline editor replaces the duplicated lower four-hand entry form. This is the synthesis of the user's chosen editing approach; the prototype's duplicate form is not a requirement to preserve. Keep unrelated context inputs such as declarer, lead and supplementary facts.
- **Validation and versioning:** use existing domain validation for duplicate known cards, valid ranks and context-appropriate counts. A failed edit must not enter confirmed state. Successful changes to cards or contract flow through existing analysis invalidation and stale-response protection; hidden information remains outside decision-time teaching.
- **Brand selection:** use the user-approved original stacked-card image as the app/logo source without blue recoloring or redesign. Keep its original palette. Do not force BC letters or additional brand storytelling into the selected image.
- **Wordmark:** use the existing approved image wordmark as a separate interface element, not a system-font approximation and not baked into the Dock icon. It may sit beside the logo if readable. The old green/red BC mark in the prototype header is historical, not the selected final image.
- **Mac identity:** visible name becomes Bridge Coup, including the app bundle display name, relevant window/menu labels and distribution documentation. Preserve stable application identifiers and data locations where possible; a cosmetic name change must not silently create a new empty library or sever existing runtime access. If a necessary change requires migration, implement and verify preservation explicitly.
- **Asset packaging:** package proper Mac icon resources derived from the chosen source, with valid small and large representations and clean transparency/edges. Generated size variants may optimize rendering but must not alter the approved composition.

## Testing Decisions

- Retain the previously approved highest practical seam: the real review workflow and its external model boundary. Test externally visible state and requests, not private view implementation or pixel-perfect snapshots of arbitrary dimensions.
- Extend settings tests to default selection, remembered settings, runtime-unavailable models, effort filtering, fallback notice and the actual submitted model/effort. Verify an in-flight request retains its captured configuration.
- Verify atomic contract choice, cancellation and dependent-result invalidation through the existing session workflow.
- Verify inline Enter/Escape, focus-change cancellation, invalid ranks, duplicated cards, unknown versus void, and correction propagation to teaching and saved review data. Retain hidden-information and stale-response regressions.
- Actual Mac acceptance must exercise keyboard focus and editing, the contract picker, settings and a real model request. A browser interaction proves only the prototype behavior.
- Open the packaged app through Finder, inspect its Dock icon and visible Bridge Coup name, and reopen an existing review to verify data continuity. Check the selected image at small sizes and the independently readable wordmark.
- Maintain the distinction between automatic checks, runtime capability verification and manual packaged acceptance. Record unsupported combinations and blocked checks instead of reporting them as passed.
- Reference prior art from the existing first-version review and integration checks during implementation. The planning session did not independently audit the current production test suite; do not invent test results or assert that all first-version tickets have passed.

## Out of Scope

- New teaching modes, bidding-system knowledge, enhanced solver algorithms or probabilistic analysis infrastructure.
- Drag-and-drop cards, rank-by-rank selection palettes, an additional duplicated hand-entry form, and a full auction editor.
- New layout directions, another broad logo exploration, or treating the old BC prototype logo as approved branding.
- Runtime authentication redesign, cloud sync, account sharing, or forcing unsupported models/effort levels.
- Repository migration, publishing the whole vault, and changing the Git boundary as part of UI work.
- Using runtime mocks, the static prototype or a new app label as evidence that the original product has passed full acceptance.

## Further Notes

- This is a planning snapshot. Publishing the spec and tickets records approved scope; it does not dispatch work or establish that implementation or acceptance is complete.
- The selected A layout and interaction direction came from the archived prototype snapshots on the separate [`archive/bridge-ui-prototype` branch](https://github.com/absurdwall/bridge-coup/tree/archive/bridge-ui-prototype/prototype). They demonstrate a visual direction only, not production runtime behavior, persistence or acceptance.
- The approved brand direction uses the original layered-card image and a separate wordmark. Ticket 04 must capture the selected source assets in durable project files and record their provenance before the build can rely on them.
- Prototype checks covered the contract table, inline editing and unknown-versus-void distinction. Teaching content was static, and real model use, solver behavior and persistence were not established by the prototype.
- This closeout publishes the planning documents and evidence without dispatching a ticket. Any later implementation must follow the user's current explicit instruction.
