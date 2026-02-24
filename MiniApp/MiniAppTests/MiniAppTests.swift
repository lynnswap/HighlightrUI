//
//  MiniAppTests.swift
//  MiniAppTests
//
//  Created by Kazuki Nakashima on 2026/02/23.
//

import Testing
import HighlightrUI

struct MiniAppTests {

    @MainActor
    @Test
    func highlightrEditorViewCanBeCreated() async throws {
        let model = HighlightrModel(
            text: "print(\"hello\")",
            language: "swift"
        )
        let editorView = HighlightrEditorView(model: model)

        #expect(editorView.model.text == "print(\"hello\")")
        #expect(editorView.model.language.rawValue == "swift")
    }
}
