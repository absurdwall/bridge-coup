# Bridge Coup 视觉修复与下一轮队列

## 本轮关闭

票 01–03 的修复与验收已完成；票 04 是只读整合视觉复核，已完成并回传规划任务。票 04 没有授权或执行应用修复。

| Ticket | 状态 | 结果 |
| --- | --- | --- |
| [01 · 紧凑牌桌录牌与修正](issues/01-compact-table.md) | complete | 完成紧凑 A 版牌桌与原位编辑 |
| [02 · 首屏复盘工作区](issues/02-first-screen-workspace.md) | complete | 完成牌桌、教学区与空状态布局 |
| [03 · 轻量顶栏](issues/03-lightweight-header.md) | complete | 完成复盘操作与模型设置入口 |
| [04 · 整合构建视觉复核](issues/04-returned-visual-review.md) | complete | 复核结论为“基本一致有偏差”；见[可公开摘要](evidence/visual-review-2026-09-26/PUBLIC-SUMMARY.md) |

验收记录：[紧凑牌桌](evidence/compact-table-acceptance.md)、[首屏工作区](evidence/first-screen-workspace-acceptance.md)、[轻量顶栏](evidence/lightweight-header-acceptance.md)。配套 synthetic/prototype 截图保存在同目录及其子目录。

完整的本机视觉复核记录含有已保存复盘的私人内容，不属于公开同步范围；与已保存复盘状态相关或无法确认状态的截图也不公开。公开摘要不包含其牌面、分析文本或截图。最新安装核验的非敏感记录见[安装摘要](evidence/installed-app-setup-2026-09-26/INSTALLATION-SUMMARY.md)。

## 用户批准的后续队列（2026-09-26）

用户按 to-tickets 流程确认并修正了下列拆分；随后按票实施并记录验收结果。以下为当前状态。

| Ticket | 状态 | Blocked by | 范围 |
| --- | --- | --- | --- |
| [02 · 定约表格直接点选并接入当前复盘](../bridge-coup-refinement/issues/02-contract-grid.md) | complete | None | 复用原精修票，恢复完整一屏叫品表与单次定约选择 |
| [05 · 将已保存分析渲染为易读 Markdown](issues/05-render-saved-analysis-markdown.md) | complete | None | 修复已保存教学内容的 Markdown 显示 |
| [07 · 验收较窄窗口下的实际安装包](issues/07-narrow-window-acceptance.md) | partial | None | 官方 Release 包直接验证 1320、1180、1101 pt；隔离 synthetic 副本实测 90 pt 拖动下限并记录可见裁切。历史 pre-install Save 的会话来源未核实；本票仅报告，不修布局 |
| [08 · 核对 GPT-6 模型目录与显式选择](issues/08-runtime-model-catalog.md) | complete | None | 已记录当前安装 runtime 目录、GPT-5.6 相似项过滤、显式选择及重启恢复 |

票 02 沿用已存在的 refinement issue 02，没有另建定约票。当前四张可执行票（02、05、07、08）均无阻塞依赖。

票 06 已移除；本队列没有 09 或 10 号票据。

2026-09-26 最终实施/验收状态以各票、[较窄窗口验收报告](evidence/narrow-window-acceptance-2026-09-26.md)及[安装 runtime 目录记录](evidence/08-runtime-model-catalog-live-2026-09-26.md)为准。官方包已备份并更新至当前 Release；替换前原 app 执行过 Save，但当时活动会话的 fixture 来源未核实，这是 issue 07 保持 partial 的原因。窗口检查后恢复原几何尺寸，官方包以唯一运行实例保留。

花色颜色与首攻修正暂记为未定界需求，须先进行 grill 讨论；目前没有对应的实现票。未来设计备忘录仅记录已确认的设计讨论方向：让拍卖序列以牌桌为中心呈现，以及将双明手核验移到界面角落。
