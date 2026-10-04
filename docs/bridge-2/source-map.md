# Spec 1.4 → Bridge Coup 2.0 章节对照

[文档入口](README.md) · [当前正式 spec](https://github.com/absurdwall/bridge-coup/issues/33) · [1.4 原文](source-spec-1.4.md)

本表覆盖原文全部 **70 个顶层章节**，用于证明整理后每个章节都有去向，并帮助实施 ticket 找到详细约束。它不是另一份规格正文。R 为当前 Issue 的需求，T 为测试决策，G 为发布门槛，M 为纵向里程碑。

原文中的详细技术约束由当前 Issue 明确引用，除 Issue 中的六项修订外继续适用。类型、代码和目录示意始终是示意。若原稿与当前发布范围冲突，按 Issue 的明确修订执行；不能仅因本表写了“保留”就恢复已被修订的旧要求。

- **保留**：技术语义继续适用。
- **澄清**：消除歧义或明确验证方式，未扩成新产品要求。
- **修订**：按本轮确认的产品范围、目标或发布标准执行。
- **延后**：保留未来方向，排除在 2.0 发布阻塞项之外。
- **替代**：旧导航／权威说明由当前文档体系接替。

| 原稿章节与行号 | 当前 Issue 对应条款 | 处理 | 核对说明 |
| --- | --- | --- | --- |
| [§1 Product goal](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L12) | R01, R19; G1–G4 | 修订 | 平台目标保留；连续单控制者辅导和基础质量门槛按本轮决定执行。 |
| [§2 Explicit non-goals for the first implementation](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L89) | Out of Scope; R08–R11 | 保留 | 研究型搜索、第二通用 agent 框架等非目标继续适用。 |
| [§3 Decisions that are currently considered frozen](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L125) | R01, R07–R09, R14, R21 | 澄清 | 职责与运行时方向保留；原文 frozen 不冻结物理目录或传输选择。 |
| [§4 Core architecture principles](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L272) | R01, R04–R12 | 保留 | 程序负责不变量，Codex 负责判断；工具暴露不重定义 Engine。 |
| [§5 Canonical architecture diagrams](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L377) | R01, R07, R09, R21 | 保留 | 架构图作为职责图；不是必须逐目录照搬的实施清单。 |
| [§6 Responsibility boundary](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L532) | R01, R02, R07, R09–R12 | 保留 | Domain、Engine、Expert 与资产职责及局部检查边界继续适用。 |
| [§7 DecisionSession and model-led capability loop](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L668) | R04, R05, R07; T03 | 保留 | 一次请求一个 session；共享 snapshot 及跨 session 继承须显式授权。 |
| [§8 Codex app-server runtime strategy](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L791) | R08; T05; M0 | 澄清 | 运行时方向保留；现有 strong isolation 的表述不能替代真实负向测试。 |
| [§9 Domain state and input model](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L869) | R02, R03; T02 | 修订 | 保留八类信息状态；中途不完整材料是正常入口，限制受影响的分析。 |
| [§10 Canonical bridge record](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L890) | R02; T02 | 保留 | 单一已接受事实／事件入口；示意类型不是冻结 API。 |
| [§11 Separate postmortem truth](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L925) | R02, R11, R16; T04, T11 | 保留 | 事后全牌真相与决策时信息访问隔离。 |
| [§12 DecisionSnapshot](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L946) | R04; T03 | 保留 | 不可变 snapshot，控制者／行动座位及过期语义。 |
| [§13 DecisionPerspective and VisibleState](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L974) | R02, R05; T03, T06 | 保留 | 含 13.1 原始持牌、当前剩余牌和历史时点的严格区别。 |
| [§14 BeliefModel and DealSampleSet](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1054) | R10; T06 | 保留 | BeliefModel 与具体 DealSampleSet 分开。 |
| [§15 Constraint taxonomy](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1093) | R10; T06 | 保留 | 机械约束、约定含义和软推断分开；高置信度不自动变成事实。 |
| [§16 InferenceProposal](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1121) | R10, R12; T06 | 保留 | Codex 提出可撤销推断；Engine 只检查可表示性、机械一致性和可计算性。 |
| [§17 Deal Sampler](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1152) | R10; T06 | 保留 | 含 17.1 完整隐藏分配上的均匀目标分布及提议偏差纠正。 |
| [§18 Sampler diagnostics](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1208) | R10, R11; T06, T07 | 保留 | 矛盾、预算耗尽、权重、覆盖与诊断；不把 unique count 当普适可靠性指标。 |
| [§19 Soft inference, scenarios, and future weighting](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1232) | R10; T06, T10 | 保留 | 优先显式情景敏感性分析；未来校准权重不进首发关键路径。 |
| [§20 Existing DDS abstraction](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1255) | R11; T07 | 保留 | 复用 DDS 3.0；先利用单次 SolveBoard 覆盖，再按测量考虑批处理。 |
| [§21 Candidate Evaluator](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1265) | R11; T07 | 保留 | 共享样本、Engine 聚合、失败覆盖和 DD 续打偏差。 |
| [§22 CandidateEvaluation](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1309) | R11, R12; T07, T08 | 保留 | 候选结果保留指标、覆盖和限制；不称为无条件实战胜率。 |
| [§23 IMP semantics and DecisionObjective](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1332) | R06; T08 | 修订 | 计分背景、正式战略目标与计算指标分别表达；代理指标不偷换用户目标。 |
| [§24 Matchpoint semantics](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1350) | R06; T08 | 修订 | 无 field model 不声称真实 MP 期望；计算回退不能隐式改变正式战略目标。 |
| [§25 Play decision and analysis lifecycle](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1358) | R03–R07, R13; T03, T12 | 修订 | 连续辅导可由人工录入其他座位；PlanState 和可观察分支约束保留。 |
| [§26 Declarer-specific reasoning](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1408) | R13; T09, T12 | 保留 | 做庄桥牌概念作为推理与评测要求，不扩成大量硬编码规则。 |
| [§27 Defense-specific reasoning](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1436) | R13, R14; T09, T12 | 保留 | 防守视角、约定、信号、同伴推断及连续决策。 |
| [§28 Bidding architecture](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1461) | R13, R14; T09 | 保留 | 叫牌共享基础设施，不强塞进出牌 evaluator 或固定 pipeline。 |
| [§29 Partnership and opponent agreement model](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1490) | R14; T05, T11 | 修订 | 有效材料集、优先级和未知语义保留；基础 CCBA 为首发起点。 |
| [§30 Bidding V1](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1573) | R13, R14; M4 | 保留 | 首发有用的下一叫品、含义解释和定性比较，不要求完整续叫模拟。 |
| [§31 Bidding V2](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1594) | R13; Out of Scope | 延后 | 高级叫牌续程策略与定约分布研究不是 2.0 必需。 |
| [§32 Bridge Expert request, Declaration, session, and result contract](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1620) | R04, R06, R07 | 澄清 | 请求／Declaration 保留；正式战略目标不与 Engine 可算指标混为一体。 |
| [§33 Tool Registration, Engine capability exposure, and scoped resource access](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1685) | R09; T05, T10 | 保留 | 保留广泛、有语义的工具暴露、低层与组合共存以及共同 session envelope。 |
| [§34 Runtime / Resources / Evidence](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L1904) | R08, R12, R17; T05, T08 | 保留 | 运行控制、资源固定、实际分析目标、不可变证据谱系和可观察历史。 |
| [§35 Final result, evidence qualification, and executable actions](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2046) | R07, R12, R17; T03, T08 | 保留 | 多种诚实结果、匹配证据引用和执行时检查；没有通用推理 Validator。 |
| [§36 Session history, durable DecisionTrace, and postmortem extension](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2131) | R12, R16, R18; T08, T11 | 保留 | 持久 trace 与事后记录分离；不保存私有 chain-of-thought。 |
| [§37 Error taxonomy](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2175) | R17; T03, T09 | 保留 | 保留故障归因类别；细分错误名和实现形态可由工程细化。 |
| [§38 Knowledge architecture and lazy retrieval](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2221) | R14, R15; T11 | 修订 | 三层知识与来源规则保留；首发小型真实材料即可，不要求大规模书籍库。 |
| [§39 Knowledge retrieval / search strategy](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2294) | R15; T10, T11 | 保留 | 模型自主检索，先使用简单可行的检索方式，再按评测决定扩展。 |
| [§40 Knowledge, agreement, evaluation, experience, and postmortem isolation](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2318) | R08, R15, R16; T04, T05, T11 | 保留 | 生产盲决策、知识、约定、原始经验、答案与事后真相的访问边界。 |
| [§41 Learning architecture](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2350) | R16; T11 | 修订 | 真实学习工作流及人工晋升保留；不要求首发已产出很多验证后新知识。 |
| [§42 Experience record](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2374) | R16; T11 | 保留 | 真实结构化 episode；原始经验不是生产指令或普通盲决策知识源。 |
| [§43 Candidate lesson](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2398) | R16, R20; T11 | 澄清 | 独立验证、反例、人工批准和回滚保留；无验证证据时诚实保持候选状态。 |
| [§44 Evaluation system](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2416) | R19, R20; T09 | 修订 | 保留开发／留出评测及先试评后冻结门槛；首发采用小但真实的质量评测。 |
| [§45 State evals](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2429) | R02, R18; T02 | 保留 | 状态、合法性、重建和 undo/redo 的外部行为检查。 |
| [§46 Visibility, session-binding, and runtime-isolation evals](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2444) | R04, R05, R08; T03–T05 | 保留 | 隐藏真相不变性、继承、版本固定、信息时点和真实负向访问测试。 |
| [§47 Sampler and inference evals](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2494) | R10; T06 | 保留 | 原始／剩余语义、可枚举目标分布、稀少可行解和情景敏感性。 |
| [§48 DDS and sampled-evaluation evals](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2504) | R11; T07 | 保留 | 真实 DDS、候选覆盖、共享样本和策略融合案例；mock 不替代数值验收。 |
| [§49 Expert bridge eval corpus](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2520) | R19, R20; T09, T10 | 修订 | 不把每阶段 20–30 题作为硬门槛；真实代表题、独立裁定和可接受替代答案保留。 |
| [§50 Ablation and architecture evaluation](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2556) | R20; T09, T10 | 澄清 | 保留基线和有用的定向消融；不要求穷尽实验矩阵或统计显著提升才能发布。 |
| [§51 Stochastic model, capability-loop, and continuous-play evaluation](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2578) | R13, R20; T09, T10, T12 | 保留 | 重要案例多次运行、工具／检索行为、连续计划稳定性及修订依据。 |
| [§52 Model strategy](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2620) | R08, R18 | 保留 | 可选模型及实际身份记录；一个主 Codex 推理者。 |
| [§53 Canonical repository target structure](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2645) | R01, R21 | 保留 | 逻辑目标结构与依赖方向保留；物理目录不是冻结合同。 |
| [§54 Migration of current types](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2736) | R18, R21; T01, T12 | 保留 | 复用 play、auction、DDS 与存档；不把旧 draft 或全牌会话伪装成盲 snapshot。 |
| [§55 Vertical implementation milestones](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2784) | R21; M0–M7 | 修订 | 保留纵向里程碑；连续辅导／内容／发布范围按本轮澄清；M8 在 2.0 后。 |
| [§56 Cross-cutting testing requirements](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2899) | Testing Decisions; T01–T13 | 澄清 | 用户已确认以最高层产品行为为主，加数学、真实 runtime 和打包 App 边界。 |
| [§57 Backwards compatibility requirement](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2916) | R18; T12 | 保留 | 增量迁移、核心工作流、截图、登录、旧复盘和 DD UI 兼容路径。 |
| [§58 Feature flags](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2931) | R18; M1 | 保留 | 首批 Expert 行为受开关控制，支持比较与回退。 |
| [§59 Observability](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2945) | R12, R17, R18; T13 | 保留 | 请求、模型、工具、资源、证据、时延、预算与最终结果的可观察记录。 |
| [§60 Performance philosophy and run budgets](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L2977) | R17; T13 | 保留 | 先有有限安全上限，再按整请求和整副牌测量设定可用性预算。 |
| [§61 Caching and evidence-reuse rules](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3000) | R12, R18; T08 | 保留 | 缓存键涵盖真实语义依赖；证据继承比普通缓存有更强限制。 |
| [§62 Reproducibility and replay](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3034) | R18; T08 | 保留 | 确定性证据、资源回放和随机模型重跑分别表述。 |
| [§63 Security and leakage](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3056) | R02, R08, R11; T04, T05 | 保留 | 含 blind complete-position/DD 假设局面规则；提示词不能替代访问隔离。 |
| [§64 Why Agents SDK is not required](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3089) | R08; Out of Scope | 保留 | 不因工具调用循环而另建 Agents SDK 框架。 |
| [§65 Runtime re-evaluation triggers](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3107) | R08, R21 | 保留 | 只在实测要求无法满足时重评 runtime／transport。 |
| [§66 Bridge Coup 2.0 definition of done](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3127) | R19; G1–G4; M7 | 修订 | 完整 2.0 四项发布门槛；允许未证显著提升，不允许未证基本质量。 |
| [§67 First Bridge Expert engineering milestone definition of done](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3248) | R21; M1 | 保留 | 首个真实做庄切片不是 2.0 完成；最小能力、证据、隔离及基础评测要求保留。 |
| [§68 Spec authority map, provenance, and handoff discipline](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3310) | R22; Further Notes | 替代 | 当前 Issue 加本表成为导航与修订依据；原文内部 authority map 仅帮助理解原稿。 |
| [§69 First implementation principle](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3390) | R21; M0, M1 | 保留 | 先在现有做庄入口证明纵向路径，不先横向建完全部子系统。 |
| [§70 Final architecture thesis](https://github.com/absurdwall/bridge-coup/blob/main/docs/bridge-2/source-spec-1.4.md#L3436) | R01, R04–R12, R19, R22 | 澄清 | 总体架构原则保留；产品完成和文档权威以当前 Issue 及明确修订为准。 |

## 六项明确修订的集中位置

1. 单决策控制者连续辅导、其他座位可人工输入：R03、R13、M2、M3、T12。
2. 中途不完整材料是正常入口，按信息限制分析：R02、R03、T02。
3. 计分背景／正式战略目标／计算指标分别表达：R06、T08。
4. 基础 CCBA 与首发内容范围：R14–R16、M4–M6、T11。
5. 小型真实评测、独立来源和人工裁定：R20、T09、T10。
6. 真实可用且无明显严重退化的发布门槛：R19、G1–G4、T13、M7。

## 完整性记录

- 原始文件：`Bridge Expert Architecture & Implementation Spec 1.4.md`。
- 原稿引用的代码基线：`0da8528438ccefcec46a02609d8f2fb40632fb9f`。
- 本轮整理时的仓库基线：`a11448ae972e93e3b906bac011970aa5e2010926`。
- 归档：3,571 行，168,847 字节，与用户提供的文件逐字节一致。
- SHA-256：`a9027db6cdfd10bb19603d896d3c8cb34f04322b1d18f749a45bfcc9eebdc947`。
- 此处的完整性核对是文档核对，不是功能、桥牌质量或 2.0 发布验收。
