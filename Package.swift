// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PedalHUD",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "PedalHUDCore",
            targets: ["PedalHUDCore"]
        ),
    ],
    targets: [
        .target(
            name: "PedalHUDCore"
        ),
        .testTarget(
            name: "PedalHUDCoreTests",
            dependencies: ["PedalHUDCore"]
        ),
    ]
)
