import SwiftUI

private let cardBg = Color.white.opacity(0.06)
private let cardRadius: CGFloat = 12

// MARK: - Main Panel

struct ExpandedIslandView: View {
    @ObservedObject private var registry = ModuleRegistry.shared

    var body: some View {
        VStack(spacing: 0) {
            mainContent
            bottomTabBar
        }
    }

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
    }

    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(registry.modules.enumerated()), id: \.offset) { i, m in
                let active = i == registry.activeModuleIndex
                Button(action: { registry.setActiveModule(at: i) }) {
                    VStack(spacing: 2) {
                        Image(systemName: m.tabIcon)
                            .font(.system(size: 12, weight: .regular))
                        Text(m.displayName)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(active ? m.accentColor : .white.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .padding(.top, 2)
    }
}

// MARK: - Info Dashboard (static test)

struct InfoDashboardView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Music
            VStack(spacing: 6) {
                Image(systemName: "music.note").font(.system(size: 11)).foregroundColor(.pink)
                Text("Music").font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)).frame(width: 36, height: 36)
                    .overlay(Image(systemName: "music.note.list").font(.caption).foregroundColor(.white.opacity(0.3)))
                Text("Not Playing").font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                Text("Unknown Artist").font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
            }
            .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity).background(cardBg).cornerRadius(cardRadius)

            // Calendar
            VStack(spacing: 6) {
                Image(systemName: "calendar").font(.system(size: 11)).foregroundColor(.blue)
                Text("Calendar").font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                VStack(spacing: 5) {
                    ForEach(["Team Meeting", "Lunch", "Review"], id: \.self) { e in
                        HStack(spacing: 5) {
                            Circle().fill(.blue).frame(width: 5, height: 5)
                            Text(e).font(.system(size: 10)).foregroundColor(.white).lineLimit(1)
                            Spacer()
                        }
                    }
                }
                Spacer()
            }
            .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity).background(cardBg).cornerRadius(cardRadius)

            // Weather
            VStack(spacing: 6) {
                Image(systemName: "cloud.sun.fill").font(.system(size: 11)).foregroundColor(.orange)
                Text("Weather").font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                Image(systemName: "sun.max.fill").font(.system(size: 26)).foregroundColor(.yellow)
                Text("24.5°C").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                Text("Beijing").font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                Spacer()
            }
            .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity).background(cardBg).cornerRadius(cardRadius)
        }
        .padding(10)
        .frame(height: 150)
    }
}

// MARK: - Clipboard Content (static test)

struct ClipboardContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard").font(.system(size: 24)).foregroundColor(.white.opacity(0.2))
            Text("Clipboard is empty").font(.system(size: 13)).foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
