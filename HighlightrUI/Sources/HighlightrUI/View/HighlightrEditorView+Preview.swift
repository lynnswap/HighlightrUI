#if DEBUG && canImport(SwiftUI)
import HighlightrUICore
import SwiftUI

private enum HighlightrEditorViewPreviewFactory {
    @MainActor
    static func makeModel() -> HighlightrEditorModel {
        HighlightrEditorModel(
            text: """
            import Foundation

            struct Hello {
                func greet(name: String) -> String {
                    "Hello, \\(name)"
                }
            }
            """,
            language: "swift"
        )
    }
}

#if canImport(UIKit)
import UIKit

private struct HighlightrEditorViewPreviewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> HighlightrEditorView {
        HighlightrEditorView(model: HighlightrEditorViewPreviewFactory.makeModel())
    }

    func updateUIView(_ uiView: HighlightrEditorView, context: Context) {}
}
#elseif canImport(AppKit)
import AppKit

private struct HighlightrEditorViewPreviewContainer: NSViewRepresentable {
    func makeNSView(context: Context) -> HighlightrEditorView {
        HighlightrEditorView(model: HighlightrEditorViewPreviewFactory.makeModel())
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
