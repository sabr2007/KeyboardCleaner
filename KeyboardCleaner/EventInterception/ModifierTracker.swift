import Foundation
import Combine

final class ModifierTracker: ObservableObject {

    @Published var countdownRemaining: Double = 0
    @Published var isCountingDown: Bool = false

    // NX event flag bits from <IOKit/hidsystem/IOLLEvent.h>
    private static let leftCommandBit: UInt64 = 0x00000008   // NX_DEVICELCMDKEYMASK
    private static let rightCommandBit: UInt64 = 0x00000010  // NX_DEVICERCMDKEYMASK
    static let exitHoldDuration: Double = 3.0
    private static let timerInterval: Double = 0.1

    var onExitTriggered: (() -> Void)?

    private var holdStartDate: Date?
    private var countdownTimer: Timer?
    private var leftCommandDown = false
    private var rightCommandDown = false

    func updateFlags(_ rawFlags: UInt64) {
        let leftDown = (rawFlags & Self.leftCommandBit) != 0
        let rightDown = (rawFlags & Self.rightCommandBit) != 0

        leftCommandDown = leftDown
        rightCommandDown = rightDown

        if leftDown && rightDown {
            startCountdownIfNeeded()
        } else {
            resetCountdown()
        }
    }

    private func startCountdownIfNeeded() {
        guard holdStartDate == nil else { return }
        holdStartDate = Date()
        isCountingDown = true
        countdownRemaining = Self.exitHoldDuration

        let timer = Timer(timeInterval: Self.timerInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }

    private func tick() {
        guard let start = holdStartDate else {
            resetCountdown()
            return
        }

        let elapsed = Date().timeIntervalSince(start)
        let remaining = max(Self.exitHoldDuration - elapsed, 0)
        countdownRemaining = remaining

        if remaining <= 0 {
            let callback = onExitTriggered
            resetCountdown()
            callback?()
        }
    }

    func resetCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        holdStartDate = nil
        isCountingDown = false
        countdownRemaining = 0
    }
}
