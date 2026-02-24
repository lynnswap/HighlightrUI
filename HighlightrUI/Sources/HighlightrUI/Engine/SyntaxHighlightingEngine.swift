import Foundation

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
    func renderHighlightPayload(source: String, in range: NSRange) async -> HighlightRenderPayload?
}

public extension SyntaxHighlightingEngine {
    func renderHighlightPayload(source: String, in range: NSRange) async -> HighlightRenderPayload? {
        nil
    }
}
