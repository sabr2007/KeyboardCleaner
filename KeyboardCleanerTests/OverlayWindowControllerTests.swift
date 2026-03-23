import XCTest
import Cocoa
@testable import KeyboardCleaner

final class OverlayWindowControllerTests: XCTestCase {

    // Use the first available screen; skip the test if no screen is present
    // (possible in headless CI without a virtual display).
    private func requireScreen() throws -> NSScreen {
        guard let s = NSScreen.screens.first else {
            throw XCTSkip("No screen available in this environment")
        }
        return s
    }

    private func makeController() throws -> OverlayWindowController {
        let s = try requireScreen()
        let contentView = NSView()
        return OverlayWindowController(screen: s, contentView: contentView)
    }

    // MARK: - Initialisation

    func testControllerCanBeInstantiated() throws {
        let controller = try makeController()
        XCTAssertNotNil(controller.window, "Controller must have a non-nil window after init")
    }

    // MARK: - Window Frame

    func testWindowFrameMatchesScreenFrame() throws {
        let s = try requireScreen()
        let controller = try makeController()
        XCTAssertEqual(controller.window?.frame, s.frame,
                       "Window frame must exactly match the screen frame")
    }

    // MARK: - Window Style Mask

    func testWindowStyleMaskIsBorderless() throws {
        let controller = try makeController()
        let mask = controller.window?.styleMask ?? []
        XCTAssertTrue(mask.contains(.borderless),
                      "Window must be borderless (no title bar, no resize handles)")
        XCTAssertFalse(mask.contains(.titled),
                       "Overlay window must not have a title bar")
    }

    // MARK: - Window Level

    func testWindowLevelIsScreenSaverLevel() throws {
        let controller = try makeController()
        let expected = NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)))
        XCTAssertEqual(controller.window?.level, expected,
                       "Window must be at screen-saver level to appear above all app content")
    }

    // MARK: - Transparency

    func testWindowIsTransparent() throws {
        let controller = try makeController()
        XCTAssertFalse(controller.window?.isOpaque ?? true,
                       "Window must be non-opaque to allow transparent background")
        XCTAssertEqual(controller.window?.backgroundColor, .clear,
                       "Window background must be clear")
    }

    func testWindowHasNoShadow() throws {
        let controller = try makeController()
        XCTAssertFalse(controller.window?.hasShadow ?? true,
                       "Overlay window must not cast a drop shadow")
    }

    // MARK: - Mouse Event Handling

    func testWindowAcceptsMouseEvents() throws {
        let controller = try makeController()
        XCTAssertFalse(controller.window?.ignoresMouseEvents ?? true,
                       "Overlay must capture mouse events to block them during cleaning")
    }

    // MARK: - Collection Behaviour

    func testWindowCanJoinAllSpaces() throws {
        let controller = try makeController()
        let behaviour = controller.window?.collectionBehavior ?? []
        XCTAssertTrue(behaviour.contains(.canJoinAllSpaces),
                      "Overlay must appear on every Space")
    }

    func testWindowIsFullScreenAuxiliary() throws {
        let controller = try makeController()
        let behaviour = controller.window?.collectionBehavior ?? []
        XCTAssertTrue(behaviour.contains(.fullScreenAuxiliary),
                      "Overlay must remain visible in full-screen apps")
    }

    func testWindowIsStationary() throws {
        let controller = try makeController()
        let behaviour = controller.window?.collectionBehavior ?? []
        XCTAssertTrue(behaviour.contains(.stationary),
                      "Overlay must be stationary (does not move with Exposé)")
    }

    func testWindowIgnoresCycling() throws {
        let controller = try makeController()
        let behaviour = controller.window?.collectionBehavior ?? []
        XCTAssertTrue(behaviour.contains(.ignoresCycle),
                      "Overlay must be excluded from the window-cycling shortcut")
    }

    // MARK: - Content View

    func testWindowContentViewIsSet() throws {
        let s = try requireScreen()
        let customView = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        let controller = OverlayWindowController(screen: s, contentView: customView)
        XCTAssertEqual(controller.window?.contentView, customView,
                       "The provided content view must be installed as the window's contentView")
    }

    // MARK: - Show / Hide

    func testShowDoesNotCrash() throws {
        let controller = try makeController()
        controller.show()
        controller.hide()
    }

    func testHideWithoutShowDoesNotCrash() throws {
        let controller = try makeController()
        controller.hide()
    }

    func testShowTwiceDoesNotCrash() throws {
        let controller = try makeController()
        controller.show()
        controller.show()
        controller.hide()
    }

    func testHideTwiceDoesNotCrash() throws {
        let controller = try makeController()
        controller.show()
        controller.hide()
        controller.hide()
    }
}
