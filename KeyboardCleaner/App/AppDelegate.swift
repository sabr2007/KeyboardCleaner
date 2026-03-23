import Cocoa
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let eventTapManager = EventTapManager()
    private let modifierTracker = ModifierTracker()
    private let appState = AppState()
    private var displayManager: MultiDisplayManager?

    private var activationTimer: Timer?
    private var autoExitTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        preventDuplicateInstances()

        guard AccessibilityChecker.ensureAccessibility() else {
            return
        }

        setupEventTapCallbacks()
        startActivationSequence()
    }

    private func preventDuplicateInstances() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.keyboardcleaner"
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if running.count > 1 {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "KeyboardCleaner is already running"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            NSApplication.shared.terminate(nil)
        }
    }

    private func setupEventTapCallbacks() {
        eventTapManager.onFlagsChanged = { [weak self] rawFlags in
            DispatchQueue.main.async {
                self?.modifierTracker.updateFlags(rawFlags)
            }
        }

        modifierTracker.onExitTriggered = { [weak self] in
            self?.exitCleaningMode()
        }
    }

    private func startActivationSequence() {
        displayManager = MultiDisplayManager(
            tracker: modifierTracker,
            appState: appState
        )
        displayManager?.showOverlays()

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.appState.activationCountdown = self.appState.activationCountdown - 1

            if self.appState.activationCountdown <= 0 {
                timer.invalidate()
                self.activationTimer = nil
                self.activateEventTap()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        activationTimer = timer
    }

    private func activateEventTap() {
        let success = eventTapManager.start()
        if !success {
            let alert = NSAlert()
            alert.messageText = "Failed to create event tap"
            alert.informativeText = "Could not block input. Ensure Accessibility permission is granted and try again."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Quit")
            alert.runModal()
            NSApplication.shared.terminate(nil)
            return
        }
        startAutoExitTimer()
    }

    private func startAutoExitTimer() {
        appState.autoExitRemaining = 180
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.appState.autoExitRemaining = self.appState.autoExitRemaining - 1
            if self.appState.autoExitRemaining <= 0 {
                timer.invalidate()
                self.exitCleaningMode()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        autoExitTimer = timer
    }

    private func exitCleaningMode() {
        autoExitTimer?.invalidate()
        autoExitTimer = nil
        eventTapManager.stop()
        displayManager?.hideOverlays()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Safety net: ensure input is restored even if exitCleaningMode was bypassed
        eventTapManager.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
