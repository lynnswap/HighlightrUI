import Foundation
import Highlighter

@SyntaxHighlightActor
final class HighlighterRuntime {
    private let highlighter: Highlighter?
    private var activeThemeName: String?

    init() {
        self.highlighter = Highlighter()
        self.activeThemeName = nil
    }

    func render(
        source: String,
        in range: NSRange,
        languageName: String?,
        themeName: String
    ) -> HighlightRenderPayload? {
        guard !Task.isCancelled else { return nil }
        guard let highlighter else { return nil }

        if activeThemeName != themeName, highlighter.setTheme(themeName) {
            activeThemeName = themeName
        }

        guard !Task.isCancelled else { return nil }

        let normalizedLanguageName = Self.normalizedLanguageName(languageName)
        let attributed: NSAttributedString?
        let usedAutoDetection: Bool

        if let normalizedLanguageName {
            if let highlighted = highlighter.highlight(source, as: normalizedLanguageName) {
                attributed = highlighted
                usedAutoDetection = false
            } else {
                attributed = highlighter.highlight(source, as: nil)
                usedAutoDetection = true
            }
        } else {
            attributed = highlighter.highlight(source, as: nil)
            usedAutoDetection = true
        }

        guard !Task.isCancelled else { return nil }
        guard let attributed else { return nil }

        let safeRange = Self.clampedRange(range, length: attributed.length)
        guard safeRange.length > 0 else { return nil }

        let highlightedSlice = attributed.attributedSubstring(from: safeRange)
        let attributedText = AttributedString(highlightedSlice)

        return HighlightRenderPayload(
            attributedText: attributedText,
            utf16Length: highlightedSlice.length,
            languageName: usedAutoDetection ? nil : normalizedLanguageName,
            usedAutoDetection: usedAutoDetection
        )
    }

    private static func normalizedLanguageName(_ languageName: String?) -> String? {
        guard let languageName else { return nil }
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
