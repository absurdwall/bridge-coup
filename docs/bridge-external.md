# 外部牌局连续调用生产 Expert

`bridge-external` 是现有正式 JSON Lines 入口。v3 增加按需解释往返与本地观察库；v2 增加从叫牌开始的同副连续流程，
保留 v1 做庄 `configuration` 的原义。两种配置不能在同一进程混用。
生产玩家与独立 reviewer 仍为 `gpt-6.1-sol / medium`；最多五轮语义 review、
每轮 reviewer 初次失败后最多三次技术重试。技术耗尽停止；关键事实不明的
`uncertain` 保留原始 review 并停止请求澄清，不作为 contested 行动执行。

## 连续流程（v3 / continuous-board-v7）

构建和启动方式见下方“启动与调用”；保持 stdin 和进程打开。ready 输出协议
`bridge-external-v3`，`supportedProtocols` 列出保留的 v1/v2 输入。使用 `continuousConfiguration` 启动；所有数组显式填写，
`confirmedContract` 未确认时省略。下面是合成结构示例，实际使用替换为本副已核实事实：

```json
{"op":"start","continuousConfiguration":{"boardID":"C703F834-5CB6-4998-A790-14586D6F026F","userSeat":"north","dealer":"north","vulnerability":"neither","scoring":"MP","objective":"Best expected MP result","agreements":"实际确认的双方体系及约定；未知项明确未知","initialHand":{"seat":"north","cards":["SA","SK","SQ","SJ","ST","S9","S8","S7","S6","S5","S4","S3","S2"]},"auction":[],"events":[],"revealedHands":[]}}
{"op":"decide"}
```

`initialHand` 只包含用户本手十三张；`auction` 是从发牌人开始的完整实际叫牌，
`P/X/XX` 表示 pass/double/redouble，普通叫品为 `1C` 至 `7NT`。
程序计算当前合法叫品、结束、倍数和首次叫出最终花色的一方庄家。
全 pass 的 `phase: finished` 正常结束，不创建定约或出牌快照。

`decide` 返回 `kind: advice` 时包含 `authorization`、`snapshotID`、`actingSeat`、`selectedAction`、
真实 `source` 及模型 `decision`（候选、有效计划、各轮独立 review、执行授权来源和
完整 RequestEvidence）。建议不推进事实；操作后核实真实对应行动再确认：

```json
{"op":"observeCall","authorization":"RETURNED-UUID","callEvent":{"sequence":0,"seat":"north","call":"1S"}}
{"op":"observeCall","callEvent":{"sequence":1,"seat":"east","call":"P"}}
```

用户叫牌只能确认精确待执行候选；其他牌手行动作为平台事实输入，不需授权。

### 实际叫品的公开解释

观察搭档、对手或自己的实际叫品时，先收集该叫品已公开的 alert／解释，再发送
`observeCall`。可选 `callDisclosure` 使用下文的 `ExplanationResult` 结构，
`provider: environment`、`candidate` 必须是这次实际叫品；完整复制接纳该事件前
`status.explanationContext`（包括前序 auction、行动者、发牌人、双方体系和条件）。
它不需要先请求自己的候选解释，也不会重置玩家 thread。

取得原文时使用 `status: found`，references 放一至五条 exact 观察，保留中文、
来源、真实时间／未知版本、证据及 notes；每条 observation 的 context 和 candidate
也须精确对应。只有 alert 或解释不可用时，用 `status: unavailable`、空 references，
在 detail 记录实际看到的 alert、缺失含义、来源证据及不确定性，不生成解释原文。
例如下面是不可用分支的结构示意，context 必须替换为完整实际对象：

```json
{"op":"observeCall","callEvent":{"sequence":1,"seat":"east","call":"1C"},"callDisclosure":{"candidate":"1C","provider":"environment","status":"unavailable","context":{"...":"完整复制此前status.explanationContext"},"references":[],"detail":"实际1C显示Alert；解释无法读取，来源及截图路径如实记录"}}
```

正常无公开说明可省略 callDisclosure。程序先检查真实事件、精确授权及 disclosure
的前序上下文，再保存取得的观察；保存失败不会推进牌局或采纳／清除待确认计划。
接纳的公开说明／缺失注记进入 explanationEvidence，供后续玩家、独立 reviewer、
阶段交接及基本接续使用。取得的原文保存入同一观察库，注记不冒充已取得的解释。
这条路径接纳实际叫品的来源陈述，不是提交前的候选查询；其含义仍须判断适用性。
自己叫牌的解释若在提交前已取得，先用 inspectCalls／provideExplanations 更新依据并
重新评审；callDisclosure 只补入实际发生后才取得的公开说明，不能追认旧 review 已见过它。

### 核对定约与打牌角色

叫牌结束后先与平台核对实际定约和庄家，再发送：

```json
{"op":"confirmContract","contract":{"level":3,"strain":"noTrump","declarer":"east","doubling":"undoubled"}}
```

首攻 `phase: openingLead` 只提供本手和公开叫牌；用户是首攻者时由同一玩家
thread 决策，否则先观察平台首攻。实际首攻之后，加入已曝光明手完整初始十三张：

```json
{"op":"observe","event":{"sequence":0,"seat":"south","card":"S5"},"authorization":"RETURNED-UUID"}
{"op":"reveal","hand":{"seat":"west","cards":["ST","S7","S2","HK","H5","DA","D7","D6","CT","C9","C5","C4","C2"]}}
```

以上首攻和明手来自历史材料，只在实际对应局面复用；不能混入别的牌局。
`reveal` 仅允许实际曝光明手；我方做庄时也允许取得需要控制的庄家本手。
提供完整原始十三张以核对历史，程序移除已打牌。防守只控制用户一家，看得到明手
不授予其控制权，搭档和庄家暗牌保持未知。我方任一家做庄时 controller 为实际
庄家，控制庄家和明手。缺少必要曝光事实时先补事实，不能猜牌。

后续仍用 `decide`、`observe`、`status`、`checkpoint`、`stop`。唯一合法牌的
`automatic:true` 和建议返回 `source:forced` 保留原来的真实来源规则。
角色和实际进展进入 snapshotID，旧叫牌授权不能用于出牌；错牌、重复、错座位和
过期授权均拒绝。平台搭档行动也记 `opponent`，意思是外部非受控行动，并非敌方身份。

玩家共用指令仅作 thread 基础；每次真实 turn 的输入携带 `phase`、
`currentPhaseGuidance`、`phaseInitial`、`latestSnapshot` 和 `effectivePlan`。
只有当前阶段完整指导进入当前请求；旧指导仍是同一 thread 的历史。
叫牌意图在进入打牌时不自动当成打法计划。相关公开分析由同一 thread 继续保留，
先前推断可随事实修改。每个候选 reviewer 使用独立新会话及相同授权资料。

全部有效指令及协议适配的阅读入口见 [连续 Expert 指令与例子](continuous-expert-instructions.md)。
`decision-REVISION.json` 和 `request-evidence.json` 保存实际装配文本、输入、schema、
公开输出和身份；`player/rpc.jsonl` 可核对 thread/start 与后续 turn/start。
缺少必需指令直接失败。

基本接续沿用下方同副核对规则；连续入口 `resume` 使用 `continuousConfiguration` 和
`ContinuousExternalCheckpoint`，只恢复安全边界的公开事实、已确认计划及原绝对截止时间，
不恢复旧授权，不重置失败或预算。私人证据目录必须在仓库外。
自主工程检查、少量生产调用与后续联合逐份 instruction／逐例人工验收分别报告。

---

## 按需叫品解释（v3）

启动时可加 `--observations /ABSOLUTE/PRIVATE/explanation-observations.sqlite`。
默认库为 `~/Library/Application Support/BridgeCoup/explanation-observations.sqlite`；
ready 的 `observationStore` 返回实际路径。多副／新进程使用同一私有文件即可回查，
不把 SQLite 或截图放入 Git。初始库无内容，不导入 CCBA 书籍或模型记忆。

`continuousConfiguration.explanationSettings` 可提供双方实际体系、查询条件及原手牌记录：

```json
{"nsSystem":"本次实际确认的NS体系","ewSystem":"本次实际确认的EW体系","conditions":"相关体系版本、竞叫或桌面条件；未知说明未知","handRecordReference":"/ABSOLUTE/PRIVATE/board-record.md"}
```

该对象只填实际资料，不能把旧简易二盖一记录改标 CCBA。省略时体系为 unknown，
条件沿用 agreements；这类查询的匹配保守标为 related，不成为已核实约定。
局况旋转归一化识别 neither/none/NS/EW/both 等常见值，未知值保留并标出差异。

叫牌中的玩家可返回 `selectedAction: REQUEST_EXPLANATIONS`、最多三个合法候选的
`requestExplanations`、说明用途的 `publicReason` 和 `plan: {update: keep, text: null}`。
这不是叫品、计划采纳或执行授权。入口暂停并返回 `kind: informationRequest`，
其中 value 含 id、snapshotID、完整 context、candidates、reason 和 localResults。
每个候选先由本地程序查询有限观察；provider 为 knowledge，状态 found 或 noMatch。
found 保留原观察来源，不能称为新睿新观察。每次决策最多两次资料请求，不增加五轮
语义 review 上限，不重置 1800 秒绝对截止时间。玩家正常建议仍经过独立 review。

调用者也能在提交前核对已建议的叫品，或比较另一个候选：

```json
{"op":"inspectCalls","candidates":["2C","2NT"],"reason":"核对准备采用的叫品并比较一个替代"}
```

此操作返回同样的 informationRequest，撤销当前旧授权但保留该决策的轮数。
重新形成候选并 review 后会产生新的候选授权，即使选中同一个叫品也不能复用旧 ID。
从请求资料到最终建议实际确认前 checkpoint 始终 unsafe；不接纳点击、预览或猜测来推进实际牌局。

按请求的准确候选和 context 服务当前环境预览；保留原中文，不提交叫品。对每个
候选回传一个 provider: environment 的结果；没有界面或资料也返回明确 unavailable。
例如返回形状（UUID、上下文与文字必须替换为真实请求及观察）：

```json
{"op":"provideExplanations","explanationRequestID":"REQUEST-UUID","snapshotID":"EXACT-SNAPSHOT-ID","explanationResults":[{"candidate":"2C","provider":"environment","status":"unavailable","references":[],"detail":"本环境没有可用预览"}]}
```

有资料时 status 为 found，references 为一个或少量观察引用。每项为：

```json
{"status":"exact","differences":[],"observation":{"id":"STABLE-OBSERVATION-UUID","context":{"...":"完整复制本次请求context"},"candidate":"2C","text":"实际中文原文","source":"新睿未提交叫品预览","observedAt":"真实观察时间；历史截图确切时刻未知则如实注明","sourceVersion":"unknown","evidence":["/ABSOLUTE/PRIVATE/preview.png"],"notes":"适用疑问、摄取时间或后续注记","isTestData":false}}
```

上例 context 是说明占位，发送前必须复制请求的完整对象。它包括 dealer、actingSeat、
实际 auction、vulnerability、nsSystem、ewSystem、conditions 和可选 handRecordReference。
环境返回的候选、context、requestID、snapshotID 必须匹配；重复／过期回传被拒绝。
found 必须有非空原文、出处、观察时间、版本（未知明确 unknown）和证据。
每次新观察使用新 ID；相同 ID 仅允许原条目完全相同的幂等保存，不能覆盖原文。
历史原图的观察时间与当前摄取时间分开说明，不以文件修改时间伪造观察时刻。

入口保存实际取得的观察，回传成功后再 `decide`。玩家和当前独立 reviewer 接收
同一 explanationEvidence；此前取得的带上下文来源也随角色交接及 safe resume 保留。
预览文字“显示过”与“适用于当前局面”不同；观察／多次出现／新版本不自动成为约定。
对话中的推断仍是推断。空库、noMatch 或 unavailable 是正常分支；只有真正关键的
未决事实才需澄清／停止。外层每次行动前仍需核对牌桌实际状态，变化后不能盲用旧建议。

离开新睿或尚未 start，也可通过同一 CLI 本地查回，不调用模型：

```json
{"op":"lookupExplanations","explanationContext":{"dealer":"north","actingSeat":"south","auction":[{"sequence":0,"seat":"north","call":"1S"},{"sequence":1,"seat":"east","call":"P"}],"vulnerability":"neither","nsSystem":"实际NS体系","ewSystem":"实际EW体系","conditions":"相关条件"},"candidate":"2C","limit":5}
```

返回 explanationLookup 数组，每项含 observation、status: exact/related 和 differences。
exact 仅指上下文相符，仍是来源观察；不同条件／体系／局况标为 related。
不同完整前缀不命中，不把相近竞叫自动继承为当前含义。座位纯轮转同时映射双方体系、
局况及行动位置；Pass、X、XX、争叫和开叫位置完整保留。查询默认五条，上限二十条，
仅向模型发送已请求的有限资料，不扫描或注入整个数据库。

SQLite 使用已观察的 parent/call 前缀节点与索引，格式 bridge-explanations、版本 1；
未知格式／版本拒绝打开，保存后可独立读回。多来源／版本按不同观察 ID 追加保留，
不会自动挑最新一条为真。合成资料仅用于 testData=true 的独立临时测试库，生产 CLI
使用真实观察库，拒绝混用。附件复用私有证据路径，不复制图片入数据库。

信息请求与回传另保存 explanation-request-UUID.json、explanation-return-UUID.json。
连续建议除 decision-REVISION.json 最新入口外，也按候选授权保存
`decision-REVISION-AUTHORIZATION.json`，保留补查前后的候选和评审证据。

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

启动返回 v3 ready，supportedProtocols 列出 v1/v2/v3；下列旧命令仍按 v5 原义处理。
之后 stdin 一行一个命令，stdout 一行一个响应。Computer Use 调用者可保留
`exec_command` 的交互 session 并用 `write_stdin` 逐次发送命令。
JSON 中 seat 使用 `north/east/south/west`，牌使用 `SA/HT/D2/CJ`，序号从 0 开始。

## 旧版做庄调用（v1 / stage1-full-snapshot-v5）

旧版 `configuration` 通过同一正式入口调用现有 `ExpertSession`、
`CodexPlayingTransport` 和独立 `CodexReviewTransport`，保持其原做庄语义。
它只处理已定约、已曝光的庄家／明手，不替代上方连续叫牌／防守入口。
庄家是 controller；从明手出牌时 actingSeat 是明手。Claim 仍由外层承担。

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
