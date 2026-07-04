import SwiftUI

// MARK: - Module

final class StorageModule: ObservableObject, IslandModule {
    var id: String { "storage" }
    var displayName: String { "Storage" }
    var tabIcon: String { "tray.full" }
    var accentColor: Color { Color(red: 0.2, green: 0.6, blue: 0.9) }
    var expandedHeight: CGFloat { 290 }

    var expandedView: AnyView {
        AnyView(StorageContentView())
    }

    func initialize() {}
}

// MARK: - Combined Content View

struct StorageContentView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var subTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $subTab) {
                    Text("剪贴板").tag(0)
                    Text("Snippets").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 140)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 10)
            .padding(.bottom, 2)

            switch subTab {
            case 0: ClipboardContentView()
            case 1: KeyValueContentView()
            default: EmptyView()
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 280)
        .onReceive(NotificationCenter.default.publisher(for: .storageMoveUp)) { _ in
            if subTab == 0 {
                NotificationCenter.default.post(name: .clipboardMoveUp, object: nil)
            } else {
                NotificationCenter.default.post(name: .snippetMoveUp, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .storageMoveDown)) { _ in
            if subTab == 0 {
                NotificationCenter.default.post(name: .clipboardMoveDown, object: nil)
            } else {
                NotificationCenter.default.post(name: .snippetMoveDown, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .storageEnter)) { _ in
            if subTab == 0 {
                NotificationCenter.default.post(name: .clipboardEnter, object: nil)
            } else {
                NotificationCenter.default.post(name: .snippetEnter, object: nil)
            }
        }
    }
}
