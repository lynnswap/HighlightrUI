import Foundation

@MainActor
final class HighlightPipeline {
    private let engine: any SyntaxHighlightingEngine
    private var task: Task<Void, Never>?
    private var revision: UInt64 = 0

    init(engine: any SyntaxHighlightingEngine) {
        self.engine = engine
    }

    isolated deinit {
        task?.cancel()
    }

    func stop() {
        task?.cancel()
        task = nil
        revision &+= 1
    }

    func schedule(
        source: String,
        range: NSRange,
        apply: @escaping @MainActor (_ payload: HighlightRenderPayload?, _ range: NSRange, _ expectedSource: String) -> Void
    ) {
        let sourceUTF16 = source as NSString
        let safeRange = Self.clampedRange(range, utf16Length: sourceUTF16.length)
        guard sourceUTF16.length > 0, safeRange.length > 0 else {
            stop()
            return
        }

        let expectedSource = sourceUTF16.substring(with: safeRange)
        revision &+= 1
        let currentRevision = revision

        task?.cancel()
        let engine = self.engine
        task = Task { [weak self] in
            let payload = await engine.renderHighlightPayload(source: source, in: safeRange)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }
                guard currentRevision == self.revision else { return }
                apply(payload, safeRange, expectedSource)
            }
        }
    }

    private static func clampedRange(_ range: NSRange, utf16Length: Int) -> NSRange {
        let location = min(max(0, range.location), utf16Length)
        let remaining = max(0, utf16Length - location)
        let length = min(max(0, range.length), remaining)
        return NSRange(location: location, length: length)
    }
}
