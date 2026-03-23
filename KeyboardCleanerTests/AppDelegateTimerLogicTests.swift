import XCTest
@testable import KeyboardCleaner

/// Tests for the countdown and auto-exit timer logic extracted into
/// `ActivationCountdownTimer` and `AutoExitTimer`.
///
/// These tests do NOT start the real AppDelegate (which would call
/// `ensureAccessibility()` and potentially terminate the process).
/// Instead they exercise the extracted timer helpers directly.
final class AppDelegateTimerLogicTests: XCTestCase {

    // MARK: - ActivationCountdownTimer

    func testActivationCountdownInitialValue() {
        let timer = ActivationCountdownTimer(startValue: 3)
        XCTAssertEqual(timer.remaining, 3)
    }

    func testActivationCountdownInitialValueCustom() {
        let timer = ActivationCountdownTimer(startValue: 5)
        XCTAssertEqual(timer.remaining, 5)
    }

    func testActivationCountdownDecrementsOnTick() {
        let timer = ActivationCountdownTimer(startValue: 3)
        timer.tick()
        XCTAssertEqual(timer.remaining, 2)
    }

    func testActivationCountdownDecrementsToZero() {
        let timer = ActivationCountdownTimer(startValue: 3)
        timer.tick()
        timer.tick()
        timer.tick()
        XCTAssertEqual(timer.remaining, 0)
    }

    func testActivationCountdownFiresCallbackAtZero() {
        let timer = ActivationCountdownTimer(startValue: 2)
        var fired = false
        timer.onComplete = { fired = true }

        timer.tick()
        XCTAssertFalse(fired, "Callback must not fire before reaching zero")

        timer.tick()
        XCTAssertTrue(fired, "Callback must fire exactly when remaining reaches zero")
    }

    func testActivationCountdownDoesNotFireCallbackBeforeZero() {
        let timer = ActivationCountdownTimer(startValue: 3)
        var fireCount = 0
        timer.onComplete = { fireCount += 1 }

        timer.tick()
        timer.tick()
        XCTAssertEqual(fireCount, 0)
    }

    func testActivationCountdownCallbackFiredOnce() {
        let timer = ActivationCountdownTimer(startValue: 1)
        var fireCount = 0
        timer.onComplete = { fireCount += 1 }

        timer.tick()   // reaches 0 — fires
        timer.tick()   // extra ticks after zero must NOT re-fire
        timer.tick()
        XCTAssertEqual(fireCount, 1, "onComplete must fire exactly once")
    }

    func testActivationCountdownDoesNotGoNegative() {
        let timer = ActivationCountdownTimer(startValue: 1)
        timer.tick()   // 0
        timer.tick()   // would be -1 if unclamped
        timer.tick()
        XCTAssertGreaterThanOrEqual(timer.remaining, 0)
    }

    func testActivationCountdownZeroStartFiresImmediately() {
        let timer = ActivationCountdownTimer(startValue: 0)
        var fired = false
        timer.onComplete = { fired = true }
        timer.tick()
        XCTAssertTrue(fired)
    }

    // MARK: - AutoExitTimer

    func testAutoExitTimerInitialValue() {
        let timer = AutoExitTimer(duration: 180)
        XCTAssertEqual(timer.remaining, 180)
    }

    func testAutoExitTimerDecrementsOnTick() {
        let timer = AutoExitTimer(duration: 10)
        timer.tick()
        XCTAssertEqual(timer.remaining, 9)
    }

    func testAutoExitTimerReachesZero() {
        let timer = AutoExitTimer(duration: 3)
        timer.tick()
        timer.tick()
        timer.tick()
        XCTAssertEqual(timer.remaining, 0)
    }

    func testAutoExitTimerFiresCallbackAtZero() {
        let timer = AutoExitTimer(duration: 2)
        var fired = false
        timer.onExpired = { fired = true }

        timer.tick()
        XCTAssertFalse(fired)

        timer.tick()
        XCTAssertTrue(fired)
    }

    func testAutoExitTimerCallbackFiredOnce() {
        let timer = AutoExitTimer(duration: 1)
        var fireCount = 0
        timer.onExpired = { fireCount += 1 }

        timer.tick()
        timer.tick()
        timer.tick()
        XCTAssertEqual(fireCount, 1)
    }

    func testAutoExitTimerDoesNotGoNegative() {
        let timer = AutoExitTimer(duration: 1)
        timer.tick()
        timer.tick()
        timer.tick()
        XCTAssertGreaterThanOrEqual(timer.remaining, 0)
    }

    func testAutoExitTimerReset() {
        let timer = AutoExitTimer(duration: 5)
        timer.tick()
        timer.tick()
        XCTAssertEqual(timer.remaining, 3)
        timer.reset()
        XCTAssertEqual(timer.remaining, 5, "reset() must restore remaining to original duration")
    }

    func testAutoExitTimerResetClearsCompletionState() {
        let timer = AutoExitTimer(duration: 1)
        var fireCount = 0
        timer.onExpired = { fireCount += 1 }

        timer.tick()   // fires
        XCTAssertEqual(fireCount, 1)

        timer.reset()
        timer.tick()   // should fire again after reset
        XCTAssertEqual(fireCount, 2, "After reset(), onExpired should fire again when it expires")
    }

    func testAutoExitTimerDefaultDurationIsThreeMinutes() {
        // Verify the app-level constant matches the specified 3-minute auto-exit
        XCTAssertEqual(AutoExitTimer.defaultDuration, 180)
    }
}
