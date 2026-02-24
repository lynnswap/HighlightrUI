import Foundation

#if canImport(UIKit)
import UIKit

@MainActor
final class EditorCoordinator: NSObject, UITextViewDelegate {
    private weak var owner: HighlightrEditorView?
    private weak var textView: UITextView?
    private let engine: any SyntaxHighlightingEngine

    private var colorScheme: EditorColorScheme

    private var isApplyingFromOwner = false
    private var autoIndentOnNewline = false
    private var isHandlingAutoIndent = false
    private var appliedLanguage: EditorLanguage?
    private var appliedThemeName: String?

    private var highlightTask: Task<Void, Never>?
    private var highlightRevision: UInt64 = 0
    private var pendingEditedRange: NSRange?
    private var pendingOriginalUTF16Length: Int?
    private var pendingReplacementUTF16Length: Int?
    private var isApplyingHighlightAttributes = false

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

    isolated deinit {
        highlightTask?.cancel()
    }

    func applyAppearance(colorScheme: EditorColorScheme) {
        guard let owner else { return }
        self.colorScheme = colorScheme
        applyThemeIfNeeded(owner.theme, force: true)
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        autoIndentOnNewline = enabled
    }

    func syncStateFromView(focusOverride: Bool? = nil) {
        guard let textView, let owner, !isApplyingFromOwner else { return }

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
        guard !isApplyingFromOwner, !isApplyingHighlightAttributes else { return }
        scheduleHighlightForPendingEdit(in: textView)
        syncStateFromView()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        guard !isApplyingHighlightAttributes else { return }
        syncStateFromView()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        syncStateFromView(focusOverride: true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        syncStateFromView(focusOverride: false)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard !isApplyingHighlightAttributes else { return true }

        let currentText = textView.text ?? ""
        let safeRange = Self.clampedRange(range, in: currentText)

        if let replacement = Self.normalizedDoubleSpaceReplacement(
            in: currentText,
            range: safeRange,
            replacementText: text
        ) {
            guard
                let start = textView.position(from: textView.beginningOfDocument, offset: safeRange.location),
                let end = textView.position(from: start, offset: safeRange.length),
                let textRange = textView.textRange(from: start, to: end)
            else {
                pendingEditedRange = safeRange
                pendingOriginalUTF16Length = safeRange.length
                pendingReplacementUTF16Length = (replacement as NSString).length
                return true
            }

            pendingEditedRange = safeRange
            pendingOriginalUTF16Length = safeRange.length
            pendingReplacementUTF16Length = (replacement as NSString).length

            textView.replace(textRange, withText: replacement)
            let cursorLocation = safeRange.location + (replacement as NSString).length
            if let position = textView.position(from: textView.beginningOfDocument, offset: cursorLocation),
               let selectedRange = textView.textRange(from: position, to: position) {
                textView.selectedTextRange = selectedRange
            }

            scheduleHighlightForPendingEdit(in: textView)
            syncStateFromView()
            return false
        }

        guard
            autoIndentOnNewline,
            !isApplyingFromOwner,
            !isHandlingAutoIndent,
            text == "\n"
        else {
            pendingEditedRange = safeRange
            pendingOriginalUTF16Length = safeRange.length
            pendingReplacementUTF16Length = (text as NSString).length
            return true
        }

        let indent = Self.leadingIndent(in: currentText, at: safeRange.location)
        let replacement = "\n" + indent

        guard
            let start = textView.position(from: textView.beginningOfDocument, offset: safeRange.location),
            let end = textView.position(from: start, offset: safeRange.length),
            let textRange = textView.textRange(from: start, to: end)
        else {
            pendingEditedRange = safeRange
            pendingOriginalUTF16Length = safeRange.length
            pendingReplacementUTF16Length = (text as NSString).length
            return true
        }

        pendingEditedRange = safeRange
        pendingOriginalUTF16Length = safeRange.length
        pendingReplacementUTF16Length = (replacement as NSString).length

        isHandlingAutoIndent = true
        defer { isHandlingAutoIndent = false }

        textView.replace(textRange, withText: replacement)
        let cursorLocation = safeRange.location + (replacement as NSString).length
        if let position = textView.position(from: textView.beginningOfDocument, offset: cursorLocation),
           let selectedRange = textView.textRange(from: position, to: position) {
            textView.selectedTextRange = selectedRange
        }

        scheduleHighlightForPendingEdit(in: textView)
        syncStateFromView()
        return false
    }

    private func applyOwnerState(syncRuntimeState: Bool) {
        guard let textView, let owner else { return }

        isApplyingFromOwner = true
        defer { isApplyingFromOwner = false }

        applyLanguageIfNeeded(owner.language)
        applyThemeIfNeeded(owner.theme)

        let shouldResetUndoHistory = textView.text != owner.text
        if shouldResetUndoHistory {
            textView.text = owner.text
            textView.undoManager?.removeAllActions()
            scheduleFullHighlightIfPossible()
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
        guard let owner else { return }
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
        scheduleFullHighlightIfPossible()
    }

    private func applyThemeIfNeeded(_ theme: EditorTheme, force: Bool = false) {
        let themeName = theme.resolvedThemeName(for: colorScheme)
        guard force || themeName != appliedThemeName else { return }
        engine.setThemeName(themeName)
        appliedThemeName = themeName
        scheduleFullHighlightIfPossible()
    }

    private func scheduleFullHighlightIfPossible() {
        guard let textView else { return }
        let textStorage = textView.textStorage
        let source = textStorage.string
        let length = (source as NSString).length
        guard length > 0 else { return }

        scheduleHighlight(
            source: source,
            range: NSRange(location: 0, length: length)
        )
    }

    private func scheduleHighlightForPendingEdit(in textView: UITextView) {
        let textStorage = textView.textStorage
        let source = textStorage.string
        guard !source.isEmpty else {
            pendingEditedRange = nil
            pendingOriginalUTF16Length = nil
            pendingReplacementUTF16Length = nil
            return
        }

        let editedRange = consumePendingEditedRange(
            fallbackSelection: textView.selectedRange,
            text: source
        )
        let sourceUTF16 = source as NSString
        let highlightRange = Self.highlightRangeForEditedFlow(
            editedRange,
            in: sourceUTF16
        )
        scheduleHighlight(
            source: source,
            range: highlightRange
        )
    }

    private func scheduleHighlight(source: String, range: NSRange) {
        let sourceUTF16 = source as NSString
        let safeRange = Self.clampedRange(range, utf16Length: sourceUTF16.length)
        guard safeRange.length > 0 else { return }

        let expectedSource = sourceUTF16.substring(with: safeRange)

        highlightRevision &+= 1
        let revision = highlightRevision

        highlightTask?.cancel()
        highlightTask = Task { [weak self] in
            guard let self else { return }

            let payload = await self.engine.renderHighlightPayload(source: source, in: safeRange)
            guard !Task.isCancelled else { return }

            self.applyHighlightPayload(
                payload,
                revision: revision,
                range: safeRange,
                expectedSource: expectedSource
            )
        }
    }

    private func applyHighlightPayload(
        _ payload: HighlightRenderPayload?,
        revision: UInt64,
        range: NSRange,
        expectedSource: String
    ) {
        guard revision == highlightRevision else { return }
        guard let payload else { return }
        guard let textView else { return }
        let textStorage = textView.textStorage

        let currentSource = textStorage.string
        let currentLength = (currentSource as NSString).length
        guard NSMaxRange(range) <= currentLength else { return }

        let expectedLength = (expectedSource as NSString).length
        guard payload.utf16Length == expectedLength else { return }

        let currentFragment = (currentSource as NSString).substring(with: range)
        guard currentFragment == expectedSource else { return }

        let highlightedSource = String(payload.attributedText.characters)
        guard highlightedSource == expectedSource else { return }

        isApplyingHighlightAttributes = true
        defer { isApplyingHighlightAttributes = false }

        let baseAttributes = textView.typingAttributes
        textStorage.beginEditing()
        textStorage.setAttributes(baseAttributes, range: range)

        for run in payload.attributedText.runs {
            guard let swiftRange = Range(run.range, in: highlightedSource) else { continue }
            let localRange = NSRange(swiftRange, in: highlightedSource)
            let targetRange = NSRange(
                location: range.location + localRange.location,
                length: localRange.length
            )
            guard targetRange.length > 0 else { continue }
            guard NSMaxRange(targetRange) <= textStorage.length else { continue }

            var attributes = baseAttributes
            if let foregroundColor = run.attributes[AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self] {
                attributes[.foregroundColor] = foregroundColor
            }
            if let backgroundColor = run.attributes[AttributeScopes.UIKitAttributes.BackgroundColorAttribute.self] {
                attributes[.backgroundColor] = backgroundColor
            }
            if let font = run.attributes[AttributeScopes.UIKitAttributes.FontAttribute.self] {
                attributes[.font] = font
            }
            if let kern = run.attributes[AttributeScopes.UIKitAttributes.KernAttribute.self] {
                attributes[.kern] = kern
            }
            if let baselineOffset = run.attributes[AttributeScopes.UIKitAttributes.BaselineOffsetAttribute.self] {
                attributes[.baselineOffset] = baselineOffset
            }
            if let underlineStyle = run.attributes[AttributeScopes.UIKitAttributes.UnderlineStyleAttribute.self] {
                attributes[.underlineStyle] = underlineStyle.rawValue
            }
            if let strikethroughStyle = run.attributes[AttributeScopes.UIKitAttributes.StrikethroughStyleAttribute.self] {
                attributes[.strikethroughStyle] = strikethroughStyle.rawValue
            }
            textStorage.setAttributes(attributes, range: targetRange)
        }
        textStorage.endEditing()
    }

    private func consumePendingEditedRange(
        fallbackSelection: NSRange,
        text: String
    ) -> NSRange {
        defer {
            pendingEditedRange = nil
            pendingOriginalUTF16Length = nil
            pendingReplacementUTF16Length = nil
        }

        guard let pendingEditedRange else {
            return fallbackSelection
        }

        let textLength = (text as NSString).length
        let clampedLocation = min(max(0, pendingEditedRange.location), textLength)
        let remaining = max(0, textLength - clampedLocation)
        let affectedLength = max(
            pendingOriginalUTF16Length ?? 0,
            pendingReplacementUTF16Length ?? 0
        )
        let clampedLength = min(max(0, affectedLength), remaining)
        return NSRange(location: clampedLocation, length: clampedLength)
    }

    private static func clampedSelection(_ selection: TextSelection, text: String) -> TextSelection {
        let textLength = (text as NSString).length
        let clampedLocation = min(max(0, selection.location), textLength)
        let remaining = max(0, textLength - clampedLocation)
        let clampedLength = min(max(0, selection.length), remaining)
        return TextSelection(location: clampedLocation, length: clampedLength)
    }

    private static func clampedRange(_ range: NSRange, in text: String) -> NSRange {
        clampedRange(range, utf16Length: (text as NSString).length)
    }

    private static func clampedRange(_ range: NSRange, utf16Length: Int) -> NSRange {
        let location = min(max(0, range.location), utf16Length)
        let remaining = max(0, utf16Length - location)
        let length = min(max(0, range.length), remaining)
        return NSRange(location: location, length: length)
    }

    private static func highlightRangeForEditedFlow(
        _ editedRange: NSRange,
        in source: NSString
    ) -> NSRange {
        guard source.length > 0 else { return NSRange(location: 0, length: 0) }

        let safeEditedRange = clampedRange(editedRange, utf16Length: source.length)
        let startLocation: Int
        if safeEditedRange.length == 0, safeEditedRange.location == source.length {
            startLocation = source.length - 1
        } else {
            startLocation = safeEditedRange.location
        }
        let startParagraph = source.paragraphRange(
            for: NSRange(location: startLocation, length: 0)
        )
        return NSRange(
            location: startParagraph.location,
            length: source.length - startParagraph.location
        )
    }

    private static func normalizedDoubleSpaceReplacement(
        in text: String,
        range: NSRange,
        replacementText: String
    ) -> String? {
        guard replacementText == ". " else { return nil }
        guard range.length == 1 else { return nil }

        let source = text as NSString
        guard source.length > 0 else { return nil }
        guard NSMaxRange(range) <= source.length else { return nil }
        guard source.substring(with: range) == " " else { return nil }
        guard range.location > 0 else { return nil }

        let previousCharacter = source.substring(with: NSRange(location: range.location - 1, length: 1))
        guard previousCharacter != " " else { return nil }
        guard previousCharacter != "\n" else { return nil }
        guard previousCharacter != "\t" else { return nil }

        return "  "
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
    private weak var owner: HighlightrEditorView?
    private weak var textView: NSTextView?
    private let engine: any SyntaxHighlightingEngine

    private var colorScheme: EditorColorScheme

    private var isApplyingFromOwner = false
    private var autoIndentOnNewline = false
    private var isHandlingAutoIndent = false
    private var appliedLanguage: EditorLanguage?
    private var appliedThemeName: String?

    private var highlightTask: Task<Void, Never>?
    private var highlightRevision: UInt64 = 0
    private var pendingEditedRange: NSRange?
    private var pendingOriginalUTF16Length: Int?
    private var pendingReplacementUTF16Length: Int?
    private var isApplyingHighlightAttributes = false

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

    isolated deinit {
        highlightTask?.cancel()
    }

    func applyAppearance(colorScheme: EditorColorScheme) {
        guard let owner else { return }
        self.colorScheme = colorScheme
        applyThemeIfNeeded(owner.theme, force: true)
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        autoIndentOnNewline = enabled
    }

    func syncStateFromView(focusOverride: Bool? = nil) {
        guard let textView, let owner, !isApplyingFromOwner else { return }

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
        guard let textView, !isApplyingFromOwner, !isApplyingHighlightAttributes else { return }
        scheduleHighlightForPendingEdit(in: textView)
        syncStateFromView()
    }

    func textDidBeginEditing(_ notification: Notification) {
        syncStateFromView(focusOverride: true)
    }

    func textDidEndEditing(_ notification: Notification) {
        syncStateFromView(focusOverride: false)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard !isApplyingHighlightAttributes else { return }
        syncStateFromView()
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString text: String?) -> Bool {
        guard !isApplyingHighlightAttributes else { return true }

        let safeRange = Self.clampedRange(range, in: textView.string)
        if safeRange.length == 0 {
            let inheritedTypingAttributes = Self.inheritedTypingAttributes(
                from: textView.attributedString(),
                insertionLocation: safeRange.location,
                fallbackFont: textView.font
            )
            if !inheritedTypingAttributes.isEmpty {
                textView.typingAttributes = inheritedTypingAttributes
            }
        }

        guard
            autoIndentOnNewline,
            !isApplyingFromOwner,
            !isHandlingAutoIndent,
            text == "\n"
        else {
            pendingEditedRange = safeRange
            pendingOriginalUTF16Length = safeRange.length
            pendingReplacementUTF16Length = ((text ?? "") as NSString).length
            return true
        }

        let indent = Self.leadingIndent(in: textView.string, at: safeRange.location)
        let replacement = "\n" + indent

        pendingEditedRange = safeRange
        pendingOriginalUTF16Length = safeRange.length
        pendingReplacementUTF16Length = (replacement as NSString).length

        isHandlingAutoIndent = true
        defer { isHandlingAutoIndent = false }

        textView.insertText(replacement, replacementRange: safeRange)
        let cursorLocation = safeRange.location + (replacement as NSString).length
        textView.setSelectedRange(NSRange(location: cursorLocation, length: 0))

        scheduleHighlightForPendingEdit(in: textView)
        syncStateFromView()
        return false
    }

    private func applyOwnerState(syncRuntimeState: Bool) {
        guard let textView, let owner else { return }

        isApplyingFromOwner = true
        defer { isApplyingFromOwner = false }

        applyLanguageIfNeeded(owner.language)
        applyThemeIfNeeded(owner.theme)

        let shouldResetUndoHistory = textView.string != owner.text
        if shouldResetUndoHistory {
            textView.string = owner.text
            textView.undoManager?.removeAllActions()
            scheduleFullHighlightIfPossible()
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

        let isEditorFocused = Self.isTextViewFirstResponder(textView)
        var focusOverride: Bool?
        if owner.isEditorFocused {
            if !isEditorFocused {
                let becameFocused = Self.requestTextViewFocus(textView)
                _ = becameFocused
            }
            let focusedAfterRequest = Self.isTextViewFirstResponder(textView)
            if !focusedAfterRequest {
                focusOverride = true
            }
        } else if isEditorFocused {
            _ = Self.requestTextViewBlur(textView)
            let focusedAfterRequest = Self.isTextViewFirstResponder(textView)
            if focusedAfterRequest {
                focusOverride = false
            }
        }

        if syncRuntimeState {
            syncRuntimeStateFromView(textView, focusOverride: focusOverride)
        }
    }

    private func syncRuntimeStateFromView(_ textView: NSTextView, focusOverride: Bool? = nil) {
        guard let owner else { return }
        let focusedFromResponder = Self.isTextViewFirstResponder(textView)
        let focused = focusOverride ?? focusedFromResponder
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
        scheduleFullHighlightIfPossible()
    }

    private func applyThemeIfNeeded(_ theme: EditorTheme, force: Bool = false) {
        let themeName = theme.resolvedThemeName(for: colorScheme)
        guard force || themeName != appliedThemeName else { return }
        engine.setThemeName(themeName)
        appliedThemeName = themeName
        scheduleFullHighlightIfPossible()
    }

    private func scheduleFullHighlightIfPossible() {
        guard let textView else { return }
        let source = textView.string
        let length = (source as NSString).length
        guard length > 0 else { return }

        scheduleHighlight(
            source: source,
            range: NSRange(location: 0, length: length)
        )
    }

    private func scheduleHighlightForPendingEdit(in textView: NSTextView) {
        let source = textView.string
        guard !source.isEmpty else {
            pendingEditedRange = nil
            pendingOriginalUTF16Length = nil
            pendingReplacementUTF16Length = nil
            return
        }

        let editedRange = consumePendingEditedRange(
            fallbackSelection: textView.selectedRange(),
            text: source
        )
        let sourceUTF16 = source as NSString
        let highlightRange = Self.highlightRangeForEditedFlow(
            editedRange,
            in: sourceUTF16
        )
        scheduleHighlight(
            source: source,
            range: highlightRange
        )
    }

    private func scheduleHighlight(source: String, range: NSRange) {
        let sourceUTF16 = source as NSString
        let safeRange = Self.clampedRange(range, utf16Length: sourceUTF16.length)
        guard safeRange.length > 0 else { return }

        let expectedSource = sourceUTF16.substring(with: safeRange)

        highlightRevision &+= 1
        let revision = highlightRevision

        highlightTask?.cancel()
        highlightTask = Task { [weak self] in
            guard let self else { return }

            let payload = await self.engine.renderHighlightPayload(source: source, in: safeRange)
            guard !Task.isCancelled else { return }

            self.applyHighlightPayload(
                payload,
                revision: revision,
                range: safeRange,
                expectedSource: expectedSource
            )
        }
    }

    private func applyHighlightPayload(
        _ payload: HighlightRenderPayload?,
        revision: UInt64,
        range: NSRange,
        expectedSource: String
    ) {
        guard revision == highlightRevision else { return }
        guard let payload else { return }
        guard let textView else { return }

        let currentSource = textView.string
        let currentLength = (currentSource as NSString).length
        guard NSMaxRange(range) <= currentLength else { return }

        let expectedLength = (expectedSource as NSString).length
        guard payload.utf16Length == expectedLength else { return }

        let currentFragment = (currentSource as NSString).substring(with: range)
        guard currentFragment == expectedSource else { return }

        let highlightedSource = String(payload.attributedText.characters)
        guard highlightedSource == expectedSource else { return }

        let highlighted = NSAttributedString(payload.attributedText)
        guard highlighted.length == expectedLength else { return }

        isApplyingHighlightAttributes = true
        defer { isApplyingHighlightAttributes = false }

        let wasAllowsUndo = textView.allowsUndo
        if wasAllowsUndo {
            textView.allowsUndo = false
        }
        defer {
            if wasAllowsUndo {
                textView.allowsUndo = true
            }
        }

        let wasEditable = textView.isEditable
        if !wasEditable {
            textView.isEditable = true
        }
        defer {
            if !wasEditable {
                textView.isEditable = false
            }
        }

        let preservedSelection = textView.selectedRange()
        textView.insertText(highlighted, replacementRange: range)
        let restoredSelection = Self.clampedRange(preservedSelection, in: textView.string)
        if textView.selectedRange() != restoredSelection {
            textView.setSelectedRange(restoredSelection)
        }
    }

    private func consumePendingEditedRange(
        fallbackSelection: NSRange,
        text: String
    ) -> NSRange {
        defer {
            pendingEditedRange = nil
            pendingOriginalUTF16Length = nil
            pendingReplacementUTF16Length = nil
        }

        guard let pendingEditedRange else {
            return fallbackSelection
        }

        let textLength = (text as NSString).length
        let clampedLocation = min(max(0, pendingEditedRange.location), textLength)
        let remaining = max(0, textLength - clampedLocation)
        let affectedLength = max(
            pendingOriginalUTF16Length ?? 0,
            pendingReplacementUTF16Length ?? 0
        )
        let clampedLength = min(max(0, affectedLength), remaining)
        return NSRange(location: clampedLocation, length: clampedLength)
    }

    private static func clampedSelection(_ selection: TextSelection, text: String) -> TextSelection {
        let textLength = (text as NSString).length
        let clampedLocation = min(max(0, selection.location), textLength)
        let remaining = max(0, textLength - clampedLocation)
        let clampedLength = min(max(0, selection.length), remaining)
        return TextSelection(location: clampedLocation, length: clampedLength)
    }

    private static func clampedRange(_ range: NSRange, in text: String) -> NSRange {
        clampedRange(range, utf16Length: (text as NSString).length)
    }

    private static func clampedRange(_ range: NSRange, utf16Length: Int) -> NSRange {
        let location = min(max(0, range.location), utf16Length)
        let remaining = max(0, utf16Length - location)
        let length = min(max(0, range.length), remaining)
        return NSRange(location: location, length: length)
    }

    private static func isTextViewFirstResponder(_ textView: NSTextView) -> Bool {
        NSApplication.shared.windows.contains { $0.firstResponder === textView }
    }

    private static func requestTextViewBlur(_ textView: NSTextView) -> Bool {
        if let window = textView.window {
            return window.makeFirstResponder(nil)
        }
        return textView.resignFirstResponder()
    }

    private static func requestTextViewFocus(_ textView: NSTextView) -> Bool {
        if let window = textView.window {
            return window.makeFirstResponder(textView)
        }
        return textView.becomeFirstResponder()
    }

    private static func highlightRangeForEditedFlow(
        _ editedRange: NSRange,
        in source: NSString
    ) -> NSRange {
        guard source.length > 0 else { return NSRange(location: 0, length: 0) }

        let safeEditedRange = clampedRange(editedRange, utf16Length: source.length)
        let startLocation: Int
        if safeEditedRange.length == 0, safeEditedRange.location == source.length {
            startLocation = source.length - 1
        } else {
            startLocation = safeEditedRange.location
        }
        let startParagraph = source.paragraphRange(
            for: NSRange(location: startLocation, length: 0)
        )
        return NSRange(
            location: startParagraph.location,
            length: source.length - startParagraph.location
        )
    }

    private static func inheritedTypingAttributes(
        from attributedString: NSAttributedString,
        insertionLocation: Int,
        fallbackFont: NSFont?
    ) -> [NSAttributedString.Key: Any] {
        let snapshot = AttributedString(attributedString)
        let source = String(snapshot.characters)
        let utf16Length = (source as NSString).length
        guard utf16Length > 0 else { return [:] }

        let probeLocation = min(max(0, insertionLocation - 1), utf16Length - 1)
        for run in snapshot.runs {
            guard let swiftRange = Range(run.range, in: source) else { continue }
            let runRange = NSRange(swiftRange, in: source)
            guard NSLocationInRange(probeLocation, runRange) else { continue }

            var attributes: [NSAttributedString.Key: Any] = [:]
            if let foregroundColor = run.attributes[AttributeScopes.AppKitAttributes.ForegroundColorAttribute.self] {
                attributes[.foregroundColor] = foregroundColor
            }
            if let backgroundColor = run.attributes[AttributeScopes.AppKitAttributes.BackgroundColorAttribute.self] {
                attributes[.backgroundColor] = backgroundColor
            }
            if let fallbackFont {
                attributes[.font] = fallbackFont
            }
            return attributes
        }

        if let fallbackFont {
            return [.font: fallbackFont]
        }
        return [:]
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
