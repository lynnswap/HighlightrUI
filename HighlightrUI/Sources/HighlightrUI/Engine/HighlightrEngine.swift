import Foundation
import Highlighter

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
public final class HighlightrEngine: SyntaxHighlightingEngine {
    private var runtime: HighlighterRuntime?
    private var runtimeInitializationTask: Task<HighlighterRuntime, Never>?
    private let validThemeNames: Set<String>
    private let sortedThemeNames: [String]
    private let fallbackThemeName: String
    private var languageName: String?
    private var themeName: String

    public init() {
        let highlighter = Highlighter()
        let themeNames = highlighter?.availableThemes().sorted() ?? []
        self.validThemeNames = Set(themeNames)
        self.sortedThemeNames = themeNames
        self.fallbackThemeName = themeNames.contains("default") ? "default" : (themeNames.first ?? "default")
        self.runtime = nil
        self.runtimeInitializationTask = nil
        self.languageName = nil
        self.themeName = fallbackThemeName
    }

    public var availableThemeNames: [String] {
        sortedThemeNames
    }

    public func makeTextStorage(initialLanguage: EditorLanguage, initialThemeName: String) -> NSTextStorage {
        languageName = Self.normalizedLanguageName(initialLanguage.rawValue)
        if validThemeNames.contains(initialThemeName) {
            themeName = initialThemeName
        } else {
            themeName = fallbackThemeName
        }
        return NSTextStorage()
    }

    public func setLanguage(_ language: EditorLanguage) {
        languageName = Self.normalizedLanguageName(language.rawValue)
    }

    public func setThemeName(_ themeName: String) {
        guard validThemeNames.contains(themeName) else { return }
        self.themeName = themeName
    }

    public func renderHighlightPayload(source: String, in range: NSRange) async -> HighlightRenderPayload? {
        let sourceUTF16 = source as NSString
        let safeRange = Self.clampedRange(range, length: sourceUTF16.length)
        guard safeRange.length > 0 else { return nil }

        let runtime = await resolvedRuntime()
        return await runtime.render(
            source: source,
            in: safeRange,
            languageName: languageName,
            themeName: themeName
        )
    }

    private func resolvedRuntime() async -> HighlighterRuntime {
        if let runtime {
            return runtime
        }
        if let runtimeInitializationTask {
            let createdRuntime = await runtimeInitializationTask.value
            runtime = createdRuntime
            self.runtimeInitializationTask = nil
            return createdRuntime
        }

        let runtimeInitializationTask = Task {
            await HighlighterRuntime()
        }
        self.runtimeInitializationTask = runtimeInitializationTask

        let createdRuntime = await runtimeInitializationTask.value
        runtime = createdRuntime
        self.runtimeInitializationTask = nil
        return createdRuntime
    }

    private static func normalizedLanguageName(_ languageName: String) -> String? {
        let trimmed = languageName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func clampedRange(_ range: NSRange, length: Int) -> NSRange {
        let location = min(max(0, range.location), length)
        let remaining = max(0, length - location)
        let clampedLength = min(max(0, range.length), remaining)
        return NSRange(location: location, length: clampedLength)
    }
}
