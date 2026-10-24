# 每日任务配置

本任务使用 Codex 桌面端正规 schedule task。用户选择：**每天 09:00，America/New_York**。平台赛事日期仍从新睿读取。每次调用本 skill，只处理一副，完成后返回结果和中文记录链接。日程不负责唤醒、解锁或登录。

启用者在实际 schedule prompt 中填写并保存以下配置；若缺少 checkout／runtime，就先报告配置缺失，避免从已删除的实现 worktree 运行。日常执行读取配置，不另建 schedule。

| 设置 | 值 |
|---|---|
| 时间 | 每天 09:00 America/New_York |
| skill | `xinrui-daily-bridge`；prompt 中写已部署 `SKILL.md` 的绝对路径 |
| bridge_repository | 部署时填写持久 Bridge Coup checkout 的绝对路径，需包含 `bridge-external` |
| codex_runtime | 部署时填写当前已验证的 Codex executable 绝对路径；沿用生产配置 |
| records | 默认 `~/Documents/xinrui-daily-bridge/`，或用户指定的仓库外目录 |
| task id／状态 | 由启用者在正规 schedule 创建成功后记录实际返回值；创建配置本身不是打牌验收 |

可以用以下自然语言作为正规任务 prompt 的主体，替换路径后提交：

> 使用 $xinrui-daily-bridge（绝对路径 SKILL.md）运行一次每日单副任务。Bridge Coup checkout：实际绝对路径；Codex runtime：实际绝对路径；记录目录：实际绝对路径。按 skill 检查已有记录与平台同一赛事牌号，优先接续未完成牌；本赛事每日单副已完成或另一运行仍在操作时不再开牌。使用正式 bridge-external 入口；叫牌、防守、claim 和总结保持外层真实归因。以新睿显示的赛事日期为准，完成后停止，不开启下一副。遇到无法核对、登录／桌面条件不足或生产调用失败时保存现场并报告未完成。完成、失败或需要用户行动时返回简短状态与可打开的中文记录链接；状态未变化且无可行动事项时保持安静。

启用前把 skill 及随附 references/assets 放在持久且可发现的位置，核对 prompt 指向的同一版本和正式入口。已有日程优先更新，避免重复；配置／修改日程需有用户授权。只使用桌面端提供的正规 automation 工具，不生成自建 cron、守护进程或额外调度产品。

工程验收只安排最终一次完整真实单副，使用此同一 skill／入口；无需再开一副验证定时触发。若最终副为防守或全 pass，明确 Expert 未在该副触发，只允许用已有做庄公开局面补一次局部真实调用。不为抽中角色另开完整副。半小时左右是当前体验预期，不能为赶时间强制 claim。
