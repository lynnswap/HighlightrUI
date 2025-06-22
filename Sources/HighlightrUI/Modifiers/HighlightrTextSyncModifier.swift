//
//  HighlightrTextSyncModifier.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/14.
//

import SwiftUI
struct HighlightrTextSyncModifier: ViewModifier {
    var model: HighlightrTextViewModel
    @Binding var text: String

    func body(content: Content) -> some View {
        content
            .task(id: text) { syncFromBinding(model) }
            .onChange(of: model.text) { if model.text != text { text = model.text } }
    }
    private func syncFromBinding(_ model: HighlightrTextViewModel) {
        if model.text != text {
            model.setText(text, initial: true)
        }
    }
}

extension View {
    func highlightrTextSync(
        _ model: HighlightrTextViewModel,
        text: Binding<String>
    ) -> some View {
        modifier(
            HighlightrTextSyncModifier(
                model: model,
                text: text
            )
        )
    }
}
