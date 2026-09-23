# Bridge 本地 Tracker

用户已确认采用本地 Markdown tracker，且已确认以完整复盘流程为主的测试边界。

- 每个功能一个目录：`.scratch/<feature-slug>/`。
- Spec：功能目录的 `spec.md`，状态以 `Status:` 记录。
- 已获批的实现 tickets：功能目录的 `issues/<NN>-<slug>.md`，每张一份，按依赖顺序编号。
- 本项目使用原样 triage 标签：`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`。
- `ready-for-agent` 表示规格可执行；能否开工还必须检查 `Blocked by`，不是忽略依赖立即开工。
- 发布 spec 与批准 ticket 拆分是两个阶段。发布前先让用户确认拆分粒度和依赖；当前不得把未批准的拆分当成已发布 tickets。
- 后续评论追加至对应文件的 `## Comments`，保留来源记录。

当前功能：[桥牌教学第一版](bridge-teaching-v1/spec.md)。
