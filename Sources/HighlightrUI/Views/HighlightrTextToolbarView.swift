//
//  HighlightrTextToolbarView.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/13.
//

#if canImport(UIKit)
import SwiftUI
extension HighlightrTextViewModel{
    public func dismissKeyboard() {
        textView.resignFirstResponder()
    }
    public func focusKeyboard(){
        textView.becomeFirstResponder()
    }
    public func undo(){
        guard let undoManager = textView.undoManager else { return }
        undoManager.undo()
    }
    public func insertIndent() {
        let selectedRange = textView.selectedRange
        let currentText = textView.text as NSString
        let indent = "    " // 4 spaces
        
        self.registerUndo()
        
        let updatedText = currentText.replacingCharacters(in: selectedRange, with: indent)
        self.setText(updatedText)
        
        // Move the cursor after the inserted indent
        let newCursorPosition = selectedRange.location + indent.count
        if let newPosition = textView.position(from: textView.beginningOfDocument, offset: newCursorPosition) {
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        }
    }
    public func insertCurlyBraces() {
        let selectedRange = textView.selectedRange
        let currentText = textView.text as NSString
        
        self.registerUndo()
        
        // 挿入箇所の前後を取得
        let textBeforeCursor = currentText.substring(to: selectedRange.location)
        let textAfterCursor = currentText.substring(from: selectedRange.location)
        
        // 挿入前の行を取得してインデントを解析
        let currentLineRange = currentText.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let currentLine = currentText.substring(with: currentLineRange)
        
        // 正規表現で前の行のインデント部分を取り出す
        let indent: String
        if let indentRange = currentLine.range(of: "^[ \t]*", options: .regularExpression) {
            let nsRange = NSRange(indentRange, in: currentLine)
            indent = (currentLine as NSString).substring(with: nsRange)
        } else {
            indent = ""
        }
        
        // カーソル位置に {} と改行＋インデントを挿入
        let updatedText = """
        \(textBeforeCursor){
        \(indent)    
        \(indent)}
        \(textAfterCursor)
        """
        
        self.setText( updatedText)
        
        // カーソル位置を {} の間に移動
        let newCursorPosition = (textBeforeCursor as NSString).length + indent.count + 6
        if let newPosition = textView.position(from: textView.beginningOfDocument, offset: newCursorPosition) {
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        }
    }
    public func clearText() {
        self.registerUndo()
        self.setText( "")
    }
    
    public func deleteCurrentLine() {
        // 現在の選択範囲（カーソル位置）を取得
        let selectedRange = textView.selectedRange
        let currentText = textView.text as NSString
        
        // 現在の行の範囲を取得
        let currentLineRange = currentText.lineRange(for: selectedRange)
        
        self.registerUndo()
        
        // 現在の行を削除
        let updatedText = currentText.replacingCharacters(in: currentLineRange, with: "")
        self.setText( updatedText)
        
        // カーソル位置を調整（次の行の先頭に移動）
        let newCursorPosition = currentLineRange.location
        if let newPosition = textView.position(from: textView.beginningOfDocument, offset: newCursorPosition) {
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        }
        
    }
    public enum insertParentType: String,CaseIterable {
        case kakko
        case singleQuotaion
        case doubleQuotaion
        
        var text: String {
            return switch self {
            case .kakko:"()"
            case .singleQuotaion:"\'\'"
            case .doubleQuotaion:"\"\""
            }
        }
    }

    public func insertParentheses(type:insertParentType) {
        self.registerUndo()
        
        let selectedRange = textView.selectedRange
        let updatedText = (textView.text as NSString).replacingCharacters(in: selectedRange, with: type.text)
        self.setText(updatedText)
        let newPosition = textView.position(from: textView.beginningOfDocument, offset: selectedRange.location + 1)
        textView.selectedTextRange = textView.textRange(from: newPosition!, to: newPosition!)
    }
}


#endif
