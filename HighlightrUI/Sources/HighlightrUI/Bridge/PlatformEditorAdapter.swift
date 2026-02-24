import Foundation

#if canImport(UIKit)
import UIKit

@MainActor
protocol PlatformEditorAdapterDelegate: AnyObject {
    func adapterDidChangeText(_ adapter: PlatformEditorAdapter)
    func adapterDidChangeSelection(_ adapter: PlatformEditorAdapter)
    func adapterDidBeginEditing(_ adapter: PlatformEditorAdapter)
    func adapterDidEndEditing(_ adapter: PlatformEditorAdapter)
    func adapter(
        _ adapter: PlatformEditorAdapter,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool
}

@MainActor
protocol PlatformEditorAdapter: AnyObject {
    var delegate: PlatformEditorAdapterDelegate? { get set }
    var textView: PlatformEditorTextView { get }
}

#elseif canImport(AppKit)
import AppKit

@MainActor
protocol PlatformEditorAdapterDelegate: AnyObject {
    func adapterDidChangeText(_ adapter: PlatformEditorAdapter)
    func adapterDidChangeSelection(_ adapter: PlatformEditorAdapter)
    func adapterDidBeginEditing(_ adapter: PlatformEditorAdapter)
    func adapterDidEndEditing(_ adapter: PlatformEditorAdapter)
    func adapter(
        _ adapter: PlatformEditorAdapter,
        shouldChangeTextIn range: NSRange,
        replacementText text: String?
    ) -> Bool
}

@MainActor
protocol PlatformEditorAdapter: AnyObject {
    var delegate: PlatformEditorAdapterDelegate? { get set }
    var textView: NSTextView { get }
}
#endif
