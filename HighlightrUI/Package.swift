// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HighlightrUI",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "HighlightrUI",
            targets: ["HighlightrUI"]
        ),
        .library(
            name: "HighlightrUICore",
            targets: ["HighlightrUICore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/raspu/Highlightr", from: "2.3.0"),
        .package(url: "https://github.com/lynnswap/ObservationsCompat", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "HighlightrUICore",
            dependencies: [
                .product(name: "ObservationsCompat", package: "ObservationsCompat"),
            ],
            path: "Sources/HighlightrUICore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "HighlightrUI",
            dependencies: [
                "HighlightrUICore",
                .product(name: "Highlightr", package: "Highlightr"),
            ],
            path: "Sources/HighlightrUI",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "HighlightrUITests",
            dependencies: [
                "HighlightrUICore",
                "HighlightrUI",
                .product(name: "ObservationsCompat", package: "ObservationsCompat"),
            ],
            path: "Tests",
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
