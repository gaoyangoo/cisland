import SwiftUI

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
    @Namespace private var tabNamespace
    var onHeightChange: ((CGFloat) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            mainContent
                .id(registry.activeModuleIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: registry.activeModuleIndex)
            bottomTabBar
        }
        .onPreferenceChange(ContentHeightKey.self) { height in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                onHeightChange?(height)
            }
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
        HStack(spacing: 2) {
            ForEach(Array(registry.modules.enumerated()), id: \.offset) { i, m in
                let active = i == registry.activeModuleIndex
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        registry.setActiveModule(at: i)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: m.tabIcon)
                            .font(.system(size: 11, weight: .medium))
                        if active {
                            Text(m.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    .foregroundColor(active ? .white : .white.opacity(0.45))
                    .padding(.horizontal, active ? 14 : 10)
                    .padding(.vertical, 7)
                    .background(
                        Group {
                            if active {
                                Capsule()
                                    .fill(m.accentColor)
                                    .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Settings button — placeholder, disabled until settings implemented
            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(6)
            }
            .buttonStyle(.plain)
            .disabled(true)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }
}

// MARK: - Info Dashboard

struct InfoDashboardView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            MusicCompactCard()
            CalendarCompactCard()
            WeatherCompactCard()
        }
        .padding(6)
        .frame(height: 130)
    }
}

// MARK: - Music Compact Card

private struct MusicCompactCard: View {
    @StateObject private var svc = MusicService()

    var body: some View {
        VStack(spacing: 6) {
            // Album art placeholder with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.4), Color.purple.opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: svc.musicInfo.isPlaying ? "music.note" : "play.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
            }

            // Song name
            Text(svc.musicInfo.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            // Artist
            Text(svc.musicInfo.artist)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
        .onAppear { svc.start() }
    }
}

// MARK: - Calendar Compact Card

private struct CalendarCompactCard: View {
    @ObservedObject private var svc = CalendarService()
    @State private var now = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "E"; return f
    }()
    private let dayNumFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()

    var body: some View {
        VStack(spacing: 6) {
            // Week strip
            HStack(spacing: 2) {
                ForEach(weekDates(), id: \.self) { date in
                    VStack(spacing: 2) {
                        Text(dayFormatter.string(from: date))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(calendar.isDateInToday(date) ? 1 : 0.5))
                        Text(dayNumFormatter.string(from: date))
                            .font(.system(size: 10, weight: calendar.isDateInToday(date) ? .bold : .regular))
                            .foregroundColor(.white)

                        // Event indicator — gradient bar if events on this day
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                hasEvents(on: date)
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(Color.clear)
                            )
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Spacer()

            // Current time with gradient
            Text(timeFormatter.string(from: now))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple, Color.blue, Color.cyan],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            Text({
                let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: now)
            }())
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
        .onReceive(timer) { t in now = t }
    }

    private func weekDates() -> [Date] {
        let cal = calendar
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let mondayOffset = weekday - cal.firstWeekday
        let monday = cal.date(byAdding: .day, value: -mondayOffset, to: today)!
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: monday)! }
    }

    private func hasEvents(on date: Date) -> Bool {
        svc.events.contains { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    private var calendar: Calendar { Calendar.current }
}

// MARK: - Weather Compact Card

private struct WeatherCompactCard: View {
    @ObservedObject private var svc = WeatherService.shared

    var body: some View {
        VStack(spacing: 4) {
            if let weather = svc.currentWeather {
                Image(systemName: iconFor(code: weather.conditionCode))
                    .font(.system(size: 24))
                    .foregroundColor(iconColorFor(code: weather.conditionCode))

                Text(weather.temperatureString)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("San Francisco")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.2))
                Text("--°C")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                Text("Loading...")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
        .onAppear { svc.start() }
    }

    private func iconFor(code: Int) -> String {
        switch code {
        case 0, 1: return "sun.max.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "smoke.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67: return "cloud.rain.fill"
        case 71...77: return "cloud.snow.fill"
        case 80...82: return "cloud.heavyrain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    private func iconColorFor(code: Int) -> Color {
        switch code {
        case 0, 1: return .yellow
        case 2: return .blue
        case 3: return .gray
        case 45, 48: return .gray
        case 51...67: return .blue
        case 71...77, 85, 86: return .cyan
        case 80...82: return .blue
        case 95...99: return .yellow
        default: return .gray
        }
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
