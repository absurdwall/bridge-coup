# 桥牌教学第一版：已发布 Tickets

用户已确认七张 tickets 的粒度和依赖（“合适”）。每张 ticket 独立发布，均为 `ready-for-agent`；尚未开工或通过验收。

来源：[Spec](spec.md)。Spec 开头的“尚待确认”是发布时状态；本记录保存后续批准结果，不修改父级 spec。

| Ticket | Blocked by |
| --- | --- |
| [01 · 在 Mac 中获得第一份真实做庄计划](issues/01-mac-declarer-plan.md) | 无 |
| [02 · 从截图识别、纠错到生成计划](issues/02-screenshot-review.md) | 01 |
| [03 · 围绕同一副牌追问与修正](issues/03-follow-up-corrections.md) | 01 |
| [04 · 核验完整牌面的双明手结果](issues/04-double-dummy-verification.md) | 01 |
| [05 · 分析关键出牌节点](issues/05-key-play-analysis.md) | 01 |
| [06 · 保存并继续一份复盘](issues/06-save-reopen-review.md) | 02, 03 |
| [07 · 完成实际 Mac 应用的整体验收](issues/07-mac-acceptance.md) | 04, 05, 06 |

## 当前可开工范围

只有 01 无依赖；完成 01 后，02、03、04、05 可各自开展；02 和 03 完成后可开展 06；04、05、06 完成后进入 07。

状态 `ready-for-agent` 不豁免依赖。发布 tickets 不代表开始实施、测试通过或功能完成。

## 设计来源

A「并排工作台」已获用户选定。三版原型快照保存在独立归档分支 [`archive/bridge-ui-prototype`](https://github.com/absurdwall/bridge-coup/tree/archive/bridge-ui-prototype/prototype)，不进入正式主线。原型回答的是视觉布局问题，不能作为真实 AI、DDS 或应用验收证据。

## 实现与验收状态快照（2026-09-23）

上面的“已发布 tickets”保留批准时的记录，不代表当前进度。以下状态记录源项目在 2026-09-23 的实现与 evidence；提交编号已映射到本独立仓库。本节不替代牌手对教学质量的验收。

| Ticket | 当前实现与证据 | 已知状态 / 缺口 |
| --- | --- | --- |
| 01 | `80d75f6`；[演示记录](evidence/01-mac-declarer-plan-demo.md) | 实际 Mac app 经 Codex runtime 生成过计划；牌例为临时构造，不是用户实战牌。原 issue 仍写 `ready-for-agent`，状态未跟进。 |
| 02 | 截图工作流与测试在 `da2e418`；[4 张截图识别记录](evidence/02-screenshot-review-demo.md) | 四张真实截图已做识别并记录差异；尚未由牌手确认截图时点/可见信息后，纠正牌面并生成计划。`in-progress`。 |
| 03 | `407b83f`、`33dbc45`、`0b525e2`；[演示记录](evidence/03-follow-up-corrections-demo.md) | 合成牌例的计划、追问与修正后重分析已记录；issue 为 `complete`。 |
| 04 | `d83b89f`；[DDS 演示记录](evidence/04-double-dummy-demo.md) | 本机 DDS 构建、Mac app 演示和定向检查有记录；issue 为 `done`。 |
| 05 | 实现在 `12b12d3`；关键出牌实机演示记录于 [07 验收](evidence/07-mac-acceptance.md) | 已用合成牌例演示关键出牌分析；issue 仍为 `ready-for-agent`，需核对并更新状态。 |
| 06 | 本机保存/重开实现在 `da2e418`；实机记录于 [07 验收](evidence/07-mac-acceptance.md) | 合成牌例保存、退出、重开及继续对话已演示；基于真实截图修正后的完整流程尚未验收。issue 仍为 `ready-for-agent`。 |
| 07 | `5510ec8`；[Mac 验收记录](evidence/07-mac-acceptance.md) | 部分通过、保持 `in-progress`；真实截图到计划闭环、完整截图场景的信息隔离仍未验收。 |

### 独立仓库发布边界

- 本仓库保留当前 Bridge 主线的 9 个项目提交；导入时去掉 monorepo 路径并重写提交哈希。映射见根目录 [HISTORY-IMPORT.md](../../HISTORY-IMPORT.md)。
- 当前设计、spec、七张 tickets、索引、提交验收记录及最新 feedback 在源目录中尚未提交；本次作为当前 Bridge 快照纳入。
- 视觉原型来自源提交 `b27def74a42385989fea48f31ad8aa4ed443ac8a`，只放在 `archive/bridge-ui-prototype` 分支。
- 一条已脱离分支引用的旧截图工作流提交 `81d014a` 未导入；当前代码树中的截图工作流来自后续主线提交。旧提交曾属于已清理的临时工作分支，不是当前实现来源。
- monorepo 中其他目录、脏文件及历史均未导入。

### 构建产物与许可证

`.build/` 中的应用包、求解器二进制、依赖缓存和工具均未发布；构建脚本从固定上游版本重新获取并构建。DDS v3.0.0 的 Apache 2.0 许可证文本位于 [`ThirdPartyNotices/DDS-LICENSE.txt`](../../ThirdPartyNotices/DDS-LICENSE.txt)。源项目和空目标仓库都没有项目自有代码的顶层许可证，本次没有替用户选择许可证。
