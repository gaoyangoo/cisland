import SwiftUI

private let cardBg = Color.white.opacity(0.06)
private let cardRadius: CGFloat = 10

// MARK: - Content Height PreferenceKey

/// Reports the ideal content height from SwiftUI to AppKit for window animation.
struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 160
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Main Panel

struct ExpandedIslandView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    var onHeightChange: ((CGFloat) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            mainContent
            bottomTabBar
        }
        .onPreferenceChange(ContentHeightKey.self) { height in
            onHeightChange?(height)
        }
    }

    // MARK: Content

    private var mainContent: some View {
        Group {
            switch registry.activeModule.id {
            case "info":
                InfoDashboardView()
            case "clipboard":
                ClipboardContentView()
            case "keyvalue":
                KeyValueContentView()
            default:
                registry.activeModule.expandedView.padding(12)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ContentHeightKey.self, value: geo.size.height)
            }
        )
    }

    // MARK: Bottom Tab Bar

    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(registry.modules.enumerated()), id: \.offset) { i, m in
                let active = i == registry.activeModuleIndex
                Button(action: { registry.setActiveModule(at: i) }) {
                    VStack(spacing: 1) {
                        Image(systemName: m.tabIcon)
                            .font(.system(size: 10, weight: .regular))
                        Text(m.displayName)
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(active ? m.accentColor : .white.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Info Dashboard

struct InfoDashboardView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            // Music
            VStack(spacing: 4) {
                Image(systemName: "music.note").font(.system(size: 10)).foregroundColor(.pink)
                Text("Music").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)).frame(width: 30, height: 30)
                    .overlay(Image(systemName: "music.note.list").font(.caption2).foregroundColor(.white.opacity(0.3)))
                Text("Not Playing").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
            }
            .padding(8).frame(maxWidth: .infinity, maxHeight: .infinity).background(cardBg).cornerRadius(cardRadius)

            // Calendar
            VStack(spacing: 4) {
                Image(systemName: "calendar").font(.system(size: 10)).foregroundColor(.blue)
                Text("Calendar").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                VStack(spacing: 4) {
                    ForEach(["Team Meeting", "Lunch", "Review"], id: \.self) { e in
                        HStack(spacing: 4) {
                            Circle().fill(.blue).frame(width: 4, height: 4)
                            Text(e).font(.system(size: 9)).foregroundColor(.white).lineLimit(1)
                            Spacer()
                        }
                    }
                }
                Spacer()
            }
            .padding(8).frame(maxWidth: .infinity, maxHeight: .infinity).background(cardBg).cornerRadius(cardRadius)

            // Weather
            VStack(spacing: 4) {
                Image(systemName: "cloud.sun.fill").font(.system(size: 10)).foregroundColor(.orange)
                Text("Weather").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                Image(systemName: "sun.max.fill").font(.system(size: 22)).foregroundColor(.yellow)
                Text("24.5°C").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Spacer()
            }
            .padding(8).frame(maxWidth: .infinity, maxHeight: .infinity).background(cardBg).cornerRadius(cardRadius)
        }
        .padding(8)
        .frame(height: 120)
    }
}

// MARK: - Clipboard Content

struct ClipboardContentView: View {
    @StateObject private var svc = ClipboardService()

    var body: some View {
        if svc.items.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "clipboard").font(.system(size: 24)).foregroundColor(.white.opacity(0.2))
                Text("Clipboard is empty").font(.system(size: 13)).foregroundColor(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(svc.items.prefix(30), id: \.id) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.isText ? "doc.text" : "photo")
                                .font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                            if case .text(let t) = item.content {
                                Text(t).font(.system(size: 11)).foregroundColor(.white.opacity(0.8)).lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(Color.white.opacity(0.04)).cornerRadius(6)
                    }
                }
                .padding(8)
            }
        }
    }
}
