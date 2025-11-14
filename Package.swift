// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpatialTextLab",
    platforms: [
        .visionOS(.v1)
    ],
    products: [
        .executable(
            name: "SpatialTextLab",
            targets: ["SpatialTextLab"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SpatialTextLab",
            dependencies: [],
            path: "Sources/SpatialTextLab"
        )
    ]
)
