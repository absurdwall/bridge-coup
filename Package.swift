// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BridgeTeacher",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BridgeTeacherCore", targets: ["BridgeTeacherCore"]),
        .executable(name: "BridgeTeacherMac", targets: ["BridgeTeacherMac"]),
        .library(name: "BridgeExpert", targets: ["BridgeExpert", "BridgeEngine", "BridgeDomain"]),
        .executable(name: "bridge-play", targets: ["BridgePlayCLI"]),
    ],
    targets: [
        .target(name: "BridgeTeacherCore"),
        .target(name: "BridgeDomain"),
        .target(name: "BridgeEngine", dependencies: ["BridgeDomain"]),
        .target(name: "BridgeExpert", dependencies: ["BridgeDomain"]),
        .target(name: "BridgeDriver", dependencies: ["BridgeExpert", "BridgeEngine", "BridgeDomain"]),
        .target(name: "BridgeCodex", dependencies: ["BridgeExpert", "BridgeDomain"]),
        .executableTarget(name: "BridgePlayCLI", dependencies: ["BridgeCodex", "BridgeDriver", "BridgeExpert", "BridgeEngine", "BridgeDomain"]),
        .testTarget(name: "BridgePlayingTests", dependencies: ["BridgeDomain", "BridgeEngine", "BridgeExpert", "BridgeCodex", "BridgeDriver"]),
        .executableTarget(name: "BridgeTeacherMac", dependencies: ["BridgeTeacherCore"]),
        .testTarget(name: "BridgeTeacherCoreTests", dependencies: ["BridgeTeacherCore"]),
        .testTarget(name: "BridgeTeacherMacTests", dependencies: ["BridgeTeacherMac", "BridgeTeacherCore"]),
    ]
)
