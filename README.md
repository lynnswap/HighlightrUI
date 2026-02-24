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

let controller = HighlightrEditorViewController(
    text: "console.log('hello')",
    language: "javascript"
)
controller.perform(.focus)

controller.editorView.theme = .named("github")
controller.editorView.text = "console.log('updated')"
```

## AppKit Example

```swift
import AppKit
import HighlightrUI

let editorView = HighlightrEditorView(
    text: "print(\"hello\")",
    language: "swift"
)

let controller = HighlightrEditorViewController(
    editorView: editorView
)
```

On iOS, `HighlightrEditorViewController` includes a built-in fixed coding keyboard toolbar.

## Core API

`HighlightrUI` exposes state via `@Observable` properties on `HighlightrEditorView`.

- Document state: `text`, `language`, `theme`, `selection`, `isEditable`
- Runtime state: `isFocused`, `isUndoable`, `isRedoable`, `hasText`

Read/update those properties directly on `HighlightrEditorView` (or via `controller.editorView`).

## Testing

Run tests with `xcodebuild` from the repository root.

```bash
# macOS: Package tests
xcodebuild -workspace HighlightrUI.xcworkspace \
  -scheme HighlightrUITests \
  -destination 'platform=macOS' \
  test

# iOS Simulator: Package tests
xcodebuild -workspace HighlightrUI.xcworkspace \
  -scheme HighlightrUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  test
```

If the destination does not exist on your machine, check available simulators with:

```bash
xcrun simctl list devices available
```

## Migration

See [`Migration`](Docs/Migration.md).

## License

[MIT](LICENSE)
