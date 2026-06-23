import Carbon
import Cocoa

/// A system-wide global hotkey using Carbon RegisterEventHotKey.
/// No Accessibility permission required — the OS reserves the key combo.
final class Hotkey {
    private let keyCode: UInt16
    private let modifiers: NSEvent.ModifierFlags
    private let callback: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID: EventHotKeyID

    // Shared across all Hotkey instances — only one Carbon event handler needed per process
    private static var installedHandlerRef: EventHandlerRef?
    private static var activeHotkeys: [UInt32: Hotkey] = [:]
    private static let signature = OSType(0x434C_5553) // "CLUS"

    init(key: KeyCode, modifiers: NSEvent.ModifierFlags, callback: @escaping () -> Void) {
        self.keyCode = key.rawValue
        self.modifiers = modifiers
        self.callback = callback

        var id = EventHotKeyID()
        id.signature = Self.signature
        id.id = UInt32(Self.activeHotkeys.count + 1)
        self.hotKeyID = id
    }

    func register() {
        // Install the shared Carbon event handler on first use
        if Self.installedHandlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            // Must use a non-optional local variable for the out-pointer
            var handlerRef: EventHandlerRef?
            let status = InstallEventHandler(
                GetApplicationEventTarget(),
                hotkeyEventHandler,
                1,
                &eventType,
                nil, // userData — we use the static dictionary instead
                &handlerRef
            )
            if status == noErr {
                Self.installedHandlerRef = handlerRef
            } else {
                print("[Hotkey] InstallEventHandler failed: \(status)")
                return
            }
        }

        // Convert NSEvent.ModifierFlags → Carbon modifiers
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if modifiers.contains(.shift)   { carbonModifiers |= UInt32(shiftKey) }
        if modifiers.contains(.option)  { carbonModifiers |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr {
            hotKeyRef = ref
            Self.activeHotkeys[hotKeyID.id] = self
        } else if status == -9875 {
            print("[Hotkey] RegisterEventHotKey: hotkey already registered by another app " +
                  "(key=\(keyCode), mods=\(carbonModifiers))")
        } else {
            print("[Hotkey] RegisterEventHotKey failed: \(status) " +
                  "(key=\(keyCode), mods=\(carbonModifiers))")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        Self.activeHotkeys.removeValue(forKey: hotKeyID.id)

        // Tear down the shared handler when no hotkeys remain
        if Self.activeHotkeys.isEmpty, let handler = Self.installedHandlerRef {
            RemoveEventHandler(handler)
            Self.installedHandlerRef = nil
        }
    }
}

// MARK: - Carbon Event Handler Callback

/// C function pointer that Carbon can call. Looks up the Hotkey instance and fires its callback.
private func hotkeyEventHandler(
    _ handler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    let err = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard err == noErr else { return err }

    if let hotkey = Hotkey.lookup(hotKeyID.id) {
        hotkey.invokeCallback()
    }
    return noErr
}

// Expose internals to the fileprivate handler
extension Hotkey {
    fileprivate static func lookup(_ id: UInt32) -> Hotkey? {
        return activeHotkeys[id]
    }

    fileprivate func invokeCallback() {
        DispatchQueue.main.async { [weak self] in
            self?.callback()
        }
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
