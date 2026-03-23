import Foundation

/// Pure countdown logic for the automatic-exit safety timer.
///
/// `AppDelegate` drives this by calling `tick()` from a 1-second `Timer`
/// closure.  The separation makes the logic unit-testable without a live
/// run loop.
final class AutoExitTimer {

    /// The default auto-exit duration used by the app (3 minutes).
    static let defaultDuration: Int = 180

    /// Seconds remaining before the timer expires.
    private(set) var remaining: Int

    /// The duration this timer was initialised with; used by `reset()`.
    private let duration: Int

    /// Called exactly once per countdown cycle when `remaining` reaches zero.
    var onExpired: (() -> Void)?

    private var expired = false

    init(duration: Int) {
        self.duration = duration
        self.remaining = duration
    }

    /// Advance the timer by one second.  Calls `onExpired` the first time
    /// `remaining` reaches zero.
    func tick() {
        guard !expired else { return }
        remaining = max(remaining - 1, 0)
        if remaining == 0 {
            expired = true
            onExpired?()
        }
    }

    /// Restart the countdown from the original duration.
    func reset() {
        remaining = duration
        expired = false
    }
}
