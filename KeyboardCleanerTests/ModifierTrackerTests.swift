import XCTest
@testable import KeyboardCleaner

final class ModifierTrackerTests: XCTestCase {

    private let leftCmd: UInt64 = 0x00000008
    private let rightCmd: UInt64 = 0x00000010
    private let commandMask: UInt64 = 0x00100000 // NSEvent.ModifierFlags.command

    func testNoCountdownWhenIdle() {
        let tracker = ModifierTracker()
        XCTAssertFalse(tracker.isCountingDown)
        XCTAssertEqual(tracker.countdownRemaining, 0)
    }

    func testNoCountdownWithOnlyLeftCommand() {
        let tracker = ModifierTracker()
        tracker.updateFlags(leftCmd | commandMask)
        XCTAssertFalse(tracker.isCountingDown)
    }

    func testNoCountdownWithOnlyRightCommand() {
        let tracker = ModifierTracker()
        tracker.updateFlags(rightCmd | commandMask)
        XCTAssertFalse(tracker.isCountingDown)
    }

    func testCountdownStartsWithBothCommands() {
        let tracker = ModifierTracker()
        tracker.updateFlags(leftCmd | rightCmd | commandMask)
        XCTAssertTrue(tracker.isCountingDown)
        XCTAssertEqual(tracker.countdownRemaining, 3.0)
    }

    func testCountdownResetsWhenLeftReleased() {
        let tracker = ModifierTracker()
        tracker.updateFlags(leftCmd | rightCmd | commandMask)
        XCTAssertTrue(tracker.isCountingDown)

        tracker.updateFlags(rightCmd | commandMask)
        XCTAssertFalse(tracker.isCountingDown)
        XCTAssertEqual(tracker.countdownRemaining, 0)
    }

    func testCountdownResetsWhenRightReleased() {
        let tracker = ModifierTracker()
        tracker.updateFlags(leftCmd | rightCmd | commandMask)
        XCTAssertTrue(tracker.isCountingDown)

        tracker.updateFlags(leftCmd | commandMask)
        XCTAssertFalse(tracker.isCountingDown)
        XCTAssertEqual(tracker.countdownRemaining, 0)
    }

    func testCountdownResetsWhenAllReleased() {
        let tracker = ModifierTracker()
        tracker.updateFlags(leftCmd | rightCmd | commandMask)
        XCTAssertTrue(tracker.isCountingDown)

        tracker.updateFlags(0)
        XCTAssertFalse(tracker.isCountingDown)
    }

    func testExitTriggeredAfterHoldDuration() {
        let tracker = ModifierTracker()
        let expectation = expectation(description: "Exit triggered")

        tracker.onExitTriggered = {
            expectation.fulfill()
        }

        tracker.updateFlags(leftCmd | rightCmd | commandMask)

        waitForExpectations(timeout: 5.0)
    }

    func testExitNotTriggeredIfReleasedEarly() {
        let tracker = ModifierTracker()
        var exitCalled = false

        tracker.onExitTriggered = {
            exitCalled = true
        }

        tracker.updateFlags(leftCmd | rightCmd | commandMask)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            tracker.updateFlags(0)
        }

        let expectation = expectation(description: "Wait for potential exit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 6.0)
        XCTAssertFalse(exitCalled)
    }
}
