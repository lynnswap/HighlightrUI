import Foundation

@MainActor
enum AsyncDrain {
    static func firstTurn() async {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    static func shortDelay() async {
        try? await Task.sleep(nanoseconds: 150_000_000)
    }
}
