import Testing
@testable import HighlightrUICore

@MainActor
struct HighlightrEditorModelStateTests {
    @Test
    func documentStateMaintainsIndependentFields() {
        let model = HighlightrEditorModel(text: "a", language: "swift")

        model.text = "b"
        model.selection = TextSelection(location: 1, length: 0)

        #expect(model.text == "b")
        #expect(model.selection == TextSelection(location: 1, length: 0))
        #expect(model.language == "swift")
        #expect(model.theme == .automatic(light: "paraiso-light", dark: "paraiso-dark"))
    }

    @Test
    func runtimeStateMaintainsIndependentFields() {
        let model = HighlightrEditorModel(
            language: "swift",
            isFocused: false,
            isUndoable: false,
            isRedoable: false,
            hasText: false
        )

        model.isUndoable = true
        model.isRedoable = true
        model.hasText = true

        #expect(!model.isFocused)
        #expect(model.isUndoable)
        #expect(model.isRedoable)
        #expect(model.hasText)
    }
}
