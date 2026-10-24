# Judge复核：第三轮验收通过

**当前裁定：PASS。** 对冻结源码 `3f0fc65470633dd90363ad0417b29a9f7f68be18` 的同一批22项、270条原始交付作人工讨论后的复核；没有修改玩家、reviewer、rubric、牌例或原始记录，没有新运行。复核后为 **22项通过；270条通过、0失败、0不确定**。原始grader仍是259P/11F，原独立判定仍是265P/5F，两者完整封存；当前结果由[单独overlay](accepted-overlay.json)表达。

[Owner决定](OWNER-DECISION.md)批准纠正验收结论，明确暂不合并PR或关闭issues。原先NO-GO的[总报告](history/ACCEPTANCE-REPORT.md)、[41项ledger](history/OBLIGATION-LEDGER.md)、原issue/PR正文及candidate3-analysis全部保留。旧文中的FAIL/UNMET/NO-GO是当时判定，当前结论以本复核及新的[总报告](../ACCEPTANCE-REPORT.md)为准。

## 一、五条FAIL为什么判得过重

五条来自short-5-r2的同一个条件计划：D7写入，D8–D11保留。它们不是五张错误的牌。当时North持♦K97，在外仅♦J2。D7原计划全文如下：

> Win HQ with HK, then lead a low club to CA and cash DK. Only DJ and D2 remain outstanding. If both defenders follow, diamonds were 3-3: cash D9 and D7, discarding South's spades, then lead a club to CK and cash HA for nine tricks. Keep CK and HA as South's entries and winners. If a defender shows out on DK, diamonds supply only one immediate winner; retain D9 behind the outstanding jack and reassess chances of developing extra club or heart tricks before conceding another trick. Do not automatically cash the remaining diamonds against the jack.

D7 reviewer批准，阻断列表为空，同时写了以下非阻断建议：

> If one defender shows out but the other plays DJ under DK, D9 and D7 are still winners; the fallback applies only when DJ remains outstanding.

[原始D7记录](../ticket52/candidate3/short-5-r2/play/decision-0007/decision.json)含完整局面、方案、实际请求和回复。拿着J2的防家面对K，正常保留J、跟2；此时不能自动兑现97，备用安排合理。原judge构造的“该家主动在K下打J，另一家示缺”的分支完全合法，既有52张证明和回放仍然有效。**但程序证明的是反例合法、原条件句没有穷举这个例外；它并不证明这个省略构成实质打牌错误。** 把这种证明直接升级成五次严重失败，是对自然语言条件及其重要性的过度判定。

更直接的实际证据在D12：看到J落下之后，玩家在收到这次review之前已经写道：

> Discard a spade, preserving the club king and heart ace. East's jack has fallen, so dummy's remaining diamonds are winners regardless of who holds the two.

它已正确识别97为赢墩，也选择了合理的当前牌S4。Reviewer要求把keep改为完整replace，第二轮批准：[原始D12两轮记录](../ticket52/candidate3/short-5-r2/play/decision-0012/decision.json)。这次修订同步了旧计划文本；不能据此说review救回了一个实际已误认J仍在外、会放弃赢墩的玩家。

| 交付 | 牌/计划操作 | 实际review | 复核 |
|---|---|---|---|
| D7 | HK / replace | 一轮approve，附上例外说明 | PASS；原严重性判断不成立 |
| D8 | H3 / keep | 一轮approve | PASS；没有新的实质错误 |
| D9 | C3 / keep | 一轮approve | PASS；没有新的实质错误 |
| D10 | CA / keep | 一轮approve | PASS；没有新的实质错误 |
| D11 | DK / keep | 一轮approve | PASS；合理测试，不要求穷举防家让墩方式 |
| D12 | S4 / keep→replace | revise→approve，两轮 | 原本已PASS；玩家先有正确判断，随后同步计划 |

这五条均不是五轮耗尽后的contested放行。我们撤回“reviewer已发现必须修复的严重错误，却错误放行”的结论；approve及附带提醒在这里是合理处理。若在实际J已落下后仍把J当成在外、明确放弃已建立赢墩，则仍应按原标准失败；现有记录并不支持这种情况。判定标准仍是实质事实/行动/必要资源的一致性，不要求最佳策略、形式化完备条件或特定措辞。

原始grader针对D1–D6的六条指控已在旧独立报告中驳回：错误的防家黑桃总数，以及把“favorable4–2”扩大成所有双张A的保证。本次只撤销剩下D7–D11的五条FAIL，D12原PASS不变，故该次最终12P/0F。其他21次原独立结论不变。

## 二、“没看出用了新信息”为什么不应否决验收

short3三次共36条原本均正确。r1/r2没有提前定位的窗口；r3确实在西家第三张梅花已出现、东家尚未示缺时调用模型。窗口事实及所有公共证明不变。

此前一句：

> Lead to CQ, drawing the last opposing club. Then cash HK and cross to HA to collect South’s clubs and SA for nine tricks.

新信息出现后的实际回答：

> Win the last opposing club. Cash HK, then cross to HA and collect CK, C8 and SA to secure nine tricks.

当前牌、进手与兑现路线都正确。新定位不改变该位置的正确行动和后续路线。原#36允许新信息下合理保留或修订；语料也明确接受：

> Justified retention when original plan anticipated the break.

旧评测进一步要求“能从文字中区分新持有方推理和原有预测”，并据此阻断整体接受。这把一项诊断目标提升成了过强的解释要求。预先记录、独立审过，不能代替对它是否符合产品目标的判断。本阶段要求正确、自洽、能继续打牌，不要求在路线不变时特意宣告每项新推理。原要求见[冻结manifest](../../../corpus/manifest.json)short3接受范围，以及#36的continuation/简洁理由规定。

因此，保留“无法单独验证模型内部是否作了这项新定位推理”的有限证据说明，撤销其验收阻断作用。没有声称知道模型内部推理，也没有把未发生窗口的r1/r2写成已发生。三次核心任务、真实r3窗口及其正确回答足以满足本阶段任务。

## 三、当前交付判断与保留边界

- 第三轮原定18短任务+4完整任务全部完成，无中断、补跑或版本拼接；四张完整牌均52张唯一合法牌/13墩，87条模型交付原本全部通过。其余结果经本次复核为270P/0F/0U；接受不是从合法性、成约或review批准推出来的。
- 255 Swift测试（10既有skip）及74 Python通过，独立Standards/Spec/指令审查、证据helper审计与保存/离线复核通过。此次只改报告与裁定；运行源码保持3f，不需新候选或重跑模型。
- 280次玩家及280次reviewer请求、10次反馈修订等实际成本保持原数；外层OS退出码未知等过程限制不清零。不能量化review净提升，也不把每次修订都说成救回一次错误打法。
- C1的旧失败和C2中断、三次预算消耗及所有分歧保持历史原样。C3通过来自同一批记录的合理复核，不来自拼接通过样本或挑选重跑。
- #36–42/#46在#48明确替换后仍适用的本阶段要求，以及#48–52的工程/有限验收范围完成。issues是否关闭、代码是否合入main分别报告，尚不因验收通过自动改变。
- 没有观察到需继续修代码或重跑的剩余阻断。PR53可进入合并准备；按Owner明确指令，本次不执行merge、不关闭issues。
