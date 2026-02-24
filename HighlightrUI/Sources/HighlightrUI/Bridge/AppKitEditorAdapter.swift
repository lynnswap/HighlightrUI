#if canImport(AppKit)
import AppKit

@MainActor
final class AppKitEditorAdapter: NSObject, PlatformEditorAdapter, NSTextViewDelegate {
    weak var delegate: PlatformEditorAdapterDelegate?
    let textView: NSTextView

    init(textView: NSTextView) {
        self.textView = textView
        super.init()
        textView.delegate = self
    }

    func textDidChange(_ notification: Notification) {
        delegate?.adapterDidChangeText(self)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        delegate?.adapterDidChangeSelection(self)
    }

    func textDidBeginEditing(_ notification: Notification) {
        delegate?.adapterDidBeginEditing(self)
    }

    func textDidEndEditing(_ notification: Notification) {
        delegate?.adapterDidEndEditing(self)
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString string: String?) -> Bool {
        delegate?.adapter(self, shouldChangeTextIn: range, replacementText: string) ?? true
    }
}
#endif
