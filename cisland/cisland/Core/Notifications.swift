//
//  Notifications.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//

import Foundation

/// Notification names used throughout the island system
public extension Notification.Name {
    /// Notification when a module becomes active
    static let moduleActivated = Notification.Name("moduleActivated")

    /// Notification when a module becomes inactive
    static let moduleDeactivated = Notification.Name("moduleDeactivated")

    /// Notification when the island size changes
    static let islandSizeChanged = Notification.Name("islandSizeChanged")

    /// Notification when a module content updates
    static let moduleContentUpdated = Notification.Name("moduleContentUpdated")
}