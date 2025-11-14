// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AeroText-Engine",
    platforms: [
        .visionOS(.v1)
    ],
    products: [
        .executable(
            name: "AeroText-Engine",
            targets: ["AeroText-Engine"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AeroText-Engine",
            dependencies: [],
            path: "Sources/AeroText-Engine"
        )
    ]
)
