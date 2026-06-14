import SwiftUI

/// ViewModifier for creating glass/dark/light background materials
struct IslandBackgroundStyle: ViewModifier {
    let backgroundStyle: IslandBackground

    func body(content: Content) -> some View {
        content
            .background(
                backgroundStyle.material
                    .opacity(0.6)
                    .blur(radius: 20)
            )
            .background(backgroundStyle.baseColor)
    }
}

/// Background style options for the Dynamic Island
enum IslandBackground {
    case glass
    case dark
    case light

    /// Material based background
    var material: Material {
        switch self {
        case .glass:
            return .ultraThinMaterial
        case .dark:
            return .thinMaterial
        case .light:
            return .regularMaterial
        }
    }

    /// Base background color
    var baseColor: Color {
        switch self {
        case .glass:
            return .clear
        case .dark:
            return Color.black.opacity(0.3)
        case .light:
            return Color.white.opacity(0.3)
        }
    }
}

extension View {
    /// Apply Dynamic Island background style
    func islandBackground(_ style: IslandBackground) -> some View {
        self.modifier(IslandBackgroundStyle(backgroundStyle: style))
    }
}