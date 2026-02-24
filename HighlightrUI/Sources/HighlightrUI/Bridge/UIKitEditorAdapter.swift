#if canImport(UIKit)
import UIKit

@MainActor
final class UIKitEditorAdapter: NSObject, PlatformEditorAdapter, UITextViewDelegate {
    weak var delegate: PlatformEditorAdapterDelegate?
    let textView: PlatformEditorTextView

    init(textView: PlatformEditorTextView) {
        self.textView = textView
        super.init()
        textView.delegate = self
    }

    func textViewDidChange(_ textView: UITextView) {
        delegate?.adapterDidChangeText(self)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.adapterDidChangeSelection(self)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.adapterDidBeginEditing(self)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.adapterDidEndEditing(self)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        delegate?.adapter(self, shouldChangeTextIn: range, replacementText: text) ?? true
    }
}
#endif
