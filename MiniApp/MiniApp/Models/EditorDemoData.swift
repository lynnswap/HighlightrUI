import Foundation
import HighlightrUI

enum DemoLanguage: String, CaseIterable, Identifiable {
    case swift
    case javascript
    case typescript
    case json
    case markdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .swift:
            "Swift"
        case .javascript:
            "JavaScript"
        case .typescript:
            "TypeScript"
        case .json:
            "JSON"
        case .markdown:
            "Markdown"
        }
    }

    var editorLanguage: EditorLanguage {
        EditorLanguage(rawValue: rawValue)
    }

    static func title(for language: EditorLanguage) -> String {
        DemoLanguage(rawValue: language.rawValue)?.title ?? language.rawValue
    }
}

enum DemoTheme: String, CaseIterable, Identifiable {
    case automatic
    case paraisoDark = "paraiso-dark"
    case paraisoLight = "paraiso-light"
    case atomOneDark = "atom-one-dark"
    case github

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            "Automatic"
        case .paraisoDark:
            "Paraiso Dark"
        case .paraisoLight:
            "Paraiso Light"
        case .atomOneDark:
            "Atom One Dark"
        case .github:
            "GitHub"
        }
    }

    var editorTheme: EditorTheme {
        switch self {
        case .automatic:
            .automatic(light: "paraiso-light", dark: "paraiso-dark")
        case .paraisoDark, .paraisoLight, .atomOneDark, .github:
            .named(rawValue)
        }
    }
}

enum DemoSnippet: String, CaseIterable, Identifiable {
    case swiftPackage
    case javascriptFetch
    case jsonPayload

    var id: String { rawValue }

    var title: String {
        switch self {
        case .swiftPackage:
            "Swift Package"
        case .javascriptFetch:
            "Fetch API"
        case .jsonPayload:
            "JSON Payload"
        }
    }

    var language: DemoLanguage {
        switch self {
        case .swiftPackage:
            .swift
        case .javascriptFetch:
            .javascript
        case .jsonPayload:
            .json
        }
    }

    var code: String {
        switch self {
        case .swiftPackage:
            """
            import Foundation

            struct PackageManifest {
                let name: String
                let platforms: [String]
            }

            let manifest = PackageManifest(
                name: "HighlightrUI",
                platforms: ["iOS 18.0+", "macOS 15.0+"]
            )
            print(manifest)
            """
        case .javascriptFetch:
            """
            async function loadUsers() {
              const response = await fetch("https://example.com/users");
              if (!response.ok) throw new Error("Request failed");
              return response.json();
            }

            loadUsers().then(console.log).catch(console.error);
            """
        case .jsonPayload:
            """
            {
              "project": "HighlightrUI",
              "language": "swift",
              "features": [
                "Observation native",
                "UIKit and AppKit",
                "Theme customization"
              ],
              "stable": true
            }
            """
        }
    }
}
