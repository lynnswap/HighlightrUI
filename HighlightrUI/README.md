# HighlightrUI

`HighlightrUI` is a UIKit/AppKit-first Swift package for syntax-highlighted text editing with `Highlightr`.

## Requirements

- Swift 6.2
- iOS 18.0+
- macOS 15.0+

## UIKit Example

```swift
import UIKit
import HighlightrUI

let model = HighlightrEditorModel(
    text: "console.log('hello')",
    language: "javascript"
)

let editor = HighlightrEditorView(model: model)
editor.setInputAccessoryView(UIToolbar())

let controller = HighlightrEditorViewController(editorView: editor)
```

## AppKit Example

```swift
import AppKit
import HighlightrUI

let model = HighlightrEditorModel(
    text: "print(\"hello\")",
    language: "swift"
)

let editor = HighlightrEditorView(model: model)
let controller = HighlightrEditorViewController(editorView: editor)
```

## Core API

```swift
let model = HighlightrEditorModel(text: "", language: "swift")

let stream = model.snapshotStream()
Task {
    for await snapshot in stream {
        print(snapshot.text)
    }
}
```

## Migration

See [`Migration`](Docs/Migration.md).

## License

[MIT](LICENSE)
