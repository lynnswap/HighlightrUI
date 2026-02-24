import Foundation
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class MockSyntaxHighlightingEngine: SyntaxHighlightingEngine {
    struct MakeTextStorageCall {
        let language: EditorLanguage
        let themeName: String
    }

    private(set) var makeTextStorageCalls: [MakeTextStorageCall] = []
    private(set) var setLanguageCalls: [EditorLanguage] = []
    private(set) var setThemeNameCalls: [String] = []

    var availableThemeNames: [String]

    private let storage = NSTextStorage(string: "")

    init(availableThemeNames: [String] = ["github", "paraiso-dark", "paraiso-light"]) {
        self.availableThemeNames = availableThemeNames
    }

    func makeTextStorage(initialLanguage: EditorLanguage, initialThemeName: String) -> NSTextStorage {
        makeTextStorageCalls.append(.init(language: initialLanguage, themeName: initialThemeName))
        return storage
    }

    func setLanguage(_ language: EditorLanguage) {
        setLanguageCalls.append(language)
    }

    func setThemeName(_ themeName: String) {
        setThemeNameCalls.append(themeName)
    }
}

private actor SuspendedRenderGate {
    private var didStart = false
    private var startContinuations: [CheckedContinuation<Void, Never>] = []
    private var pendingResultContinuation: CheckedContinuation<HighlightRenderPayload?, Never>?

    func markStarted() {
        didStart = true
        for continuation in startContinuations {
            continuation.resume()
        }
        startContinuations.removeAll()
    }

    func waitForStart() async {
        guard !didStart else { return }
        await withCheckedContinuation { continuation in
            startContinuations.append(continuation)
        }
    }

    func waitForResult() async -> HighlightRenderPayload? {
        await withCheckedContinuation { continuation in
            pendingResultContinuation = continuation
        }
    }

    func resume(with payload: HighlightRenderPayload? = nil) {
        guard let continuation = pendingResultContinuation else { return }
        pendingResultContinuation = nil
        continuation.resume(returning: payload)
    }
}

@MainActor
final class SuspendingSyntaxHighlightingEngine: SyntaxHighlightingEngine {
    var availableThemeNames: [String]

    private let storage = NSTextStorage(string: "")
    private let gate = SuspendedRenderGate()

    init(availableThemeNames: [String] = ["github", "paraiso-dark", "paraiso-light"]) {
        self.availableThemeNames = availableThemeNames
    }

    func makeTextStorage(initialLanguage: EditorLanguage, initialThemeName: String) -> NSTextStorage {
        storage
    }

    func setLanguage(_ language: EditorLanguage) {}

    func setThemeName(_ themeName: String) {}

    func renderHighlightPayload(source: String, in range: NSRange) async -> HighlightRenderPayload? {
        await gate.markStarted()
        return await gate.waitForResult()
    }

    func waitForRenderStart() async {
        await gate.waitForStart()
    }

    func resumeRender(with payload: HighlightRenderPayload? = nil) async {
        await gate.resume(with: payload)
    }
}
