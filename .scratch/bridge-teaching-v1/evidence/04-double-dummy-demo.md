# Ticket 04 — 双明手核验记录

## 集成与分发

- 引擎：[DDS v3.0.0](https://github.com/dds-bridge/dds/tree/v3.0.0)，annotated tag 解引用后的源码 commit 为 `37c8a79f4c67c55d1a309ccb66dd00cb58af464a`。版本信息见 [DDS README](https://github.com/dds-bridge/dds/blob/v3.0.0/README.md)；源码许可证为 [Apache 2.0](https://github.com/dds-bridge/dds/blob/v3.0.0/LICENSE)。
- `Scripts/build-dds-helper.sh` 将受校验和保护的 Bazelisk 1.29.0 下载到 `.build/dds-tools`，并固定使用 Bazel 9.2.0；Bazel 从固定 DDS 源码构建本机 helper。无需把 DDS 安装到系统范围。
- `Scripts/build-macos-app.sh` 把 helper 放到 `BridgeTeacher.app/Contents/Helpers/bridge-dds`，把上游 `LICENSE` 复制到 `Contents/Resources/DDS-LICENSE.txt`，再对 app bundle 做本地 ad-hoc code signing。对外发布时仍需用发行证书签署嵌套 helper 和 app，并完成 Apple 要求的公证；许可证文件须随包保留。
- 应用通过单次启动的本地 helper 调用 DDS legacy C API `SolveBoard`；helper 用 `SetMaxThreads(0)` 初始化 macOS 线程资源，`target=-1`、`solutions=3` 请求当前所有合法出牌及等价牌。输入与输出采用私有单行协议，不发送到网络或教学模型。
- 求解分值基于四家手牌全部已知、双方都按最佳方式行牌；它不预测普通实战或隐藏手牌下的牌桌走势。DDS 内部将将牌索引按黑桃、红心、方块、梅花、无将编码为 `0...4`；各花色和五种定约都由真实 helper 集成例核对。

## 独立已知完整牌例

黑桃为将牌，北家领出；当前墩为空。剩余牌为：

| 方位 | ♠ | ♥ | ♦ | ♣ |
| --- | --- | --- | --- | --- |
| 北 | AKQJT98765432 | - | - | - |
| 东 | - | AKQJT | AKQJ | AKQJ |
| 南 | - | 98765 | T987 | T987 |
| 西 | - | 432 | 65432 | 65432 |

这副牌中北家持有全部黑桃且其他三家黑桃缺门。13 张合法首引都必然让北南方拿下 13 墩。真实 DDS helper 返回 `suit=0, rank=14, equals=16380, tricks=13`；Core 按等价牌掩码展开并确认恰好覆盖全部 13 张合法牌。结果显示为“行牌方搭档 13 / 13 墩”。

## 含部分已出墩的残局

无将，北家领出，已出牌依序为 `♣2 ♣A`，南家行动。剩余牌为北家 `♠A`、东家 `♥A`、南家 `♣K ♦2`、西家 `♣Q ♦3`。四家的剩余张数加上当前墩已出牌数均为 2；南家仍有梅花，因此唯一合法牌是 `♣K`。

DDS 对南北行牌方返回 0 个剩余墩。补上庄家为东家、1 阶定约、庄家在本墩前已得 0 墩后，界面与 Core 显示庄家方剩余 2 墩、全副累计 2 墩、宕 5 墩。这里的 DDS 值包含当前未完成的一墩；庄家方值通过“剩余墩数 − 南北方得墩数”换算。

## Mac 应用内演示

在实际构建的 Mac app 中，从“桥牌复盘”顶部进入“事后双明手核验”，再点“运行已知结果例牌”。该按钮把上述完整牌例填入独立核验工作流并调用 bundle 内的 DDS helper。实机 AX 状态显示 `已验证`、`DDS 3.0.0`、北家行动、剩余 13 墩、全部 13 张黑桃等价且结果为 13 墩。随后改动北家牌面，界面改为“输入已更改 · 结果过期”、清除所有求解数字，并给出手牌张数矛盾原因。点“返回教学”后，教学侧之前输入的南家 `♠AK4` 保持不变。

核验视图拥有单独的 `DoubleDummyVerificationWorkflow`，不属于教学模型，也不会构造教学请求。缺失花色、重复牌、错误跟牌、牌张数不一致等情况在 helper 启动前被拒绝；不完全牌面仍保留在教学工作流。

## 本次验证

- `Scripts/build-dds-helper.sh`：DDS v3.0.0 本机 helper 构建成功；首次 Bazel 依赖与 C++ 编译完成后，重复构建命中 action cache。
- `swift build --target BridgeTeacherMac`：通过。
- `Scripts/build-macos-app.sh`：Release app 和嵌套 helper 构建、打包成功；`codesign --verify --deep --strict` 通过。
- Ticket 04 定向 XCTest：10 项通过，包括三项调用真实打包 DDS 的完整牌例/残局测试（五种定约花色均有实解核对），以及校验、等价牌、缺料不求解、失败无数字、修正过期等 workflow 检查。
- 当时整套 SwiftPM 测试因同一 checkout 中其他并行 ticket 的未完成改动而未能编译：截图识别测试引用尚不存在的类型，另有运行时 mock 未实现新增的追问协议方法。这些错误来自并行的其他测试文件；本 ticket 定向测试在独立临时 package 中运行并通过。
