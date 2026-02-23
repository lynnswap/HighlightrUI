import Testing
@testable import HighlightrUICore

@MainActor
struct HighlightrEditorModelMutationTests {
    @Test
    func documentModelFieldsCanBeUpdated() {
        let model = HighlightrEditorModel(text: "start", language: "swift")

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
        let model = HighlightrEditorModel(language: "swift")

        model.isFocused = true
        model.isUndoable = true
        model.isRedoable = true
        model.hasText = true

        #expect(model.isFocused)
        #expect(model.isUndoable)
        #expect(model.isRedoable)
        #expect(model.hasText)
    }
}
