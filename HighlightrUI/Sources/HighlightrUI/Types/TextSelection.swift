import Foundation

public struct TextSelection: Hashable, Sendable, Equatable {
    public var location: Int
    public var length: Int

    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }

    public static let zero = TextSelection(location: 0, length: 0)
}
