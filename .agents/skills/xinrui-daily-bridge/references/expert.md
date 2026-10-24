# 调用生产做庄 Expert

配置 `bridge_repository` 为持久可用且含正式入口的 checkout；个人安装的 skill 也通过该配置找到仓库。先读该 checkout 的 `docs/bridge-external.md`，其中是完整 JSON 协议与生产限制的唯一依据。这里给出从新睿衔接的最短路径，不依赖临时 Swift 探针。

## 一次进程、一副牌

在配置的仓库内 `swift build --product bridge-external`，然后运行：

```sh
.build/debug/bridge-external --output /ABSOLUTE/OUTSIDE/REPO/board-assets/expert-run-1 --codex /ABSOLUTE/VERIFIED/CODEX
```

两条命令使用普通 shell／exec 工具。保留交互进程（例如 `exec_command` 的 `tty: true` session），通过 `write_stdin` 每次输入一行 JSON 并读回响应，不能每张牌重启。`--output` 是仓库外新的／空目录。按现有认证读取默认 auth，必要时显式 `--auth`；认证内容不复制进记录。

启动返回 `bridge-external-v1` ready 后，用 `start` 传 configuration：

- `boardID`：该副记录中生成并持久保存的 UUID。
- `contract`：实际 level、strain、declarer、doubling。
- `vulnerability`、`scoring`、`objective`：实际局况、计分和正式目标。
- `publicBackground`：实际叫牌、体系、alerts／公开解释与已知防守约定；未知写未知。
- `initialHands`：庄家、已曝光明手各 13 张初始牌，而非当前余牌。
- `events`：从首攻起已观察的完整公开牌序，从 sequence 0 开始。

字段枚举和可执行形状见仓库文档。JSON 牌码 `SA/HT/D2/CJ`，seat 为 `north/east/south/west`。如果控制者是北家，仍按实际座位传入，不把自己的手固定当南家。

## 循环

每次先收齐实际已发生的公开牌。若新睿已自动打出受控座位的唯一合法牌，直接发送（替换为本次事实）：

```json
{"op":"observe","automatic":true,"event":{"sequence":1,"seat":"north","card":"D3"}}
```

此分支不带 authorization；要求没有待执行／进行中的决策，且规则层核对当前序号、座位与唯一合法牌，返回 `source: forced`，不产生模型建议或计划。多选择与已有模型建议都不能这样确认。第一项实际 Expert 选择仍建立经 review 的计划；失败和运行时限保持原状。

轮到有待选择的庄家／明手时，发送 `{"op":"decide"}`，读 `kind: advice` 的 `value`。记录实际 action seat/card、authorization 和 source。`source: model` 带公开理由、计划及 review；`source: forced` 无模型决策，不能计作一次模型选择。

在新睿操作后确认实际牌出现，再发送：

```json
{"op":"observe","authorization":"本次返回的UUID","event":{"sequence":1,"seat":"north","card":"SA"}}
```

例子的序号／座位／牌必须替换为本次事实。对手平台事件不带 authorization，按发生顺序 `observe`。读响应确认入口已接纳，然后保存当前记录。若重复、过期、错牌或错座位被拒绝，先核对平台和 `{"op":"status"}`，不能改写实际事实凑到成功。

未执行的 advice 保持候选；只有匹配实际确认才采纳其计划。外层记录 `source: model` 为 `production-expert`，`forced` 为 `forced`，平台为 `platform`。真实 reviewer verdict 与 executionDisposition 分列；contested 授权不能抹掉 reviewer 异议。

需要检查当前状态／落盘时发送 `status`／`checkpoint`。入口自动保存 `continuation.json` 和 `decision-REVISION.json`，原始请求、公开回复、review、runtime identity、耗时在这些文件及其引用中。journal 链接它们即可，不重复建设日志，也不收集隐藏思维。

## 基本接续和停止

最新 `continuation.json` 是接续依据。先核对同副身份、公开牌序、当前墩和余牌；只有 `safeToResume: true` 可重建。最新 unsafe／失败／超时状态不能用旧文件覆盖。

新进程使用新的空证据目录，发 `resume`（不是 `start`），含 checkpointPath 及**完整逐值相同且经过牌桌核对的** checkpoint.configuration。读回 `status.reconstructed: true`，保留旧／新证据路径及新会话标记。不会恢复旧 authorization 或 thread ID；新平台实际事件随后按序输入。

单请求现有上限 180 秒；入口整副上限 1800 秒，checkpoint 保存绝对截止时间。超限／失败后保存并报告未完成，不重开来重置期限。它不是透明崩溃恢复。

Claim 拒绝／取消时保留进程和实际状态继续同副；平台确认终局后才发送 `{"op":"stop"}`。`stop` 只是停止入口，不能证明本副完成。Claim 接受分配的未打出余墩不发送为虚构 `observe`。
