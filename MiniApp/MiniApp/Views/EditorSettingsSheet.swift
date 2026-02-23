import SwiftUI
import HighlightrUI
import Observation

struct EditorSettingsSheet: View {
    @Binding var selectedSnippet: DemoSnippet
    @Bindable var model: HighlightrEditorModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    Picker("Sample", selection: $selectedSnippet) {
                        ForEach(DemoSnippet.allCases) { snippet in
                            Text(snippet.title).tag(snippet)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("settings.samplePicker")

                    Picker("Language", selection: $model.language) {
                        ForEach(DemoLanguage.allCases) { language in
                            Text(language.title).tag(language.editorLanguage)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("settings.languagePicker")

                    Toggle("Editable", isOn: $model.isEditable)
                        .accessibilityIdentifier("settings.editableToggle")
                }

                Section("Appearance") {
                    Picker("Theme", selection: $model.theme) {
                        ForEach(DemoTheme.allCases) { theme in
                            Text(theme.title).tag(theme.editorTheme)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("settings.themePicker")
                }
            }
            .accessibilityIdentifier("settings.form")
            .navigationTitle("Editor Settings")
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("settings.doneButton")
                }
            }
        }
#if os(iOS)
        .presentationDetents([.medium, .large])
#endif
    }
}
