import SwiftUI

struct ModuleIcon: View {
    let module: any IslandModule
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: module.tabIcon)
                .font(.title2)
                .foregroundColor(isActive ? module.accentColor : .white.opacity(0.6))
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)

            if isActive {
                Capsule()
                    .fill(module.accentColor)
                    .frame(height: 3)
            }
        }
        .padding(.vertical, 8)
    }
}