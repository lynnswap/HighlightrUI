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
        .package(url: "https://github.com/smittytone/HighlighterSwift", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "HighlightrUI",
            dependencies: [
                .product(name: "Highlighter", package: "highlighterswift"),
            ],
            path: "HighlightrUI/Sources/HighlightrUI",
            resources: [
                .process("Localizable.xcstrings"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(nil),
                .strictMemorySafety(),
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
                .defaultIsolation(nil),
                .strictMemorySafety(),
            ]
        ),
    ]
)
