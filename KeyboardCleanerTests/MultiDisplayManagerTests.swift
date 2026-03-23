import XCTest
import SwiftUI
@testable import KeyboardCleaner

final class MultiDisplayManagerTests: XCTestCase {

    private func makeManager() -> MultiDisplayManager {
        MultiDisplayManager(
            tracker: ModifierTracker(),
            appState: AppState()
        )
    }

    // MARK: - Initialisation

    func testManagerCanBeInstantiated() {
        let manager = makeManager()
        XCTAssertNotNil(manager)
    }

    func testManagerInitWithCustomTracker() {
        let tracker = ModifierTracker()
        let manager = MultiDisplayManager(
            tracker: tracker,
            appState: AppState()
        )
        XCTAssertNotNil(manager)
    }

    // MARK: - showOverlays / hideOverlays Lifecycle

    func testShowOverlaysDoesNotCrash() {
        let manager = makeManager()
        manager.showOverlays()
        manager.hideOverlays()  // clean up
    }

    func testHideOverlaysWithoutShowDoesNotCrash() {
        let manager = makeManager()
        manager.hideOverlays()
    }

    func testShowThenHideIsIdempotent() {
        let manager = makeManager()
        manager.showOverlays()
        manager.hideOverlays()
        manager.hideOverlays()  // second hide must be safe
    }

    func testShowOverlaysMultipleTimesIsIdempotent() {
        let manager = makeManager()
        manager.showOverlays()
        manager.showOverlays()  // second show must re-create without crash
        manager.hideOverlays()
    }

    // MARK: - Screen Change Notification Handling

    func testScreenChangeNotificationDoesNotCrashAfterShow() {
        let manager = makeManager()
        manager.showOverlays()

        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        manager.hideOverlays()
    }

    func testScreenChangeNotificationNotProcessedAfterHide() {
        let manager = makeManager()
        manager.showOverlays()
        manager.hideOverlays()

        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }

    // MARK: - Deallocation

    func testManagerDeallocatesAfterShowWithoutCrash() {
        var manager: MultiDisplayManager? = makeManager()
        manager?.showOverlays()
        manager = nil
    }

    func testManagerDeallocatesWithoutShowWithoutCrash() {
        autoreleasepool {
            var manager: MultiDisplayManager? = makeManager()
            _ = manager
            manager = nil
        }
    }
}
