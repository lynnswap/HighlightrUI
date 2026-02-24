# HighlightrUI

`HighlightrUI` is a Swift package for syntax-highlighted text editing with `HighlighterSwift`.

## Requirements

- Swift 6.2
- iOS 18.0+
- macOS 15.0+

## UIKit Example

```swift
import UIKit
import HighlightrUI

let model = HighlightrModel(
    text: "console.log('hello')",
    language: "javascript"
)

let controller = HighlightrEditorViewController(
    model: model
)
controller.perform(.focus)

model.theme = .named("github")
model.text = "console.log('updated')"
```

## AppKit Example

```swift
import AppKit
import HighlightrUI

let model = HighlightrModel(
    text: "print(\"hello\")",
    language: "swift"
)

let editorView = HighlightrEditorView(model: model)
let controller = HighlightrEditorViewController(model: model)
```

On iOS, `HighlightrEditorViewController` includes a built-in fixed coding keyboard toolbar.

## Core API

`HighlightrUI` exposes state via `HighlightrModel` (`@Observable`).

- State: `text`, `language`, `theme`, `selection`, `isEditable`
- Runtime: `isEditorFocused`, `isUndoable`, `isRedoable`, `hasText`

`HighlightrEditorView` / `HighlightrEditorViewController` are initialized by injecting a shared `HighlightrModel`.
Update state directly on `HighlightrModel`.

## Migration

See [`Migration`](Docs/Migration.md).

## License

[MIT](LICENSE)
