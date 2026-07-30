// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "snake",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "snake", targets: ["snake"])
    ],
    targets: [
        .executableTarget(name: "snake")
    ],
    swiftLanguageModes: [.v6]
)