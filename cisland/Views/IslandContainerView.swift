import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared

    public init() {}

    public var body: some View {
        ExpandedIslandView()
            .frame(width: 480)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
    }
}
