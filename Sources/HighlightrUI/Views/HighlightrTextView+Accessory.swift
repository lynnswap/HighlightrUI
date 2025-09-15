//
//  HighlightrTextView+Accessory.swift
//  PDHighlightr
//
//  Extracted extension for inputAccessory handling.
//

#if canImport(UIKit)
import SwiftUI

extension HighlightrTextView {
    public func inputAccessoryView(_ view: UIView?) -> HighlightrTextView {
        var copy = self
        copy._inputAccessoryView = view
        return copy
    }

    public func inputAccessoryView(_ builder: @escaping (HighlightrTextViewModel) -> UIView?) -> HighlightrTextView {
        var copy = self
        copy._accessoryBuilder = builder
        return copy
    }

    public func inputAccessory<AccessoryContent: View>(@ViewBuilder _ content: @escaping (HighlightrTextViewModel) -> AccessoryContent) -> HighlightrTextView {
        var copy = self
        copy._accessoryBuilder = { model in
            AccessoryInputView { content(model) }
        }
        return copy
    }
}
#endif

