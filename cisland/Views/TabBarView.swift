import SwiftUI

struct TabBarView: View {
    @ObservedObject var moduleRegistry: ModuleRegistry

    var body: some View {
        HStack(spacing: 24) {
            ForEach(Array(moduleRegistry.modules.enumerated()), id: \.element.id) { index, module in
                ModuleIcon(module: module, isActive: index == moduleRegistry.activeModuleIndex)
                    .onTapGesture {
                        moduleRegistry.switchToModule(at: index)
                    }
            }

            Spacer()

            Button(action: { /* Open settings */ }) {
                Image(systemName: "gearshape")
                    .foregroundStyle(.white)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }
}