import Cocoa
import SwiftUI
import Combine

final class MultiDisplayManager {

    private var windowControllers: [OverlayWindowController] = []
    private let tracker: ModifierTracker
    private let appState: AppState
    private var screenObserver: Any?

    init(tracker: ModifierTracker, appState: AppState) {
        self.tracker = tracker
        self.appState = appState
    }

    func showOverlays() {
        createOverlayWindows()
        observeScreenChanges()
    }

    func hideOverlays() {
        removeScreenObserver()
        for controller in windowControllers {
            controller.hide()
        }
        windowControllers.removeAll()
    }

    private func createOverlayWindows() {
        for controller in windowControllers {
            controller.hide()
        }
        windowControllers.removeAll()

        for screen in NSScreen.screens {
            let contentView = OverlayContentView(
                tracker: tracker,
                appState: appState
            )
            let hostingView = NSHostingView(rootView: contentView)
            let controller = OverlayWindowController(screen: screen, contentView: hostingView)
            controller.show()
            windowControllers.append(controller)
        }
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.createOverlayWindows()
        }
    }

    private func removeScreenObserver() {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }
    }

    deinit {
        removeScreenObserver()
    }
}
