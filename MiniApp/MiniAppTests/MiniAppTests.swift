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
        let editorView = HighlightrEditorView(
            text: "print(\"hello\")",
            language: "swift"
        )

        #expect(editorView.text == "print(\"hello\")")
        #expect(editorView.language.rawValue == "swift")
    }
}
