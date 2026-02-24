# Migration Guide (v1 -> v2)

This guide is for applications currently using HighlightrUI **v1** and migrating to **v2**.

## Scope

- Focus: public API changes that require app-side migration.
- Out of scope: internal implementation refactors that do not change app-facing APIs.

## Breaking API Changes

- `HighlightrModel` is now the single public state owner.
- `HighlightrEditorView` / `HighlightrEditorViewController` are model-injection based.
- Legacy direct initializers (`text:language:...`) were removed.
- `HighlightrDocumentModel` and `HighlightrRuntimeModel` were removed.
- `HighlightrEditorView` mirror properties were removed (`text`, `language`, `theme`, `selection`, `isEditable`, `isEditorFocused`, `isUndoable`, `isRedoable`, `hasText`).

## API Mapping

- `HighlightrEditorView(text:language:...)`
  -> `HighlightrEditorView(model: HighlightrModel(text:language:...))`
- `HighlightrEditorViewController(text:language:...)`
  -> `HighlightrEditorViewController(model: HighlightrModel(...))`
- `HighlightrEditorViewController(editorView: ...)`
  -> unchanged (still available)
- `editorView.text` / `editorView.theme` / `editorView.selection` / ...
  -> `model.text` / `model.theme` / `model.selection` / ...

## New State Model (v2)

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

let view = HighlightrEditorView(model: model)
let controller = HighlightrEditorViewController(model: model)
```

Update editor state through `model` (`model.text`, `model.theme`, etc.).

## Migration Checklist

1. Replace removed direct initializers with model-based initializers.
2. Introduce and share `HighlightrModel` where the editor state is managed.
3. Replace removed `HighlightrEditorView` mirror property access with `model` property access.
4. Remove references to deleted model types (`HighlightrDocumentModel` / `HighlightrRuntimeModel`).
5. Re-run your app tests against v2.
