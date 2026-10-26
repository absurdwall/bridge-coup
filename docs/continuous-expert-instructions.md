# 连续 Expert 指令与例子检查入口

本页用于 Spec #61 的逐份 instruction／逐例检查。实现与基础自主检查、后续用户与助手联合人工验收分别记录；模型建议合法、review approve 或回归通过，都不表示用户已认可全部指导或证明广泛棋力。

## 先读实际装配

连续入口为 `bridge-external-v3 / continuous-board-v7`，协议见 [外部调用](bridge-external.md)。同一玩家 thread 的基础指令为 PlayerCommon；每次 turn 的 `phase/currentPhaseGuidance` 指定当前任务。历史指导保留在会话中，但当前请求不拼入全部角色的完整内容。每个候选 reviewer 使用独立新 thread。

| 检查对象 | 单一源文件 | 生效位置 |
|---|---|---|
| 共用玩家原则 | [PlayerCommon](../Sources/BridgeExpert/Instructions/PlayerCommon.txt) | 玩家 thread/start 基础指令 |
| 叫牌与解释请求 | [Bidding](../Sources/BridgeExpert/Instructions/Bidding.txt) | bidding 当前 turn 的 currentPhaseGuidance |
| 做庄策略原文 | [Declarer](../Sources/BridgeExpert/Instructions/Declarer.txt) | declarer 当前指导，另有下述协议适配 |
| 首攻／普通防守 | [Defense](../Sources/BridgeExpert/Instructions/Defense.txt) | openingLead、defense 当前指导 |
| 共用证据／verdict 标准 | [ReviewCommon](../Sources/BridgeExpert/Instructions/ReviewCommon.txt) | 每次独立 reviewer 的基础指令 |
| 叫牌检查 | [ReviewBidding](../Sources/BridgeExpert/Instructions/ReviewBidding.txt) | 共用 review 标准之后 |
| 做庄检查原文 | [ReviewDeclarer](../Sources/BridgeExpert/Instructions/ReviewDeclarer.txt) | 共用 review 标准之后，另有协议适配 |
| 首攻／防守检查 | [ReviewDefense](../Sources/BridgeExpert/Instructions/ReviewDefense.txt) | 共用 review 标准之后 |

[PlayerInstructions 装配代码](../Sources/BridgeExpert/ContinuousExpert.swift) 中的 `phase(.declarer)` 和 `review(.declarer)` 还分别附加 **CURRENT CONTINUOUS PROTOCOL ADAPTER** 与 **CURRENT CONTINUOUS REVIEW PROTOCOL ADAPTER**。它们也是有效指令，须一起检查：把原 v5 的 selectedCard、座位／手牌结构、current/effectivePlan 等引用映射到当前格式。原做庄策略和原 reviewer 正文迁移保留；适配不表示策略获得了新的广泛质量证明。旧 v1/v5 调用仍使用其原字段语义。

当前源码通过公开 `PlayerInstructions.common/phase/review` 导出的完整阅读快照位于本机仓库外：

[完整当前指令阅读快照](/Users/tingranwang/Documents/bridge-spec61-implementation-2026-10-25/ticket64/effective-instructions/READ-ME.md)

该快照逐项包含共用玩家文本、四个阶段的当前指导、四个阶段完整 reviewer 指令和做庄适配原文；manifest 记录源 commit 与文件摘要。它是源码装配阅读材料，不冒充某次网络请求。修改指令后重新导出，并以实际请求证据核对。

实际装配证据应从 decision.requestEvidence 与 player/rpc.jsonl 读：核对 thread/start 的 instructions、各 turn/start 的 phase/currentPhaseGuidance、授权 snapshot、动态合法行动 schema、公开返回，以及独立 review 的相同资料。计划／推断与程序接纳的事实分开；隐藏思维不收集。

## 代表例子与证据边界

私人材料均在仓库外；以下本机路径与源截图供实际阅读，不复制附件入 Git。

| 例子 | 阅读入口 | 实际覆盖与限制 |
|---|---|---|
| 同 thread 叫牌 P → 首攻 S5 → 防守 D2 | [叫牌／打牌生产样例](/Users/tingranwang/Documents/bridge-spec61-implementation-2026-10-25/ticket62/acceptance.md) | 新鲜生产玩家／reviewer 使用历史授权事实，三次 review-approved；首攻前无明手，随后实际回放曝光。v6 历史请求；未操作新睿，最后 D2 未执行 |
| 对家做庄 D2 | 同目录 acceptance.md、declarer-transcript.jsonl、production-partner-declarer/ | 新鲜生产调用与独立 approve；历史首攻后公开局面，v6 协议适配。不是新完成实战 |
| 中文 2C 解释 → 建议／review → 旋转查询 | [2C 解释与生产判断样例](/Users/tingranwang/Documents/bridge-spec61-implementation-2026-10-25/ticket63/acceptance.md) | 当前 v7 真实生产调用；调用者 inspectCalls 发起核对，原中文进入玩家及 reviewer。模型主动请求分支由录制回复检查；没有实际叫品提交 |
| 中文 3NT 预览回传 → 新进程离线查询 | [3NT 预览回传与离线读回](/Users/tingranwang/Documents/bridge-spec61-implementation-2026-10-25/ticket64/acceptance.md) | 当前正式 CLI 的历史截图 provider 回放；空库正常、牌局未推进、无执行授权、最终决定前 checkpoint unsafe、重开库后旋转精确命中。未新增模型或现场 UI 调用 |

历史 2C／3NT 图来自 NS **简易二盖一**、EW CCBA 桌面，保留原标签；源日期为 2026-10-25，确切截图观察时刻与 app 版本未知。不能改标为当前 CCBA，不能把提示显示过当成该解释必然适用。原赛事已结束，后续检查没有另开替代牌。

每个例子应一起看决策时事实、来源、有效指导、schema、候选／公开理由／计划、真实 reviewer verdict、executionDisposition，以及是否有匹配的实际确认。合理替代可以并存；记录问题和预期，不以重问直到出现偏好行动代替检查。

## 状态与后续联合检查

基础自主检查聚焦可用性、合法性、视角、资料往返及没有已确认的明显实质错误。它不要求唯一最优、全竞叫树、高级信号或新的多副棋力矩阵。现场预览和新赛中全角色使用尚未由本轮回放证明；下一次正常使用继续按 skill 收集真实证据。

联合人工验收保持**待做**：用户与助手逐份读上述全部有效文本，再逐例讨论指导是否合理、预期应怎样、实际建议／review 是否合理。实际部署 commit、构建及现有任务切换以 `/Users/tingranwang/Documents/bridge-spec61-implementation-2026-10-25/deployment.md` 的读回为准；PR／源码或本页本身不证明已切换，更不替代用户批准合并。
