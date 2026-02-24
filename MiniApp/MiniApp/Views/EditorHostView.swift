import SwiftUI
import HighlightrUI

#if os(iOS)
import UIKit

@MainActor
struct EditorHostView: UIViewControllerRepresentable {
    let editorView: HighlightrEditorView

    func makeUIViewController(context: Context) -> HighlightrEditorViewController {
        let controller = HighlightrEditorViewController(editorView: editorView)
        controller.editorView.accessibilityIdentifier = "editor.host"
        return controller
    }

    func updateUIViewController(_ uiViewController: HighlightrEditorViewController, context: Context) {}
}
#elseif os(macOS)
import AppKit

@MainActor
struct EditorHostView: NSViewControllerRepresentable {
    let editorView: HighlightrEditorView

    func makeNSViewController(context: Context) -> HighlightrEditorViewController {
        let controller = HighlightrEditorViewController(editorView: editorView)
        controller.editorView.setAccessibilityIdentifier("editor.host")
        return controller
    }

    func updateNSViewController(_ nsViewController: HighlightrEditorViewController, context: Context) {}
}
#endif
