import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    public init() {}

    public var body: some View {
        ExpandedIslandView()
            .frame(width: 504)
            .padding(.horizontal, 8)
            .background(
                IslandShape()
                    .fill(themeManager.theme == .light
                          ? AnyShapeStyle(.regularMaterial)
                          : AnyShapeStyle(Color.black))
            )
            .environment(\.colorScheme, themeManager.colors.colorScheme)
    }
}
