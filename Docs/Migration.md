# Migration Guide (v1 -> v2)

This guide summarizes breaking changes introduced in HighlightrUI v2.

## Overview

- `HighlightrEditorModel` remains the single public editor state model.
- Public stream APIs are removed; state is consumed via `@Observable` properties.
- `setViewStateChangeHandler` / `onViewStateChanged` are removed.
- Internal sync is driven by `ObservationsCompat` over `@Observable` model changes.

## API Mapping

- `HighlightrEditorView(model: ...)` -> `HighlightrEditorView(model: ...)`
- `HighlightrEditorViewController(model: ...)` -> `HighlightrEditorViewController(model: ...)`

## `HighlightrEditorModel` State

- Document state: `text`, `language`, `theme`, `selection`, `isEditable`
- Runtime state: `isFocused`, `isUndoable`, `isRedoable`, `hasText`

## Removed APIs

- Public snapshot/stream APIs:
  - `snapshot()`
  - `snapshotStream(...)`
  - `textStream(...)`
  - `themeStream(...)`
- `EditorSnapshot` / `EditorDocumentSnapshot` (public)
- `setViewStateChangeHandler` / `onViewStateChanged`
- `HighlightrEditorCommandAvailability`

## Notes

- v2 does not provide a compatibility wrapper for removed APIs.
- App code should read/write `HighlightrEditorModel` properties directly.
