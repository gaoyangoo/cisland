import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    public init() {}

    public var body: some View {
        ExpandedIslandView()
            .frame(width: 640)
            .padding(.horizontal, 14)
            .background(
                IslandShape()
                    .fill(themeManager.theme == .light
                          ? AnyShapeStyle(Color(white: 0.94))
                          : AnyShapeStyle(Color(white: 0.08)))
            )
            .environment(\.colorScheme, themeManager.colors.colorScheme)
    }
}
