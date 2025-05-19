# HighlightrUI

A Swift Package that provides SwiftUI views for syntax highlighted text editing using [Highlightr](https://github.com/raspu/Highlightr).

Current release: **1.0.0**

This package targets **iOS 17** and **macOS 14** and offers:

- `HighlightrTextView` &ndash; a SwiftUI wrapper around a text view with syntax highlighting
- `HighlightrJSConsoleView` &ndash; a resizable JavaScript console view
- Toolbar modifiers to make editing code more comfortable

## Installation

Add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/yourusername/HighlightrUI.git", from: "1.0.0")
```

and then import `HighlightrUI` where needed.

## Example Usage

```swift
import HighlightrUI

struct ContentView: View {
    @State private var text = "console.log(\"Hello\")"

    var body: some View {
        HighlightrTextView(text: $text, language: "javascript")
    }
}
```

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.
