// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Stitcher",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Stitcher",
            targets: ["Stitcher"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mihaelamj/PureYAML.git", from: "0.1.3")
    ],
    targets: [
        .target(
            name: "Stitcher",
            dependencies: ["PureYAML"]
        ),
        .testTarget(
            name: "StitcherTests",
            dependencies: ["Stitcher"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
