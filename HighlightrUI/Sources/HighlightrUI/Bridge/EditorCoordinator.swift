import Foundation

#if canImport(UIKit)
import UIKit

@MainActor
final class EditorCoordinator: NSObject, UITextViewDelegate {
    private unowned let owner: HighlightrEditorView
    private weak var textView: UITextView?
    private let engine: any SyntaxHighlightingEngine

    private var colorScheme: EditorColorScheme

    private var isApplyingFromOwner = false
    private var autoIndentOnNewline = false
    private var isHandlingAutoIndent = false
    private var appliedLanguage: EditorLanguage?
    private var appliedThemeName: String?

    init(
        owner: HighlightrEditorView,
        textView: UITextView,
        engine: any SyntaxHighlightingEngine,
        initialColorScheme: EditorColorScheme
    ) {
        self.owner = owner
        self.textView = textView
        self.engine = engine
        self.colorScheme = initialColorScheme
        super.init()

        textView.delegate = self
        syncViewFromOwner(syncRuntimeState: false)
    }

    func applyAppearance(colorScheme: EditorColorScheme) {
        self.colorScheme = colorScheme
        applyThemeIfNeeded(owner.theme, force: true)
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        autoIndentOnNewline = enabled
    }

    func syncStateFromView(focusOverride: Bool? = nil) {
        guard let textView, !isApplyingFromOwner else { return }

        let currentText = textView.text ?? ""
        let selectedRange = textView.selectedRange
        let selection = TextSelection(location: selectedRange.location, length: selectedRange.length)
        let editable = textView.isEditable

        if owner.text != currentText || owner.selection != selection || owner.isEditable != editable {
            owner.applyPlatformDocumentState(
                text: currentText,
                selection: selection,
                isEditable: editable
            )
        }

        syncRuntimeStateFromView(textView, focusOverride: focusOverride)
    }

    func syncViewFromOwner(syncRuntimeState: Bool = true) {
        applyOwnerState(syncRuntimeState: syncRuntimeState)
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
            !isApplyingFromOwner,
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

    private func applyOwnerState(syncRuntimeState: Bool) {
        guard let textView else { return }

        isApplyingFromOwner = true
        defer { isApplyingFromOwner = false }

        applyLanguageIfNeeded(owner.language)
        applyThemeIfNeeded(owner.theme)

        let shouldResetUndoHistory = textView.text != owner.text
        if shouldResetUndoHistory {
            textView.text = owner.text
            textView.undoManager?.removeAllActions()
        }

        let clampedSelection = Self.clampedSelection(owner.selection, text: textView.text ?? "")
        if owner.selection != clampedSelection {
            owner.applyPlatformSelectionState(clampedSelection)
        }
        let clampedRange = NSRange(location: clampedSelection.location, length: clampedSelection.length)
        if textView.selectedRange != clampedRange {
            textView.selectedRange = clampedRange
        }

        if textView.isEditable != owner.isEditable {
            textView.isEditable = owner.isEditable
        }

        var focusOverride: Bool?
        if owner.isEditorFocused {
            if !textView.isFirstResponder {
                _ = textView.becomeFirstResponder()
            }
            if !textView.isFirstResponder {
                focusOverride = true
            }
        } else if textView.isFirstResponder {
            _ = textView.resignFirstResponder()
        }

        if syncRuntimeState {
            syncRuntimeStateFromView(textView, focusOverride: focusOverride)
        }
    }

    private func syncRuntimeStateFromView(_ textView: UITextView, focusOverride: Bool? = nil) {
        let focused = focusOverride ?? textView.isFirstResponder
        let canUndo = textView.undoManager?.canUndo ?? false
        let canRedo = textView.undoManager?.canRedo ?? false

        guard
            owner.isEditorFocused != focused ||
            owner.isUndoable != canUndo ||
            owner.isRedoable != canRedo
        else {
            return
        }

        owner.applyPlatformRuntimeState(
            isEditorFocused: focused,
            isUndoable: canUndo,
            isRedoable: canRedo
        )
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
    private unowned let owner: HighlightrEditorView
    private weak var textView: NSTextView?
    private let engine: any SyntaxHighlightingEngine

    private var colorScheme: EditorColorScheme

    private var isApplyingFromOwner = false
    private var autoIndentOnNewline = false
    private var isHandlingAutoIndent = false
    private var appliedLanguage: EditorLanguage?
    private var appliedThemeName: String?

    init(
        owner: HighlightrEditorView,
        textView: NSTextView,
        engine: any SyntaxHighlightingEngine,
        initialColorScheme: EditorColorScheme
    ) {
        self.owner = owner
        self.textView = textView
        self.engine = engine
        self.colorScheme = initialColorScheme
        super.init()

        textView.delegate = self
        syncViewFromOwner(syncRuntimeState: false)
    }

    func applyAppearance(colorScheme: EditorColorScheme) {
        self.colorScheme = colorScheme
        applyThemeIfNeeded(owner.theme, force: true)
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        autoIndentOnNewline = enabled
    }

    func syncStateFromView(focusOverride: Bool? = nil) {
        guard let textView, !isApplyingFromOwner else { return }

        let currentText = textView.string
        let selectedRange = textView.selectedRange()
        let selection = TextSelection(location: selectedRange.location, length: selectedRange.length)
        let editable = textView.isEditable

        if owner.text != currentText || owner.selection != selection || owner.isEditable != editable {
            owner.applyPlatformDocumentState(
                text: currentText,
                selection: selection,
                isEditable: editable
            )
        }

        syncRuntimeStateFromView(textView, focusOverride: focusOverride)
    }

    func syncViewFromOwner(syncRuntimeState: Bool = true) {
        applyOwnerState(syncRuntimeState: syncRuntimeState)
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
            !isApplyingFromOwner,
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

    private func applyOwnerState(syncRuntimeState: Bool) {
        guard let textView else { return }

        isApplyingFromOwner = true
        defer { isApplyingFromOwner = false }

        applyLanguageIfNeeded(owner.language)
        applyThemeIfNeeded(owner.theme)

        let shouldResetUndoHistory = textView.string != owner.text
        if shouldResetUndoHistory {
            textView.string = owner.text
            textView.undoManager?.removeAllActions()
        }

        let clampedSelection = Self.clampedSelection(owner.selection, text: textView.string)
        if owner.selection != clampedSelection {
            owner.applyPlatformSelectionState(clampedSelection)
        }
        let clampedRange = NSRange(location: clampedSelection.location, length: clampedSelection.length)
        if textView.selectedRange() != clampedRange {
            textView.setSelectedRange(clampedRange)
        }

        if textView.isEditable != owner.isEditable {
            textView.isEditable = owner.isEditable
        }

        let isEditorFocused = textView.window?.firstResponder === textView
        var focusOverride: Bool?
        if owner.isEditorFocused {
            if !isEditorFocused {
                _ = textView.window?.makeFirstResponder(textView)
            }
            if textView.window?.firstResponder !== textView {
                focusOverride = true
            }
        } else if isEditorFocused {
            _ = textView.window?.makeFirstResponder(nil)
        }

        if syncRuntimeState {
            syncRuntimeStateFromView(textView, focusOverride: focusOverride)
        }
    }

    private func syncRuntimeStateFromView(_ textView: NSTextView, focusOverride: Bool? = nil) {
        let focused = focusOverride ?? (textView.window?.firstResponder === textView)
        let canUndo = textView.undoManager?.canUndo ?? false
        let canRedo = textView.undoManager?.canRedo ?? false

        guard
            owner.isEditorFocused != focused ||
            owner.isUndoable != canUndo ||
            owner.isRedoable != canRedo
        else {
            return
        }

        owner.applyPlatformRuntimeState(
            isEditorFocused: focused,
            isUndoable: canUndo,
            isRedoable: canRedo
        )
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
