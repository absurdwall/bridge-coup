# 每日任务配置

沿用现有 Codex 正规任务：**每天 09:00，America/New_York，每次一副**。平台赛事日期从新睿读取；日程不负责唤醒、解锁或登录。先读下列部署读回，再调用同一版本 skill／入口；不创建重复任务。

| 设置 | 持久路径／身份 |
|---|---|
| skill | `/Users/tingranwang/.codex/worktrees/daily-bridge-integration/bridge-coup/.agents/skills/xinrui-daily-bridge/SKILL.md` |
| bridge_repository | `/Users/tingranwang/.codex/worktrees/daily-bridge-integration/bridge-coup` |
| codex_runtime | `/Users/tingranwang/.nvm/versions/node/v24.12.0/bin/codex`；实际版本从本次入口 identity 记录 |
| records | `/Users/tingranwang/Documents/xinrui-daily-bridge/` |
| 解释观察库 | 启动 ready 的 observationStore；默认 `~/Library/Application Support/BridgeCoup/explanation-observations.sqlite` |
| task id／名称 | `automation`／“新睿每日单副” |
| 类型／目标聊天 | thread heartbeat／`01a16c74-47e8-7bb1-988e-7a91adee00f3` |
| 当前部署与构建读回 | `/Users/tingranwang/Documents/bridge-spec61-implementation-2026-10-25/deployment.md` |
| 正规任务读回 | `/Users/tingranwang/.codex/automations/automation/automation.toml` |

部署记录保存实际 checkout commit、构建与协议、原／新任务 prompt 及工具读回。可变状态以该记录和正规任务读回为准；本文件不把待切换分支、测试通过或 PR 状态当成实际部署。旧版配置证据仍在 `/Users/tingranwang/Documents/bridge-daily-implementation-2026-10-24/schedule-config.md`，用于历史核对。

新副使用 `bridge-external-v3 / continuous-board-v7`：叫牌、首攻、做庄和防守由生产 Expert；外层收集事实、服务解释预览、执行并确认授权行动，负责 claim 与两类总结。旧 v1 未完成记录保持真实语义，先按同副接续规则核对，不能假造早期叫牌／玩家连续性。缺少 checkout／runtime／部署核对或桌面条件时保存并报告未完成。

更新部署时复用该持久 checkout，先验证新版本和资料往返，再切换现有任务，读回同一 skill／入口版本后才视为完成；旧版本及配置证据保留到切换完成。只用桌面端正规 automation 工具更新原任务，保留原名称、目标、每天 09:00 America/New_York、状态及通知偏好。Spec #61 已授权本轮切换；其他日程改动遵循用户授权。

任务 prompt 应指向上表绝对路径，并要求：核对已有记录与平台同一赛事牌号，优先接续原副；每日单副已完成或另一运行仍操作时不再开牌；所有已支持常规选择走同一生产入口；按需解释预览不提交，最终授权后操作并观察确认；资料缺失／失败保留原副和原因，不由外层代打冒充成功。以新睿赛事日期为准，完成后停止并退出，不开启下一副。完成、失败或需要用户行动时返回简短状态和中文记录链接；状态未变化且无可行动事项时保持安静。

本轮自主检查使用已有公开局面、录制回复和少量真实生产调用，预览材料回放与新现场操作分别报告。不另设定时触发、真实宕机、多副／无 claim 或全角色实战门槛。全部有效指令与代表例子见 checkout 的 `docs/continuous-expert-instructions.md`；联合逐份、逐例人工验收待用户与助手共同完成。
