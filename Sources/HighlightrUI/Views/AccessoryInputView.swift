//
//  AccessoryInputView.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/14.
//

#if canImport(UIKit)
import SwiftUI

class AccessoryInputView<AccessoryContent: View>: UIToolbar {
    private let controller: UIHostingController<AccessoryContent>

    init(_ accessoryViewBuilder: () -> AccessoryContent ) {
        controller = UIHostingController<AccessoryContent>(rootView: accessoryViewBuilder())
        super.init(frame: .zero)
        isTranslucent = true
        
        controller.view.backgroundColor = .clear
        
        let customButton = UIBarButtonItem(customView:controller.view )
#if swift(>=6.2)
        if #available(iOS 26.0, *) {
            customButton.hidesSharedBackground = false
            customButton.sharesBackground = true
        }
#endif
        setItems([customButton], animated: false)
        sizeToFit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
