//
//  Hotkey.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//

import Cocoa

/// Global hotkey management - simplified for modern macOS
class Hotkey {
    private let key: KeyCode
    private let modifiers: NSEvent.ModifierFlags
    private let callback: () -> Void

    init(key: KeyCode, modifiers: NSEvent.ModifierFlags, callback: @escaping () -> Void) {
        self.key = key
        self.modifiers = modifiers
        self.callback = callback
    }

    func register() {
        // Simplified hotkey registration for modern macOS
        // Note: Carbon API is deprecated - this is a placeholder
        print("Registering hotkey: \(key) with modifiers: \(modifiers)")
        // In a real implementation, use NSEvent.addGlobalMonitorForEvents
    }

    func unregister() {
        // Clean up hotkey registration
        print("Unregistering hotkey")
    }
}

enum KeyCode: UInt32 {
    case a = 0x00, b = 0x02, c = 0x08, d = 0x0D, e = 0x0E, f = 0x0F
    case g = 0x10, h = 0x11, i = 0x12, j = 0x13, k = 0x14, l = 0x15
    case m = 0x16, n = 0x17, o = 0x1D, p = 0x1E, q = 0x1F, r = 0x20
    case s = 0x1B, t = 0x1C, u = 0x25, v = 0x21, w = 0x22, x = 0x23
    case y = 0x24, z = 0x26
    case number0 = 0x29, number1 = 0x50, number2 = 0x51, number3 = 0x52
    case number4 = 0x27, number5 = 0x28, number6 = 0x2A, number7 = 0x2B
    case number8 = 0x2C, number9 = 0x2D
    case returnKey = 0x35, tab = 0x30, space = 0x31, delete = 0x33
    case escape = 0x60, command = 0x37, shift = 0x38, capsLock = 0x39
    case option = 0x3A, control = 0x3B, rightShift = 0x3C, rightCommand = 0x3D
    case rightOption = 0x3E, rightControl = 0x3F, function = 0x40
}