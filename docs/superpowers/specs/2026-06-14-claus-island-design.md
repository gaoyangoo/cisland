# Claus Island Design Document

> Version: 1.0
> Date: 2026-06-14
> Scope: Core Framework + Dashboard + Clipboard Module

## Overview

Claus Island is a macOS SwiftUI application that creates a Dynamic Island-style floating panel below the menu bar. This design covers the implementation of the core framework plus two modules: Dashboard (InfoModule) and Clipboard (ClipboardModule).

## Implementation Approach

**Method A: Vertical Layered Construction**

The implementation will follow a layered approach:
1. Base framework layer (Window, Panel, IslandModule protocol, ModuleRegistry)
2. Common view layer (IslandContainerView, ExpandedIslandView, TabBarView)
3. Dashboard complete module (Models → Services → Views → Module integration)
4. Clipboard complete module
5. Integration verification and debugging

This approach ensures clear boundaries between layers and makes future module additions straightforward.

---

## Project Structure (XcodeGen)

```
cisland/
├── cisland/                          # Main project source code
│   ├── App/
│   │   ├── AppDelegate.swift         # App lifecycle, module registration, hotkeys
│   │   └── DynamicIslandApp.swift    # @main entry point
│   ├── Core/
│   │   ├── IslandModule.swift        # Module protocol definition
│   │   └── ModuleRegistry.swift      # Module registry center
│   ├── Models/
│   │   ├── CalendarData.swift        # Calendar data structures
│   │   ├── ClipboardItem.swift       # Clipboard entry
│   │   └── IslandSize.swift          # Size constants
│   ├── Modules/
│   │   ├── InfoModule.swift          # Dashboard module
│   │   └── ClipboardModule.swift     # Clipboard module
│   ├── Services/
│   │   ├── CalendarService.swift     # Calendar service (EventKit)
│   │   ├── MusicService.swift        # Music service (nowplaying script)
│   │   ├── WeatherService.swift      # Weather service (CoreLocation + Open-Meteo)
│   │   └── ClipboardService.swift    # Clipboard service
│   ├── Views/
│   │   ├── IslandContainerView.swift # Root container
│   │   ├── ExpandedIslandView.swift  # Expanded state view
│   │   ├── TabBarView.swift          # Tab bar
│   │   ├── DashboardView.swift       # Dashboard content view
│   │   └── ClipboardView.swift       # Clipboard content view
│   ├── Windows/
│   │   ├── IslandPanel.swift         # NSPanel subclass
│   │   └── IslandWindowController.swift # Window controller
│   └── Resources/
│       └── Assets.xcassets/          # Image resources
├── hooks/
│   └── nowplaying.swift              # Music info extraction script
├── project.yml                        # XcodeGen configuration
└── CLAUDE.md                          # Project guide
```

## Technology Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI |
| Window Management | AppKit (NSPanel, NSWindowController) |
| Data Persistence | UserDefaults + File System |
| Dependency Management | Swift Package Manager (via XcodeGen) |
| Project Generation | XCodeGen |

---

## Core Constants

```swift
enum IslandSize {
    static let expandedFrameWidth: CGFloat = 520
    static let expandedWidth: CGFloat = 480
    static let expandedHeight: CGFloat = 240
    static let compactHeight: CGFloat = 60
}
```

---

## Component Definitions

### IslandModule Protocol

```swift
protocol IslandModule {
    var id: String { get }
    var displayName: String { get }
    var tabIcon: String { get }           // SF Symbol name
    var accentColor: Color { get }
    var expandedHeight: CGFloat { get }
    var expandedView: AnyView { get }
}
```

### ModuleRegistry

```swift
@Observable
class ModuleRegistry {
    private(set) var modules: [IslandModule] = []
    private(set) var activeModuleIndex: Int = 0

    var activeModule: IslandModule? {
        guard activeModuleIndex < modules.count else { return nil }
        return modules[activeModuleIndex]
    }

    func register(_ module: IslandModule)
    func switchToModule(at index: Int)
}
```

### Notification System

```swift
extension Notification.Name {
    static let islandShouldShow = Notification.Name("islandShouldShow")
    static let islandShouldHide = Notification.Name("islandShouldHide")
    static let islandDidBecomeVisible = Notification.Name("islandDidBecomeVisible")
    static let islandDidBecomeHidden = Notification.Name("islandDidBecomeHidden")
    static let islandSwitchToModule = Notification.Name("islandSwitchToModule")
}
```

---

## Window System

### IslandPanel (NSPanel)

```swift
class IslandPanel: NSPanel {
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                   backing: backingStoreType,
                   defer: flag)

        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false  // Custom shadow in SwiftUI
        self.canBecomeKey = true
        self.canBecomeMain = false

        // Don't show in Dock
        NSApp.setActivationPolicy(.accessory)
    }
}
```

### IslandWindowController

```swift
class IslandWindowController: NSWindowController {
    private let moduleRegistry: ModuleRegistry
    private var compactFrame: NSRect
    private var expandedFrame: NSRect

    init(moduleRegistry: ModuleRegistry) {
        self.moduleRegistry = moduleRegistry
        // Calculate position: screen top, below menu bar
        let screen = NSScreen.main!
        let menuBarHeight = 25  // Estimated
        let compactRect = NSRect(
            x: (screen.frame.width - IslandSize.compactHeight) / 2,
            y: screen.frame.height - menuBarHeight - IslandSize.compactHeight,
            width: IslandSize.compactHeight,
            height: IslandSize.compactHeight
        )
        let expandedRect = NSRect(
            x: (screen.frame.width - IslandSize.expandedFrameWidth) / 2,
            y: screen.frame.height - menuBarHeight - IslandSize.expandedHeight,
            width: IslandSize.expandedFrameWidth,
            height: IslandSize.expandedHeight
        )

        let panel = IslandPanel(contentRect: compactRect, styleMask: [], backing: .buffered, defer: false)
        self.compactFrame = compactRect
        self.expandedFrame = expandedRect
        super.init(window: panel)

        setupNotifications()
    }

    func showIsland()
    func hideIsland()
    func toggleIsland()
    func expandIsland()
    func collapseIsland()
}
```

### Window Animation

Use `NSAnimationContext` for smooth transitions:

```swift
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.25
    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    window?.animator().setFrame(newFrame, display: true)
}
```

---

## View Layer

### IslandContainerView

```swift
struct IslandContainerView: View {
    @State private var isExpanded = false
    @ObservedObject var moduleRegistry: ModuleRegistry
    @AppStorage("islandBackground") private var background: IslandBackground = .glass

    var body: some View {
        IslandShape()
            .fill(backgroundMaterial)
            .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
            .overlay {
                if isExpanded {
                    ExpandedIslandView(moduleRegistry: moduleRegistry)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    CompactView(moduleRegistry: moduleRegistry)
                }
            }
    }

    private var backgroundMaterial: some Material {
        switch background {
        case .glass: return .ultraThinMaterial
        case .dark: return .regularMaterial
        case .light: return .thickMaterial
        }
    }
}

enum IslandBackground: String, CaseIterable {
    case glass, dark, light
}
```

### IslandShape (Dynamic Island Shape)

```swift
struct IslandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 24
        let topOverhang: CGFloat = 8

        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(tangent1End: .zero,
                    tangent2End: CGPoint(x: 0, y: cornerRadius),
                    radius: cornerRadius)
        path.addLine(to: CGPoint(x: 0, y: topOverhang))

        // Top inward curve
        path.addLine(to: CGPoint(x: 20, y: topOverhang))
        path.addQuadCurve(to: CGPoint(x: 30, y: 0),
                          control: CGPoint(x: 25, y: topOverhang))
        path.addLine(to: CGPoint(x: rect.width - 30, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width - 20, y: topOverhang),
                          control: CGPoint(x: rect.width - 25, y: topOverhang))

        path.addLine(to: CGPoint(x: rect.width, y: cornerRadius))
        path.addArc(tangent1End: CGPoint(x: rect.width, y: cornerRadius),
                    tangent2End: CGPoint(x: rect.width - cornerRadius, y: rect.height),
                    radius: cornerRadius)
        path.addArc(tangent1End: CGPoint(x: rect.width - cornerRadius, y: rect.height),
                    tangent2End: CGPoint(x: cornerRadius, y: rect.height),
                    radius: cornerRadius)
        path.addArc(tangent1End: CGPoint(x: cornerRadius, y: rect.height),
                    tangent2End: CGPoint(x: 0, y: cornerRadius),
                    radius: cornerRadius)

        return path
    }
}
```

### ExpandedIslandView

```swift
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
```

### TabBarView

```swift
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
            }
            .buttonStyle(.plain)
        }
    }
}
```

---

## Dashboard Module

### CalendarData Model

```swift
struct CalendarData {
    let currentDate: Date
    let weekDates: [Date]
    let selectedDate: Date
    let events: [Event]

    struct Event {
        let title: String
        let startDate: Date
        let endDate: Date
        let location: String?
    }
}
```

### CalendarService

```swift
@Observable
class CalendarService {
    static let shared = CalendarService()

    private(set) var calendarData: CalendarData?
    private var refreshTimer: Timer?

    private init() {
        setupEventStore()
        startPeriodicRefresh()
    }

    private func setupEventStore()
    private func startPeriodicRefresh() // 60 second refresh
    func fetchCalendarData()
    func formatTime(_ date: Date) -> String
}
```

### MusicService

```swift
@Observable
class MusicService {
    static let shared = MusicService()

    @Published var songName: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var isPlaying: Bool = false
    @Published var hasMusic: Bool = false
    @Published var artwork: NSImage?
    @Published var elapsed: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var refreshTimer: Timer?

    private init() {
        startPeriodicRefresh() // 10 second refresh
    }

    private func startPeriodicRefresh()
    private func fetchMusicInfo() // Execute nowplaying.swift
}
```

### WeatherService

```swift
@Observable
class WeatherService {
    static let shared = WeatherService()
    private let locationManager = CLLocationManager()

    @Published var temperature: Int?
    @Published var conditionSymbol: String = "cloud"
    @Published var conditionText: String = ""
    @Published var cityName: String = ""

    private init() {
        setupLocationManager()
        startPeriodicRefresh() // 15 minute refresh
    }

    private func setupLocationManager()
    private func fetchWeatherData(for location: CLLocation)
}
```

### DashboardView

```swift
struct DashboardView: View {
    @State private var calendarService = CalendarService.shared
    @State private var musicService = MusicService.shared
    @State private var weatherService = WeatherService.shared

    var body: some View {
        HStack(spacing: 12) {
            MusicCard(musicService: musicService)
            CalendarCard(calendarService: calendarService)
            WeatherCard(weatherService: weatherService)
        }
        .padding(.horizontal, 16)
    }
}
```

---

## Clipboard Module

### ClipboardItem Model

```swift
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date

    enum ClipboardContent: Codable {
        case text(String)
        case image(ImageData)

        struct ImageData: Codable {
            let filename: String
            let width: Int
            let height: Int
        }
    }
}
```

### ClipboardService

```swift
@Observable
class ClipboardService {
    static let shared = ClipboardService()

    @Published var items: [ClipboardItem] = []
    @Published var searchTerm: String = ""

    private let maxItems = 100
    private let historyFileURL: URL
    private let imagesDirectoryURL: URL
    private var imageCache: [UUID: NSImage] = [:]
    private var refreshTimer: Timer?

    private init() {
        setupDirectories()
        loadHistory()
        startMonitoring() // 1 second polling
    }

    private func setupDirectories()
    private func loadHistory()
    private func saveHistory()
    private func startMonitoring()
    private func checkForChanges()
    func copyToClipboard(item: ClipboardItem)
    var filteredItems: [ClipboardItem] { get }
}
```

### ClipboardView

```swift
struct ClipboardView: View {
    @State private var clipboardService = ClipboardService.shared
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ClipboardSearchField(searchText: $clipboardService.searchTerm)
                .focused($searchFieldFocused)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(clipboardService.filteredItems) { item in
                        ClipboardRow(item: item)
                            .onTapGesture {
                                clipboardService.copyToClipboard(item: item)
                                NotificationCenter.default.post(name: .islandShouldHide, object: nil)
                            }
                    }
                }
                .padding(12)
            }
        }
    }
}
```

### ClipboardSearchField

```swift
struct ClipboardSearchField: NSViewRepresentable {
    @Binding var searchText: String

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = "Search clipboard..."
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = searchText
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: ClipboardSearchField

        init(_ parent: ClipboardSearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSSearchField {
                parent.searchText = field.stringValue
            }
        }
    }
}
```

---

## Error Handling Strategy

| Scenario | Handling |
|----------|----------|
| Empty module list | Display "No modules available" placeholder |
| Calendar access denied | Display "Calendar access denied", prompt for permissions |
| Music script no output | `hasMusic = false`, display "Not Playing" |
| Weather location failed | `conditionText = "Location unavailable"`, icon shows `location.slash` |
| Clipboard image file missing | Filter out that entry, log warning |
| nowplaying.swift execution failed | Silent fail, continue retry (next poll) |
| File system I/O error | Display error alert, fallback to memory mode |

---

## Integration Verification Checkpoints

1. **Base framework complete**: Window can show/hide, Tab bar can switch modules
2. **Dashboard complete**: Three-card layout works, data refreshes in real-time, animations smooth
3. **Clipboard complete**: Captures clipboard changes, history list displays, search filters, click-to-copy works
4. **Visual effects complete**: Glass effect, custom shape, shadow, gradients correct

---

## AppDelegate Integration

```swift
@main
struct DynamicIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty, use AppDelegate to manage
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: IslandWindowController!
    private var moduleRegistry: ModuleRegistry!
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupModuleRegistry()
        setupWindowController()
        setupStatusBarItem()
        setupGlobalHotkey() // ⌘⇧O
    }

    private func setupModuleRegistry() {
        moduleRegistry = ModuleRegistry()
        moduleRegistry.register(InfoModule())
        moduleRegistry.register(ClipboardModule())
        moduleRegistry.switchToModule(at: 0)
    }

    private func setupWindowController() {
        windowController = IslandWindowController(moduleRegistry: moduleRegistry)
    }

    private func setupStatusBarItem() { ... }
    private func setupGlobalHotkey() { ... }
}
```

---

## Data Persistence Paths

| Data | Path |
|------|------|
| Clipboard history | `~/.claus_island/clipboard/history.json` |
| Clipboard images | `~/.claus_island/clipboard/images/*.png` |
| Background theme preference | UserDefaults `islandBackground` |

---

## Notes

- Testing: No unit tests for this implementation
- Visual effects: Full visual effects (glass, custom shape, gradients, shadows) required
- Project management: XCodeGen with project.yml configuration
- Future modules: Claude Permission and QuickInfo modules can be added following the established IslandModule protocol