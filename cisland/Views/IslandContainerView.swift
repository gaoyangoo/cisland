import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    var onHeightChange: ((CGFloat) -> Void)?

    public init(onHeightChange: ((CGFloat) -> Void)? = nil) {
        self.onHeightChange = onHeightChange
    }

    public var body: some View {
        ExpandedIslandView(onHeightChange: onHeightChange)
            .frame(width: 480)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
    }
}
