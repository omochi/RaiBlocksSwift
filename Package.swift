// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RaiBlocksSwift",
    products: [
        .library(name: "RaiBlocksSwift", targets: ["RaiBlocksBasic"]),
        ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "3.0.2"),
        ],
    targets: [
        .target(name: "RaiBlocksCRandom", dependencies: []),
        .target(name: "BLAKE2", dependencies: []),
        .target(name: "ED25519Donna", dependencies: ["BLAKE2", "RaiBlocksCRandom"]),
        .target(name: "RaiBlocksBasic", dependencies: [
            "BLAKE2", "ED25519Donna", "BigInt"]),
        .testTarget(name: "RaiBlocksBasicTests", dependencies: ["RaiBlocksBasic"]),
        ]
)
