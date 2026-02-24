#if DEBUG && canImport(SwiftUI)
import SwiftUI

private enum HighlightrEditorViewPreviewFactory {
    @MainActor
    static var previewText: String {
        """
        import Foundation

        struct Hello {
            func greet(name: String) -> String {
                "Hello, \\(name)"
            }
        }
        """
    }
}

#if canImport(UIKit)
import UIKit

private struct HighlightrEditorViewPreviewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> HighlightrEditorView {
        let model = HighlightrModel(
            text: HighlightrEditorViewPreviewFactory.previewText,
            language: "swift"
        )
        return HighlightrEditorView(
            model: model
        )
    }

    func updateUIView(_ uiView: HighlightrEditorView, context: Context) {}
}
#elseif canImport(AppKit)
import AppKit

private struct HighlightrEditorViewPreviewContainer: NSViewRepresentable {
    func makeNSView(context: Context) -> HighlightrEditorView {
        let model = HighlightrModel(
            text: HighlightrEditorViewPreviewFactory.previewText,
            language: "swift"
        )
        return HighlightrEditorView(
            model: model
        )
    }

    func updateNSView(_ nsView: HighlightrEditorView, context: Context) {}
}
#endif

#Preview("HighlightrEditorView") {
#if canImport(UIKit)
    HighlightrEditorViewPreviewContainer()
#elseif canImport(AppKit)
    HighlightrEditorViewPreviewContainer()
        .frame(minWidth: 640, minHeight: 360)
#endif
}
#endif
