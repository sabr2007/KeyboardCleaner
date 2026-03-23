import Foundation

/// Pure countdown logic for the pre-activation delay shown to the user.
///
/// This type holds no `Timer` itself — `AppDelegate` drives it by calling
/// `tick()` from a 1-second `Timer` closure.  Keeping the logic here makes
/// it straightforward to unit-test without touching the run loop.
final class ActivationCountdownTimer {

    /// The number of seconds remaining until the activation fires.
    private(set) var remaining: Int

    /// Called exactly once, when `remaining` first reaches zero.
    var onComplete: (() -> Void)?

    private var completed = false

    init(startValue: Int) {
        self.remaining = startValue
    }

    /// Advance the countdown by one second.  Calls `onComplete` the first
    /// time `remaining` reaches zero.
    func tick() {
        guard !completed else { return }
        remaining = max(remaining - 1, 0)
        if remaining == 0 {
            completed = true
            onComplete?()
        }
    }
}
