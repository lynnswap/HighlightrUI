import Foundation
import HighlightrUICore

#if canImport(UIKit)
import UIKit

@MainActor
final class EditorCoordinator: NSObject, UITextViewDelegate {
    private let model: HighlightrEditorModel
    private weak var textView: UITextView?
    private let engine: any SyntaxHighlightingEngine

    private var documentTask: Task<Void, Never>?
    private var colorScheme: EditorColorScheme

    private var isApplyingFromDocument = false
    private var autoIndentOnNewline = false
    private var isHandlingAutoIndent = false
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
        applyDocumentSnapshot(currentDocumentObservation)
        let keepFocusedRequest = model.isFocused && !textView.isFirstResponder
        syncRuntimeStateFromView(textView, focusOverride: keepFocusedRequest ? true : nil)
        startDocumentSync()
    }

    isolated deinit {
        documentTask?.cancel()
        documentTask = nil
    }

    func applyAppearance(colorScheme: EditorColorScheme) {
        self.colorScheme = colorScheme
        applyThemeIfNeeded(model.theme, force: true)
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        autoIndentOnNewline = enabled
    }

    func syncStateFromView(focusOverride: Bool? = nil) {
        guard let textView, !isApplyingFromDocument else { return }

        let currentText = textView.text ?? ""
        if model.text != currentText {
            model.text = currentText
        }

        let selectedRange = textView.selectedRange
        let selection = TextSelection(location: selectedRange.location, length: selectedRange.length)
        if model.selection != selection {
            model.selection = selection
        }

        if model.isEditable != textView.isEditable {
            model.isEditable = textView.isEditable
        }

        syncRuntimeStateFromView(textView, focusOverride: focusOverride)
    }

    func syncViewFromModel() {
        applyDocumentSnapshot(currentDocumentObservation)
    }

    func textViewDidChange(_ textView: UITextView) {
        syncStateFromView()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        syncStateFromView()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        syncStateFromView(focusOverride: true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        syncStateFromView(focusOverride: false)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard
            autoIndentOnNewline,
            !isApplyingFromDocument,
            !isHandlingAutoIndent,
            text == "\n"
        else {
            return true
        }

        let currentText = textView.text ?? ""
        let safeRange = Self.clampedRange(range, in: currentText)
        let indent = Self.leadingIndent(in: currentText, at: safeRange.location)
        let replacement = "\n" + indent

        guard
            let start = textView.position(from: textView.beginningOfDocument, offset: safeRange.location),
            let end = textView.position(from: start, offset: safeRange.length),
            let textRange = textView.textRange(from: start, to: end)
        else {
            return true
        }

        isHandlingAutoIndent = true
        defer { isHandlingAutoIndent = false }

        textView.replace(textRange, withText: replacement)
        let cursorLocation = safeRange.location + (replacement as NSString).length
        if let position = textView.position(from: textView.beginningOfDocument, offset: cursorLocation),
           let selectedRange = textView.textRange(from: position, to: position) {
            textView.selectedTextRange = selectedRange
        }
        syncStateFromView()
        return false
    }

    private var currentDocumentObservation: EditorDocumentObservation {
        EditorDocumentObservation(model: model)
    }

    private func startDocumentSync() {
        documentTask?.cancel()
        let stream = observeDocumentState(model: model)
        documentTask = Task { [weak self] in
            for await snapshot in stream {
                if Task.isCancelled {
                    break
                }
                guard let self else {
                    break
                }
                guard snapshot == self.currentDocumentObservation else {
                    continue
                }
                self.applyDocumentSnapshot(snapshot)
            }
        }
    }

    private func applyDocumentSnapshot(_ snapshot: EditorDocumentObservation) {
        guard let textView else { return }

        isApplyingFromDocument = true
        defer { isApplyingFromDocument = false }

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

        var focusOverride: Bool?
        if snapshot.isFocused {
            if !textView.isFirstResponder {
                _ = textView.becomeFirstResponder()
            }
            if !textView.isFirstResponder {
                focusOverride = true
            }
        } else if textView.isFirstResponder {
            _ = textView.resignFirstResponder()
        }

        syncRuntimeStateFromView(textView, focusOverride: focusOverride)
    }

    private func syncRuntimeStateFromView(_ textView: UITextView, focusOverride: Bool? = nil) {
        let focused = focusOverride ?? textView.isFirstResponder
        if model.isFocused != focused {
            model.isFocused = focused
        }

        let canUndo = textView.undoManager?.canUndo ?? false
        if model.isUndoable != canUndo {
            model.isUndoable = canUndo
        }

        let canRedo = textView.undoManager?.canRedo ?? false
        if model.isRedoable != canRedo {
            model.isRedoable = canRedo
        }

        let hasText = !(textView.text ?? "").isEmpty
        if model.hasText != hasText {
            model.hasText = hasText
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

    private static func clampedRange(_ range: NSRange, in text: String) -> NSRange {
        let textLength = (text as NSString).length
        let location = min(max(0, range.location), textLength)
        let remaining = max(0, textLength - location)
        let length = min(max(0, range.length), remaining)
        return NSRange(location: location, length: length)
    }

    private static func leadingIndent(in text: String, at location: Int) -> String {
        let source = text as NSString
        guard source.length > 0 else { return "" }

        let safeLocation = min(max(0, location), source.length)
        let lineRange = source.lineRange(for: NSRange(location: safeLocation, length: 0))
        let line = source.substring(with: lineRange)
        guard let indentRange = line.range(of: "^[ \\t]*", options: .regularExpression) else {
            return ""
        }
        return String(line[indentRange])
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

    private var documentTask: Task<Void, Never>?
    private var colorScheme: EditorColorScheme

    private var isApplyingFromDocument = false
    private var autoIndentOnNewline = false
    private var isHandlingAutoIndent = false
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
        applyDocumentSnapshot(currentDocumentObservation)
        let keepFocusedRequest = model.isFocused && (textView.window?.firstResponder !== textView)
        syncRuntimeStateFromView(textView, focusOverride: keepFocusedRequest ? true : nil)
        startDocumentSync()
    }

    isolated deinit {
        documentTask?.cancel()
        documentTask = nil
    }

    func applyAppearance(colorScheme: EditorColorScheme) {
        self.colorScheme = colorScheme
        applyThemeIfNeeded(model.theme, force: true)
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        autoIndentOnNewline = enabled
    }

    func syncStateFromView(focusOverride: Bool? = nil) {
        guard let textView, !isApplyingFromDocument else { return }

        let currentText = textView.string
        if model.text != currentText {
            model.text = currentText
        }

        let selectedRange = textView.selectedRange()
        let selection = TextSelection(location: selectedRange.location, length: selectedRange.length)
        if model.selection != selection {
            model.selection = selection
        }

        if model.isEditable != textView.isEditable {
            model.isEditable = textView.isEditable
        }

        syncRuntimeStateFromView(textView, focusOverride: focusOverride)
    }

    func syncViewFromModel() {
        applyDocumentSnapshot(currentDocumentObservation)
    }

    func textDidChange(_ notification: Notification) {
        syncStateFromView()
    }

    func textDidBeginEditing(_ notification: Notification) {
        syncStateFromView(focusOverride: true)
    }

    func textDidEndEditing(_ notification: Notification) {
        syncStateFromView(focusOverride: false)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        syncStateFromView()
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString text: String?) -> Bool {
        guard
            autoIndentOnNewline,
            !isApplyingFromDocument,
            !isHandlingAutoIndent,
            text == "\n"
        else {
            return true
        }

        let safeRange = Self.clampedRange(range, in: textView.string)
        let indent = Self.leadingIndent(in: textView.string, at: safeRange.location)
        let replacement = "\n" + indent

        isHandlingAutoIndent = true
        defer { isHandlingAutoIndent = false }

        textView.insertText(replacement, replacementRange: safeRange)
        let cursorLocation = safeRange.location + (replacement as NSString).length
        textView.setSelectedRange(NSRange(location: cursorLocation, length: 0))
        syncStateFromView()
        return false
    }

    private var currentDocumentObservation: EditorDocumentObservation {
        EditorDocumentObservation(model: model)
    }

    private func startDocumentSync() {
        documentTask?.cancel()
        let stream = observeDocumentState(model: model)
        documentTask = Task { [weak self] in
            for await snapshot in stream {
                if Task.isCancelled {
                    break
                }
                guard let self else {
                    break
                }
                guard snapshot == self.currentDocumentObservation else {
                    continue
                }
                self.applyDocumentSnapshot(snapshot)
            }
        }
    }

    private func applyDocumentSnapshot(_ snapshot: EditorDocumentObservation) {
        guard let textView else { return }

        isApplyingFromDocument = true
        defer { isApplyingFromDocument = false }

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

        let isFocused = textView.window?.firstResponder === textView
        var focusOverride: Bool?
        if snapshot.isFocused {
            if !isFocused {
                _ = textView.window?.makeFirstResponder(textView)
            }
            if textView.window?.firstResponder !== textView {
                focusOverride = true
            }
        } else if isFocused {
            _ = textView.window?.makeFirstResponder(nil)
        }

        syncRuntimeStateFromView(textView, focusOverride: focusOverride)
    }

    private func syncRuntimeStateFromView(_ textView: NSTextView, focusOverride: Bool? = nil) {
        let focused = focusOverride ?? (textView.window?.firstResponder === textView)
        if model.isFocused != focused {
            model.isFocused = focused
        }

        let canUndo = textView.undoManager?.canUndo ?? false
        if model.isUndoable != canUndo {
            model.isUndoable = canUndo
        }

        let canRedo = textView.undoManager?.canRedo ?? false
        if model.isRedoable != canRedo {
            model.isRedoable = canRedo
        }

        let hasText = !textView.string.isEmpty
        if model.hasText != hasText {
            model.hasText = hasText
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

    private static func clampedRange(_ range: NSRange, in text: String) -> NSRange {
        let textLength = (text as NSString).length
        let location = min(max(0, range.location), textLength)
        let remaining = max(0, textLength - location)
        let length = min(max(0, range.length), remaining)
        return NSRange(location: location, length: length)
    }

    private static func leadingIndent(in text: String, at location: Int) -> String {
        let source = text as NSString
        guard source.length > 0 else { return "" }

        let safeLocation = min(max(0, location), source.length)
        let lineRange = source.lineRange(for: NSRange(location: safeLocation, length: 0))
        let line = source.substring(with: lineRange)
        guard let indentRange = line.range(of: "^[ \\t]*", options: .regularExpression) else {
            return ""
        }
        return String(line[indentRange])
    }
}

@MainActor
func editorColorScheme(from appearance: NSAppearance) -> EditorColorScheme {
    let bestMatch = appearance.bestMatch(from: [.aqua, .darkAqua])
    return bestMatch == .darkAqua ? .dark : .light
}
#endif
