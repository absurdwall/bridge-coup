# 首屏工作区验收记录

## 截图状态

- [00 · Prototype A 固定示例](first-screen-workspace/00-prototype-a-static-example.png)：已有原型页面，牌例为 3NT、南家、首攻 ♠K；右栏是原型内置的固定教学文案，不是实时模型输出。原型没有“新复盘空状态”或可导入的真实分析状态。
- [01 · App 新复盘空状态](first-screen-workspace/01-app-new-review-empty.png)：实际 Bridge Coup app 窗口，显示完整四向牌桌、桌心和真实教学空状态。
- [02 · App 同牌例空分析](first-screen-workspace/02-app-same-deal-empty-analysis.png)：app 中录入与 Prototype A 相同的 3NT、南家、♠K 牌例和已知手牌；教学区仍为空，未把原型固定文案带入 app。
- [03 · App 已有内容布局夹具](first-screen-workspace/03-app-analysis-test-fixture.png)：隔离的临时测试会话，用明确标识的布局夹具展示分层教学内容与追问入口。界面标出“非真实模型响应”和“未保存”；没有调用 Codex 或求解器，也没有保存复盘。

Prototype A 的来源是已打开的原型页面截图，仅裁出网页内容区域以去掉浏览器工具栏。App 截图来自独立临时 `.app` 包和 bundle ID，不替换或写入已运行的用户 app。空状态及同牌例截图使用 `/tmp/bridge-coup-issue02-acceptance/Bridge Coup QA.app`（bundle ID `app.tortillaflat.bridge-teacher.issue02qa`）；内容布局截图使用 `/tmp/bridge-coup-issue02-fixture-run/Bridge Coup Fixture.app`（bundle ID `app.tortillaflat.bridge-teacher.issue02fixture`）。截图时内容视口为 1320×900 pt。所有临时测试数据仅在测试会话中，未写入用户保存数据。

## 手工检查

- 首屏同时看到完整牌桌与教学栏；工作区使用一个纵向滚动容器承载长内容。
- 截图导入入口保持在牌桌前方。点击后出现系统文件选择器，再取消；未选择用户文件。
- 展开“复盘背景与补充事实”后，可访问背景字段。定约、做庄人、首攻与牌面编辑仍位于牌桌附近。
- 在隔离 app 中选入 3NT、南家、♠K 并录入同牌例手牌；没有生成模型结果或保存会话。
- 未对较窄宽度做拖拽尺寸验收；布局以最小宽度约束加统一纵向滚动处理高度变化，1320×900 视口实测可见牌桌全貌。

## 自动回归

`swift test --filter 'DeclarerPlanWorkflowTests|ScreenshotReviewWorkflowTests|ReviewSessionArchiveTests'`：15 项通过；`swift test`：38 项通过；`swift build --configuration release` 成功。既有工作流测试覆盖背景/牌面修正使旧计划与追问过期、重新生成后追问引用当前计划，以及截图会话更换与确认；断言的是工作流外部状态与请求信息，不依赖 SwiftUI 视图结构。
