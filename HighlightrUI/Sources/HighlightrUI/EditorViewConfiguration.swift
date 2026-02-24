import Foundation

public struct EditorViewConfiguration: Sendable, Equatable {
    public var lineWrappingEnabled: Bool
    public var allowsUndo: Bool

    public init(lineWrappingEnabled: Bool = false, allowsUndo: Bool = true) {
        self.lineWrappingEnabled = lineWrappingEnabled
        self.allowsUndo = allowsUndo
    }
}
