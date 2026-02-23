import Foundation
import HighlightrUICore

#if canImport(UIKit)
import UIKit

@MainActor
final class EditorCoordinator: NSObject, UITextViewDelegate {
    private let model: HighlightrEditorModel
    private weak var textView: UITextView?
    private let engine: any SyntaxHighlightingEngine

    private var snapshotTask: Task<Void, Never>?
    private var colorScheme: EditorColorScheme

    private var sourceRevision: UInt64 = 0
    private var lastViewRevision: UInt64 = 0
    private var lastModelRevision: UInt64 = 0

    private var isApplyingFromModel = false
    private var appliedLanguage: EditorLanguage?
    private var appliedThemeName: String?

    init(
        model: HighlightrEditorModel,
        textView: UITextView,
        engine: any SyntaxHighlightingEngine,
        initialColorScheme: EditorColorScheme
    ) {
        self.model = model
        self.textView = textView
        self.engine = engine
        self.colorScheme = initialColorScheme
        super.init()

        textView.delegate = self
        applyModelSnapshot(model.snapshot())
        startSnapshotSync()
    }

    nonisolated func invalidate() {
        Task { @MainActor [weak self] in
            self?.snapshotTask?.cancel()
            self?.snapshotTask = nil
        }
    }

    func applyAppearance(colorScheme: EditorColorScheme) {
        self.colorScheme = colorScheme
        applyThemeIfNeeded(model.theme, force: true)
    }

    func textViewDidChange(_ textView: UITextView) {
        syncModelFromView()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        syncModelFromView()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        syncModelFromView(focusOverride: true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        syncModelFromView(focusOverride: false)
    }

    private func startSnapshotSync() {
        snapshotTask?.cancel()
        snapshotTask = Task { [weak self] in
            guard let self else { return }
            for await snapshot in model.snapshotStream() {
                if Task.isCancelled {
                    break
                }
                applyModelSnapshot(snapshot)
            }
        }
    }

    private func syncModelFromView(focusOverride: Bool? = nil) {
        guard let textView, !isApplyingFromModel else { return }

        sourceRevision &+= 1
        lastViewRevision = sourceRevision

        let currentText = textView.text ?? ""
        if model.text != currentText {
            model.text = currentText
        }

        let selectedRange = textView.selectedRange
        let selection = TextSelection(location: selectedRange.location, length: selectedRange.length)
        if model.selection != selection {
            model.selection = selection
        }

        let focused = focusOverride ?? textView.isFirstResponder
        if model.isFocused != focused {
            model.isFocused = focused
        }
    }

    private func applyModelSnapshot(_ snapshot: EditorSnapshot) {
        guard let textView else { return }

        sourceRevision &+= 1
        lastModelRevision = sourceRevision

        isApplyingFromModel = true
        defer { isApplyingFromModel = false }

        applyLanguageIfNeeded(snapshot.language)
        applyThemeIfNeeded(snapshot.theme)

        if textView.text != snapshot.text {
            textView.text = snapshot.text
        }

        let clampedSelection = Self.clampedSelection(snapshot.selection, text: textView.text ?? "")
        let clampedRange = NSRange(location: clampedSelection.location, length: clampedSelection.length)
        if textView.selectedRange != clampedRange {
            textView.selectedRange = clampedRange
        }

        if textView.isEditable != snapshot.isEditable {
            textView.isEditable = snapshot.isEditable
        }

        if snapshot.isFocused {
            if !textView.isFirstResponder {
                _ = textView.becomeFirstResponder()
            }
        } else if textView.isFirstResponder {
            _ = textView.resignFirstResponder()
        }
    }

    private func applyLanguageIfNeeded(_ language: EditorLanguage) {
        guard language != appliedLanguage else { return }
        engine.setLanguage(language)
        appliedLanguage = language
    }

    private func applyThemeIfNeeded(_ theme: EditorTheme, force: Bool = false) {
        let themeName = theme.resolvedThemeName(for: colorScheme)
        guard force || themeName != appliedThemeName else { return }
        engine.setThemeName(themeName)
        appliedThemeName = themeName
    }

    private static func clampedSelection(_ selection: TextSelection, text: String) -> TextSelection {
        let textLength = (text as NSString).length
        let clampedLocation = min(max(0, selection.location), textLength)
        let remaining = max(0, textLength - clampedLocation)
        let clampedLength = min(max(0, selection.length), remaining)
        return TextSelection(location: clampedLocation, length: clampedLength)
    }
}

@MainActor
func editorColorScheme(from style: UIUserInterfaceStyle) -> EditorColorScheme {
    style == .dark ? .dark : .light
}

#elseif canImport(AppKit)
import AppKit

@MainActor
final class EditorCoordinator: NSObject, NSTextViewDelegate {
    private let model: HighlightrEditorModel
    private weak var textView: NSTextView?
    private let engine: any SyntaxHighlightingEngine

    private var snapshotTask: Task<Void, Never>?
    private var colorScheme: EditorColorScheme

    private var sourceRevision: UInt64 = 0
    private var lastViewRevision: UInt64 = 0
    private var lastModelRevision: UInt64 = 0

    private var isApplyingFromModel = false
    private var appliedLanguage: EditorLanguage?
    private var appliedThemeName: String?

    init(
        model: HighlightrEditorModel,
        textView: NSTextView,
        engine: any SyntaxHighlightingEngine,
        initialColorScheme: EditorColorScheme
    ) {
        self.model = model
        self.textView = textView
        self.engine = engine
        self.colorScheme = initialColorScheme
        super.init()

        textView.delegate = self
        applyModelSnapshot(model.snapshot())
        startSnapshotSync()
    }

    nonisolated func invalidate() {
        Task { @MainActor [weak self] in
            self?.snapshotTask?.cancel()
            self?.snapshotTask = nil
        }
    }

    func applyAppearance(colorScheme: EditorColorScheme) {
        self.colorScheme = colorScheme
        applyThemeIfNeeded(model.theme, force: true)
    }

    func textDidChange(_ notification: Notification) {
        syncModelFromView()
    }

    func textDidBeginEditing(_ notification: Notification) {
        syncModelFromView(focusOverride: true)
    }

    func textDidEndEditing(_ notification: Notification) {
        syncModelFromView(focusOverride: false)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        syncModelFromView()
    }

    private func startSnapshotSync() {
        snapshotTask?.cancel()
        snapshotTask = Task { [weak self] in
            guard let self else { return }
            for await snapshot in model.snapshotStream() {
                if Task.isCancelled {
                    break
                }
                applyModelSnapshot(snapshot)
            }
        }
    }

    private func syncModelFromView(focusOverride: Bool? = nil) {
        guard let textView, !isApplyingFromModel else { return }

        sourceRevision &+= 1
        lastViewRevision = sourceRevision

        let currentText = textView.string
        if model.text != currentText {
            model.text = currentText
        }

        let selectedRange = textView.selectedRange()
        let selection = TextSelection(location: selectedRange.location, length: selectedRange.length)
        if model.selection != selection {
            model.selection = selection
        }

        let focused = focusOverride ?? (textView.window?.firstResponder === textView)
        if model.isFocused != focused {
            model.isFocused = focused
        }
    }

    private func applyModelSnapshot(_ snapshot: EditorSnapshot) {
        guard let textView else { return }

        sourceRevision &+= 1
        lastModelRevision = sourceRevision

        isApplyingFromModel = true
        defer { isApplyingFromModel = false }

        applyLanguageIfNeeded(snapshot.language)
        applyThemeIfNeeded(snapshot.theme)

        if textView.string != snapshot.text {
            textView.string = snapshot.text
        }

        let clampedSelection = Self.clampedSelection(snapshot.selection, text: textView.string)
        let clampedRange = NSRange(location: clampedSelection.location, length: clampedSelection.length)
        if textView.selectedRange() != clampedRange {
            textView.setSelectedRange(clampedRange)
        }

        if textView.isEditable != snapshot.isEditable {
            textView.isEditable = snapshot.isEditable
        }

        if snapshot.isFocused {
            if textView.window?.firstResponder !== textView {
                textView.window?.makeFirstResponder(textView)
            }
        } else if textView.window?.firstResponder === textView {
            textView.window?.makeFirstResponder(nil)
        }
    }

    private func applyLanguageIfNeeded(_ language: EditorLanguage) {
        guard language != appliedLanguage else { return }
        engine.setLanguage(language)
        appliedLanguage = language
    }

    private func applyThemeIfNeeded(_ theme: EditorTheme, force: Bool = false) {
        let themeName = theme.resolvedThemeName(for: colorScheme)
        guard force || themeName != appliedThemeName else { return }
        engine.setThemeName(themeName)
        appliedThemeName = themeName
    }

    private static func clampedSelection(_ selection: TextSelection, text: String) -> TextSelection {
        let textLength = (text as NSString).length
        let clampedLocation = min(max(0, selection.location), textLength)
        let remaining = max(0, textLength - clampedLocation)
        let clampedLength = min(max(0, selection.length), remaining)
        return TextSelection(location: clampedLocation, length: clampedLength)
    }
}

@MainActor
func editorColorScheme(from appearance: NSAppearance) -> EditorColorScheme {
    let bestMatch = appearance.bestMatch(from: [.aqua, .darkAqua])
    return bestMatch == .darkAqua ? .dark : .light
}
#endif
