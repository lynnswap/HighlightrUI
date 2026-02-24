import Testing
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit

@MainActor
struct HighlightrEditorViewControllerTests {
    @Test
    func loadViewUsesProvidedEditorView() {
        let editorView = makeEditorView(
            language: "swift",
        )
        let controller = HighlightrEditorViewController(editorView: editorView)

        controller.loadViewIfNeeded()

        #expect(controller.view === editorView)
        #expect(controller.editorView === editorView)
    }

    @Test
    func initWithModelCreatesEditorViewUsingModel() {
        let model = HighlightrModel(language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()

        #expect(controller.editorView.model.text == model.text)
        #expect(controller.editorView.model.language == model.language)
        #expect(controller.view === controller.editorView)
    }
}

#elseif canImport(AppKit)
import AppKit

@MainActor
struct HighlightrEditorViewControllerTests {
    @Test
    func loadViewUsesProvidedEditorView() {
        let editorView = makeEditorView(
            language: "swift",
        )
        let controller = HighlightrEditorViewController(editorView: editorView)

        controller.loadView()

        #expect(controller.view === editorView)
        #expect(controller.editorView === editorView)
    }

    @Test
    func initWithModelCreatesEditorViewUsingModel() {
        let model = HighlightrModel(language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadView()

        #expect(controller.editorView.model.text == model.text)
        #expect(controller.editorView.model.language == model.language)
        #expect(controller.view === controller.editorView)
    }
}
#endif
