#if DEBUG && canImport(SwiftUI)
import HighlightrUICore
import SwiftUI

private enum HighlightrEditorViewControllerPreviewFactory {
    @MainActor
    static func makeModel() -> HighlightrEditorModel {
        HighlightrEditorModel(
            text: """
            func compute(_ value: Int) -> Int {
                if value <= 1 { return 1 }
                return value * compute(value - 1)
            }
            """,
            language: "swift"
        )
    }
}

#if canImport(UIKit)
import UIKit

@MainActor
private struct HighlightrEditorViewControllerPreviewContainer: UIViewControllerRepresentable {
    final class Coordinator {
        var didFocus = false
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> HighlightrEditorViewController {
        HighlightrEditorViewController(model: HighlightrEditorViewControllerPreviewFactory.makeModel())
    }

    func updateUIViewController(_ uiViewController: HighlightrEditorViewController, context: Context) {
        guard context.coordinator.didFocus == false else {
            return
        }
        context.coordinator.didFocus = true

        uiViewController.loadViewIfNeeded()
        uiViewController.perform(.focus)
    }
}
#elseif canImport(AppKit)
import AppKit

private struct HighlightrEditorViewControllerPreviewContainer: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> HighlightrEditorViewController {
        HighlightrEditorViewController(model: HighlightrEditorViewControllerPreviewFactory.makeModel())
    }

    func updateNSViewController(_ nsViewController: HighlightrEditorViewController, context: Context) {}
}
#endif

#Preview("HighlightrEditorViewController") {
#if canImport(UIKit)
    HighlightrEditorViewControllerPreviewContainer()
#elseif canImport(AppKit)
    HighlightrEditorViewControllerPreviewContainer()
        .frame(minWidth: 640, minHeight: 360)
#endif
}
#endif
