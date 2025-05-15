//
//  HighlightrThemeModifier.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/13.
//

import SwiftUI

public struct HighlightrThemeKey: EnvironmentKey {
    public static let defaultValue: Binding<String>? = nil
}

public extension EnvironmentValues {
    var highlightrTheme: Binding<String>? {
        get { self[HighlightrThemeKey.self] }
        set { self[HighlightrThemeKey.self] = newValue }
    }
}
struct HighlightrThemeModifier: ViewModifier {
    let theme: String
    func body(content: Content) -> some View {
        content.environment(\.highlightrTheme, .constant(theme))
    }
}
struct HighlightrThemeBindingModifier: ViewModifier {
    let theme: Binding<String>
    func body(content: Content) -> some View {
        content.environment(\.highlightrTheme, theme)
    }
}
public extension View where Self == HighlightrTextView {
    func theme(_ name: String) -> some View {
        modifier(HighlightrThemeModifier(theme: name))
    }
    func theme(_ name: Binding<String>) -> some View {
        modifier(HighlightrThemeBindingModifier(theme: name))
    }
}
