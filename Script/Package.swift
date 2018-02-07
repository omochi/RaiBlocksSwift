// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Script",
    products: [
        .executable(name: "fix-xcodeproj", targets: ["fix-xcodeproj"]),
    ],
    dependencies: [
        .package(url: "https://github.com/xcodeswift/xcproj.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "fix-xcodeproj", dependencies: ["xcproj"]),
    ]
)
