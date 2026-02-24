import Testing
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit

@MainActor
struct HighlightrEditorViewControllerTests {
    @Test
    func loadViewUsesProvidedEditorView() {
        let editorView = HighlightrEditorView(
            language: "swift",
        )
        let controller = HighlightrEditorViewController(editorView: editorView)

        controller.loadViewIfNeeded()

        #expect(controller.view === editorView)
        #expect(controller.editorView === editorView)
    }

    @Test
    func initWithModelCreatesEditorViewUsingModel() {
        let model = HighlightrEditorView(language: "swift")
        let controller = HighlightrEditorViewController(
            editorView: model,
        )

        controller.loadViewIfNeeded()

        #expect(controller.editorView.text == model.text)
        #expect(controller.editorView.language == model.language)
        #expect(controller.view === controller.editorView)
    }
}

#elseif canImport(AppKit)
import AppKit

@MainActor
struct HighlightrEditorViewControllerTests {
    @Test
    func loadViewUsesProvidedEditorView() {
        let editorView = HighlightrEditorView(
            language: "swift",
        )
        let controller = HighlightrEditorViewController(editorView: editorView)

        controller.loadView()

        #expect(controller.view === editorView)
        #expect(controller.editorView === editorView)
    }

    @Test
    func initWithModelCreatesEditorViewUsingModel() {
        let model = HighlightrEditorView(language: "swift")
        let controller = HighlightrEditorViewController(
            editorView: model,
        )

        controller.loadView()

        #expect(controller.editorView.text == model.text)
        #expect(controller.editorView.language == model.language)
        #expect(controller.view === controller.editorView)
    }
}
#endif
