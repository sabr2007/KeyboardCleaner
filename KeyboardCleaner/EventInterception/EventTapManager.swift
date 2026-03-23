import Cocoa

final class EventTapManager {

    var onFlagsChanged: ((UInt64) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var watchdogTimer: Timer?
    private var retainedSelf: Unmanaged<EventTapManager>?

    // Named constants for event types not in CGEventType enum
    private enum EventTypeBit {
        static let nxSystemDefined = 14  // NX_SYSDEFINED — media keys
        static let rotate          = 18  // NSEvent.EventType.rotate
        static let beginGesture    = 19  // NSEvent.EventType.beginGesture
        static let endGesture      = 20  // NSEvent.EventType.endGesture
        static let smartMagnify    = 22  // NSEvent.EventType.smartMagnify (double-tap)
        static let gesture         = 29  // NSEvent.EventType.gesture
        static let magnify         = 30  // NSEvent.EventType.magnify
        static let swipe           = 31  // NSEvent.EventType.swipe
    }

    func start() -> Bool {
        var eventMask: CGEventMask = 0
        eventMask |= (1 << CGEventType.keyDown.rawValue)
        eventMask |= (1 << CGEventType.keyUp.rawValue)
        eventMask |= (1 << CGEventType.flagsChanged.rawValue)
        eventMask |= (1 << CGEventType.scrollWheel.rawValue)
        eventMask |= (1 << CGEventType.leftMouseDown.rawValue)
        eventMask |= (1 << CGEventType.leftMouseUp.rawValue)
        eventMask |= (1 << CGEventType.rightMouseDown.rawValue)
        eventMask |= (1 << CGEventType.rightMouseUp.rawValue)
        eventMask |= (1 << CGEventType.otherMouseDown.rawValue)
        eventMask |= (1 << CGEventType.otherMouseUp.rawValue)
        eventMask |= (1 << CGEventType.mouseMoved.rawValue)
        eventMask |= (1 << CGEventType.leftMouseDragged.rawValue)
        eventMask |= (1 << CGEventType.rightMouseDragged.rawValue)
        eventMask |= (1 << CGEventType.otherMouseDragged.rawValue)
        eventMask |= (1 << CGEventType.tabletPointer.rawValue)
        eventMask |= (1 << CGEventType.tabletProximity.rawValue)
        eventMask |= (1 << EventTypeBit.nxSystemDefined)
        eventMask |= (1 << EventTypeBit.gesture)
        eventMask |= (1 << EventTypeBit.magnify)
        eventMask |= (1 << EventTypeBit.swipe)
        eventMask |= (1 << EventTypeBit.rotate)
        eventMask |= (1 << EventTypeBit.beginGesture)
        eventMask |= (1 << EventTypeBit.endGesture)
        eventMask |= (1 << EventTypeBit.smartMagnify)

        // Retain self for the C callback's lifetime — balanced in stop()
        let retained = Unmanaged.passRetained(self)
        let userInfo = retained.toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: userInfo
        ) else {
            retained.release()
            return false
        }

        retainedSelf = retained
        eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // Freeze cursor — CGEvent tap alone doesn't prevent cursor movement
        CGAssociateMouseAndMouseCursorPosition(0)

        startWatchdog()
        return true
    }

    func stop() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil

        // Unfreeze cursor
        CGAssociateMouseAndMouseCursorPosition(1)

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil

        // Balance the passRetained from start()
        retainedSelf?.release()
        retainedSelf = nil
    }

    private func startWatchdog() {
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.reenableTapIfNeeded()
        }
        RunLoop.main.add(timer, forMode: .common)
        watchdogTimer = timer
    }

    private func reenableTapIfNeeded() {
        guard let tap = eventTap else { return }
        if !CGEvent.tapIsEnabled(tap: tap) {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    guard type != .tapDisabledByTimeout, type != .tapDisabledByUserInput else {
        return Unmanaged.passUnretained(event)
    }

    guard let userInfo = userInfo else {
        return nil
    }

    let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .flagsChanged {
        let rawFlags = event.flags.rawValue
        manager.onFlagsChanged?(rawFlags)
    }

    // Suppress all events
    return nil
}
