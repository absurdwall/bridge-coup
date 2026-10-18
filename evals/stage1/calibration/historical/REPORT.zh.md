# 可审阅结果：第一阶段实现前材料与有限 grader 比较

准备范围已完成，仓库无改动。材料是实现前候选与校准结果，不能视作产品打牌验收。独立复核后的一项人工计数错误和修正见 `revision-log.md`；该错误未进入grader输入，本次总计仍只有4次grader请求。

## 实测结论

同一组6份人工候选，Luna Medium 与 Sol Medium 各两次独立 `codex exec`。预期在运行前写入独立文件，未传给 grader。每份候选只对共同牌局评分，禁止互相比较/配额；但每次仍是6份批量输入，不能认为统计独立。

|请求配置|第1次|第2次|漏错|误杀|请求耗时（秒）|
|---|---|---|---|---|---|
|gpt-6-luna / medium|4/6|4/6|两次均D|两次均B|5.810 / 5.312|
|gpt-6.1-sol / medium|6/6|6/6|无|无|14.499 / 11.611|

Luna共8/12 verdict符合人工预期，Sol为12/12。以“可接受”为阳性，Luna精确率2/4、召回率2/4，错误答案检出6/8；Sol三个指标在此小集合均为100%。两次重复不能扩大成12道独立牌例，也不能据此估计普遍准确率。均值耗时分别5.561秒和13.055秒（约2.35倍）；每轮两模型并发、机器/服务竞争与预热未控制，只报告观察值，不做生产延迟承诺。

关键判据已在 `human-expectations.json` 运行前固定：

|候选|人工预期|理由|
|---|---|---|
|A|通过|8顶张、草花Q后向AK路线、3-2是条件；D3合法|
|B|通过|先AK再小到Q，北小红心到南A可回南兑现两张草花；D8合法|
|C|失败|南没有SJ；虚构第九顶张|
|D|失败|对手共5张草花，“双方都跟三轮”需6张，物理不可能|
|E|失败|北当前跟方块，CA属于南，当前动作非法|
|F|失败|DQ首攻不能证明草花3-2；合法D5不是失败原因|

Luna不仅误杀B，解释还说南兑现AK后无草花，然而南五张草花兑现两张后还剩三张，出第三轮后仍有两张；第二次还说HA不能作为回南进手。D的错误条件被两次原样接受。E两次虽正确判失败，理由分别误称北“on lead”、把当前跟牌座位写成南；应区分判分正确与解释准确。Sol此批理由经人工复读未发现同类错误；这不是Sol自证可靠。

此前单次试验的Sol曾正确找出D类不可能条件，也曾对正确路线说“两次由明手引向AK”，忽略第一次回南后明手已不能自动再次在手。本批A理由未重复该细节，但保留这一历史失败边界。旧试验仅定向读取run.json与grades.json，未遍历旧evidence。路径：`/var/folders/1l/xh7kf4ss1rqg3vxjr17q9_0w0000gn/T/bridge-grader-demo-is0zoto6`。

建议：首版可暂用Sol Medium作这类战略/解释grader，基本合法性仍由程序检查并保留人工抽查。Luna Medium继续作为已选打牌LLM，不因grader比较替换产品模型。本批比较的是“评分能力”，没有测打牌表现。不要因为两次6/6就取消人工标注或把grader判词当作战略gold。

## 已交付材料

- `materials.zh.md`：合成题、接受替代路线、错误边界、8点短场景、3个公开教学候选和适用限制。
- `synthetic-fixture.json`：完整52张合成牌、13墩合法示范。东西牌仅为程序fixture，不能泄漏给单明手打牌模型。
- `decision-points.json`：26个受控点的逐次可见事件增量、合法牌与示范动作，前8点为首批短场景。每个明手点均保留。以后实际运行必须继承真实模型计划与已执行选择，不能强塞固定轨迹。
- `prepare.py`、`basic-checks.json`：52张唯一/每手13张/全轨迹顺序、持牌、跟牌及10:3结果，候选当前牌是否合法。它是轻量规则检查，不是战略评分平台。
- `candidates.json` / `human-expectations.json`：6份实际输入和提前固定的人审预期；后者未进入模型输入。
- `grader-input.txt` / `schema.json`：四次完全相同的评分任务和输出约束。输入SHA256见comparison.json。
- 每次 `*.command.json`、`*.jsonl`、`*.stderr.txt`、`*.final.json`、`*.run.json`：原命令、事件、警告、答案、配置及壁钟耗时。
- `run-graders.py`、`analyze.py`、`comparison.json`：运行与格式/ID覆盖/比较脚本和结果。4次均exit 0；6个ID完整唯一、字段类型有效；JSONL无工具调用事件。
- `revision-log.md`：父审阅纠正人工场景计数推断，以及对交通省略判据的澄清。

## 实测局限及运行事实

CLI为0.160.0。使用仓库外独立空cwd、`--ignore-user-config --ephemeral --skip-git-repo-check --sandbox read-only`，明确要求不读文件、不用工具/网络/记忆，答案与输入由CLI输出到授权目录。未创建worktree、提交、push或PR。未静默替换模型。请求明确指定各自模型及medium；CLI成功返回，但JSONL没有独立返回底层resolved模型/实际effort标识，因此这里只确认请求配置及成功运行，不能独立证明服务端模型路由。Luna报告reasoning_output_tokens为0也不应擅自改称非medium；它是观察到的usage字段，须保留其不确定性。

相同任务文本的input_tokens在模型/重复间不同（详见comparison.json），说明CLI附带环境/系统包装或模型记账并非由此实验控制。本次没有捕获完整传输层effective request；隔离cwd和忽略用户配置也不等于清除CLI内建上下文。JSONL未见外部访问。部分stderr含state-db查找警告（falling_back），它指状态路径查找，不是已证明发生模型fallback；原文完整保留。

教学候选原文均已在线打开实读；其中两例出自同一Pavlicek文章。计分、局况未注明的不能擅自补成IMPs。候选不是已验证的唯一战略标答，尚须形成明确决策信息与人审边界后才能纳入后续eval。来源和简要牌面见materials。

本次没有运行产品或打牌LLM，没有同thread连续实际打牌，也没有真实整局耗时。下一步验收可以先审核这8点场景、6份人审预期和grader理由；实现后再以真实计划/实际动作适配场景，并记录整局时间。3分钟无阶段硬门槛。

官方CLI资料已使用OpenAI Docs检索并实读：https://learn.chatgpt.com/docs/developer-commands#codex-exec 。本机help是实际参数支持证据。记忆仅作历史边界提示，未用作当前牌局/结果依据（相关MEMORY.md 160-165说明曾要求区分工程和模型验收、内部矛盾）。
