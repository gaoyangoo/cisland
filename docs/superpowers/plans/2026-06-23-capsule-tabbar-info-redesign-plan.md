# Capsule Tab Bar + Info Page Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign tab bar as capsule pills, smooth dynamic-height tab switching, and redesign Info page with three compact cards (Music/Calendar/Weather).

**Architecture:** SwiftUI views drive all layout; a `ContentHeightPreferenceKey` bridges ideal height from SwiftUI to AppDelegate for animated window resizing. A `@Namespace` + `matchedGeometryEffect` powers the capsule tab bar animation. Info page uses existing services (MusicService, CalendarService, WeatherService) with a new compact three-column card layout.

**Tech Stack:** SwiftUI, AppKit (NSWindow + NSAnimationContext), Combine

---

### Task 1: Add ContentHeightPreferenceKey + dynamic height plumbing

**Files:**
- Modify: `cisland/Views/ExpandedIslandView.swift`

- [ ] **Step 1: Add PreferenceKey at top of ExpandedIslandView.swift**

Before `struct ExpandedIslandView`, add:

```swift
/// Reports the ideal content height from SwiftUI to AppKit for window animation.
struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 160
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

- [ ] **Step 2: Add onChangeHeight callback to ExpandedIslandView**

```swift
struct ExpandedIslandView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    var onHeightChange: ((CGFloat) -> Void)?

    // ...
}
```

- [ ] **Step 3: Wrap mainContent in GeometryReader and set preference**

Replace `private var mainContent: some View` body with:

```swift
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
```

- [ ] **Step 4: Listen to preference change and call onHeightChange**

Add `.onPreferenceChange` to the outer VStack in `var body: some View`:

```swift
var body: some View {
    VStack(spacing: 0) {
        mainContent
        bottomTabBar
    }
    .onPreferenceChange(ContentHeightKey.self) { height in
        onHeightChange?(height)
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add cisland/Views/ExpandedIslandView.swift
git commit -m "feat: add ContentHeightPreferenceKey + dynamic height plumbing"
```

---

### Task 2: Update AppDelegate for dynamic height + smooth NSWindow animation

**Files:**
- Modify: `cisland/App/AppDelegate.swift`

- [ ] **Step 1: Remove hardcoded tabHeights, replace with dynamic height state**

Remove:
```swift
private let tabHeights: [CGFloat] = [160, 390, 390]

private func panelHeight() -> CGFloat {
    let i = min(currentTabIndex, tabHeights.count - 1)
    return tabHeights[i]
}
```

Add:
```swift
private var contentHeight: CGFloat = 160
```

- [ ] **Step 2: Update showPanel() to use contentHeight**

Replace `let h = panelHeight()` with `let h = contentHeight`.

- [ ] **Step 3: Update resizePanelIfVisible() for smooth NSAnimationContext animation**

```swift
private func resizePanelIfVisible() {
    guard let p = panel, p.isVisible, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
    let h = contentHeight
    let x = screen.visibleFrame.midX - 240
    let y = screen.visibleFrame.maxY - h

    NSAnimationContext.runAnimationGroup { ctx in
        ctx.duration = 0.35
        ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1)
        p.animator().setFrame(NSRect(x: x, y: y, width: 480, height: h), display: true)
    }
}
```

- [ ] **Step 4: Pass height callback to IslandContainerView**

Update `IslandContainerView` to accept and forward `onHeightChange`:

```swift
// In showPanel(), update the hosting line:
let rootView = IslandContainerView(onHeightChange: { [weak self] h in
    self?.contentHeight = h
    self?.resizePanelIfVisible()
})
```

- [ ] **Step 5: Commit**

```bash
git add cisland/App/AppDelegate.swift
git commit -m "feat: replace hardcoded tab heights with dynamic ContentHeightKey + NSAnimationContext"
```

---

### Task 3: Update IslandContainerView to pass onHeightChange

**Files:**
- Modify: `cisland/Views/IslandContainerView.swift`

- [ ] **Step 1: Add onHeightChange parameter and forward it**

```swift
public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    var onHeightChange: ((CGFloat) -> Void)?

    public init(onHeightChange: ((CGFloat) -> Void)? = nil) {
        self.onHeightChange = onHeightChange
    }

    public var body: some View {
        ExpandedIslandView(onHeightChange: onHeightChange)
            .frame(width: 480)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add cisland/Views/IslandContainerView.swift
git commit -m "feat: wire onHeightChange from IslandContainerView to ExpandedIslandView"
```

---

### Task 4: Capsule Tab Bar with matchedGeometryEffect

**Files:**
- Modify: `cisland/Views/ExpandedIslandView.swift`

- [ ] **Step 1: Replace bottomTabBar with capsule design**

Add `@Namespace private var tabNamespace` to `ExpandedIslandView`. Replace `private var bottomTabBar` with:

```swift
@Namespace private var tabNamespace

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
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: active)
            }
            .buttonStyle(.plain)
        }

        Spacer()

        Button(action: { /* settings */ }) {
            Image(systemName: "gearshape")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .padding(6)
        }
        .buttonStyle(.plain)
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
```

- [ ] **Step 2: Commit**

```bash
git add cisland/Views/ExpandedIslandView.swift
git commit -m "feat: capsule tab bar with matchedGeometryEffect sliding pill"
```

---

### Task 5: Content cross-fade transition on tab switch

**Files:**
- Modify: `cisland/Views/ExpandedIslandView.swift`

- [ ] **Step 1: Add transition + animation to mainContent**

Wrap the `mainContent` in a transition modifier. Update `var body`:

```swift
var body: some View {
    VStack(spacing: 0) {
        mainContent
            .id(registry.activeModuleIndex)  // triggers re-render on tab switch
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
```

- [ ] **Step 2: Commit**

```bash
git add cisland/Views/ExpandedIslandView.swift
git commit -m "feat: cross-fade content transition + smooth height animation on tab switch"
```

---

### Task 6: Redesign Info page — MusicCard (column 1)

**Files:**
- Modify: `cisland/Views/ExpandedIslandView.swift`

- [ ] **Step 1: Replace the InfoDashboardView Music column**

Inside `InfoDashboardView`, replace the first VStack (Music) with:

```swift
// Music column — no header, album art focus
MusicCompactCard()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

Add a new `MusicCompactCard` struct at file scope:

```swift
private struct MusicCompactCard: View {
    @StateObject private var svc = MusicService()

    var body: some View {
        VStack(spacing: 6) {
            // Album art placeholder
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
        .onAppear { svc.start() }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add cisland/Views/ExpandedIslandView.swift
git commit -m "feat: redesign Info music card with album art placeholder and compact layout"
```

---

### Task 7: Redesign Info page — CalendarCard (column 2)

**Files:**
- Modify: `cisland/Views/ExpandedIslandView.swift`

- [ ] **Step 1: Replace the InfoDashboardView Calendar column**

Replace the second VStack (Calendar) with:

```swift
CalendarCompactCard()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

Add `CalendarCompactCard` struct:

```swift
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

            Text(dayFormatter.string(from: now) + ", " + {
                let f = DateFormatter(); f.dateFormat = "MMMM d"; return f.string(from: now)
            }())
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(6)
        .onReceive(timer) { t in now = t }
    }

    private func weekDates() -> [Date] {
        let cal = calendar
        let today = Date()
        // Find Monday of this week
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
```

- [ ] **Step 2: Commit**

```bash
git add cisland/Views/ExpandedIslandView.swift
git commit -m "feat: redesign Info calendar card with week strip, gradient event bars, gradient time"
```

---

### Task 8: Redesign Info page — WeatherCard (column 3)

**Files:**
- Modify: `cisland/Views/ExpandedIslandView.swift`

- [ ] **Step 1: Replace the InfoDashboardView Weather column**

Replace the third VStack (Weather) with:

```swift
WeatherCompactCard()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

Add `WeatherCompactCard` struct:

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add cisland/Views/ExpandedIslandView.swift
git commit -m "feat: redesign Info weather card with icon, temperature, and city"
```

---

### Task 9: Final info layout — three equal-height columns

**Files:**
- Modify: `cisland/Views/ExpandedIslandView.swift`

- [ ] **Step 1: Rewrite InfoDashboardView to use the three compact cards**

Replace the entire `InfoDashboardView` with:

```swift
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
```

Remove the old card code that was inline in InfoDashboardView (the three VStacks).

- [ ] **Step 2: Commit**

```bash
git add cisland/Views/ExpandedIslandView.swift
git commit -m "feat: final Info page layout — three equal-height compact columns"
```

---

### Task 10: Build, launch, verify

**Files:**
- None (verification only)

- [ ] **Step 1: Build**

```bash
xcodebuild -project cisland.xcodeproj -scheme cisland build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Launch and test**

```bash
pkill -f cisland 2>/dev/null
open ~/Library/Developer/Xcode/DerivedData/cisland-*/Build/Products/Debug/cisland.app
```

- [ ] **Step 3: Manual verification checklist**
  - [ ] Shift+Cmd+O opens the island panel
  - [ ] Bottom tabs show as capsule pills with sliding animation
  - [ ] Clicking tabs cross-fades content + smooth height change
  - [ ] Info page shows three equal-height columns
  - [ ] Music card: gradient placeholder, song + artist
  - [ ] Calendar card: week strip, gradient bars, gradient time
  - [ ] Weather card: icon, temperature, location
