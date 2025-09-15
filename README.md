# HighlightrUI

A Swift Package that provides SwiftUI views for syntax highlighted text editing using [Highlightr](https://github.com/raspu/Highlightr).

This package targets **iOS 17** and **macOS 14** and offers:

- `HighlightrTextView` &ndash; a SwiftUI wrapper around a text view with syntax highlighting
- `HighlightrJSConsoleView` &ndash; a resizable JavaScript console view
- Toolbar modifiers to make editing code more comfortable

## Installation

Add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/lynnswap/HighlightrUI.git", from: "1.2.1")
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

## iOS Input Accessory

Attach a keyboard accessory to `HighlightrTextView` on iOS.

- `inputAccessoryView(_ view: UIView?)`: Attach any UIKit view as the accessory.
- `inputAccessoryView(_ builder: (HighlightrTextViewModel) -> UIView?)`: Build a UIKit view with access to the editor model.
- `inputAccessory(_ content: (HighlightrTextViewModel) -> some View)`: Provide a SwiftUI accessory; it is wrapped under the hood.

SwiftUI example:

```swift
HighlightrTextView(text: $text, language: "javascript")
    .inputAccessory { model in
        HStack {
            Spacer()
            Button {
                model.dismissKeyboard()
            } label: {
                Image(systemName: "chevron.down")
            }
        }
    }
```

UIKit builder example:

```swift
HighlightrTextView(text: $text, language: "javascript")
    .inputAccessoryView { model in
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.addAction(UIAction { _ in model.dismissKeyboard() }, for: .touchUpInside)

        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(customView: button)
        ]
        toolbar.sizeToFit()
        return toolbar
    }
```

## Apps Using

<p float="left">
    <a href="https://apps.apple.com/jp/app/tweetpd/id1671411031"><img src="https://i.imgur.com/AC6eGdx.png" width="65" height="65"></a>
</p>

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.

## Changelog

Current release: **1.0.0**. See [CHANGELOG](CHANGELOG.md) for details.
