// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "COREEngine",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .library(
            name: "COREEngine",
            targets: ["COREEngine"]
        ),
    ],
    targets: [
        .target(
            name: "COREEngine",
            resources: [
                .copy("Fashion/knowledge_base.json"),
                .copy("Fashion/i18n")
            ]
        ),
        .testTarget(
            name: "COREEngineTests",
            dependencies: ["COREEngine"]
        ),
    ]
)
