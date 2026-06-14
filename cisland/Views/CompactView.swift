import SwiftUI

/// Simplified compact view showing module icon and activity
@MainActor
public struct CompactView: View {
    private let module: any IslandModule
    private let isActive: Bool

    /// Initialize with a specific module and activity state
    /// - Parameters:
    ///   - module: The module to display
    ///   - isActive: Whether this module is currently active
    public init(module: any IslandModule, isActive: Bool = true) {
        self.module = module
        self.isActive = isActive
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Module icon
            Image(systemName: module.tabIcon)
                .font(.title2)
                .foregroundStyle(module.accentColor)
                .frame(width: 24, height: 24)
                .scaleEffect(isActive ? 1.0 : 0.9)
                .animation(.easeInOut(duration: 0.3), value: isActive)

            // Activity indicators for active modules
            if isActive {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 2, height: 2)
                            .opacity(index == 0 ? 1.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isActive
                            )
                    }
                }
            }

            Spacer()

            // Module label (if space allows)
            if isActive {
                Text(module.title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.3), value: isActive)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
        .opacity(isActive ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// MARK: - Previews
struct CompactView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                CompactView(module: MockModule(title: "Music", icon: "music.note"))
                CompactView(module: MockModule(title: "Timer", icon: "timer"), isActive: false)
            }
            .padding()

            Spacer()
        }
        .background(Color.black)
    }
}

// MARK: - Mock Module for Preview
private class MockModule: ObservableObject, IslandModule {
    let title: String
    let icon: String

    init(title: String, icon: String) {
        self.title = title
        self.icon = icon
    }

    var id: String { title }
    var displayName: String { title }
    var tabIcon: String { icon }
    var accentColor: Color { .white }
    var expandedHeight: CGFloat { 240 }
    var expandedView: AnyView { AnyView(Text("Mock expanded content for \(title)")) }

    func initialize() {}
}