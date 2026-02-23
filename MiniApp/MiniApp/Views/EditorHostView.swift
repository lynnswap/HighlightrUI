import SwiftUI
import HighlightrUI

#if os(iOS)
import UIKit

@MainActor
struct EditorHostView: UIViewRepresentable {
    let model: HighlightrEditorModel

    func makeUIView(context: Context) -> HighlightrEditorView {
        HighlightrEditorView(model: model)
    }

    func updateUIView(_ uiView: HighlightrEditorView, context: Context) {}
}
#elseif os(macOS)
import AppKit

@MainActor
struct EditorHostView: NSViewRepresentable {
    let model: HighlightrEditorModel

    func makeNSView(context: Context) -> HighlightrEditorView {
        HighlightrEditorView(model: model)
    }

    func updateNSView(_ nsView: HighlightrEditorView, context: Context) {}
}
#endif
