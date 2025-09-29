//
//  HighlightrTextView.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/13.
//

import SwiftUI

public struct HighlightrTextView: View{
    @Binding private var text:String
    private let language: String
    
    @State var model:HighlightrTextViewModel?
#if canImport(UIKit)
    var _inputAccessoryView: UIView?
    var _accessoryBuilder: ((HighlightrTextViewModel) -> UIView?)?
#endif
    
    public init(
        text: Binding<String>,
        language: String
    ) {
        self._text = text
        self.language = language
    }
    
    public var body:some View{
        if let model {
#if canImport(UIKit)
            let accessory = _accessoryBuilder?(model) ?? _inputAccessoryView
            HighlightrTextViewRepresentable(model:model, inputAccessoryView: accessory)
                .highlightrToolbar(model)
                .highlightrTextSync(model, text: $text)
                .navigationBarTitleDisplayMode(.inline)
#else
            HighlightrTextViewRepresentable(model:model)
                .highlightrToolbar(model)
                .highlightrTextSync(model, text: $text)
#endif
        }else{
            Color.clear
                .onAppear{
                    self.model = HighlightrTextViewModel(language)
                }
        }
    }
}
 



#if canImport(UIKit)
struct HighlightrTextViewRepresentable: UIViewRepresentable {
    var model: HighlightrTextViewModel
    var inputAccessoryView: UIView?

    func makeUIView(context: Context) -> PAM_HighlightrTextView {
        let tv = model.textView
        tv.inputAccessoryView = inputAccessoryView
        return tv
    }

    func updateUIView(_ uiView: PAM_HighlightrTextView, context: Context) {
    }
}

#elseif canImport(AppKit)
struct HighlightrTextViewRepresentable: NSViewRepresentable {
    var model:HighlightrTextViewModel
    func makeNSView(context: Context) -> PAM_HighlightrTextView {
        return model.textView
    }
    func updateNSView(_ uiView: PAM_HighlightrTextView, context: Context) {
    }
}
#endif

#if DEBUG
#Preview{
    HighlightrTextViewWrapper()
}
struct HighlightrTextViewWrapper:View{
    @State private var theme = "paraiso-dark"
    @State private var text :String = testScript
    var body:some View{
        NavigationStack{
            HighlightrTextView(text:$text,language:"javascript")
#if canImport(UIKit)
                .inputAccessory { model in
                    HStack{
                        Spacer()
                        Button{
                            model.dismissKeyboard()
                        }label:{
                            Image(systemName:"chevron.down")
                        }
                    }
                }
#endif
                .theme($theme)
                .padding(.leading,4)
            
        }
    }
}
private let testScript = """
let searchHrefCache = window.location.href;
function searchResults(){
    if (searchHrefCache == window.location.href) return;
    if (searchHrefCache.indexOf('https://x.com/explore') !==-1 && window.location.href.indexOf('https://x.com/search?q=')!==-1) {
        const liveButton = document.querySelector('a[href$="&f=live"]');
        if (!liveButton) return;
        liveButton.click();
    }
    searchHrefCache = window.location.href;
}
"""
#endif

