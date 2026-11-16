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
        .package(url: "https://git.aleahim.com/NodetteHQ/PureYAML.git", branch: "main")
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
