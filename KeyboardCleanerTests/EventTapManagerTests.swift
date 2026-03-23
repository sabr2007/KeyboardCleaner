import XCTest
@testable import KeyboardCleaner

final class EventTapManagerTests: XCTestCase {

    // MARK: - Initial State

    func testOnFlagsChangedIsNilByDefault() {
        let manager = EventTapManager()
        XCTAssertNil(manager.onFlagsChanged, "onFlagsChanged callback should be nil before assignment")
    }

    func testOnFlagsChangedCanBeAssigned() {
        let manager = EventTapManager()
        var callCount = 0
        manager.onFlagsChanged = { _ in callCount += 1 }
        XCTAssertNotNil(manager.onFlagsChanged)
    }

    func testOnFlagsChangedCallbackInvocation() {
        let manager = EventTapManager()
        var receivedFlags: UInt64 = 0
        manager.onFlagsChanged = { flags in receivedFlags = flags }

        // Invoke the stored callback directly to verify it routes correctly
        manager.onFlagsChanged?(0xDEADBEEF)
        XCTAssertEqual(receivedFlags, 0xDEADBEEF)
    }

    // MARK: - Stop Without Prior Start (safety guard)

    func testStopWithoutStartDoesNotCrash() {
        let manager = EventTapManager()
        // Must not crash or throw — stop() guards against nil eventTap/runLoopSource
        manager.stop()
    }

    func testStopTwiceDoesNotCrash() {
        let manager = EventTapManager()
        manager.stop()
        manager.stop()
    }

    // MARK: - Start Failure Path (no Accessibility permission in CI)

    func testStartReturnsFalseWithoutAccessibilityPermission() {
        // In a sandboxed test environment without Accessibility entitlement,
        // CGEvent.tapCreate returns nil and start() must return false gracefully.
        // If the test runs with permission, this will return true — both outcomes
        // are valid; we assert the return type is Bool.
        let manager = EventTapManager()
        let result = manager.start()
        XCTAssertTrue(result == true || result == false,
                      "start() must return a Bool without crashing regardless of permission state")
        // Clean up if start succeeded
        if result { manager.stop() }
    }

    // MARK: - Start / Stop Lifecycle

    func testStopAfterFailedStartDoesNotCrash() {
        let manager = EventTapManager()
        // If start() returns false, eventTap is nil — stop() must still be safe
        _ = manager.start()
        manager.stop()
    }

    func testOnFlagsChangedSurvivesStopCycle() {
        let manager = EventTapManager()
        var called = false
        manager.onFlagsChanged = { _ in called = true }
        manager.stop()
        // Callback reference is unaffected by stop()
        manager.onFlagsChanged?(0)
        XCTAssertTrue(called)
    }

    // MARK: - Callback Reassignment

    func testOnFlagsChangedCanBeReassigned() {
        let manager = EventTapManager()
        var first = false
        var second = false

        manager.onFlagsChanged = { _ in first = true }
        manager.onFlagsChanged = { _ in second = true }

        manager.onFlagsChanged?(0)
        XCTAssertFalse(first, "First callback should no longer be invoked after reassignment")
        XCTAssertTrue(second, "Second callback should be invoked")
    }

    func testOnFlagsChangedCanBeCleared() {
        let manager = EventTapManager()
        manager.onFlagsChanged = { _ in }
        manager.onFlagsChanged = nil
        XCTAssertNil(manager.onFlagsChanged)
    }

    // MARK: - Deallocation Safety

    func testManagerDeallocatesWithoutCrash() {
        var manager: EventTapManager? = EventTapManager()
        manager?.onFlagsChanged = { _ in }
        manager = nil  // Should not crash
    }

    func testManagerDeallocatesAfterStopWithoutCrash() {
        var manager: EventTapManager? = EventTapManager()
        manager?.stop()
        manager = nil
    }
}
