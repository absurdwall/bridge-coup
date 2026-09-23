# 桥牌教学 Mac 应用

## 已实现范围

- 原生 SwiftUI Mac 应用，A 版浅色并排工作台；左侧录入，右侧教学。
- 手动录入庄家、定约、首攻、四家按花色记录的已知牌和补充事实。空白保持未知，`-` 表示已确认缺门。
- 在发送前检查重复牌、单手超过 13 张、无效牌符和缺少定约等输入问题。
- IMP 为默认背景。每次计划请求创建一个临时、独立的 Codex 会话。
- 使用 Codex app-server 本地 stdio JSON-RPC；ChatGPT 登录由 Codex runtime 自己管理，不读取或转换订阅凭据。
- Codex 会话只收到当时可见手牌、用户补充的决策时事实和当前问题；运行在空目录、只读沙箱中，不读取截图或复盘历史。
- runtime 缺失、版本过低、登录未完成、额度限制、超时和请求失败会显示错误；输入会保留，失败后可重试。

截图识别、持续追问、DDS、保存与重新打开属于后续 tickets。

## 技术栈与已验证 runtime

- UI 与工作流：SwiftUI、Swift Package Manager；目标 macOS 14 或更高版本。
- Codex runtime：官方 `codex-cli 0.156.1`。启动方式为 `codex app-server --listen stdio://`，通过换行分隔的 JSON-RPC 与 App 通信。
- 当前实现要求 Codex CLI `0.156.1` 或更高。构建和协议握手已在 Apple Silicon Mac 上使用 `0.156.1` 实测。
- 登录使用 app-server 的 ChatGPT `account/login/start` 浏览器流程。应用把 `CODEX_HOME` 指向 `~/Library/Application Support/Bridge Teacher/Codex Home`，由 Codex runtime 自行保存其登录状态；首次使用需要在本应用中登录一次。

官方协议文档：[Codex App Server](https://learn.chatgpt.com/docs/app-server)。该文档说明 app-server 支持本地 stdio JSONL，并提供 ChatGPT 登录与线程/回合 API。WebSocket 传输标为 experimental，因此本应用使用 stdio。

## 安装和启动

在 Mac 上安装已验证版本：

```sh
npm install --global @openai/codex@0.156.1
```

构建并打开应用：

```sh
swift test
./Scripts/build-macos-app.sh
open .build/macos/BridgeTeacher.app
```

如果应用没有自动找到 Codex CLI，在应用顶部点“选择 Codex”，选取 `codex` 可执行文件。首次打开应用后，点“连接 ChatGPT”，在系统浏览器完成登录，再点“检查登录”。完成连接后可以录入当时可见的牌并生成计划。

## 开发与测试

```sh
swift test
swift build --configuration release
```

自动化检查覆盖手牌输入验证、未知牌保留、发给 runtime 的决策时信息和失败重试时输入保留。真实教学质量、用户账号授权和实际打开应用后的完整计划演示仍需单独验收；这些证据不能由 mock 或协议握手代替。
