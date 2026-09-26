# 05: 将已保存分析渲染为易读 Markdown

**What to build:** 在教学区把已保存分析中的 Markdown 标记呈现为可读内容，同时保留原始分析文本和复盘数据，不用重新生成或改写分析。

**Blocked by:** None

**Status:** open

**Priority:** P1

- [ ] 以当前已保存分析视图作为问题入口；验收数据用 synthetic fixture，不复制或公开本机复盘内容。
- [ ] 正确显示常用标题、段落、强调、列表、行内代码和表格；正文不再露出格式标记或表格分隔符。
- [ ] 长分析可滚动阅读，牌桌及教学区关系保持稳定；窄幅下表格不把窗口撑出边界。
- [ ] 纯文本、缺少 Markdown 和不完整列表/表格仍可读；渲染不修改存档原文或触发模型请求。
- [ ] 保存 screenshot / regression evidence 时只使用 synthetic fixture，并检查安装包中的实际展示。

## Context

票 04 的只读复核确认已有分析视图会直接显示 Markdown 格式符号。原始已保存复盘的正文与对应截图不纳入公开材料。
