//
//  WindowModule.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//

import SwiftUI

/// Module for managing window functionality
@MainActor
public class WindowModule: IslandModule {
    public let id = "window"
    public let displayName = "Window"
    public let tabIcon = "window"
    public let accentColor = Color.purple
    public let expandedHeight: CGFloat = 250

    public var expandedView: AnyView {
        AnyView(WindowContentView())
    }

    public func initialize() {
        // Initialize window functionality
        print("WindowModule initialized")
    }
}

// Simple placeholder view for window module
private struct WindowContentView: View {
    var body: some View {
        VStack {
            Text("Window Module")
                .font(.title2)
                .padding()

            Text("Manage window settings and behavior")
                .foregroundColor(.secondary)
                .padding()

            VStack(alignment: .leading, spacing: 8) {
                Text("• Window opacity")
                Text("• Always on top")
                Text("• Minimize to dock")
                Text("• Window snapping")
            }
            .padding()
        }
    }
}