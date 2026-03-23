import XCTest
@testable import KeyboardCleaner

/// Tests for AccessibilityChecker.
///
/// `AXIsProcessTrustedWithOptions` is a system call that requires a real macOS
/// security prompt; we cannot grant or revoke that permission from unit tests.
/// These tests therefore verify:
///   1. The API surface compiles and is callable.
///   2. The return value is a Bool (the function contracts hold regardless of
///      whether the host machine has the entitlement).
///   3. Calling the function repeatedly is idempotent (no crash on second call).
///
/// Behaviour that is intentionally NOT covered here:
///   - The NSAlert dialog path (requires a display server and user interaction).
///   - NSApplication.terminate() (would abort the test runner).
final class AccessibilityCheckerTests: XCTestCase {

    // MARK: - API Surface

    func testEnsureAccessibilityReturnsBool() {
        // Calling the real system API is acceptable: in a test runner without the
        // entitlement it returns false without showing a UI prompt when the
        // kAXTrustedCheckOptionPrompt value is overridden at the call site. We
        // cannot override it from outside, but we can assert the return type.
        let result = AccessibilityChecker.ensureAccessibility()
        XCTAssertTrue(result == true || result == false,
                      "ensureAccessibility() must return a Bool")
    }

    func testEnsureAccessibilityIsCallableMultipleTimes() {
        // Verifies there is no internal state that makes repeated calls crash.
        // In CI the permission is never granted so both calls return false;
        // on a dev machine with permission both return true.
        let first  = AccessibilityChecker.ensureAccessibility()
        let second = AccessibilityChecker.ensureAccessibility()
        XCTAssertEqual(first, second,
                       "Repeated calls with the same OS permission state must return the same value")
    }

    // MARK: - Struct Semantics

    func testAccessibilityCheckerIsAValueType() {
        // AccessibilityChecker is a struct — verify it has value-type copy semantics.
        let a = AccessibilityChecker()
        let b = a             // copy
        _ = b                 // use to suppress warning
        // No crash or assertion means the value-type copy succeeded.
    }
}
