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

- [Bridge Coup 2.0 正式总 spec（Issue #33）](https://github.com/absurdwall/bridge-coup/issues/33)
- [Bridge Coup 2.0 文档入口、原稿归档与章节对照](docs/bridge-2/README.md)
- [领域词汇](CONTEXT.md)
- [第一版设计记录](DESIGN.md)
- [设计访谈记录](DESIGN-NOTES.md)
- [当前 Stage 1 有限验收与义务清单](docs/acceptance/stage1/README.md)
- [外部牌局持续调用生产 Expert](docs/bridge-external.md)
- [历史记录、原始证据及旧规格恢复](docs/archive/README.md)
- [独立发布的历史边界](HISTORY-IMPORT.md)

## 当前状态

当前 App 外 reviewed declarer 实现已通过 #48/#52 的有限验收，具体范围见验收报告；不代表完整 Mac 产品或广泛打法质量验收。完整运行记录外置归档，日常仓库保留源码、必要测试样例和报告。

## 第三方许可

DDS v3.0.0 的 Apache 2.0 许可证见 [ThirdPartyNotices/DDS-LICENSE.txt](ThirdPartyNotices/DDS-LICENSE.txt)。源项目和目标仓库此前均未提供项目自有代码的顶层 `LICENSE`；本仓库没有替用户指定该许可证。
