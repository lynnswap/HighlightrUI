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
    @State private var model = HighlightrEditorModel(
        text: DemoSnippet.swiftPackage.code,
        language: DemoSnippet.swiftPackage.language.editorLanguage
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                EditorHostView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background{
                        Rectangle().fill(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 8))
                    }

                HStack {
                    Label(
                        DemoLanguage.title(for: model.language),
                        systemImage: "curlybraces"
                    )
                    Spacer()
                    Label(
                        model.isEditable ? "Editable" : "Read Only",
                        systemImage: model.isEditable ? "pencil" : "lock"
                    )
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .scenePadding()
            .toolbar {
                ToolbarItem(placement:.navigation) {
                    Menu{
                        Picker("Sample", selection: $selectedSnippet) {
                            ForEach(DemoSnippet.allCases) { snippet in
                                Text(snippet.title).tag(snippet)
                            }
                        }
                        .pickerStyle(.inline)
                    }label:{
                        Text(selectedSnippet.title)
                    }
                }

                ToolbarItem(placement:.primaryAction) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            EditorSettingsSheet(
                selectedSnippet: $selectedSnippet,
                model: model
            )
        }
        .onChange(of: selectedSnippet, initial: true) {
            model.text = selectedSnippet.code
            model.language = selectedSnippet.language.editorLanguage
        }
    }
}

#Preview {
    ContentView()
}
