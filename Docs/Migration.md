# Migration Guide (v1 -> v2)

This guide summarizes breaking changes introduced in HighlightrUI v2.

## Overview

- `HighlightrEditorModel` is removed.
- `HighlightrUICore` is removed and merged into `HighlightrUI`.
- Internal stream synchronization (`ObservationsCompat`) is removed.
- `HighlightrEditorView` is now the single state owner (`@Observable`).
- `HighlightrEditorViewController` manages commands/toolbar and references `editorView`.

## API Mapping

- `HighlightrEditorView(model: ...)` -> `HighlightrEditorView(text:language:theme:selection:isEditable:isFocused:isUndoable:isRedoable:...)`
- `HighlightrEditorViewController(model: ...)` -> `HighlightrEditorViewController(text:language:...)` or `HighlightrEditorViewController(editorView: ...)`
- `import HighlightrUICore` -> `import HighlightrUI`

## State Model

State now lives on `HighlightrEditorView`:

- Document state: `text`, `language`, `theme`, `selection`, `isEditable`
- Runtime state: `isFocused`, `isUndoable`, `isRedoable`, `hasText`

`hasText` is now derived from `text` and is no longer independently mutable.

## Removed APIs

- `HighlightrEditorModel`
- `HighlightrUICore` product/target
- `ObservationsCompat`-based editor state streams

## Notes

- This release is intentionally breaking and does not include compatibility shims.
- App code should read/write state through `HighlightrEditorView`.
