//
//  AccessoryInputView.swift
//  PDHighlightr
//
//  Created by lynnswap on 2025/05/14.
//

#if canImport(UIKit)
import SwiftUI

class AccessoryInputView<AccessoryContent: View>: UIInputView {
    private let controller: UIHostingController<AccessoryContent>

    init(_ accessoryViewBuilder: () -> AccessoryContent ) {
        controller = UIHostingController<AccessoryContent>(rootView: accessoryViewBuilder())
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: NAVBAR_SIZE), inputViewStyle: .default)

        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = UIColor.clear
        addSubview(controller.view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var safeAreaInsets: UIEdgeInsets {
        .zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: controller.view.widthAnchor),
            heightAnchor.constraint(equalTo: controller.view.heightAnchor),
            centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
        ])
    }
}
#endif
