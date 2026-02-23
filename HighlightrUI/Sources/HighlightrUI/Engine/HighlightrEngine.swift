import Foundation
import Highlightr
import HighlightrUICore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
public final class HighlightrEngine: SyntaxHighlightingEngine {
    private let textStorage: CodeAttributedString

    public init() {
        textStorage = CodeAttributedString()
    }

    public var availableThemeNames: [String] {
        textStorage.highlightr.availableThemes().sorted()
    }

    public func makeTextStorage(initialLanguage: EditorLanguage, initialThemeName: String) -> NSTextStorage {
        textStorage.language = initialLanguage.rawValue
        textStorage.highlightr.setTheme(to: initialThemeName)
        return textStorage
    }

    public func setLanguage(_ language: EditorLanguage) {
        textStorage.language = language.rawValue
    }

    public func setThemeName(_ themeName: String) {
        textStorage.highlightr.setTheme(to: themeName)
    }
}
