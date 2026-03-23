import SwiftUI

struct OverlayContentView: View {

    @ObservedObject var tracker: ModifierTracker
    @ObservedObject var appState: AppState

    var body: some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            if appState.activationCountdown > 0 {
                activationView
            } else {
                cleaningView
            }
        }
    }

    private var activationView: some View {
        VStack(spacing: 24) {
            Text("🧹")
                .font(.system(size: 64))
            Text("Locking input in...")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
            Text("\(appState.activationCountdown)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var cleaningView: some View {
        VStack(spacing: 32) {
            Text("🧹")
                .font(.system(size: 72))

            Text("Keyboard Cleaner Active")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)

            Text("Your keyboard and trackpad are locked.\nClean away!")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            autoExitView

            Spacer().frame(height: 24)

            exitInstructionView

            if tracker.isCountingDown {
                countdownView
            }
        }
    }

    private var autoExitView: some View {
        let minutes = appState.autoExitRemaining / 60
        let seconds = appState.autoExitRemaining % 60
        return Text(String(format: "Auto-exit in %d:%02d", minutes, seconds))
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.5))
    }

    private var exitInstructionView: some View {
        VStack(spacing: 8) {
            Text("To exit, hold both ⌘ Command keys for 3 seconds")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 16) {
                keyBadge("Left ⌘")
                Text("+")
                    .foregroundColor(.white.opacity(0.4))
                keyBadge("Right ⌘")
            }
        }
    }

    private func keyBadge(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
    }

    private var countdownView: some View {
        VStack(spacing: 16) {
            let remaining = Int(ceil(tracker.countdownRemaining))
            let progress = 1.0 - (tracker.countdownRemaining / ModifierTracker.exitHoldDuration)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)

                Text("\(remaining)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }

            Text("Releasing will cancel...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 16)
    }
}
