#if canImport(AppKit)
import AppKit

@MainActor
final class WindowHost {
    let window: NSWindow

    init(view: NSView) {
        _ = NSApplication.shared

        let frame = NSRect(x: 0, y: 0, width: 960, height: 640)
        self.window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        let container = NSView(frame: frame)
        container.wantsLayer = true
        window.contentView = container

        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        container.layoutSubtreeIfNeeded()
    }

    func pump() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    isolated deinit {
        window.orderOut(nil)
    }
}
#endif
