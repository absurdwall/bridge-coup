# 每日任务配置

本任务使用 Codex 桌面端正规 schedule task。用户选择：**每天 09:00，America/New_York**。平台赛事日期仍从新睿读取。每次调用本 skill，只处理一副，完成后返回结果和中文记录链接。日程不负责唤醒、解锁或登录。

当前部署配置如下，来自本轮保存的实际日程配置；日常执行读取此配置，不另建 schedule。当前仍为 PAUSED，等待最终验收及启用；创建配置不等于已激活或已完成工程交付。

| 设置 | 值 |
|---|---|
| 时间 | 每天 09:00 America/New_York |
| skill | `/Users/tingranwang/.codex/worktrees/daily-bridge-integration/bridge-coup/.agents/skills/xinrui-daily-bridge/SKILL.md` |
| bridge_repository | `/Users/tingranwang/.codex/worktrees/daily-bridge-integration/bridge-coup` |
| codex_runtime | `/Users/tingranwang/.nvm/versions/node/v24.12.0/bin/codex`；本轮读回 0.160.0，沿用生产模型配置 |
| records | `/Users/tingranwang/Documents/xinrui-daily-bridge/` |
| task id／状态 | `automation`／PAUSED；名称“新睿每日单副” |
| 类型／目标聊天 | thread heartbeat／`01a16c74-47e8-7bb1-988e-7a91adee00f3` |
| 配置证据 | `/Users/tingranwang/Documents/bridge-daily-implementation-2026-10-24/schedule-config.md` |
| 正规任务读回 | `/Users/tingranwang/.codex/automations/automation/automation.toml` |

integration checkout 在 PR #60 等待用户批准合入期间保留，作为当前部署路径。合并或清理前，先更新正规日程与此处路径、核对能运行同一 skill／入口，再归档部署 checkout。缺少 checkout／runtime 时保存并报告配置缺失。后续启用或路径变化以正规任务的新读回同步状态。

需要更新正规任务时，可用以下自然语言作为 prompt 主体，填入上表实际路径；现有任务优先更新：

> 使用 $xinrui-daily-bridge（绝对路径 SKILL.md）运行一次每日单副任务。Bridge Coup checkout：实际绝对路径；Codex runtime：实际绝对路径；记录目录：实际绝对路径。按 skill 检查已有记录与平台同一赛事牌号，优先接续未完成牌；本赛事每日单副已完成或另一运行仍在操作时不再开牌。使用正式 bridge-external 入口；叫牌、防守、claim 和总结保持外层真实归因。以新睿显示的赛事日期为准，完成后停止，不开启下一副。遇到无法核对、登录／桌面条件不足或生产调用失败时保存现场并报告未完成。完成、失败或需要用户行动时返回简短状态与可打开的中文记录链接；状态未变化且无可行动事项时保持安静。

启用前把 skill 及随附 references/assets 放在持久且可发现的位置，核对 prompt 指向的同一版本和正式入口。已有日程优先更新，避免重复；配置／修改日程需有用户授权。只使用桌面端提供的正规 automation 工具，不生成自建 cron、守护进程或额外调度产品。

工程验收只安排最终一次完整真实单副，使用此同一 skill／入口；无需再开一副验证定时触发。若最终副为防守或全 pass，明确 Expert 未在该副触发，只允许用已有做庄公开局面补一次局部真实调用。不为抽中角色另开完整副。半小时左右是当前体验预期，不能为赶时间强制 claim。
