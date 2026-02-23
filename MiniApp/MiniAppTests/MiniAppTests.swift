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
    func highlightrEditorModelCanBeCreated() async throws {
        let model = HighlightrEditorModel(
            text: "print(\"hello\")",
            language: "swift"
        )

        #expect(model.text == "print(\"hello\")")
        #expect(model.language.rawValue == "swift")
    }
}
