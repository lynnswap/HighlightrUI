// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HighlightrUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "HighlightrUI",
            targets: ["HighlightrUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/raspu/Highlightr", from: "2.3.0"),
    ],
    targets: [
        .target(
            name: "HighlightrUI",
            dependencies: [
                .product(name: "Highlightr", package: "Highlightr"),
            ],
            path: "HighlightrUI/Sources/HighlightrUI",
            resources: [
                .process("Localizable.xcstrings"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "HighlightrUITests",
            dependencies: [
                "HighlightrUI",
            ],
            path: "HighlightrUI/Tests",
            sources: [
                "HighlightrUICoreTests",
                "HighlightrUITests",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
