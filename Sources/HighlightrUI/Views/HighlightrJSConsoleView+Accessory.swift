//
//  HighlightrJSConsoleView+Accessory.swift
//  PDHighlightr
//
//  Adds input accessory configuration APIs similar to HighlightrTextView.
//

#if canImport(UIKit)
import SwiftUI

extension HighlightrJSConsoleView {
    public func inputAccessoryView(_ view: UIView?) -> HighlightrJSConsoleView {
        var copy = self
        copy._inputAccessoryView = view
        return copy
    }

    public func inputAccessoryView(_ builder: @escaping (HighlightrTextViewModel) -> UIView?) -> HighlightrJSConsoleView {
        var copy = self
        copy._accessoryBuilder = builder
        return copy
    }

    public func inputAccessory<AccessoryContent: View>(@ViewBuilder _ content: @escaping (HighlightrTextViewModel) -> AccessoryContent) -> HighlightrJSConsoleView {
        var copy = self
        copy._accessoryBuilder = { model in
            AccessoryInputView { content(model) }
        }
        return copy
    }
}
#endif

