// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RaiBlocksSwift",
    products: [
        .library(name: "RaiBlocksSwift", targets: ["RaiBlocksSwift"]),
        ],
    dependencies: [
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(name: "Basic", dependencies: []),
        .target(name: "RaiBlocksSwift", dependencies: ["Basic"]),
        .testTarget(name: "BasicTests", dependencies: ["Basic"]),
        .testTarget(name: "RaiBlocksSwiftTests", dependencies: ["RaiBlocksSwift"]),
        ]
)
