// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RaiBlocksSwift",
    products: [
        .library(name: "RaiBlocksSwift",
                 targets: ["RaiBlocksBasic", "RaiBlocksNode"]),
        .executable(name: "rbsw_node",
                    targets: ["rbsw_node"]),
        .executable(name: "test_bootstrap",
                    targets: ["test_bootstrap"])
        ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "3.0.2"),
        .package(url: "https://github.com/omochi/SQLite.swift.git", from: "0.11.4")
        ],
    targets: [
        .target(name: "RaiBlocksCRandom", dependencies: []),
        .target(name: "BLAKE2", dependencies: []),
        .target(name: "ED25519Donna", dependencies: ["BLAKE2", "RaiBlocksCRandom"]),
        .target(name: "RaiBlocksRandom",
                dependencies: ["RaiBlocksCRandom"]),
        .target(name: "RaiBlocksPosix"),
        .target(name: "RaiBlocksSocket",
                dependencies: ["RaiBlocksRandom", "RaiBlocksPosix"]),
        .target(name: "RaiBlocksBasic",
                dependencies: ["RaiBlocksCRandom", "RaiBlocksSocket", "BLAKE2", "ED25519Donna", "BigInt", "SQLite"]),
        .target(name: "RaiBlocksNode", dependencies: ["RaiBlocksBasic"]),
        .target(name: "rbsw_node",
                dependencies: ["RaiBlocksBasic", "RaiBlocksNode"]),
        .target(name: "test_bootstrap",
                dependencies: ["RaiBlocksBasic", "RaiBlocksNode"]),
        .testTarget(name: "RaiBlocksSocketTests", dependencies: ["RaiBlocksSocket"]),
        .testTarget(name: "RaiBlocksBasicTests", dependencies: ["RaiBlocksBasic"]),
        .testTarget(name: "RaiBlocksNodeTests", dependencies: ["RaiBlocksNode"])
        ]
)
