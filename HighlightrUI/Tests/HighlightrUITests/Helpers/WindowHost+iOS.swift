#if canImport(UIKit)
import UIKit

@MainActor
final class WindowHost {
    let window: UIWindow
    let rootViewController: UIViewController

    init(view: UIView) {
        let frame = CGRect(x: 0, y: 0, width: 390, height: 844)

        self.window = UIWindow(frame: frame)
        self.rootViewController = UIViewController()

        let container = UIView(frame: frame)
        container.backgroundColor = .systemBackground

        rootViewController.view = container
        container.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        container.layoutIfNeeded()
    }

    func pump() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    isolated deinit {
        window.isHidden = true
    }
}
#endif
