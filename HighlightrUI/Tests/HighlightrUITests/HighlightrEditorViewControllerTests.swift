import HighlightrUICore
import Testing
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit

@MainActor
struct HighlightrEditorViewControllerTests {
    @Test
    func loadViewUsesProvidedEditorView() {
        let editorView = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )
        let controller = HighlightrEditorViewController(editorView: editorView)

        controller.loadViewIfNeeded()

        #expect(controller.view === editorView)
        #expect(controller.editorView === editorView)
    }

    @Test
    func initWithModelCreatesEditorViewUsingModel() {
        let model = HighlightrEditorModel(language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()

        #expect(controller.editorView.model === model)
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
            model: HighlightrEditorModel(language: "swift"),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )
        let controller = HighlightrEditorViewController(editorView: editorView)

        controller.loadView()

        #expect(controller.view === editorView)
        #expect(controller.editorView === editorView)
    }

    @Test
    func initWithModelCreatesEditorViewUsingModel() {
        let model = HighlightrEditorModel(language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadView()

        #expect(controller.editorView.model === model)
        #expect(controller.view === controller.editorView)
    }
}
#endif
