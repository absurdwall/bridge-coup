// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BridgeTeacher",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BridgeTeacherCore", targets: ["BridgeTeacherCore"]),
        .executable(name: "BridgeTeacherMac", targets: ["BridgeTeacherMac"]),
    ],
    targets: [
        .target(name: "BridgeTeacherCore"),
        .executableTarget(name: "BridgeTeacherMac", dependencies: ["BridgeTeacherCore"]),
        .testTarget(name: "BridgeTeacherCoreTests", dependencies: ["BridgeTeacherCore"]),
        .testTarget(name: "BridgeTeacherMacTests", dependencies: ["BridgeTeacherMac", "BridgeTeacherCore"]),
    ]
)
