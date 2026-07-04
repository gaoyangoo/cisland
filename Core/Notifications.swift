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

    /// Clipboard list — move selection up
    static let clipboardMoveUp = Notification.Name("clipboardMoveUp")

    /// Clipboard list — move selection down
    static let clipboardMoveDown = Notification.Name("clipboardMoveDown")

    /// Snippet list — move selection up
    static let snippetMoveUp = Notification.Name("snippetMoveUp")

    /// Snippet list — move selection down
    static let snippetMoveDown = Notification.Name("snippetMoveDown")

    /// Clipboard — Enter key pressed on selected item
    static let clipboardEnter = Notification.Name("clipboardEnter")

    /// Snippet — Enter key pressed on selected item
    static let snippetEnter = Notification.Name("snippetEnter")

    /// Storage (combined) — move selection up
    static let storageMoveUp = Notification.Name("storageMoveUp")

    /// Storage (combined) — move selection down
    static let storageMoveDown = Notification.Name("storageMoveDown")

    /// Storage (combined) — Enter key pressed
    static let storageEnter = Notification.Name("storageEnter")

    /// Focus the search field in the active view
    static let focusSearch = Notification.Name("focusSearch")

    /// Request the floating panel to close
    static let togglePanel = Notification.Name("togglePanel")
}