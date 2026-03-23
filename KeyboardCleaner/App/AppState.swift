import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var activationCountdown: Int = 3
    @Published var autoExitRemaining: Int = 180
}
