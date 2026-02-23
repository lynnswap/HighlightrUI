import Foundation
import HighlightrUICore
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class MockSyntaxHighlightingEngine: SyntaxHighlightingEngine {
    struct MakeTextStorageCall {
        let language: EditorLanguage
        let themeName: String
    }

    private(set) var makeTextStorageCalls: [MakeTextStorageCall] = []
    private(set) var setLanguageCalls: [EditorLanguage] = []
    private(set) var setThemeNameCalls: [String] = []

    var availableThemeNames: [String]

    private let storage = NSTextStorage(string: "")

    init(availableThemeNames: [String] = ["github", "paraiso-dark", "paraiso-light"]) {
        self.availableThemeNames = availableThemeNames
    }

    func makeTextStorage(initialLanguage: EditorLanguage, initialThemeName: String) -> NSTextStorage {
        makeTextStorageCalls.append(.init(language: initialLanguage, themeName: initialThemeName))
        return storage
    }

    func setLanguage(_ language: EditorLanguage) {
        setLanguageCalls.append(language)
    }

    func setThemeName(_ themeName: String) {
        setThemeNameCalls.append(themeName)
    }
}
