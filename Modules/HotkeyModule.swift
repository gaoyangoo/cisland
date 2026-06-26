//
//  HotkeyModule.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//

import SwiftUI

/// Module for managing global hotkeys
@MainActor
public class HotkeyModule: IslandModule {
    public let id = "hotkey"
    public let displayName = "Hotkeys"
    public let tabIcon = "keyboard"
    public let accentColor = Color.green
    public let expandedHeight: CGFloat = 300

    public var expandedView: AnyView {
        AnyView(HotkeyContentView())
    }

    public func initialize() {
        // Initialize hotkey functionality
        print("HotkeyModule initialized")
    }
}


// Simple placeholder view for hotkey module
private struct HotkeyContentView: View {
    var body: some View {
        VStack {
            Text("Hotkey Module")
                .font(.title2)
                .padding()

            Text("Manage global hotkeys")
                .foregroundColor(.secondary)
                .padding()

            VStack(alignment: .leading, spacing: 10) {
                Text("⌘⇧O - Toggle Main Window")
                    .padding(.leading)

                Text("⌘⇧C - Copy to Clipboard")
                    .padding(.leading)

                Text("⌘⇧V - Paste from Clipboard")
                    .padding(.leading)
            }
            .padding()
        }
    }
}