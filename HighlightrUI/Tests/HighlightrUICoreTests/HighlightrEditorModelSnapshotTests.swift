import Testing
@testable import HighlightrUI

@MainActor
struct HighlightrEditorViewMutationTests {
    @Test
    func documentModelFieldsCanBeUpdated() {
        let model = HighlightrEditorView(text: "start", language: "swift")

        model.text = "updated"
        model.language = "javascript"
        model.theme = .named("atom-one-dark")
        model.selection = TextSelection(location: 2, length: 3)
        model.isEditable = false

        #expect(model.text == "updated")
        #expect(model.language == "javascript")
        #expect(model.theme == .named("atom-one-dark"))
        #expect(model.selection == TextSelection(location: 2, length: 3))
        #expect(!model.isEditable)
    }

    @Test
    func runtimeModelFieldsCanBeUpdated() {
        let model = HighlightrEditorView(language: "swift")

        model.text = "content"
        model.isEditorFocused = true
        model.isUndoable = true
        model.isRedoable = true

        #expect(model.isEditorFocused)
        #expect(model.isUndoable)
        #expect(model.isRedoable)
        #expect(model.hasText)
    }
}
