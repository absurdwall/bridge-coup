# 08: 诊断运行时模型目录并验证选择

**What to build:** 在受支持的 Codex runtime 上查明 app 当前模型目录中 Luna/Sol 不可用的原因，并验证 app 是否正确展示、选择和持久化 runtime 实际提供的模型。

**Blocked by:** 需要可用于验收的 `codex-cli 0.156.1+` runtime

**Status:** open

**Priority:** P2

- [ ] 记录安装包版本、runtime 版本及 runtime 原始模型目录；区分 runtime 未提供与 app 过滤/映射错误。
- [ ] 若 runtime 提供 Luna 或 Sol，确认设置面板显示匹配的 effort，选择后可以提交并在重新打开时保持偏好。
- [ ] 若 runtime 未提供某模型，保留不可用状态并记录证据；不得伪造模型选项或发起无授权的模型请求。
- [ ] 用空白 synthetic review 完成 app 级手工检查；不读取或截图私人复盘内容。
