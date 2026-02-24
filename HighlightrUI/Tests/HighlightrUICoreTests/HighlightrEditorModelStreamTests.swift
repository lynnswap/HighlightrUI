import Testing
@testable import HighlightrUI

@MainActor
struct HighlightrEditorViewStateTests {
    @Test
    func documentStateMaintainsIndependentFields() {
        let model = HighlightrEditorView(text: "a", language: "swift")

        model.text = "b"
        model.selection = TextSelection(location: 1, length: 0)

        #expect(model.text == "b")
        #expect(model.selection == TextSelection(location: 1, length: 0))
        #expect(model.language == "swift")
        #expect(model.theme == .automatic(light: "paraiso-light", dark: "paraiso-dark"))
    }

    @Test
    func runtimeStateMaintainsIndependentFields() {
        let model = HighlightrEditorView(
            language: "swift",
            isEditorFocused: false,
            isUndoable: false,
            isRedoable: false
        )

        model.text = "b"
        model.isUndoable = true
        model.isRedoable = true

        #expect(!model.isEditorFocused)
        #expect(model.isUndoable)
        #expect(model.isRedoable)
        #expect(model.hasText)
    }
}
