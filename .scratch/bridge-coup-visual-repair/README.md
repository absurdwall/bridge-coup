# Bridge Coup 视觉修复与下一轮队列

## 本轮关闭

票 01–03 的修复与验收已完成；票 04 是只读整合视觉复核，已完成并回传规划任务。票 04 没有授权或执行应用修复。

| Ticket | 状态 | 结果 |
| --- | --- | --- |
| [01 · 紧凑牌桌录牌与修正](issues/01-compact-table.md) | complete | 完成紧凑 A 版牌桌与原位编辑 |
| [02 · 首屏复盘工作区](issues/02-first-screen-workspace.md) | complete | 完成牌桌、教学区与空状态布局 |
| [03 · 轻量顶栏](issues/03-lightweight-header.md) | complete | 完成复盘操作与模型设置入口 |
| [04 · 整合构建视觉复核](issues/04-returned-visual-review.md) | complete | 复核结论为“基本一致有偏差”；见[可公开摘要](evidence/visual-review-2026-09-26/PUBLIC-SUMMARY.md) |

验收记录： [紧凑牌桌](evidence/compact-table-acceptance.md)、[首屏工作区](evidence/first-screen-workspace-acceptance.md)、[轻量顶栏](evidence/lightweight-header-acceptance.md)。配套 synthetic/prototype 截图保存在同目录及其子目录。

完整的本机视觉复核记录含有已保存复盘的私人内容，不属于公开同步范围；与已保存复盘状态相关或无法确认状态的截图也不公开。公开摘要不包含其牌面、分析文本或截图。最新安装核验的非敏感记录见 [安装摘要](evidence/installed-app-setup-2026-09-26/INSTALLATION-SUMMARY.md)。

## 下一轮：保持 open，尚未实施

| Ticket | 状态 | 范围 |
| --- | --- | --- |
| [05 · 将已保存分析渲染为易读 Markdown](issues/05-render-saved-analysis-markdown.md) | open | 处理标题、列表、强调、表格和长内容布局 |
| [06 · 校准 app 牌桌与 A 原型的尺寸差异](issues/06-align-table-scale.md) | open | 在保持牌面清晰与可读的前提下缩小可见差距 |
| [07 · 验收较窄窗口下的实际安装包](issues/07-narrow-window-acceptance.md) | open | 对安装包做可复现的窗口宽度验收；是否需要修复由证据决定 |
| [08 · 诊断运行时模型目录并验证选择](issues/08-runtime-model-catalog.md) | open | 查明 Luna/Sol 缺失来自运行时能力还是 app 侧目录/选择流程 |

本轮只做 closeout、记录队列并同步安全文档与代码；05–08 均未开始实现。
