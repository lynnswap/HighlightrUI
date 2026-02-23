import Testing
@testable import HighlightrUICore

@MainActor
struct HighlightrEditorModelInitializationTests {
    @Test
    func initSetsDefaultValues() {
        let model = HighlightrEditorModel(language: "swift")

        #expect(model.text == "")
        #expect(model.language == "swift")
        #expect(model.theme == .automatic(light: "paraiso-light", dark: "paraiso-dark"))
        #expect(model.selection == .zero)
        #expect(model.isEditable)
    }

    @Test
    func initAcceptsCustomValues() {
        let model = HighlightrEditorModel(
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
struct HighlightrEditorModelRuntimeInitializationTests {
    @Test
    func initSetsDefaultValues() {
        let model = HighlightrEditorModel(language: "swift")

        #expect(!model.isFocused)
        #expect(!model.isUndoable)
        #expect(!model.isRedoable)
        #expect(!model.hasText)
    }

    @Test
    func initAcceptsCustomValues() {
        let model = HighlightrEditorModel(
            language: "swift",
            isFocused: true,
            isUndoable: true,
            isRedoable: false,
            hasText: true
        )

        #expect(model.isFocused)
        #expect(model.isUndoable)
        #expect(!model.isRedoable)
        #expect(model.hasText)
    }
}
