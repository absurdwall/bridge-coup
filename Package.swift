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
        .executable(name: "bridge-external", targets: ["BridgeExternalCLI"]),
    ],
    targets: [
        .target(name: "BridgeTeacherCore"),
        .target(name: "BridgeDomain"),
        .systemLibrary(name: "CSQLite"),
        .target(name: "BridgeKnowledge", dependencies: ["BridgeDomain", "CSQLite"]),
        .target(name: "BridgeEngine", dependencies: ["BridgeDomain"]),
        .target(name: "BridgeExpert", dependencies: ["BridgeDomain"], resources: [.process("Instructions")]),
        .target(name: "BridgeDriver", dependencies: ["BridgeExpert", "BridgeEngine", "BridgeDomain", "BridgeKnowledge"]),
        .target(name: "BridgeCodex", dependencies: ["BridgeExpert", "BridgeDomain"]),
        .executableTarget(name: "BridgePlayCLI", dependencies: ["BridgeCodex", "BridgeDriver", "BridgeExpert", "BridgeEngine", "BridgeDomain"]),
        .executableTarget(name: "BridgeExternalCLI", dependencies: ["BridgeCodex", "BridgeDriver", "BridgeExpert", "BridgeEngine", "BridgeDomain", "BridgeKnowledge"]),
        .testTarget(name: "BridgePlayingTests", dependencies: ["BridgeDomain", "BridgeEngine", "BridgeExpert", "BridgeCodex", "BridgeDriver", "BridgeKnowledge"]),
        .executableTarget(name: "BridgeTeacherMac", dependencies: ["BridgeTeacherCore"]),
        .testTarget(name: "BridgeTeacherCoreTests", dependencies: ["BridgeTeacherCore"]),
        .testTarget(name: "BridgeTeacherMacTests", dependencies: ["BridgeTeacherMac", "BridgeTeacherCore"]),
    ]
)
