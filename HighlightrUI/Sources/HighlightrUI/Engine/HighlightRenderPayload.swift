import Foundation

public struct HighlightRenderPayload: Sendable {
    public let attributedText: AttributedString
    public let utf16Length: Int
    public let languageName: String?
    public let usedAutoDetection: Bool

    public init(
        attributedText: AttributedString,
        utf16Length: Int,
        languageName: String?,
        usedAutoDetection: Bool
    ) {
        self.attributedText = attributedText
        self.utf16Length = utf16Length
        self.languageName = languageName
        self.usedAutoDetection = usedAutoDetection
    }
}
