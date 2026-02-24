# Migration Guide (v2 -> v3)

This guide summarizes breaking changes introduced in HighlightrUI v3.

## Overview

- Public state owner is `HighlightrModel` (`@Observable`) with a single flat property set.
- `HighlightrEditorView` / `HighlightrEditorViewController` now require injected `HighlightrModel`.
- Legacy direct initializers (`text:language:...`) were removed from public API.
- `EditorCoordinator` was removed and replaced by internal `EditorSession` + `HighlightPipeline`.
- Command interpretation moved to internal `EditorCommandService`.

## API Mapping

- `HighlightrEditorView(text:language:...)`
  -> `HighlightrEditorView(model: HighlightrModel(text:language:...))`
- `HighlightrEditorViewController(text:language:...)`
  -> `HighlightrEditorViewController(model: ...)`
- `HighlightrEditorViewController(editorView: ...)`
  -> `HighlightrEditorViewController(model: editorView.model)`

## New State Model

```swift
let model = HighlightrModel(
    text: "print(\"hello\")",
    language: "swift",
    theme: .automatic(light: "paraiso-light", dark: "paraiso-dark"),
    selection: .zero,
    isEditable: true,
    isEditorFocused: false,
    isUndoable: false,
    isRedoable: false
)
```

Update state directly on `model` properties (`model.text`, `model.theme`, etc.).

## Removed Public APIs

- `HighlightrDocumentModel`
- `HighlightrRuntimeModel`
- `HighlightrEditorView` document/runtime mirror properties (`text`, `language`, `theme`, `selection`, `isEditable`, `isEditorFocused`, `isUndoable`, `isRedoable`, `hasText`)
- Public convenience initializers based on `text/language/...`
- `EditorCoordinator` public usage

## Notes

- This release is intentionally breaking and does not include public compatibility shims.
