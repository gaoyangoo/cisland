import SwiftUI

struct ExpandedIslandView: View {
    @ObservedObject var moduleRegistry: ModuleRegistry

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(moduleRegistry: moduleRegistry)
                .frame(height: 44)
                .padding(.horizontal, 20)

            Divider()
                .background(Color.white.opacity(0.1))

            moduleRegistry.activeModule?.expandedView
                .frame(maxHeight: .infinity)
        }
    }
}