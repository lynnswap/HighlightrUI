//
//  ContentView.swift
//  MiniApp
//
//  Created by Kazuki Nakashima on 2026/02/23.
//

import SwiftUI
import HighlightrUI

struct ContentView: View {
    @State private var selectedSnippet: DemoSnippet = .swiftPackage
    @State private var isSettingsPresented = false
    @State private var editorView = HighlightrEditorView(
        text: DemoSnippet.swiftPackage.code,
        language: DemoSnippet.swiftPackage.language.editorLanguage
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                EditorHostView(editorView: editorView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        Rectangle().fill(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    .accessibilityIdentifier("editor.host")

                HStack {
                    Label(
                        DemoLanguage.title(for: editorView.language),
                        systemImage: "curlybraces"
                    )
                    .accessibilityIdentifier("status.language")
                    Spacer()
                    Label(
                        editorView.isEditable ? "Editable" : "Read Only",
                        systemImage: editorView.isEditable ? "pencil" : "lock"
                    )
                    .accessibilityIdentifier("status.editable")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .scenePadding()
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Menu {
                        Picker("Sample", selection: $selectedSnippet) {
                            ForEach(DemoSnippet.allCases) { snippet in
                                Text(snippet.title).tag(snippet)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Text(selectedSnippet.title)
                    }
                    .accessibilityIdentifier("toolbar.snippetMenu")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .accessibilityIdentifier("toolbar.settingsButton")
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            EditorSettingsSheet(
                selectedSnippet: $selectedSnippet,
                editorView: editorView
            )
        }
        .onChange(of: selectedSnippet, initial: true) {
            editorView.text = selectedSnippet.code
            editorView.language = selectedSnippet.language.editorLanguage
        }
    }
}

#Preview {
    ContentView()
}
