//
//  HighlightrJSConsoleView.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/14.
//


import SwiftUI
import Highlightr

#if canImport(UIKit)
typealias PAM_ViewRepresentable = UIViewRepresentable

#elseif canImport(AppKit)
typealias PAM_ViewRepresentable = NSViewRepresentable
#endif


public struct HighlightrJSConsoleView:View{
    @Binding private var text:String
    private let maxHeight:CGFloat
    
    @State var model:HighlightrTextViewModel?
    
#if canImport(UIKit)
    var _inputAccessoryView: UIView?
    var _accessoryBuilder: ((HighlightrTextViewModel) -> UIView?)?
#endif
    
    public init(text: Binding<String>, maxHeight: CGFloat) {
        self._text    = text
        self.maxHeight = maxHeight
    }
    
    public var body:some View{
        if let model {
#if canImport(UIKit)
            let accessory = _accessoryBuilder?(model) ?? _inputAccessoryView
            HighlightrConsoleViewRepresentable(model:model, maxHeight:maxHeight, text:$text, inputAccessoryView: accessory)
                .onChange(of:text){
                    let textView = model.textView
                    var frame = textView.frame
                    frame.size.height = min(textView.contentSize.height,maxHeight)
                    textView.frame = frame
                }
                .highlightrToolbar(model)
                .highlightrTextSync(model, text: $text)
#else
            HighlightrConsoleViewRepresentable(model:model, maxHeight:maxHeight, text:$text)
                .onChange(of:text){
                    let textView = model.textView
                    var frame = textView.frame
                    frame.size.height = min(textView.contentSize.height,maxHeight)
                    textView.frame = frame
                }
                .highlightrToolbar(model)
                .highlightrTextSync(model, text: $text)
#endif
        }else{
            Color.clear
                .onAppear{
                    self.model = HighlightrTextViewModel("javascript")
                }
        }
    }
}

struct HighlightrConsoleViewRepresentable: PAM_ViewRepresentable {
    var model:HighlightrTextViewModel
    var maxHeight:CGFloat
    @Binding var text:String
    
#if canImport(UIKit)
    var inputAccessoryView: UIView?
#endif
    
#if canImport(UIKit)
    func makeUIView(context: Context) -> PAM_HighlightrTextView {
        let tv = model.textView
        tv.inputAccessoryView = inputAccessoryView
        return tv
    }
    
    func updateUIView(_ textView: PAM_HighlightrTextView, context: Context) {
    }
#elseif canImport(AppKit)
    func makeNSView(context: Context) -> PAM_HighlightrTextView {
        return model.textView
    }
    func updateNSView(_ uiView: PAM_HighlightrTextView, context: Context) {
    }
#endif
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PAM_HighlightrTextView, context: Context) -> CGSize? {
        let dimensions = proposal.replacingUnspecifiedDimensions(
            by: .init(
                width: 0,
                height: CGFloat.greatestFiniteMagnitude
            )
        )
#if canImport(UIKit)
        let calculatedHeight = calculateTextViewHeight(
            containerSize: dimensions,
            attributedString: uiView.attributedText
        )
#elseif canImport(AppKit)
        
        guard let textView = uiView.documentView as? NSTextView else { return nil }
        let calculatedHeight = calculateTextViewHeight(
            containerSize: dimensions,
            attributedString: textView.attributedString()
        )
#endif
        return .init(
            width: dimensions.width,
            height: calculatedHeight
        )
    }
    
    private func calculateTextViewHeight(containerSize: CGSize,
                                         attributedString: NSAttributedString) -> CGFloat {
        let boundingRect = attributedString.boundingRect(
            with: .init(width: containerSize.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        if boundingRect.height < 50{
            return 70
        }else if boundingRect.height > maxHeight{
            return maxHeight
        }else {
            return boundingRect.height
        }
    }
}
#Preview{
    @Previewable @State var text :String = "aaaa\naaaaa\n\niii"
    VStack(spacing:0){
        Rectangle()
            .fill(.indigo.gradient)
            .ignoresSafeArea()
        HighlightrJSConsoleView(text:$text,maxHeight: 300)
            .padding(.top,4)
            .padding(.leading,16)
    }
}
