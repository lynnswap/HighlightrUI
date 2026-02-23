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

## Testing

Run tests with `xcodebuild` from the repository root.

```bash
# macOS: Package tests (Core)
xcodebuild -workspace HighlightrUI.xcworkspace \
  -scheme HighlightrUICoreTests \
  -destination 'platform=macOS' \
  test

# macOS: Package tests (UI)
xcodebuild -workspace HighlightrUI.xcworkspace \
  -scheme HighlightrUITests \
  -destination 'platform=macOS' \
  test

# iOS Simulator: Package tests (Core)
xcodebuild -workspace HighlightrUI.xcworkspace \
  -scheme HighlightrUICoreTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  test

# iOS Simulator: Package tests (UI)
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

See [`Migration`](HighlightrUI/Docs/Migration.md).

## License

[MIT](LICENSE)
