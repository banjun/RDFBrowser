import Cocoa

final class WindowController: NSWindowController {
    init(contentViewController: NSViewController) {
        super.init(window: NSWindow(contentRect: NSRect(x: 0, y: 0, width: 512, height: 512), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered,
                                    defer: false))
        self.contentViewController = contentViewController
    }
    required init?(coder: NSCoder) {fatalError()}
}
