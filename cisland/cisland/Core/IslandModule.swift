//
//  IslandModule.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//

import SwiftUI

/// Protocol defining the contract for all island modules
@MainActor
public protocol IslandModule: Identifiable, ObservableObject {
    /// Unique identifier for the module
    var id: String { get }

    /// Display name shown in the UI
    var displayName: String { get }

    /// Icon for the module tab
    var tabIcon: Image { get }

    /// Accent color for the module
    var accentColor: Color { get }

    /// Expanded height of the module when active
    var expandedHeight: CGFloat { get }

    /// View to display when the module is expanded
    var expandedView: AnyView { get }

    /// Initialize the module (called when becoming active)
    func initialize()
}