// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HighlightrUI",
    platforms: [
        .iOS(.v17),.macOS(.v14)
    ],
    products: [
        .library(
            name: "HighlightrUI",
            targets: ["HighlightrUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/raspu/Highlightr", from: "2.3.0")
    ],
    targets: [
        .target(
            name: "HighlightrUI",
            dependencies: [
                .product(name: "Highlightr", package: "Highlightr")
            ],
            path: "Sources/HighlightrUI")
    ]
)
