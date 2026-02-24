import Foundation

@globalActor
enum SyntaxHighlightActor {
    actor SharedActor {}

    static let shared = SharedActor()
}
