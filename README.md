# 桥牌教学 | Bridge Teacher

一个面向 Mac 的桥牌做庄教学与复盘应用。它围绕用户当时可见的信息组织分析，并把截图识别候选、用户确认的信息、条件假设和双明手核验分开处理。

## 构建与使用

要求 macOS 14 或更高版本。发行版会内附官方 Codex CLI 0.156.1；首次使用时，在应用内通过浏览器完成自己的 ChatGPT 账号登录。AI 功能需要网络和账号可用额度。

```sh
swift test
./Scripts/build-macos-app.sh
open ".build/macos/Bridge Coup.app"
```

完整设置和操作说明见 [APP-README.md](APP-README.md)。构建输出和下载缓存位于 `.build/`，不会提交。

## 产品记录

- [领域词汇](CONTEXT.md)
- [第一版设计记录](DESIGN.md)
- [设计访谈记录](DESIGN-NOTES.md)
- [v1 规格](.scratch/bridge-teaching-v1/spec.md)
- [Tickets、进度和验收证据索引](.scratch/bridge-teaching-v1/README.md)
- [待后续安排的用户反馈](.scratch/bridge-teaching-v1/feedback.md)
- [独立发布的历史边界](HISTORY-IMPORT.md)

## 当前状态

本仓库包含实现源码和项目记录；发布仓库不代表整体验收通过。Ticket 07 仍标记为进行中，真实截图到教学计划的完整闭环和信息隔离尚未验收。最新反馈仅作为待办输入保留，本次未实施。

视觉原型 A/B/C 保存在独立归档分支 [`archive/bridge-ui-prototype`](https://github.com/absurdwall/bridge-coup/tree/archive/bridge-ui-prototype/prototype)，不属于正式主线。

## 第三方许可

DDS v3.0.0 的 Apache 2.0 许可证见 [ThirdPartyNotices/DDS-LICENSE.txt](ThirdPartyNotices/DDS-LICENSE.txt)。源项目和目标仓库此前均未提供项目自有代码的顶层 `LICENSE`；本仓库没有替用户指定该许可证。
