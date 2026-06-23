import SwiftUI

struct TabBarView: View {
    @ObservedObject var moduleRegistry: ModuleRegistry

    var body: some View {
        HStack(spacing: 24) {
            ForEach(0..<moduleRegistry.modules.count, id: \.self) { index in
                let isActive = index == moduleRegistry.activeModuleIndex
                ModuleIcon(module: moduleRegistry.modules[index], isActive: isActive)
                    .onTapGesture {
                        moduleRegistry.setActiveModule(at: index)
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
