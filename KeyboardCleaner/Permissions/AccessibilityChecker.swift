import Cocoa
import ApplicationServices

struct AccessibilityChecker {

    static func ensureAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            showPermissionAlert()
        }
        return trusted
    }

    private static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
            KeyboardCleaner needs Accessibility access to block keyboard and trackpad input.

            Please grant access in:
            System Settings → Privacy & Security → Accessibility

            Then relaunch the app.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        NSApplication.shared.terminate(nil)
    }
}
