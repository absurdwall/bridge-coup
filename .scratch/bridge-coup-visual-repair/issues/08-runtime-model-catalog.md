# 08: 核对 GPT-6 模型目录与显式选择

**What to build:** 在 Bridge Coup 设置中只识别运行时实际提供的 GPT-6 Astra、Luna、Sol 模型，并让默认值、可用性提示和显式选择遵守用户确认的模型规则。

**Blocked by:** None (can start immediately)

**Status:** complete

**Priority:** P2

- [x] 记录最终安装包版本、runtime 版本及原始模型目录；区分 runtime 未提供与 app 侧过滤或匹配错误。
- [x] 只接受 GPT-6 Astra、Luna、Sol 标识；排除 GPT-5.6 模型，即使其标识包含 Luna、Sol 或 Astra。
- [x] Luna · Medium 可用时首次默认选择它。Luna 不可用时说明原因，要求用户显式选择当前可用的 GPT-6 模型；不得静默切换到 Astra。若没有可用的 GPT-6 选择，阻止提交并说明原因。
- [x] 思考深度限于 runtime 支持与产品规则的交集：不提供 Ultra，Max 仅用于 Luna。只保存仍有效的显式选择；恢复时重新核对当前可用性。
- [x] 检查设置面板的实时可用状态、显式选择、模型与 effort 偏好恢复，以及 recording-fake 测试中的模型标识/effort 请求字段；不发送实际教学请求、不打开保存的复盘。
- [x] 留存最终安装包、app/runtime 版本和可用性证据；将 GPT-5.6 相似标识与 runtime 未提供的模型区分。

## Context

现有安装摘要记录 codex-cli 0.156.1 报告 Astra 可用、Luna 和 Sol 未出现，但没有留存原始目录。该记录不证明其他 runtime 上的可用性。

## Approval

2026-09-26：用户确认本票仅覆盖 GPT-6 Astra/Luna/Sol、Luna · Medium 默认、Max 仅 Luna、排除 Ultra、显式选择及运行时可用性核对。本次没有发起模型请求。

## Historical Release-build status before installed follow-up — 2026-09-26

- Catalog filtering, policy-limited efforts, Luna · Medium defaulting, preference revalidation, and request-field tests passed in focused regression runs. The historical `codex-cli 0.156.1` catalog was captured from the previous installed executable, SHA `278696e…`; it is not the final installed-build record.
- The final Release QA copy used a unique sandbox container and showed “no Codex runtime”; Luna, Sol, and Astra were all disabled and plan submission was blocked. That verifies the no-runtime safety state but cannot verify current runtime availability, selection, or preference restore in this build.
- The official app process was still running from the older executable, so it was not closed or replaced. At that time the ticket remained partial until the final build could be checked with the installed runtime. See [narrow-window acceptance](../evidence/narrow-window-acceptance-2026-09-26.md).

## Final installed-app follow-up — 2026-09-26

The official installed Release build was subsequently verified against the configured runtime. The current sanitized raw `model/list` page and the installed-app selection/restore evidence are recorded in [the live catalog record](../evidence/08-runtime-model-catalog-live-2026-09-26.md) and [its model-only JSON](../evidence/08-runtime-model-catalog-live-2026-09-26.json). The earlier QA no-runtime note above remains historical evidence and is not presented as the final installed-app result.

After those checks, the user requested Luna · Medium as the final installed-app selection. It was selected and remained visible after a graceful relaunch; the final preference is recorded in the live catalog report.
