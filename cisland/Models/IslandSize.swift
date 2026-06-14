//
//  IslandSize.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//

import Foundation

/// Represents different island sizes and their associated heights
public enum IslandSize: Int, CaseIterable, Hashable {
    case small
    case medium
    case large

    /// Standard height constants for each island size
    public static let smallHeight: CGFloat = 120
    public static let mediumHeight: CGFloat = 160
    public static let largeHeight: CGFloat = 200

    /// Returns the height for the current size
    public var height: CGFloat {
        switch self {
        case .small:
            return Self.smallHeight
        case .medium:
            return Self.mediumHeight
        case .large:
            return Self.largeHeight
        }
    }

    /// Returns the expanded height for the current size
    public var expandedHeight: CGFloat {
        switch self {
        case .small:
            return Self.mediumHeight
        case .medium:
            return Self.largeHeight
        case .large:
            return Self.largeHeight * 1.2
        }
    }

    /// Returns the compact height for the current size
    public var compactHeight: CGFloat {
        switch self {
        case .small:
            return 60
        case .medium:
            return 80
        case .large:
            return 100
        }
    }
}