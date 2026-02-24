import SwiftUI
import HighlightrUI

#if os(iOS)
import UIKit

@MainActor
struct EditorHostView: UIViewControllerRepresentable {
    let model: HighlightrModel

    func makeUIViewController(context: Context) -> HighlightrEditorViewController {
        let controller = HighlightrEditorViewController(model: model)
        controller.editorView.accessibilityIdentifier = "editor.host"
        return controller
    }

    func updateUIViewController(_ uiViewController: HighlightrEditorViewController, context: Context) {}
}
#elseif os(macOS)
import AppKit

@MainActor
struct EditorHostView: NSViewControllerRepresentable {
    let model: HighlightrModel

    func makeNSViewController(context: Context) -> HighlightrEditorViewController {
        let controller = HighlightrEditorViewController(model: model)
        controller.editorView.setAccessibilityIdentifier("editor.host")
        return controller
    }

    func updateNSViewController(_ nsViewController: HighlightrEditorViewController, context: Context) {}
}
#endif
