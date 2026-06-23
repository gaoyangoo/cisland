import Cocoa

final class Hotkey {
    private let key: KeyCode
    private let modifiers: NSEvent.ModifierFlags
    private let callback: () -> Void
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(key: KeyCode, modifiers: NSEvent.ModifierFlags, callback: @escaping () -> Void) {
        self.key = key
        self.modifiers = modifiers
        self.callback = callback
    }

    func register() {
        // Global monitor: works when ANY app is frontmost (needs Accessibility permission)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
        }

        // Local monitor: works when cisland itself is frontmost (no permission needed)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
            return event
        }

        // Hotkey registered
    }

    private func handleEvent(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == modifiers, event.keyCode == key.rawValue {
            callback()
        }
    }

    func unregister() {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        localMonitor = nil
    }
}

enum KeyCode: UInt16 {
    case a = 0x00, b = 0x0B, c = 0x08, d = 0x02, e = 0x0E, f = 0x03
    case g = 0x05, h = 0x04, i = 0x22, j = 0x26, k = 0x28, l = 0x25
    case m = 0x2E, n = 0x2D, o = 0x1F, p = 0x23, q = 0x0C, r = 0x0F
    case s = 0x01, t = 0x11, u = 0x20, v = 0x09, w = 0x0D, x = 0x07
    case y = 0x10, z = 0x06
    case number0 = 0x29, number1 = 0x12, number2 = 0x13, number3 = 0x14
    case number4 = 0x15, number5 = 0x17, number6 = 0x16, number7 = 0x1A
    case number8 = 0x1C, number9 = 0x19
    case space = 0x31, `return` = 0x24, tab = 0x30, escape = 0x35
    case delete = 0x33, leftArrow = 0x7B, rightArrow = 0x7C
    case downArrow = 0x7D, upArrow = 0x7E
}
