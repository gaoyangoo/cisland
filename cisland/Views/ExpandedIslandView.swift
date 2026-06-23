import SwiftUI

/// Monospace font helpers — consistent typography across the app.
private enum Mono {
    static func regular(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .monospaced) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .monospaced) }
}

// MARK: - Main Panel

struct ExpandedIslandView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    @Namespace private var tabNamespace

    var body: some View {
        VStack(spacing: 0) {
            mainContent
                .id(registry.activeModuleIndex)
                .transition(.opacity)
            bottomTabBar
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
    }

    // MARK: Bottom Tab Bar

    /// Unified accent color for the active tab pill — dark green matching the Info module.
    private static let tabAccent = Color(red: 0.05, green: 0.45, blue: 0.25)

    private var bottomTabBar: some View {
        HStack(spacing: 1) {
            ForEach(Array(registry.modules.enumerated()), id: \.offset) { i, m in
                let active = i == registry.activeModuleIndex
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        registry.setActiveModule(at: i)
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: m.tabIcon)
                            .font(.system(size: 9, weight: .medium))
                        if active {
                            Text(m.displayName)
                                .font(Mono.semibold(9))
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    .foregroundColor(active ? .white : .white.opacity(0.45))
                    .padding(.horizontal, active ? 12 : 8)
                    .padding(.vertical, 4)
                    .background(
                        Group {
                            if active {
                                Capsule()
                                    .fill(Self.tabAccent)
                                    .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(3)
            }
            .buttonStyle(.plain)
            .disabled(true)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
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
        ZStack(alignment: .bottom) {
            // Album art — fills entire card
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.5), Color.purple.opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            // Music note icon centered
            Image(systemName: svc.musicInfo.isPlaying ? "music.note" : "play.circle")
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            // Song + Artist overlay at bottom
            VStack(spacing: 2) {
                Text(svc.musicInfo.title)
                    .font(Mono.semibold(9))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(svc.musicInfo.artist)
                    .font(Mono.regular(8))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.5), Color.black.opacity(0.2), Color.clear],
                    startPoint: .bottom, endPoint: .top
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { svc.start() }
    }
}

// MARK: - Calendar Compact Card

private struct CalendarCompactCard: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "E"; return f
    }()
    private static let dayNumFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()

    /// Dark green matching the tab accent / Info module.
    private static let todayColor = Color(red: 0.05, green: 0.45, blue: 0.25)

    var body: some View {
        VStack(spacing: 6) {
            // Week strip — Mon–Sun, only today has the white underline
            HStack(spacing: 2) {
                ForEach(weekDates(), id: \.self) { date in
                    let isToday = calendar.isDate(date, inSameDayAs: now)
                    VStack(spacing: 2) {
                        Text(Self.dayFormatter.string(from: date))
                            .font(Mono.medium(8))
                            .foregroundColor(isToday ? Self.todayColor : .white.opacity(0.5))
                        Text(Self.dayNumFormatter.string(from: date))
                            .font(isToday ? Mono.bold(9) : Mono.regular(9))
                            .foregroundColor(isToday ? Self.todayColor : .white.opacity(0.6))

                        // Underline — solid white, only for today
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isToday ? Color.white : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Spacer()

            // Current time — large hour:minute, smaller seconds
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text({
                    let f = DateFormatter(); f.dateFormat = "h:mm"; return f.string(from: now)
                }())
                    .font(Mono.bold(16))
                Text({
                    let f = DateFormatter(); f.dateFormat = "ss"; return f.string(from: now)
                }())
                    .font(Mono.medium(9))
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.purple, Color.blue, Color.cyan],
                    startPoint: .leading, endPoint: .trailing
                )
            )

            Text({
                let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: now)
            }())
                .font(Mono.regular(7))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
        .onReceive(timer) { t in now = t }
    }

    /// Returns Mon–Sun dates for the week containing `now`.
    private func weekDates() -> [Date] {
        let cal = calendar
        let weekday = cal.component(.weekday, from: now)
        let offsetToMonday = (weekday + 5) % 7  // weekday 2 (Mon) → 0, 3 (Tue) → 1, … 1 (Sun) → 6
        let monday = cal.startOfDay(for: cal.date(byAdding: .day, value: -offsetToMonday, to: now)!)
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: monday)! }
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
                    .font(Mono.bold(17))
                    .foregroundColor(.white)

                Text(weather.location)
                    .font(Mono.regular(8))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.2))
                Text("--°C")
                    .font(Mono.bold(17))
                    .foregroundColor(.white.opacity(0.3))
                Text("Loading...")
                    .font(Mono.regular(8))
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
    @ObservedObject private var svc = ClipboardService.shared
    @State private var selectedID: UUID?
    @FocusState private var isFocused: Bool

    /// Auto-select first item when list changes (tab switch, new content, search).
    private func autoSelectFirst() {
        if let first = svc.filteredItems.first, selectedID == nil || !svc.filteredItems.contains(where: { $0.id == selectedID }) {
            selectedID = first.id
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
                TextField("Search clipboard...", text: $svc.searchTerm)
                    .textFieldStyle(.plain)
                    .font(Mono.regular(10))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .cornerRadius(6)
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if svc.filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.2))
                    Text(svc.searchTerm.isEmpty
                         ? "Clipboard is empty"
                         : "No items match \"\(svc.searchTerm)\"")
                        .font(Mono.regular(10))
                        .foregroundColor(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 3) {
                            ForEach(Array(svc.filteredItems.prefix(50).enumerated()), id: \.element.id) { idx, item in
                                clipboardRow(item, isSelected: selectedID == item.id)
                                    .id(item.id)
                                    .onTapGesture {
                                        selectedID = item.id
                                        svc.copyToClipboard(item)
                                    }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    .focusable()
                    .focused($isFocused)
                    .focusEffectDisabled()
                    .onMoveCommand { direction in
                        moveSelection(direction, proxy: proxy)
                    }
                }
            }
        }
        .frame(height: 260)
        .onAppear {
            autoSelectFirst()
            isFocused = true
        }
        .onChange(of: svc.filteredItems.map(\.id)) { _ in autoSelectFirst() }
    }

    private func moveSelection(_ direction: MoveCommandDirection, proxy: ScrollViewProxy) {
        let items = Array(svc.filteredItems.prefix(50))
        guard !items.isEmpty else { return }
        let currentIdx = items.firstIndex(where: { $0.id == selectedID })
        switch direction {
        case .up:
            let next = currentIdx.map { max($0 - 1, 0) } ?? 0
            selectedID = items[next].id
            proxy.scrollTo(selectedID, anchor: .center)
        case .down:
            let next = currentIdx.map { min($0 + 1, items.count - 1) } ?? 0
            selectedID = items[next].id
            proxy.scrollTo(selectedID, anchor: .center)
        default:
            break
        }
    }

    @ViewBuilder
    private func clipboardRow(_ item: ClipboardItem, isSelected: Bool) -> some View {
        let highlight = isSelected ? Color.white.opacity(0.10) : Color.clear
        switch item.content {
        case .text(let text):
            Text(text)
                .font(Mono.regular(10))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(highlight)
                .contentShape(Rectangle())

        case .image(let data):
            HStack {
                if let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 60)
                        .cornerRadius(4)
                }
                Text("Image — \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                    .font(Mono.regular(9))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(highlight)
            .contentShape(Rectangle())
        }
    }
}
