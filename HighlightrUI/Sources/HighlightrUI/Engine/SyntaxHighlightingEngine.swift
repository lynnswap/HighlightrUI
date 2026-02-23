import Foundation
import HighlightrUICore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
public protocol SyntaxHighlightingEngine: AnyObject {
    var availableThemeNames: [String] { get }

    func makeTextStorage(initialLanguage: EditorLanguage, initialThemeName: String) -> NSTextStorage
    func setLanguage(_ language: EditorLanguage)
    func setThemeName(_ themeName: String)
}
