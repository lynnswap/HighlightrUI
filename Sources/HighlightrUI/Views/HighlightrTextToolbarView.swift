//
//  HighlightrTextToolbarView.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/13.
//
import SwiftUI
let NAVBAR_SIZE :CGFloat = 44
#if canImport(UIKit)
let ICON_WEIGHT :Font.Weight = .bold


struct HighlightrTextToolbarView: View {
    var model:HighlightrTextViewModel
    var body:some View{
        toolbarView
            .padding(.horizontal,16)
            .frame(height:NAVBAR_SIZE)
            .background(.ultraThinMaterial)
        
    }
    let iconSize :CGFloat = 32
    let iconSize2 :CGFloat = 36
    private var toolbarView: some View{
        HStack(spacing:4){
            Button {
                model.undo()
            } label: {
                Image(systemName:"arrow.uturn.left")
                    .fontWeight(ICON_WEIGHT)
                    .imageScale(.medium)
                    .contentShape(Rectangle())
            }
            .frame(width:iconSize)
            
            Button {
                model.insertIndent()
            } label: {
                Text(String("→"))
                    .fontWeight(ICON_WEIGHT)
                    .imageScale(.medium)
                    .contentShape(Rectangle())
            }
            .frame(width:iconSize)
            
            Button {
                model.insertParentheses(type:.kakko)
            } label: {
                Text(String("( )"))
                    .fontWeight(ICON_WEIGHT)
                    .imageScale(.medium)
                    .contentShape(Rectangle())
            }
            .frame(width:iconSize)
            
            Button {
                model.insertCurlyBraces()
            } label: {
                Text(String("{ }"))
                    .fontWeight(ICON_WEIGHT)
                    .imageScale(.medium)
                    .contentShape(Rectangle())
            }
            .frame(width:iconSize)
            
           
            doubleQuoteButton()
            singleQuoteButton()
            
            Spacer()
            
            Button {
                model.deleteCurrentLine()
            } label: {
                Text(String("←"))
                    .fontWeight(ICON_WEIGHT)
                    .imageScale(.medium)
                    .contentShape(Rectangle())
            }
            .frame(width:iconSize2)
            
            Button {
                model.clearText()
            } label: {
                Image(systemName: "eraser")
                    .fontWeight(ICON_WEIGHT)
                    .imageScale(.medium)
                    .contentShape(Rectangle())
            }
            .frame(width:iconSize2)
            
            Button {
                model.dismissKeyboard()
            } label: {
                Image(systemName: "chevron.down")
                    .fontWeight(ICON_WEIGHT)
                    .imageScale(.medium)
                    .contentShape(Rectangle())
            }
            .frame(width:iconSize2)
        }
    }
    
    private func doubleQuoteButton() -> some View {
        Button {
            model.insertParentheses(type:.doubleQuotaion)
        } label: {
            Text(String("\" \""))
                .fontWeight(ICON_WEIGHT)
                .imageScale(.medium)
                .contentShape(Rectangle())
        }
        .frame(width:iconSize)
    }
    private func singleQuoteButton() -> some View {
        Button {
            model.insertParentheses(type:.singleQuotaion)
        } label: {
            Text(String("\' \'"))
                .fontWeight(ICON_WEIGHT)
                .imageScale(.medium)
                .contentShape(Rectangle())
        }
        .frame(width:iconSize)
    }
}
extension HighlightrTextViewModel{
    func dismissKeyboard() {
        textView.resignFirstResponder()
    }
    func focusKeyboard(){
        textView.becomeFirstResponder()
    }
    func undo(){
        guard let undoManager = textView.undoManager else { return }
        undoManager.undo()
    }
    func insertIndent() {
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
    func insertCurlyBraces() {
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
    func clearText() {
        self.registerUndo()
        self.setText( "")
    }
    
    func deleteCurrentLine() {
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
    enum insertParentType: String,CaseIterable {
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

    func insertParentheses(type:insertParentType) {
        self.registerUndo()
        
        let selectedRange = textView.selectedRange
        let updatedText = (textView.text as NSString).replacingCharacters(in: selectedRange, with: type.text)
        self.setText(updatedText)
        let newPosition = textView.position(from: textView.beginningOfDocument, offset: selectedRange.location + 1)
        textView.selectedTextRange = textView.textRange(from: newPosition!, to: newPosition!)
    }
}


#endif
