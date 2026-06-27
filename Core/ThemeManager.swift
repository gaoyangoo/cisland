import SwiftUI

// MARK: - Theme Enum

enum AppTheme: String, CaseIterable, Codable {
    case light   // Day
    case dark    // Night

    var displayName: String {
        switch self {
        case .light: return "Day"
        case .dark:  return "Night"
        }
    }

    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark:  return "moon.fill"
        }
    }
}

// MARK: - Semantic Color Palette

struct ThemeColors {
    let text: Color
    let textSecondary: Color
    let textMuted: Color
    let cardBackground: Color
    let cardBackgroundAlt: Color
    let tabBarBackground: Color
    let searchFieldBackground: Color
    let snippetRow: Color
    let snippetRowEditing: Color
    let snippetRowHover: Color
    let emptyIcon: Color
    let emptyText: Color
    let gearForeground: Color
    let colorScheme: ColorScheme

    static let dark = ThemeColors(
        text: .white,
        textSecondary: .white.opacity(0.50),
        textMuted: .white.opacity(0.28),
        cardBackground: .white.opacity(0.08),
        cardBackgroundAlt: .white.opacity(0.10),
        tabBarBackground: .white.opacity(0.06),
        searchFieldBackground: .white.opacity(0.06),
        snippetRow: .white.opacity(0.03),
        snippetRowEditing: .white.opacity(0.06),
        snippetRowHover: Color(red: 0.10, green: 0.50, blue: 0.25).opacity(0.35),
        emptyIcon: .white.opacity(0.12),
        emptyText: .white.opacity(0.25),
        gearForeground: .white.opacity(0.50),
        colorScheme: .dark
    )

    static let light = ThemeColors(
        text: .black.opacity(0.82),
        textSecondary: .black.opacity(0.50),
        textMuted: .black.opacity(0.30),
        cardBackground: .black.opacity(0.05),
        cardBackgroundAlt: .black.opacity(0.08),
        tabBarBackground: .black.opacity(0.07),
        searchFieldBackground: .black.opacity(0.06),
        snippetRow: .black.opacity(0.03),
        snippetRowEditing: .black.opacity(0.06),
        snippetRowHover: Color(red: 0.15, green: 0.55, blue: 0.30).opacity(0.18),
        emptyIcon: .black.opacity(0.12),
        emptyText: .black.opacity(0.30),
        gearForeground: .black.opacity(0.45),
        colorScheme: .light
    )
}

// MARK: - Theme Manager

@MainActor
final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        }
    }

    static let shared = ThemeManager()

    var colors: ThemeColors {
        switch theme {
        case .dark:  return .dark
        case .light: return .light
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "appTheme"),
           let t = AppTheme(rawValue: raw) {
            theme = t
        } else {
            theme = .dark
        }
    }
}
