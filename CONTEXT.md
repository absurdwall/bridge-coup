# 桥牌教学

围绕用户提供的桥牌材料，解释叫牌与打牌的思路，帮助用户复盘和学习。

## Language

**牌局材料**：用户为教学提供的截图及补充说明；可能只包含部分手牌或牌局过程，不等同于完整牌局记录。

**教学分析**：围绕具体牌局解释行动选择及其理由，帮助用户理解叫牌或打牌思路的内容。

**教学例题**：为解释桥牌思路而另外提供的示例牌局，区别于用户实际打过的牌局。

**决策时信息**：用户作出某次叫牌或出牌选择时能够获得的信息，是教学推断的依据；不包含复盘后才揭示的隐藏手牌。

**做庄计划**：庄家根据决策时信息，为完成定约或争取更多赢墩形成的整体打牌思路，包含后续信息变化时的调整。

**叫牌决策**：在给定手牌、已有叫牌及体系约定下，对下一次叫牌的选择及理由。

**关键出牌节点**：复盘中需要比较具体出牌选择及其理由的时刻。

**识别结果**：从牌局材料提取出的牌面和其他牌局信息，允许用户修改；未经核对时可能包含错牌或漏牌。

**识别错误**：材料中存在的信息被错误提取或遗漏，不等同于材料本身未提供该信息。

**缺失信息**：当前牌局材料未提供的信息；在获得补充前保持未知。

**决策控制者（decision controller）**：作出当前桥牌选择的牌手；庄家从明手出牌时，决策控制者仍是庄家，出牌座位则是明手。

**连续牌局辅导**：针对选定决策控制者，随牌局实际行动持续提供建议并调整计划的教学过程；其他座位的行动可以由用户或外部牌局事实提供。

**中途局部求助（ad-hoc mid-board help）**：从牌局中途提供现有材料、请求分析的入口；历史可以不完整，结论的适用范围受实际已知信息限制。

**计分背景（scoring context）**：牌局采用的计分方式，例如 IMP 或 MP；它为战略判断提供背景，不等同于某项分析能够计算的指标。

**正式战略目标（official strategic objective）**：用户本次决策真正要求追求的结果，例如按通常 IMP 策略决策，或明确只追求成约机会而不考虑超墩。

**计算分析指标（Engine analysis metric）**：一次计算实际衡量的数量，例如样本在双明手续打假设下的成约比例、原始得分或赢墩分布；其定义和假设不自动替代正式战略目标。

### Reviewed declarer play

**Pending declarer decision**: A choice at one authorized public bridge position whose proposed plan operation and current card await review before play advances.

**Candidate advice**: A proposed declarer plan operation, current card and explanation. It is distinct from the advice already accepted for the board.

**Active plan**: The working declarer plan carried forward from execution-authorized advice, whether review-approved or released as contested play. A pending replacement remains candidate advice until authorized.

**Play review**: Assessment of candidate declarer advice before execution, resulting in approval, a request for revision, or a need for critical factual clarification.

**Acceptance grading**: Independent assessment of recorded delivered decisions against the agreed quality criteria. Its results establish evaluation evidence rather than direct the live play.

**Review-approved advice**: Candidate declarer advice that received an approve verdict from play review.

**Contested play**: A declarer play released by the agreed execution policy while reviewer objections remain unresolved. Its authorization does not imply reviewer approval or establish bridge quality.

**Semantic review round**: One valid approve, revise or uncertain judgment on a pending declarer proposal. A technical attempt that yields no valid judgment is not a semantic review round.

### Continuous board roles

**玩家连续会话（continuing player conversation）**：同一副牌持续的玩家模型对话，保留实际叫牌和公开分析；阶段变化不清空历史，工作推断始终可修正。

**当前阶段（board phase）**：实际叫牌、首攻、做庄、防守或终局所确定的当前任务。首攻阶段明手尚未曝光；防守仅控制用户一家，做庄控制庄家与明手。

**实际行动确认（actual action confirmation）**：对已观察到的叫牌或出牌的确认，与候选、review 和执行授权分别记录；预览和点击本身不建立牌局事实。

**叫品解释观察（call explanation observation）**：在特定实际叫牌上下文中取得的有来源文字，连同条件、时间、版本及证据保留；显示过、保存过或重复出现都不自动成为双方约定。

**归一化叫牌上下文（normalized auction context）**：保留完整叫牌序列、开叫位置、双方体系与局况条件，消除纯座位轮转差异的查询视角；条件未知或不同的资料保持来源参考，不冒充当前已核实含义。
