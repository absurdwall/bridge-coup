# 外部牌局调用生产做庄 Expert

`bridge-external` 是与 app 无关的持续 JSON Lines 入口。它使用现有
`ExpertSession`、`CodexPlayingTransport` 和独立 `CodexReviewTransport`，
玩家与 reviewer 均保持生产 `gpt-6.1-sol / medium`，结构化协议和 ADR 0003
的五轮语义 review、四次 reviewer 技术尝试及 contested 授权规则不变。

外部调用者负责观察牌桌、提供合法可见事实、执行建议并确认实际结果。
入口只跟踪公开事实，不控制新睿，不模拟对手，不提供叫牌、防守或 claim 决策。
庄家是 controller；从明手出牌时 actingSeat 是明手，controller 仍是庄家。

## 启动与调用

从仓库目录构建一次，再在同一进程中逐行发送 JSON。不要对每张牌重启进程。

```sh
swift build --product bridge-external
.build/debug/bridge-external --output /ABSOLUTE/OUTSIDE/REPO/board-run --codex /ABSOLUTE/PATH/TO/codex
```

`--output` 必须是新的或空目录，并位于仓库外。`--codex` 使用项目当前已验证的
Codex runtime 可执行文件；可参考 `Scripts/codex-runtime-identity.sh`。
认证默认读取 `$CODEX_HOME/auth.json`，未设置时读取 `~/.codex/auth.json`；可用
`--auth /ABSOLUTE/PATH/auth.json` 指定。认证文件不放入记录或证据目录。

启动会输出 `{"ok":true,"state":"ready","protocol":"bridge-external-v1"}`。
之后 stdin 一行一个命令，stdout 一行一个响应。Computer Use 调用者可保留
`exec_command` 的交互 session 并用 `write_stdin` 逐次发送命令。
JSON 中 seat 使用 `north/east/south/west`，牌使用 `SA/HT/D2/CJ`，序号从 0 开始。

第一条 `start` 命令绑定一副：

```json
{"op":"start","configuration":{"boardID":"C703F834-5CB6-4998-A790-14586D6F026F","contract":{"level":4,"strain":"spades","declarer":"south","doubling":"undoubled"},"vulnerability":"neither","scoring":"MP","objective":"Choose a line that aims for the best expected result under the stated scoring conditions.","publicBackground":"Actual auction: N Pass, E Pass, S 1S, W Pass; N 3S, E Pass, S 4S, W Pass; N Pass, E Pass. NS simplified 2/1; EW CCBA. N 3S publicly explained as 11-12 HCP and 3+ spades. Defensive carding unknown.","initialHands":[{"seat":"north","cards":["SA","SK","S9","HK","HT","H8","D6","D5","D4","D2","C7","C3","C2"]},{"seat":"south","cards":["SQ","SJ","S8","S6","S2","HA","H3","DT","CK","CJ","CT","C8","C4"]}],"events":[{"sequence":0,"seat":"west","card":"S5"}]}}
```

这是 2026-10-24 已有实测公开局面，供局部复用；新牌必须填写实际事实和新的
boardID。`initialHands` 是庄家及已曝光明手在出牌前的各 13 张牌，不含对手暗牌。
`events` 是从首攻开始的完整真实公开牌序；若中途接入，必须能核对该历史和两手
初始牌，否则停止，不猜牌补齐。叫牌、体系及公开解释放入 `publicBackground`。
`strain` 为 `spades/hearts/diamonds/clubs/noTrump`；局况、计分和 objective 必须
明确填写，不用 IMP 默认目标替代实际 MP 背景。

## 建议 → 观察确认 → 后续决策

```json
{"op":"decide"}
```

响应 `kind: advice` 的 `value` 包含 `action`、`authorization`、`source`；模型行动
另含公开理由、计划变更、有效计划、真实 review verdict、executionDisposition、
耗时及 `decisionPath`。`source: model` 只能执行该次返回的座位与牌。
`executionDisposition: contested` 是既有有界执行政策的授权，不是 reviewer approve。

先操作牌桌，再重新观察确实打出了对应牌，才能发送（替换授权 UUID）：

```json
{"op":"observe","authorization":"RETURNED-UUID","event":{"sequence":1,"seat":"north","card":"SA"}}
{"op":"observe","event":{"sequence":2,"seat":"east","card":"S3"}}
{"op":"decide"}
```

`observe` 的 controller 行动必须匹配当前待执行建议和授权。点击、动画或建议本身
均不算实际事件。重复确认、旧序号、旧授权、错牌或错座位被拒绝，不推进状态。
平台对手行动无需授权，响应标记 `source: opponent`；本入口不代其选择牌。
若平台一次产生多张真实牌，按顺序逐张输入，不把未观察到的牌补入。

平台可能在调用者请求建议前，已自动打出庄家或明手的唯一合法牌。观察确认后可直接发送：

```json
{"op":"observe","automatic":true,"event":{"sequence":1,"seat":"north","card":"D3"}}
```

序号／座位／牌必须替换为当前真实事件。这条路径要求没有待执行建议或正在调用的
决策，不带 authorization，且该牌在当前受控座位恰为唯一合法牌；返回
`source: forced`，不生成建议、不调用模型、不建立计划。错序、重复、多选择、
平台对手或已有待执行模型建议不能使用它。先按序接纳此前已发生的真实事件，
不能为凑成强制出牌而跳过牌序或补造事实。

首次实际 Expert 决策仍须经过 review 并建立计划。其后若只有一张合法牌，`decide`
仍可返回 `source: forced`，无模型决策记录，观察后带该次授权确认。此手动授权路径
保留；已有模型建议不能改记为自动强制行动。所有有选择的庄家与明手常规行动继续
通过生产 Expert，外层不得替换不满意的牌。两条 forced 路径都遵守原会话失败和运行限额。

```json
{"op":"status"}
{"op":"checkpoint"}
{"op":"stop"}
```

`status` 返回真实事件、当前 actingSeat、可用时的规则快照、已确认 activePlan、
待执行授权、是否为重建会话和 stopped。建议尚未确认时不采纳其计划。
`stop` 只结束本调用进程，不将真实牌局声明为完成，也不生成 claim 分配的虚构牌序。
claim 接受后的结果由 skill 记录；入口只保存实际打出的牌。

## 记录与基本接续

每次实际状态变化自动原子保存 `continuation.json`，模型建议保存
`decision-REVISION.json`。后者复用既有 DecisionRecord，包含公开请求／回复、review
轮次、runtime identity、耗时和 RequestEvidence；transport 的原始证据位于 `player/`、
`reviewer/` 和 `objects/`。失败时另保存 `request-evidence.json`。不收集隐藏思维。
记录模板及中文打牌／流程总结属于调用 skill，不是本入口的新日志产品。

正常同副持续用原进程，不调用 `start` 重置。需要新会话时：

1. 读回最新 `continuation.json`，核对赛事、牌号、实际公开牌序及当前两手余牌。
2. 只在 `safeToResume: true` 且与实际牌桌一致时重建。未确认建议、正在调用或失败后
   文件标为 false，不能重建来绕过 review／失败。不要退回更早的 safe 文件。
3. 启动新的空证据目录，以 `resume` 代替 `start`；`configuration` 必须逐值等于
   checkpoint 中的 configuration，并代表核对后的同一副。

```json
{"op":"resume","checkpointPath":"/ABSOLUTE/previous-run/continuation.json","configuration":{"...":"copy the complete reconciled checkpoint.configuration here"}}
```

上例 configuration 为说明占位，发送时必须替换完整对象。恢复的是公开历史与已确认
计划，`status.reconstructed: true` 明确标记新会话；不会恢复 thread ID、旧点击或授权。
随后新观察到的平台事件通过 `observe` 输入。若牌桌与记录不同且不能逐项核对，保留
材料并报告未完成。入口不提供透明恢复、自动回滚、忽略失败或重发旧点击。

单次请求沿用最多 180 秒；整副入口保留 1800 秒自动运行上限，绝对截止时间随
checkpoint 保存，新会话不能重置它。超限或 Expert 失败后 `stopped: true`，继续保留
已有事实及证据；不得反复重启规避限额。已确认而尚未请求下一决策的安全边界才支持
基本接续；不承诺恢复执行／保存之间崩溃的所有情况。

## 可引用的现有证据与局部验证

原实测记录及完整请求、review、runtime、耗时资料保存在仓库外：

- `/Users/tingranwang/Documents/bridge-session-2026-10-24-0007.md`
- `/Users/tingranwang/Documents/bridge-session-2026-10-24-0007-assets/decision-1.json`
- 同目录 `decision-3.json`、`commit-2.json`、`public-ledger.json`、`player/`、`reviewer/`。

这些是已有探索的生产调用证据，不是本正式入口的新实战验收，也不证明棋力。
`Tests/BridgePlayingTests/ExternalBoardTests.swift` 从正式 session 接口检查建议、实际
确认、后续快照和公开计划重建；外部模型边界复用录制回复。原有
`SnapshotInputTests`、`ReviewedDecisionTests`、`ReviewRecoveryTests` 继续覆盖结构化
协议、review 与技术恢复。新增入口无需另开整副或真实中断测试。
