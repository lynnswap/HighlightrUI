import Testing
@testable import HighlightrUI

@MainActor
struct HighlightrEditorViewInitializationTests {
    @Test
    func initSetsDefaultValues() {
        let model = HighlightrEditorView(language: "swift")

        #expect(model.text == "")
        #expect(model.language == "swift")
        #expect(model.theme == .automatic(light: "paraiso-light", dark: "paraiso-dark"))
        #expect(model.selection == .zero)
        #expect(model.isEditable)
    }

    @Test
    func initAcceptsCustomValues() {
        let model = HighlightrEditorView(
            text: "print(1)",
            language: "javascript",
            theme: .named("atom-one-dark"),
            isEditable: false
        )

        #expect(model.text == "print(1)")
        #expect(model.language == "javascript")
        #expect(model.theme == .named("atom-one-dark"))
        #expect(model.selection == .zero)
        #expect(!model.isEditable)
    }
}

@MainActor
struct HighlightrEditorViewRuntimeInitializationTests {
    @Test
    func initSetsDefaultValues() {
        let model = HighlightrEditorView(language: "swift")

        #expect(!model.isEditorFocused)
        #expect(!model.isUndoable)
        #expect(!model.isRedoable)
        #expect(!model.hasText)
    }

    @Test
    func initAcceptsCustomValues() {
        let model = HighlightrEditorView(
            text: "x",
            language: "swift",
            isEditorFocused: true,
            isUndoable: true,
            isRedoable: false
        )

        #expect(model.isEditorFocused)
        #expect(!model.isUndoable)
        #expect(!model.isRedoable)
        #expect(model.hasText)
    }
}
