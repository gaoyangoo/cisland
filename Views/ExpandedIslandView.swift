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
    @ObservedObject private var theme = ThemeManager.shared
    @Namespace private var tabNamespace
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            mainContent
                .id(registry.activeModuleIndex)
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
                    .foregroundColor(active ? .white : m.accentColor)
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

            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(3)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                ThemePickerView()
                    .environment(\.colorScheme, theme.colors.colorScheme)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(theme.colors.tabBarBackground)
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
                .frame(width: 140, height: 135)
            CalendarCompactCard()
                .frame(height: 135)
            WeatherCompactCard()
                .frame(maxWidth: 95)
                .frame(height: 135)
            SystemMonitorCard()
                .frame(width: 115, height: 135)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .frame(height: 149)
    }
}

// MARK: - Music Compact Card

private struct MusicCompactCard: View {
    @ObservedObject private var svc = MusicService.shared
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack {
            Spacer()
            // Text overlay at bottom
            VStack(spacing: 2) {
                Text(svc.musicInfo.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                    .lineLimit(1)
                Text(svc.musicInfo.artist)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.black.opacity(0.2), Color.clear],
                    startPoint: .bottom, endPoint: .top
                )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if let art = svc.artwork {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color.pink.opacity(0.5), Color.purple.opacity(0.4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
        .background(theme.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear { svc.start() }
    }
}

// MARK: - Calendar Compact Card

private struct CalendarCompactCard: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "E"; return f
    }()
    private static let dayNumFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()

    private static let enMonthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM"; return f
    }()
    private static let cnMonths = ["一月","二月","三月","四月","五月","六月",
                                    "七月","八月","九月","十月","十一月","十二月"]
    private static let lunarCalendar = Calendar(identifier: .chinese)
    private static let lunarFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        f.calendar = Calendar(identifier: .chinese)
        return f
    }()

    /// Dark green matching the tab accent / Info module.
    private static let todayColor = Color(red: 0.05, green: 0.45, blue: 0.25)

    var body: some View {
        VStack(spacing: 2) {
            // Month at top
            Text(monthLabel())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Week strip
            HStack(spacing: 2) {
                ForEach(weekDates(), id: \.self) { date in
                    let isToday = calendar.isDate(date, inSameDayAs: now)
                    VStack(spacing: 2) {
                        Text(Self.dayFormatter.string(from: date))
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(isToday ? Self.todayColor : theme.colors.textSecondary)
                        Text(Self.dayNumFormatter.string(from: date))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isToday ? .white : theme.colors.text)
                            .frame(width: 22, height: 22)
                            .background(
                                isToday
                                ? Circle().fill(Self.todayColor)
                                : nil
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 1)
                }
            }

            Spacer().frame(height: 4)

            // Current time
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text({
                    let f = DateFormatter(); f.dateFormat = "h:mm"; return f.string(from: now)
                }())
                    .font(.system(size: 26, weight: .bold))
                Text({
                    let f = DateFormatter(); f.dateFormat = "ss"; return f.string(from: now)
                }())
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(
                LinearGradient(
                    colors: theme.theme == .light
                        ? [Color(red: 0.3, green: 0.1, blue: 0.6),
                           Color(red: 0.1, green: 0.2, blue: 0.7),
                           Color(red: 0.0, green: 0.4, blue: 0.6)]
                        : [Color(red: 0.7, green: 0.4, blue: 1.0),
                           Color(red: 0.3, green: 0.5, blue: 1.0),
                           Color(red: 0.2, green: 0.7, blue: 1.0)],
                    startPoint: .leading, endPoint: .trailing
                )
            )

            // Lunar date
            Text(lunarDateString())
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(theme.colors.cardBackgroundAlt))
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.cardBackground)
        .cornerRadius(10)
        .onReceive(timer) { t in now = t }
    }

    private func monthLabel() -> String {
        let en = Self.enMonthFormatter.string(from: now)
        let m = calendar.component(.month, from: now)
        let cn = Self.cnMonths[min(m - 1, 11)]
        return "\(en) · \(cn)"
    }

    private func lunarDateString() -> String {
        let comps = Self.lunarCalendar.dateComponents([.month, .day], from: now)
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        let months = ["正月","二月","三月","四月","五月","六月",
                      "七月","八月","九月","十月","冬月","腊月"]
        let days = ["","初一","初二","初三","初四","初五","初六","初七","初八","初九","初十",
                    "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十",
                    "廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"]
        return months[min(m-1, 11)] + (d <= 30 ? days[d] : "")
    }

    private func weekDates() -> [Date] {
        let cal = calendar
        let weekday = cal.component(.weekday, from: now)
        let offsetToMonday = (weekday + 5) % 7
        let monday = cal.startOfDay(for: cal.date(byAdding: .day, value: -offsetToMonday, to: now)!)
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: monday)! }
    }

    private var calendar: Calendar { Calendar.current }
}

// MARK: - Weather Compact Card

private struct WeatherCompactCard: View {
    @ObservedObject private var svc = WeatherService.shared
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(spacing: 4) {
            if let weather = svc.currentWeather {
                Text(WeatherModel.iconFor(code: weather.conditionCode))
                    .font(.system(size: 28))

                Text(weather.temperatureString)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(tempColor(weather.temperature))

                Text(weather.location)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(theme.colors.text)

                if let tomorrow = weather.tomorrowString {
                    Text(tomorrow)
                        .font(.system(size: 8, weight: .regular))
                        .foregroundColor(theme.colors.textSecondary)
                }
            } else {
                Text("☁️")
                    .font(.system(size: 28))
                Text("--°")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.colors.emptyText)
                Text("Loading...")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(theme.colors.emptyText)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear { svc.start() }
    }

    private func tempColor(_ t: Double) -> Color {
        if t <= 0 { return .cyan }
        if t <= 10 { return .blue }
        if t <= 20 { return .green }
        if t <= 30 { return .orange }
        return .red
    }
}

// MARK: - System Monitor Card

private struct SystemMonitorCard: View {
    @ObservedObject private var svc = SystemMonitorService.shared
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // CPU
            metricRow(
                icon: "cpu", iconColor: .orange,
                label: "CPU", value: svc.stats.cpuString,
                color: cpuColor, top: svc.stats.topCPUName
            )
            ProgressBar(value: svc.stats.cpu / 100, color: cpuColor)

            // Memory
            metricRow(
                icon: "memorychip", iconColor: .blue,
                label: "MEM", value: String(format: "%.0f%%", svc.stats.memoryPercent),
                color: memColor, top: svc.stats.topMemName
            )
            ProgressBar(value: svc.stats.memoryPercent / 100, color: memColor)

            // Power / Thermal
            metricRow(
                icon: "thermometer.medium", iconColor: thermalColor,
                label: "TMP", value: svc.stats.thermalState,
                color: thermalColor, top: svc.stats.powerSource
            )
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear { svc.start() }
    }

    private func metricRow(icon: String, iconColor: Color, label: String, value: String, color: Color, top: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(theme.colors.text)
                Spacer()
                Text(value)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            Text(top)
                .font(.system(size: 7, weight: .regular))
                .foregroundColor(theme.colors.textMuted)
                .lineLimit(1)
        }
    }

    private var cpuColor: Color {
        svc.stats.cpu < 50 ? .green : svc.stats.cpu < 80 ? .orange : .red
    }

    private var memColor: Color {
        svc.stats.memoryPercent < 50 ? .green : svc.stats.memoryPercent < 80 ? .orange : .red
    }

    private var thermalColor: Color {
        switch svc.stats.thermalState {
        case "Nominal": return .green
        case "Fair":    return .orange
        case "Serious": return .red
        case "Critical": return .red
        default:         return .green
        }
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {
    let value: Double // 0…1
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(0.15))
                    .frame(height: 3)
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: max(geo.size.width * value, 3), height: 3)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Clipboard Content

struct ClipboardContentView: View {
    @ObservedObject private var svc = ClipboardService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var selectedID: UUID?

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
                    .foregroundColor(theme.colors.textMuted)
                TextField("Search clipboard...", text: $svc.searchTerm)
                    .textFieldStyle(.plain)
                    .font(Mono.regular(10))
                    .foregroundColor(theme.colors.text)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(theme.colors.searchFieldBackground)
            .cornerRadius(6)
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if svc.filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 24))
                        .foregroundColor(theme.colors.emptyIcon)
                    Text(svc.searchTerm.isEmpty
                         ? "Clipboard is empty"
                         : "No items match \"\(svc.searchTerm)\"")
                        .font(Mono.regular(10))
                        .foregroundColor(theme.colors.emptyText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(Array(svc.filteredItems.prefix(50).enumerated()), id: \.element.id) { idx, item in
                                clipboardRow(item, isSelected: selectedID == item.id)
                                    .id(item.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedID = item.id
                                        svc.copyToClipboard(item)
                                    }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .clipboardMoveUp)) { _ in
                        moveSelection(.up, proxy: proxy)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .clipboardMoveDown)) { _ in
                        moveSelection(.down, proxy: proxy)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .clipboardEnter)) { _ in
                        handleEnter()
                    }
                }
            }
        }
        .frame(height: 260)
        .onAppear {
            autoSelectFirst()
        }
        .onChange(of: svc.filteredItems.map(\.id)) { _ in autoSelectFirst() }
    }

    private func handleEnter() {
        guard let id = selectedID,
              let item = svc.filteredItems.first(where: { $0.id == id }) else { return }
        svc.copyToClipboard(item)
        svc.moveToTop(item)
        NotificationCenter.default.post(name: .togglePanel, object: nil)
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
        switch item.content {
        case .text(let text):
            Text(text)
                .font(Mono.regular(10))
                .foregroundColor(theme.colors.text)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
                .cornerRadius(4)

        case .image(let data):
            HStack(spacing: 8) {
                if let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: isSelected ? 80 : 40)
                        .cornerRadius(4)
                }
                Text("Image (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))")
                    .font(Mono.regular(9))
                    .foregroundColor(theme.colors.textMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: isSelected ? 88 : 44)
            .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
            .cornerRadius(4)
        }
    }
}

// MARK: - Theme Picker

private struct ThemePickerView: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Text("Appearance")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(themeManager.colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        themeManager.theme = theme
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: theme.iconName)
                            .font(.system(size: 11))
                            .frame(width: 18)
                            .foregroundColor(themeManager.theme == theme ? .accentColor : themeManager.colors.textSecondary)

                        Text(theme.displayName)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(themeManager.theme == theme ? .accentColor : themeManager.colors.text)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 130)
        .padding(.bottom, 4)
    }
}
