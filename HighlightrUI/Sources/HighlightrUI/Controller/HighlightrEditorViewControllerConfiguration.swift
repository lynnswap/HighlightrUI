import Foundation

public struct HighlightrEditorViewControllerConfiguration: Sendable {
    public var autoIndentOnNewline: Bool

    public init(autoIndentOnNewline: Bool = true) {
        self.autoIndentOnNewline = autoIndentOnNewline
    }
}
