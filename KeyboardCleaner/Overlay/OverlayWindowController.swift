import Cocoa
import SwiftUI

final class OverlayWindowController: NSWindowController {

    init(screen: NSScreen, contentView: NSView) {
        let window = OverlayWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = .init(Int(CGWindowLevelForKey(.screenSaverWindow)))
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.contentView = contentView
        window.setFrame(screen.frame, display: true)

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func show() {
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }
}

private final class OverlayWindow: NSWindow {

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func makeTouchBar() -> NSTouchBar? {
        NSTouchBar()
    }
}
