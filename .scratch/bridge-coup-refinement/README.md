# Bridge Coup 精修：已批准的 Tickets

用户已确认五张 tickets 的粒度和依赖，并授权在新的 GPT-6 Luna / Max 任务中仅启动 01。其余 tickets 只发布，不自动派发。父级 [Spec](spec.md) 保留发布时状态；本索引记录后续拆分批准。

| Ticket | Blocked by |
| --- | --- |
| [01 · 模型与 effort 选择、保存偏好并用于真实请求](issues/01-model-effort-settings.md) | 无 |
| [02 · 定约表格直接点选并接入当前复盘](issues/02-contract-grid.md) | 无 |
| [03 · A 版牌桌原位键盘编辑](issues/03-inline-table-editing.md) | 无 |
| [04 · Bridge Coup 名称、选定图标与独立字标落地](issues/04-brand-name-icon.md) | 无 |
| [05 · 整体视觉精修与实际 Mac 验收](issues/05-visual-packaged-acceptance.md) | 01, 02, 03, 04 |

各 ticket 均为 ready-for-agent，不代表已完成；05 等待 01–04 的实际改动整合到同一验收 checkout。派发只需 /implement 加 ticket 绝对路径；细节以各 ticket 和父级 spec 为准。

## 后续重开记录（2026-09-26）

用户再次批准复用并重开 issue 02，以恢复单次选择完整定约的一屏叫品表。原编号与原有范围继续有效；本次票据整理未开始实现。其范围和批准记录见 [issue 02](issues/02-contract-grid.md)。

## 实施状态更新（2026-09-26）

Issue 02 已完成；最终 Release-build 的合成复盘交互、取消、键盘确认与过期分析状态均已核验，回归测试通过。证据见 [issue 02](issues/02-contract-grid.md) 和[较窄窗口验收报告](../bridge-coup-visual-repair/evidence/narrow-window-acceptance-2026-09-26.md)。该状态更新仅覆盖 issue 02，不改变其余票据。

## 本次 closeout 派发状态（2026-09-26）

本次只整理并发布已经批准的规格与证据，没有派发任何 refinement ticket。历史派发记录保留在上文；后续实施须遵循用户当下明确指令。
