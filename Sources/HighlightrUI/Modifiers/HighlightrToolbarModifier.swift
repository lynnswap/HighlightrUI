//
//  HighlightrToolbarModifier.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/14.
//
import SwiftUI
struct HighlightrToolbarModifier: ViewModifier {
    var model:HighlightrTextViewModel
    @Binding var text:String
    
    @State private var store = HighlightrStore.shared
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("PDHighlightr_theme") var theme :String = "default"
    
    func body(content: Content) -> some View {
        content
            .toolbar{
#if os(macOS)
                let placement = ToolbarItemPlacement.primaryAction
#else
                let placement = ToolbarItemPlacement.secondaryAction
#endif
                ToolbarItem(placement: placement){
                    Picker(String(localized:"theme"),selection: $theme) {
                        Section{
                            Text(String(localized:"default")).tag("default")
                        }
                        Section{
                            ForEach(store.availableThemes,id:\.self) { theme in
                                Text(theme).tag(theme)
                            }
                        }
                    }
                }
            }
            .task(id: theme){
                if theme == "default"{
                    model.setTheme(defaultTheme)
                }else{
                    model.setTheme(theme)
                }
            }
            .task(id: text) { syncFromBinding(model) }
            .onChange(of: model.text) { if model.text != text { text = model.text } }
            .onChange(of:colorScheme){
                if theme == "default"{
                    model.setTheme(defaultTheme)
                }
            }
    }
    private func syncFromBinding(_ model:HighlightrTextViewModel) {
        if model.text != text {
            model.setText(text, initial: true)
        }
    }
    private var defaultTheme:String{
        colorScheme == .dark ? "paraiso-dark" : "paraiso-light"
    }
}
extension View {
    func highlightrToolbar(
        _ model: HighlightrTextViewModel,
        text:Binding<String>
    ) -> some View {
        modifier(
            HighlightrToolbarModifier(
                model:model,
                text:text
            )
        )
    }
}
