//
//  HighlightrTextViewModel.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/13.
//

import SwiftUI
import Highlightr

#if canImport(UIKit)
public typealias PAM_HighlightrTextView = UITextView
public typealias PAM_TextView = UITextView
#elseif canImport(AppKit)
public typealias PAM_HighlightrTextView = NSScrollView
public typealias PAM_TextView = NSTextView
#endif

@MainActor
@Observable public class HighlightrTextViewModel: NSObject{
    @ObservationIgnored public lazy var codeAttributedString : CodeAttributedString = {
        let container = CodeAttributedString()
        container.language = self.language
        return container
    }()
    @ObservationIgnored public var highlightr:Highlightr{
        self.codeAttributedString.highlightr
    }
    public var pam_textView:PAM_TextView?
    @ObservationIgnored public lazy var textView : PAM_HighlightrTextView = {
#if canImport(UIKit)
        let layoutManager = NSLayoutManager()
        let textStorage = codeAttributedString
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: .zero)
        layoutManager.addTextContainer(textContainer)
        let textView = PAM_HighlightrTextView(frame: .zero, textContainer: textContainer)
        
        textView.delegate = self
        
        textView.alwaysBounceVertical = true
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.spellCheckingType = .no
        textView.keyboardDismissMode = .interactive
        
        pam_textView = textView
        
        
#elseif canImport(AppKit)
        let textView = NSTextView.scrollableTextView()
        let textDocumentView = textView.documentView as! NSTextView
        pam_textView = textDocumentView
        let textStorage = codeAttributedString
        textDocumentView.allowsUndo = true
        textStorage.addLayoutManager(textDocumentView.layoutManager!)
        textDocumentView.delegate = self
        
        
        textView.hasHorizontalScroller = true
        textDocumentView.isHorizontallyResizable = true
        textDocumentView.maxSize = NSMakeSize(.greatestFiniteMagnitude, .greatestFiniteMagnitude)
        textDocumentView.textContainer?.widthTracksTextView = false
        textDocumentView.textContainer?.containerSize = NSMakeSize(.greatestFiniteMagnitude, .greatestFiniteMagnitude)
        
        // 文字補正設定
        textDocumentView.isAutomaticQuoteSubstitutionEnabled = false
        textDocumentView.isAutomaticDashSubstitutionEnabled = false
        textDocumentView.isAutomaticTextReplacementEnabled = false
        textDocumentView.isAutomaticSpellingCorrectionEnabled = false
        textDocumentView.isContinuousSpellCheckingEnabled = false
        textDocumentView.isGrammarCheckingEnabled = false
        
        textDocumentView.backgroundColor = .clear
        textView.drawsBackground = false
        
        textView.contentInsets.bottom = 80
#endif
        textView.backgroundColor = .clear
        return textView
    }()
    @ObservationIgnored var language:String
    
    public private(set) var text:String = ""
#if os(iOS)
    public private(set) var isForcused:Bool = false
#endif
    
    public init(
        _ language:String
    ){
        self.language = language
    }
    public func setText(
        _ inputText: String,
        initial: Bool = false
    ) {
        self.text = inputText          // モデル側の保持値を更新
        
    #if canImport(AppKit)
        guard let tv = (textView.documentView as? NSTextView) else { return }
        
        if initial {
            if let um = tv.undoManager {
                um.disableUndoRegistration() // これ以降の操作は記録しない
                tv.string = inputText        // 初期テキストを流し込む
                um.enableUndoRegistration()  // Undo 登録を再開
                um.removeAllActions()        // 既存スタックを丸ごと削除
            } else {
                tv.string = inputText        // UndoManager が nil なら普通に代入
            }
        } else {
            tv.string = inputText            // 通常の更新
        }
    #else   // UIKit
        if initial {
            if let um = textView.undoManager {
              
                textView.text = inputText
                um.removeAllActions()
            } else {
                textView.text = inputText
            }
        } else {
            textView.text = inputText
        }
    #endif
    }
}
#if canImport(AppKit)
extension HighlightrTextViewModel:NSTextViewDelegate{
    public func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }

        self.text = textView.string
    }
    
}
extension NSTextView{
    var text:String{
        get { self.string }
        set { self.string = newValue }
    }
}
#endif

#if canImport(UIKit)
extension HighlightrTextViewModel:UITextViewDelegate{
    public func textViewDidChange(_ textView: UITextView){
        self.text = textView.text
    }
}
#endif

extension HighlightrTextViewModel {
    public func registerUndo() {
        guard let textView = pam_textView,
              let manager = textView.undoManager  else { return }
#if os(iOS)
        let oldText  = textView.text ?? ""
        let beforeLoc = textView.offset(
            from: textView.beginningOfDocument,
            to: textView.selectedTextRange?.start ?? textView.beginningOfDocument
        )
        
        manager.beginUndoGrouping()
        
        manager.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                guard let tv = target.pam_textView else { return }
                
                // MARK: テキスト復元
                tv.undoManager?.disableUndoRegistration()
                tv.replace(tv.textRange(from: tv.beginningOfDocument,to: tv.endOfDocument)!,withText: oldText)
                tv.undoManager?.enableUndoRegistration()
                
                // MARK: カーソル位置補正
                let lengthDiff = tv.text.count - oldText.count
                var newLoc = max(0, beforeLoc - lengthDiff)
                newLoc = min(newLoc, oldText.count)
                
                if let pos = tv.position(from: tv.beginningOfDocument, offset: newLoc) {
                    tv.selectedTextRange = tv.textRange(from: pos, to: pos)
                }
                tv.scrollRangeToVisible(NSRange(location: newLoc, length: 0))
            }
        }
        
        manager.setActionName("Edit")
        manager.endUndoGrouping()
#elseif os(macOS)
        let oldText = textView.string
        manager.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                guard let tv = target.pam_textView else { return }
                
                let beforeUndoRange = tv.selectedRange()
                let lengthDiff = tv.string.count - oldText.count
                
                // MARK: テキスト復元
                tv.string = oldText
                
                // MARK: カーソル位置補正
                var newLoc = max(0, beforeUndoRange.location - lengthDiff)
                newLoc = min(newLoc, oldText.count)
                tv.setSelectedRange(NSRange(location: newLoc, length: 0))
                tv.scrollRangeToVisible(NSRange(location: newLoc, length: 0))
            }
        }
#endif
    }
}
extension HighlightrTextViewModel{
#if canImport(UIKit)
    public func textView(_ textView: PAM_TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView_shouldChangeTextIn(textView,shouldChangeTextIn:range,replacementText:text)
    }
#elseif canImport(AppKit)
    public func textView(_ textView: PAM_TextView, shouldChangeTextIn range: NSRange, replacementString text: String?) -> Bool {
        return textView_shouldChangeTextIn(textView,shouldChangeTextIn:range,replacementText:text ?? "")
    }
#endif
    public func textView_shouldChangeTextIn(
        _ textView: PAM_TextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool{
        
        guard text == "\n" else { return true }
        // ユーザーが改行キーを押した場合
        
        let currentText = textView.text as NSString
        let currentLineRange = currentText.lineRange(for: NSRange(location: range.location, length: 0))
        let currentLine = currentText.substring(with: currentLineRange)
        
        // 前の行のインデント部分を正規表現で取り出す
        guard let indentRange = currentLine.range(of: "^[ \t]*", options: .regularExpression) else { return true }
    
        let nsRange = NSRange(indentRange, in: currentLine) // Range<String.Index>をNSRangeに変換
        let indent = (currentLine as NSString).substring(with: nsRange)
        self.registerUndo()
        // カーソル位置に改行とインデントを挿入
        let updatedText = (textView.text as NSString).replacingCharacters(in: range, with: "\n" + indent)
        textView.text = updatedText
        
        // カーソル位置を改行後のインデント部分の直後に移動
        let newCursorPosition = range.location + indent.count + 1
#if canImport(UIKit)
        // ------ iOS (UITextView) ------
        if let newPosition = textView.position(from: textView.beginningOfDocument, offset: newCursorPosition) {
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        }
#elseif canImport(AppKit)
        // ------ macOS (NSTextView) ------
        textView.setSelectedRange(NSRange(location: newCursorPosition, length: 0))
        textView.scrollRangeToVisible(textView.selectedRange())
#endif
        self.text = textView.text
        // すでに改行を処理したのでfalseを返してデフォルトの挙動を無効化
        return false
    }
    public func setTheme(_ theme:String){
        self.codeAttributedString.highlightr.setTheme(to: theme)
    }

#if os(iOS)
    public func textViewDidBeginEditing(_ textView: UITextView) {
        self.isForcused = true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        self.isForcused = false
    }
#endif
}


#if canImport(AppKit)
class WrappableTextView: NSTextView {
    /// 現在折り返しをしているかどうか
    private var isLineWrapping = false

    override func keyDown(with event: NSEvent) {
        // optionキーが押されていて、文字が "z" の場合にトグル
        if event.modifierFlags.contains(.option),
           let chars = event.charactersIgnoringModifiers,
           chars == "z" {
            toggleLineWrapping()
        } else {
            super.keyDown(with: event)
        }
    }

    private func toggleLineWrapping() {
        isLineWrapping.toggle()
        applyLineWrapping(isLineWrapping)
    }

    private func applyLineWrapping(_ wrap: Bool) {
        guard let container = self.textContainer else { return }

        if wrap {
            // 折り返しあり
            self.isHorizontallyResizable = false
            container.widthTracksTextView = true
            // 自動でビューポート幅に追随するように設定
            let newSize = NSMakeSize(
                self.superview?.bounds.width ?? self.bounds.width,
                .greatestFiniteMagnitude)
            self.maxSize = newSize
            container.containerSize = newSize
            
        } else {
            // 折り返しなし
            self.isHorizontallyResizable = true
            container.widthTracksTextView = false
            // 横幅は無限大にして水平スクロール可能にする
            let newSize =  NSMakeSize(
                .greatestFiniteMagnitude,
                .greatestFiniteMagnitude
            )
            self.maxSize = newSize
            container.containerSize = newSize
        }

        // 再描画
//        needsDisplay = true
    }
}
#endif
