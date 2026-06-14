//
//  Hotkey.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//

import Cocoa

/// Global hotkey management
class Hotkey {
    private let key: KeyCode
    private let modifiers: NSEvent.ModifierFlags
    private let callback: () -> Void
    private var hotkeyRef: EventHotKeyRef?

    init(key: KeyCode, modifiers: NSEvent.ModifierFlags, callback: @escaping () -> Void) {
        self.key = key
        self.modifiers = modifiers
        self.callback = callback
    }

    func register() {
        var eventType = EventTypeSpec()
        eventType.eventClass = EventClassKeyboard
        eventType.eventKind = EventKindHotKey

        var carbonHotkey = EventHotKeyID()
        carbonHotkey.signature = "clsi"
        carbonHotkey.id = 0

        var hotkeyRef: EventHotKeyRef?
        let error = RegisterEventHotKey(
            UInt32(key.rawValue),
            modifiers.rawValue,
            carbonHotkey,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if error == noErr {
            self.hotkeyRef = hotkeyRef
        }
    }

    func unregister() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
    }
}

enum KeyCode: UInt32 {
    case a = 0x00, b = 0x02, c = 0x08, d = 0x0D, e = 0x0E, f = 0x0F
    case g = 0x10, h = 0x11, i = 0x12, j = 0x13, k = 0x14, l = 0x15
    case m = 0x16, n = 0x17, o = 0x1D, p = 0x1E, q = 0x1F, r = 0x20
    case s = 0x1B, t = 0x1C, u = 0x1F, v = 0x21, w = 0x22, x = 0x23
    case y = 0x24, z = 0x25
    case number0 = 0x29, number1 = 0x1E, number2 = 0x1F, number3 = 0x20
    case number4 = 0x21, number5 = 0x22, number6 = 0x23, number7 = 0x24
    case number8 = 0x25, number9 = 0x26
    case returnKey = 0x24, tab = 0x30, space = 0x31, delete = 0x33
    case escape = 0x35, command = 0x37, shift = 0x38, capsLock = 0x39
    case option = 0x3A, control = 0x3B, rightShift = 0x3C, rightCommand = 0x3D
    case rightOption = 0x3E, rightControl = 0x3F, function = 0x3F
}