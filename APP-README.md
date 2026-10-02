# Bridge Coup Mac 应用

## 已实现范围

- 原生 SwiftUI Mac 应用，A 版浅色并排工作台；左侧录入，右侧教学。
- 手动录入庄家、定约、首攻、四家按花色记录的已知牌和补充事实。空白保持未知，`-` 表示已确认缺门。
- 在发送前检查重复牌、单手超过 13 张、无效牌符和缺少定约等输入问题。
- IMP 为默认背景。每次计划请求创建一个临时、独立的 Codex 会话。
- 可围绕当前计划继续追问。每次请求会重建当前决策时事实、当前计划和同版本的已完成问答，不复用旧 Codex 线程。
- 已确认事实与条件假设分开录入；假设只用于明确标注的条件讨论，不写入已确认牌面。
- 牌面、决策时事实或初始问题修改后，原计划与依赖它的追问标为过期；重新生成计划会创建新信息版本和干净教学上下文。
- 请求按信息版本记录。旧请求迟到时不会覆盖当前状态；失败的问题和材料保留，可用原追问记录显式重试。
- 使用 Codex app-server 本地 stdio JSON-RPC；ChatGPT 登录由 Codex runtime 自己管理，不读取或转换订阅凭据。
- 做庄教学会话只收到本次决策时可见手牌、已确认事实、当前计划、同计划且同信息版本的已完成问答与当前问题；运行在空目录、只读沙箱中，不读取截图或其他复盘历史。截图识别使用独立短期会话，读图后只返回候选，不复用作教学。
- runtime 缺失、版本过低、登录未完成、额度限制、超时和请求失败会显示错误；输入会保留，失败后可重试。
- 可导入本地截图并查看原图。识别会填写可编辑的牌面、定约、做庄人、首攻、叫牌与屏幕明确给出的叫牌解释；未显示、可见但不清晰、识别有歧义会分开标记。
- 截图牌面默认不进入计划。牌手须逐家勾选在所选决策点可见的手牌并确认；识别失败或迟到响应不会覆盖新截图和修正，重复牌和单手超过 13 张会在发送前拦截。
- 复盘与截图可保存在本机并重新打开；独立的事后核验面板使用随应用提供的 DDS，不把核验结果加入教学请求。

本项目各轮实现与验收边界见 `.scratch/bridge-teaching-v1/README.md`；本轮视觉修复状态见 `.scratch/bridge-coup-visual-repair/README.md`。

## 技术栈与已验证 runtime

- UI 与工作流：SwiftUI、Swift Package Manager；目标 macOS 14 或更高版本。
- Codex runtime：官方 `codex-cli 0.156.1`。启动方式为 `codex app-server --listen stdio://`，通过换行分隔的 JSON-RPC 与 App 通信。
- 当前实现要求 Codex CLI `0.156.1` 或更高。构建和协议握手已在 Apple Silicon Mac 上使用 `0.156.1` 实测。
- 登录使用 app-server 的 ChatGPT `account/login/start` 浏览器流程。应用把 `CODEX_HOME` 指向 `~/Library/Application Support/Bridge Teacher/Codex Home`，由 Codex runtime 自行保存其登录状态；首次使用需要在本应用中登录一次。

官方协议文档：[Codex App Server](https://learn.chatgpt.com/docs/app-server)。该文档说明 app-server 支持本地 stdio JSONL，并提供 ChatGPT 登录与线程/回合 API。WebSocket 传输标为 experimental，因此本应用使用 stdio。

## 品牌资源和兼容性

- Dock / Finder 图标及界面图标使用 `AppResources/BridgeCoupLogo.png`；该文件与手选的原始叠牌图逐字节一致。构建脚本只生成 macOS 所需尺寸，不改变构图或配色。
- 界面字标使用独立透明图片 `AppResources/BridgeCoupWordmark.png`，没有把长字样并入 Dock 图标，也没有用系统字体重绘。
- 应用显示名为 Bridge Coup；bundle identifier 仍是 `app.tortillaflat.bridge-teacher`。复盘、Codex 登录和偏好继续使用 `~/Library/Application Support/Bridge Teacher/`，更新不会创建空白的新数据目录。

## 安装和启动

发行版 DMG 的构建、校验、复制到“应用程序”及首次启动说明见
[`Release/README.md`](Release/README.md)。本节的命令用于开发环境；
公开下载与干净用户环境验收应以实际发布的 DMG 为准。

在 Mac 上安装已验证版本：

```sh
npm install --global @openai/codex@0.156.1
```

构建并打开应用：

```sh
swift test
./Scripts/build-macos-app.sh
open ".build/macos/Bridge Coup.app"
```

应用启动时自动检查已保存的手动路径、应用内资源、PATH、Homebrew、nvm，以及 `/Applications` 和 `~/Applications` 中 Codex/ChatGPT 桌面应用内嵌的 `codex`。每个候选都检查可执行性、版本和 app-server 协议；失效候选不会阻止后续搜索。

在顶部模型设置的“连接状态”中点“重新搜索”可恢复更新后的 Runtime。搜索优先保留仍可用的手动路径；自动搜索不会改写保存的手动路径。“查看建议路径”列出本次检查的具体路径、结果，以及“复制”和“定位”入口；未找到的位置明确标为候选，不保证已安装。仍可点“手动选择”选取非标准位置的 `codex` 可执行文件。

未找到、不可运行、协议不可用会分别显示恢复提示。Runtime 可用但未登录时，点“连接 ChatGPT”，在系统浏览器完成登录，再点“检查连接”。登录沿用本应用独立的 Codex Home，不读取或搬运桌面应用的凭据。完成连接后可以录入当时可见的牌并生成计划。

## 开发与测试

```sh
swift test
swift build --configuration release
```

自动化检查覆盖手牌输入验证、未知牌保留、追问对当前计划与同版本问答的延续、事实与假设隔离、截图候选纠错与可见性隔离、识别失败恢复和迟到响应丢弃、修正后旧分析过期，以及失败问题的显式重试。mock 检查不能替代真实图像输入，也不代表真实教学质量已验收。
