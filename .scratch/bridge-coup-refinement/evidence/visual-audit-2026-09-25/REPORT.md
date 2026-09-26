# Bridge Coup 实际 Mac app 对照认可原型 A

> 这是 2026-09-25 的历史 app 快照。后续的 [2026-09-26 窄窗口验收记录](../../../bridge-coup-visual-repair/evidence/narrow-window-acceptance-2026-09-26.md)更新了之后的验收状态；本报告中的修正优先级是历史观察，不是新增 tickets。

**结论：明显不一致。** app 保留了四向座位和桌心定约，但桌面本身的尺寸、背景处理、首屏层级与原型 A 相差明显。相同牌例的 app 截图里，牌桌需要滚动后才能完整看到；此时右侧教学栏仍为空白。

## 审查范围

- **认可原型：** A「独立座位卡」；原型快照保存在 [`archive/bridge-ui-prototype` 分支](https://github.com/absurdwall/bridge-coup/tree/archive/bridge-ui-prototype/prototype)。本报告引用当前项目的 [spec](../../spec.md)。原型页面在 Codex In-app Browser 以 A 方案、约 1320×900 内容视口查看。
- **实际 app：** 从临时构建目录打开的打包版本，代码点为 `ddca013`，显示名 `Bridge Coup`。这次不是 Finder 安装包验收。
- **对照牌例：** 3NT、南家庄家、♠K 首攻；北家 ♠852 ♥74 ♦AKQJ10 ♣862，南家 ♠A93 ♥AK5 ♦742 ♣A953，东西家未知。app 中只录入了这组临时未保存的数据；没有生成计划、保存复盘或发送模型请求，截图后退出了 app。
- **证据边界：** 原型截图是在同次 CUA 浏览器查看中捕获并目视检查；其可重现来源是上面的原型文件。以下 PNG 是从实际 app 窗口保存的截图。截图用于视觉对照，不代表已完成 Dock 图标、既有复盘重开或真实模型请求的验收。

## 一致之处

- 北上、南下、西左、东右；四家仍以独立座位块呈现，定约位于牌桌中心。
- ♠♥♦♣ 顺序、红色红心/方块与牌点记法一致。匹配状态中，已知牌与未知的东西家也一致。
- app 使用所选叠牌图案和独立 Bridge Coup 字标，品牌素材方向符合当前选定版本。
- app 没有把原型里的 A/B/C 变体选择器带入产品界面；单一编辑桌面也符合项目 spec 对生产界面的要求。

## 主要差异

### P1 — A 方案的浅绿牌桌和紧凑比例没有落到 app

原型把四张白色座位卡和桌心放在一块浅绿桌面上，HANDOFF 将牌面区域作为约 310×200px 的紧凑参考。实际 app 把座位放在大幅表单式白/灰区域：每个花色是一整条带边框的宽输入框，桌面没有独立的浅绿底板。牌桌及座位输入区明显更高、更宽，成为一列大型表单。罗盘关系保留了，但 A 的主要视觉特征没有保留。

证据：[实际 app 匹配牌例](./06-app-matched-table.png)、[原型快照](https://github.com/absurdwall/bridge-coup/tree/archive/bridge-ui-prototype/prototype)。

### P1 — 首屏的左右工作台关系断开

原型在同一屏内展示完整牌桌与右侧教学示例。实际 app 初始视口先显示截图导入、做庄背景和表单；完整牌桌落在下方，需滚动后才可见。滚动到匹配牌例的牌桌时，右栏是一大片空白，而原型右栏在同一视口提供有标题、层级和内容的示例教学。视觉重心从左右并列工作台变成左侧长表单加空白侧栏。

证据：[实际 app 首屏](./02-app-overview.png)、[实际 app 牌桌滚动位置](./06-app-matched-table.png)、[牌桌初始未录牌状态](./03-app-table-scrolled.png)。

### P2 — 顶部品牌区与模型设置入口比原型更重

原型顶栏是小尺寸标志、字标和紧凑的模型偏好入口。实际 app 顶部在字标旁放置保存/打开复盘、模型、连接状态、登录与 Codex 选择等一整排控件；模型设置展开后又以大型浮层覆盖工作区。这些控件服务于真实 app，但从视觉上压过了原型的轻量顶栏和牌局内容。

证据：[实际 app 模型设置面板](./05-app-model-settings.png)。当前运行环境显示 Astra 可用、Luna 与 Sol 不可用；这次仅记录显示状态，没有更改选择。

## 修正优先级

先把牌桌缩回紧凑浅绿区域，并让完整牌桌与有内容的教学栏在常见窗口首屏并列出现；再收敛顶部复盘/连接控件的视觉占比，模型设置展开面板也应减少对牌局内容的遮挡。保留已实现的四向布局、行内录牌和中心定约。

## 截图索引

- [02-app-overview.png](./02-app-overview.png) — app 空白新复盘的首屏
- [03-app-table-scrolled.png](./03-app-table-scrolled.png) — app 空白牌面滚动至四向桌位
- [04-app-contract-grid.png](./04-app-contract-grid.png) — 合同选择器打开状态
- [05-app-model-settings.png](./05-app-model-settings.png) — 模型与 thinking effort 面板
- [06-app-matched-table.png](./06-app-matched-table.png) — 按原型 A 数据录入后的四向桌位
