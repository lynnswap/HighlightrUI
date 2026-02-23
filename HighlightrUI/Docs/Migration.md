# Migration Guide (v1 -> v2)

This guide summarizes breaking changes introduced in HighlightrUI v2.

## Overview

- SwiftUI-first APIs were removed.
- UIKit/AppKit-first APIs were introduced.
- State management was unified into `@Observable` model types.

## API Mapping

- `HighlightrTextView` -> `HighlightrEditorView`
- `HighlightrTextViewModel` -> `HighlightrEditorModel`
- `HighlightrJSConsoleView` -> removed (out of v2 core scope)
- SwiftUI modifiers (`theme`, toolbar modifiers, accessory modifiers) -> removed
- No external replacement API is provided for the iOS accessory view; use the fixed keyboard toolbar built into `HighlightrEditorViewController`.

## Platform and Toolchain

- Swift: `6.2`
- iOS: `18.0+`
- macOS: `15.0+`

## Notes

- v2 does not provide a compatibility layer for the removed SwiftUI APIs.
- For observation streams, use `ObservationsCompat`-backed APIs exposed by `HighlightrEditorModel`.
