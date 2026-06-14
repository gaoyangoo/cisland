# Claus Island Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a macOS SwiftUI application with Dynamic Island-style floating panel with Dashboard and Clipboard modules following the design specification.

**Architecture:** Vertical layered construction - implement core framework first, then common view layer, then complete modules one at a time with full integration.

**Tech Stack:** SwiftUI, AppKit, EventKit, CoreLocation, Open-Meteo API, Swift Package Manager, XcodeGen

---

## Phase 1: Core Framework Foundation

### Task 1.1: Create XcodeGen Configuration

**Files:**
- Create: `/Users/claus/code/claude_code/island/project.yml`

- [ ] **Step 1: Write the project.yml configuration**

```yaml
name: cisland
options:
  bundleIdPrefix: com.claus.island
  deploymentTarget: "14.0"
  createIntermediateGroups: true
settings:
  base:
    CLANG_ENABLE_OBJC_WEAK: "YES"
    ENABLE_USER_SCRIPT_SANDBOXING: "NO"
    SWIFT_VERSION: 5.10
targets:
  cisland:
    type: application
    platform: macos
    sources:
      - cisland
    resources:
      - cisland/Resources
    dependencies:
      - package: SwiftUIKit
        url: https://github.com/onmyway133/SwiftUIKit.git
        exactVersion: "1.2.0"
    info:
      path: cisland/Info.plist
      version: "1.0.0"
      build: "1"
      category: public.app-category.utilities
```

- [ ] **Step 2: Run XcodeGen to generate project**

```bash
cd /Users/claus/code/claude_code/island
rm -rf cisland/cisland.xcodeproj
xcodegen generate --project project.yml
```

- [ ] **Step 3: Commit project configuration**

```bash
git add project.yml
git commit -m "feat: add XcodeGen project configuration"
```

### Task 1.2: Create IslandModule Protocol and ModuleRegistry

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Core/IslandModule.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Core/ModuleRegistry.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Core/Notifications.swift`

- [ ] **Step 1: Write IslandModule protocol**

```swift
// cisland/Core/IslandModule.swift
import SwiftUI

protocol IslandModule {
    var id: String { get }
    var displayName: String { get }
    var tabIcon: String { get }
    var accentColor: Color { get }
    var expandedHeight: CGFloat { get }
    var expandedView: AnyView { get }
}
```

- [ ] **Step 2: Write ModuleRegistry class**

```swift
// cisland/Core/ModuleRegistry.swift
import SwiftUI

@Observable
class ModuleRegistry {
    private(set) var modules: [IslandModule] = []
    private(set) var activeModuleIndex: Int = 0

    var activeModule: IslandModule? {
        guard activeModuleIndex < modules.count else { return nil }
        return modules[activeModuleIndex]
    }

    func register(_ module: IslandModule) {
        modules.append(module)
    }

    func switchToModule(at index: Int) {
        guard index < modules.count else { return }
        activeModuleIndex = index
    }
}
```

- [ ] **Step 3: Write Notifications extensions**

```swift
// cisland/Core/Notifications.swift
import Foundation

extension Notification.Name {
    static let islandShouldShow = Notification.Name("islandShouldShow")
    static let islandShouldHide = Notification.Name("islandShouldHide")
    static let islandDidBecomeVisible = Notification.Name("islandDidBecomeVisible")
    static let islandDidBecomeHidden = Notification.Name("islandDidBecomeHidden")
    static let islandSwitchToModule = Notification.Name("islandSwitchToModule")
}
```

- [ ] **Step 4: Island size constants**

```swift
// cisland/Models/IslandSize.swift
import SwiftUI

enum IslandSize {
    static let expandedFrameWidth: CGFloat = 520
    static let expandedWidth: CGFloat = 480
    static let expandedHeight: CGFloat = 240
    static let compactHeight: CGFloat = 60
}
```

- [ ] **Step 5: Commit core framework**

```bash
git add cisland/Core cisland/Models
git commit -m "feat: add core framework (IslandModule protocol, ModuleRegistry, Notifications, IslandSize)"
```

### Task 1.3: Create Window System

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Windows/IslandPanel.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Windows/IslandWindowController.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Windows/WindowUtils.swift`

- [ ] **Step 1: Write IslandPanel NSPanel subclass**

```swift
// cisland/Windows/IslandPanel.swift
import Cocoa

class IslandPanel: NSPanel {
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                   backing: backingStoreType,
                   defer: flag)

        setupWindowProperties()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindowProperties()
    }

    private func setupWindowProperties() {
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.canBecomeKey = true
        self.canBecomeMain = false
        
        NSApp.setActivationPolicy(.accessory)
    }
}
```

- [ ] **Step 2: Write IslandWindowController**

```swift
// cisland/Windows/IslandWindowController.swift
import Cocoa

class IslandWindowController: NSWindowController {
    private let moduleRegistry: ModuleRegistry
    private var compactFrame: NSRect
    private var expandedFrame: NSRect
    private var isShowing = false

    init(moduleRegistry: ModuleRegistry) {
        self.moduleRegistry = moduleRegistry
        
        // Calculate position below menu bar
        let screen = NSScreen.main!
        let menuBarHeight: CGFloat = 25
        
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
        setupWindowObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShouldShow),
            name: .islandShouldShow,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShouldHide),
            name: .islandShouldHide,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwitchToModule(_:)),
            name: .islandSwitchToModule,
            object: nil
        )
    }

    private func setupWindowObservers() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: window,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .islandDidBecomeVisible, object: nil)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .islandDidBecomeHidden, object: nil)
        }
    }

    @objc private func handleShouldShow() {
        showIsland()
    }

    @objc private func handleShouldHide() {
        hideIsland()
    }

    @objc private func handleSwitchToModule(_ notification: Notification) {
        if let index = notification.userInfo?["index"] as? Int {
            switchToModule(at: index)
        }
    }

    func showIsland() {
        guard !isShowing else { return }
        
        window?.setFrame(compactFrame, display: true, animate: true)
        window?.makeKeyAndOrderFront(nil)
        isShowing = true
    }

    func hideIsland() {
        guard isShowing else { return }
        
        window?.orderOut(nil)
        isShowing = false
    }

    func toggleIsland() {
        if isShowing {
            hideIsland()
        } else {
            showIsland()
        }
    }

    func expandIsland() {
        guard isShowing else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window?.animator().setFrame(expandedFrame, display: true)
        }
    }

    func collapseIsland() {
        guard isShowing else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window?.animator().setFrame(compactFrame, display: true)
        }
    }

    func switchToModule(at index: Int) {
        moduleRegistry.switchToModule(at: index)
        if isShowing && window?.frame == expandedFrame {
            // Only collapse if currently expanded
            collapseIsland()
        }
    }
}
```

- [ ] **Step 3: Write WindowUtils for animation**

```swift
// cisland/Windows/WindowUtils.swift
import Cocoa

struct WindowUtils {
    static func animateWindow(
        _ window: NSWindow,
        to frame: NSRect,
        duration: TimeInterval = 0.25,
        timing: CAMediaTimingFunctionName = .easeInEaseOut,
        completion: (() -> Void)? = nil
    ) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: timing)
            context.allowsImplicitAnimation = true
            window.setFrame(frame, display: true)
        } completionHandler: {
            completion?()
        }
    }
}
```

- [ ] **Step 4: Commit window system**

```bash
git add cisland/Windows
git commit -m "feat: add window system (IslandPanel, IslandWindowController, WindowUtils)"
```

### Task 1.4: Create Core View Components

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Views/IslandShape.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Views/IslandBackgroundStyle.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Views/IslandContainerView.swift`

- [ ] **Step 1: Write IslandShape**

```swift
// cisland/Views/IslandShape.swift
import SwiftUI

struct IslandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 24
        let topOverhang: CGFloat = 8

        // Start at bottom left
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        
        // Bottom-left arc
        path.addArc(tangent1End: .zero,
                    tangent2End: CGPoint(x: 0, y: cornerRadius),
                    radius: cornerRadius)
        
        // Bottom line to bottom-right
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: rect.height))
        
        // Bottom-right arc
        path.addArc(tangent1End: CGPoint(x: rect.width, y: rect.height),
                    tangent2End: CGPoint(x: rect.width - cornerRadius, y: rect.height),
                    radius: cornerRadius)
        
        // Top line (partially inset for Dynamic Island effect)
        path.addLine(to: CGPoint(x: rect.width - 20, y: cornerRadius))
        
        // Top inward curve left
        path.addQuadCurve(to: CGPoint(x: 30, y: 0),
                          control: CGPoint(x: rect.width - 25, y: cornerRadius))
        
        // Top line across the gap
        path.addLine(to: CGPoint(x: 30, y: 0))
        
        // Top inward curve right
        path.addQuadCurve(to: CGPoint(x: rect.width - 20, y: cornerRadius),
                          control: CGPoint(x: 25, y: 0))
        
        // Top line to top-right
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        
        // Top-right arc
        path.addArc(tangent1End: CGPoint(x: rect.width, y: 0),
                    tangent2End: CGPoint(x: rect.width, y: cornerRadius),
                    radius: cornerRadius)

        return path
    }
}
```

- [ ] **Step 2: Write IslandBackgroundStyle**

```swift
// cisland/Views/IslandBackgroundStyle.swift
import SwiftUI

enum IslandBackground: String, CaseIterable {
    case glass, dark, light
}

struct IslandBackgroundStyle: ViewModifier {
    let style: IslandBackground
    
    func body(content: Content) -> some View {
        content
            .background(alignment: .bottom) {
                IslandShape()
                    .fill(backgroundMaterial)
                    .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
            }
    }
    
    private var backgroundMaterial: some Material {
        switch style {
        case .glass: return .ultraThinMaterial
        case .dark: return .regularMaterial
        case .light: return .thickMaterial
        }
    }
}
```

- [ ] **Step 3: Write IslandContainerView**

```swift
// cisland/Views/IslandContainerView.swift
import SwiftUI

struct IslandContainerView: View {
    @State private var isExpanded = false
    @ObservedObject var moduleRegistry: ModuleRegistry
    @AppStorage("islandBackground") private var background: IslandBackground = .glass

    var body: some View {
        ZStack {
            // Compact state
            if !isExpanded {
                CompactView(moduleRegistry: moduleRegistry)
                    .modifier(IslandBackgroundStyle(style: background))
                    .onTapGesture {
                        expandIsland()
                    }
            }
            
            // Expanded state
            if isExpanded {
                ExpandedIslandView(moduleRegistry: moduleRegistry)
                    .modifier(IslandBackgroundStyle(style: background))
                    .onTapGesture {
                        collapseIsland()
                    }
            }
        }
    }
    
    private func expandIsland() {
        isExpanded = true
    }
    
    private func collapseIsland() {
        isExpanded = false
    }
}
```

- [ ] **Step 4: Create CompactView placeholder**

```swift
// cisland/Views/CompactView.swift
import SwiftUI

struct CompactView: View {
    @ObservedObject var moduleRegistry: ModuleRegistry
    
    var body: some View {
        HStack {
            if let module = moduleRegistry.activeModule {
                Image(systemName: module.tabIcon)
                    .font(.title2)
                    .foregroundStyle(module.accentColor)
                    .frame(width: 30, height: 30)
            } else {
                Image(systemName: "questionmark")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 5: Commit core views**

```bash
git add cisland/Views
git commit -m "feat: add core view components (IslandShape, IslandBackgroundStyle, IslandContainerView, CompactView)"
```

## Phase 2: Dashboard Module Implementation

### Task 2.1: Create Dashboard Models

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/InfoModule/Models/CalendarData.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/InfoModule/InfoModule.swift`

- [ ] **Step 1: Write CalendarData model**

```swift
// cisland/Modules/InfoModule/Models/CalendarData.swift
import Foundation

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
        
        var isAllDay: Bool {
            Calendar.current.isDate(startDate, inSameDayAs: endDate) &&
            Calendar.current.component(.hour, from: startDate) == 0 &&
            Calendar.current.component(.minute, from: startDate) == 0
        }
    }
}
```

- [ ] **Step 2: Write InfoModule implementation**

```swift
// cisland/Modules/InfoModule/InfoModule.swift
import SwiftUI

struct InfoModule: IslandModule {
    let id = "dashboard"
    let displayName = "Dashboard"
    let tabIcon = "dashboard"
    let accentColor = Color.blue
    let expandedHeight: CGFloat = IslandSize.expandedHeight
    
    var expandedView: AnyView {
        AnyView(DashboardView())
    }
}
```

- [ ] **Step 3: Commit Dashboard models**

```bash
git add cisland/Modules/InfoModule
git commit -m "feat: add Dashboard module models (InfoModule, CalendarData)"
```

### Task 2.2: Implement Calendar Service

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Services/CalendarService.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/InfoModule/Views/CalendarCard.swift`

- [ ] **Step 1: Write CalendarService**

```swift
// cisland/Services/CalendarService.swift
import SwiftUI
import EventKit

@Observable
class CalendarService {
    static let shared = CalendarService()
    
    private(set) var calendarData: CalendarData?
    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?
    
    private init() {
        requestCalendarAccess()
        startPeriodicRefresh()
    }
    
    private func requestCalendarAccess() {
        let status = eventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            fetchCalendarData()
        case .denied, .restricted:
            print("Calendar access denied")
        case .notDetermined:
            eventStore.requestAccess(to: .event) { granted, _ in
                if granted {
                    DispatchQueue.main.async {
                        self.fetchCalendarData()
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.fetchCalendarData()
        }
    }
    
    func fetchCalendarData() {
        guard eventStore.authorizationStatus(for: .event) == .authorized else {
            calendarData = nil
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Get current week
        let weekDates = calendar.generateWeekDates(for: now)
        
        // Get events for the week
        let startDate = weekDates.first ?? now
        let endDate = weekDates.last ?? now
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate).map { event in
            CalendarData.Event(
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location
            )
        }.sorted { $0.startDate < $1.startDate }
        
        calendarData = CalendarData(
            currentDate: now,
            weekDates: weekDates,
            selectedDate: now,
            events: events
        )
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// Calendar extension for week generation
extension Calendar {
    func generateWeekDates(for date: Date) -> [Date] {
        var dates: [Date] = []
        let components = self.dateComponents([.year, .month, .day], from: date)
        let startOfWeek = self.date(from: components)!
        let endOfWeek = self.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        var currentDate = startOfWeek
        while currentDate <= endOfWeek {
            dates.append(currentDate)
            currentDate = self.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
}
```

- [ ] **Step 2: Write CalendarCard**

```swift
// cisland/Modules/InfoModule/Views/CalendarCard.swift
import SwiftUI

struct CalendarCard: View {
    @StateObject private var calendarService = CalendarService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
            
            if let calendarData = calendarService.calendarData {
                ForEach(calendarData.events.prefix(3)) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text(calendarService.formatTime(event.startDate))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            if let location = event.location {
                                Spacer()
                                Image(systemName: "location")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No calendar access")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(12)
    }
}
```

- [ ] **Step 3: Commit Calendar service**

```bash
git add cisland/Services cisland/Modules/InfoModule/Views
git commit -m "feat: implement Calendar service and CalendarCard view"
```

### Task 2.3: Implement Music Service

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Services/MusicService.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/hooks/nowplaying.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/InfoModule/Views/MusicCard.swift`

- [ ] **Step 1: Write nowplaying.swift script**

```bash
# cisland/hooks/nowplaying.swift
#!/usr/bin/env swift

import Foundation

struct MusicInfo: Codable {
    let track: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let elapsed: Double?
    let status: String?
}

let args = CommandLine.arguments
let command = args.count > 1 ? args[1] : "info"

func getNowPlaying() -> MusicInfo? {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = [
        "-e", "tell application \"Music\" to get name of current track",
        "-e", "tell application \"Music\" to get artist of current track",
        "-e", "tell application \"Music\" to get album of current track",
        "-e", "tell application \"Music\" to get duration of current track",
        "-e", "tell application \"Music\" to get player position",
        "-e", "tell application \"Music\" to get player state"
    ]
    
    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    task.standardError = outputPipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus == 0 {
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.split(separator: "\n").map { String($0) }
                if lines.count >= 6 {
                    return MusicInfo(
                        track: lines[0].isEmpty ? nil : lines[0],
                        artist: lines[1].isEmpty ? nil : lines[1],
                        album: lines[2].isEmpty ? nil : lines[2],
                        duration: Double(lines[3]),
                        elapsed: Double(lines[4]),
                        status: lines[5]
                    )
                }
            }
        }
    } catch {
        return nil
    }
    
    return nil
}

func getPlaybackStatus() -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = ["-e", "tell application \"Music\" to get player state"]
    
    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus == 0 {
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    } catch {
        return "stopped"
    }
    
    return "stopped"
}

switch command {
case "info":
    if let musicInfo = getNowPlaying() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(musicInfo) {
            print(String(data: data, encoding: .utf8) ?? "{}")
        }
    } else {
        let emptyInfo = MusicInfo(track: nil, artist: nil, album: nil, duration: nil, elapsed: nil, status: "stopped")
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(emptyInfo) {
            print(String(data: data, encoding: .utf8) ?? "{}")
        }
    }
case "status":
    print(getPlaybackStatus())
default:
    print("{}")
}
```

- [ ] **Step 2: Make nowplaying.swift executable**

```bash
chmod +x /Users/claus/code/claude_code/island/cisland/hooks/nowplaying.swift
```

- [ ] **Step 3: Write MusicService**

```swift
// cisland/Services/MusicService.swift
import SwiftUI

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
    
    private let nowplayingURL = URL(fileURLWithPath: "/Users/claus/code/claude_code/island/cisland/hooks/nowplaying.swift")
    private var refreshTimer: Timer?
    
    private init() {
        startPeriodicRefresh()
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            fetchMusicInfo()
        }
    }
    
    private func fetchMusicInfo() {
        let task = Process()
        task.executableURL = nowplayingURL
        task.arguments = ["info"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8),
                   let data = output.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    if let musicInfo = try? decoder.decode(MusicInfo.self, from: data) {
                        DispatchQueue.main.async {
                            self.updateWithMusicInfo(musicInfo)
                        }
                    }
                }
            }
        } catch {
            // Silent fail - retry on next poll
        }
    }
    
    private func updateWithMusicInfo(_ info: MusicInfo) {
        hasMusic = info.track != nil || info.artist != nil
        songName = info.track ?? ""
        artist = info.artist ?? ""
        album = info.album ?? ""
        elapsed = info.elapsed ?? 0
        duration = info.duration ?? 0
        
        let status = info.status ?? "stopped"
        isPlaying = status.lowercased() == "playing"
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// Keep the MusicInfo struct from the script
struct MusicInfo: Codable {
    let track: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let elapsed: Double?
    let status: String?
}
```

- [ ] **Step 4: Write MusicCard**

```swift
// cisland/Modules/InfoModule/Views/MusicCard.swift
import SwiftUI

struct MusicCard: View {
    @StateObject private var musicService = MusicService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Music")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
            
            if musicService.hasMusic {
                VStack(alignment: .leading, spacing: 8) {
                    Text(musicService.songName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(musicService.artist)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    if musicService.isPlaying {
                        ProgressView()
                            .scaleEffect(0.5)
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                }
                .padding(.vertical, 8)
            } else {
                Text("Not Playing")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.2))
        .cornerRadius(12)
    }
}
```

- [ ] **Step 5: Commit Music service**

```bash
git add cisland/Services/MusicService.swift cisland/hooks/nowplaying.swift cisland/Modules/InfoModule/Views/MusicCard.swift
git commit -m "feat: implement Music service and MusicCard with nowplaying script"
```

### Task 2.4: Implement Weather Service

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Services/WeatherService.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/InfoModule/Views/WeatherCard.swift`

- [ ] **Step 1: Write WeatherService**

```swift
// cisland/Services/WeatherService.swift
import SwiftUI
import CoreLocation

@Observable
class WeatherService: NSObject, CLLocationManagerDelegate {
    static let shared = WeatherService()
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    
    @Published var temperature: Int?
    @Published var conditionSymbol: String = "cloud"
    @Published var conditionText: String = ""
    @Published var cityName: String = ""
    @Published var isLoading: Bool = false
    
    private var refreshTimer: Timer?
    
    override init() {
        super.init()
        setupLocationManager()
        startPeriodicRefresh()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in // 15 minutes
            self.fetchWeatherData()
        }
        fetchWeatherData() // Initial fetch
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
        fetchWeatherData()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        // Show default weather or error state
    }
    
    private func fetchWeatherData() {
        guard let location = lastLocation ?? locationManager.location else {
            // Use default coordinates if location not available
            let defaultLocation = CLLocation(latitude: 40.7128, longitude: -74.0060) // NYC
            fetchWeatherForLocation(defaultLocation)
            return
        }
        
        fetchWeatherForLocation(location)
    }
    
    private func fetchWeatherForLocation(_ location: CLLocation) {
        isLoading = true
        
        // Create URL for Open-Meteo API
        let url = URL(
            string: "https://api.open-meteo.com/v1/forecast?" +
            "latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)&" +
            "current=temperature_2m,weather_code&" +
            "hourly=temperature_2m"
        )!
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                print("Weather fetch error: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.updateWithWeatherResponse(weatherResponse)
                }
            } catch {
                print("Weather decode error: \(error)")
            }
        }
        
        task.resume()
    }
    
    private func updateWithWeatherResponse(_ response: WeatherResponse) {
        if let current = response.current {
            temperature = Int(current.temperature2m.rounded())
            conditionSymbol = weatherCodeToSymbol(current.weatherCode)
            conditionText = weatherCodeToDescription(current.weatherCode)
            cityName = "Current Location" // Could be improved with reverse geocoding
        }
    }
    
    private func weatherCodeToSymbol(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max"
        case 1, 2, 3: return "cloud.sun"
        case 45, 48: return "cloud.fog"
        case 51, 53, 55, 56, 57: return "cloud.drizzle"
        case 61, 63, 65: return "cloud.rain"
        case 66, 67: return "cloud.heavyrain"
        case 71, 73, 75: return "cloud.snow"
        case 77: return "cloud.sleet"
        case 80, 81, 82: return "cloud.heavyrain"
        case 85, 86: return "cloud.snow"
        case 95, 96, 99: return "cloud.bolt"
        default: return "cloud"
        }
    }
    
    private func weatherCodeToDescription(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2, 3: return "Partly Cloudy"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing Drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing Rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Ice Pellets"
        case 80, 81, 82: return "Heavy Rain"
        case 85, 86: return "Snow Showers"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Unknown"
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// Weather API response models
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let current: CurrentWeather?
    let hourly: HourlyWeather?
    
    struct CurrentWeather: Codable {
        let temperature2m: Double
        let weatherCode: Int
    }
    
    struct HourlyWeather: Codable {
        let time: [String]
        let temperature2m: [Double]
    }
}
```

- [ ] **Step 2: Write WeatherCard**

```swift
// cisland/Modules/InfoModule/Views/WeatherCard.swift
import SwiftUI

struct WeatherCard: View {
    @StateObject private var weatherService = WeatherService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
            
            if weatherService.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let temperature = weatherService.temperature {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(temperature)°")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Image(systemName: weatherService.conditionSymbol)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Text(weatherService.conditionText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(weatherService.cityName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 8)
            } else {
                HStack {
                    Image(systemName: "location.slash")
                        .font(.title2)
                    Text("Location unavailable")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
    }
}
```

- [ ] **Step 3: Write DashboardView**

```swift
// cisland/Modules/InfoModule/Views/DashboardView.swift
import SwiftUI

struct DashboardView: View {
    var body: some View {
        HStack(spacing: 12) {
            MusicCard()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            
            CalendarCard()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            
            WeatherCard()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
```

- [ ] **Step 4: Commit Weather service and Dashboard**

```bash
git add cisland/Services/WeatherService.swift cisland/Modules/InfoModule/Views/WeatherCard.swift cisland/Modules/InfoModule/Views/DashboardView.swift
git commit -m "feat: implement Weather service, WeatherCard, and complete DashboardView"
```

## Phase 3: Clipboard Module Implementation

### Task 3.1: Create Clipboard Models

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Models/ClipboardItem.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/ClipboardModule/ClipboardModule.swift`

- [ ] **Step 1: Write ClipboardItem model**

```swift
// cisland/Models/ClipboardItem.swift
import Foundation
import AppKit

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
            
            init(from image: NSImage) {
                let UUID = UUID()
                self.filename = "\(UUID.uuidString).png"
                self.width = Int(image.size.width)
                self.height = Int(image.size.height)
            }
        }
    }
}
```

- [ ] **Step 2: Write ClipboardModule**

```swift
// cisland/Modules/ClipboardModule/ClipboardModule.swift
import SwiftUI

struct ClipboardModule: IslandModule {
    let id = "clipboard"
    let displayName = "Clipboard"
    let tabIcon = "doc.on.clipboard"
    let accentColor = Color.green
    let expandedHeight: CGFloat = IslandSize.expandedHeight
    
    var expandedView: AnyView {
        AnyView(ClipboardView())
    }
}
```

- [ ] **Step 3: Commit Clipboard models**

```bash
git add cisland/Models cisland/Modules/ClipboardModule
git commit -m "feat: add Clipboard module models (ClipboardItem, ClipboardModule)"
```

### Task 3.2: Implement Clipboard Service

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Services/ClipboardService.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/ClipboardModule/Views/ClipboardView.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/ClipboardModule/Views/ClipboardSearchField.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Modules/ClipboardModule/Views/ClipboardRow.swift`

- [ ] **Step 1: Write ClipboardService**

```swift
// cisland/Services/ClipboardService.swift
import SwiftUI
import AppKit

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
    private var lastChangeCount: NSInteger?
    private var pasteboardObservers: [NSObjectProtocol] = []
    
    private init() {
        let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let clausIslandURL = documentsURL.appendingPathComponent("claus_island", isDirectory: true)
        
        // Create directories if they don't exist
        try? FileManager.default.createDirectory(at: clausIslandURL, withIntermediateDirectories: true)
        
        let clipboardURL = clausIslandURL.appendingPathComponent("clipboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: clipboardURL, withIntermediateDirectories: true)
        
        self.historyFileURL = clipboardURL.appendingPathComponent("history.json")
        self.imagesDirectoryURL = clipboardURL.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.imagesDirectoryURL, withIntermediateDirectories: true)
        
        loadHistory()
        startMonitoring()
    }
    
    private func setupDirectories() {
        let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let clausIslandURL = documentsURL.appendingPathComponent("claus_island", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: clausIslandURL, withIntermediateDirectories: true)
        
        let clipboardURL = clausIslandURL.appendingPathComponent("clipboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: clipboardURL, withIntermediateDirectories: true)
        
        self.historyFileURL = clipboardURL.appendingPathComponent("history.json")
        self.imagesDirectoryURL = clipboardURL.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.imagesDirectoryURL, withIntermediateDirectories: true)
    }
    
    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyFileURL),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.items = decoded.prefix(self.maxItems).reversed()
        }
    }
    
    private func saveHistory() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try? encoder.encode(Array(self.items.prefix(self.maxItems)))
            
            if let data = data {
                try? data.write(to: self.historyFileURL)
            }
        }
    }
    
    private func startMonitoring() {
        // Monitor pasteboard changes
        pasteboardObservers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.checkForChanges()
        })
        
        pasteboardObservers.append(NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSWindowDidBecomeKey,
            object: nil,
            queue: .main
        ) { _ in
            self.checkForChanges()
        })
        
        // Timer-based polling as fallback
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        if lastChangeCount != currentChangeCount {
            lastChangeCount = currentChangeCount
            addItems(from: pasteboard)
        }
    }
    
    private func addItems(from pasteboard: NSPasteboard) {
        // Get text
        if let text = pasteboard.string(forType: .string),
           !text.isEmpty,
           !items.contains(where: { $0.content.textValue == text }) {
            let newItem = ClipboardItem(
                id: UUID(),
                content: .text(text),
                timestamp: Date()
            )
            items.insert(newItem, at: 0)
            saveHistory()
        }
        
        // Get image
        if let imageData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData) {
            let imageData = ClipboardItem.ClipboardContent.ImageData(from: image)
            let newItem = ClipboardItem(
                id: UUID(),
                content: .image(imageData),
                timestamp: Date()
            )
            
            // Save image file
            let imageFileURL = imagesDirectoryURL.appendingPathComponent(imageData.filename)
            try? imageData.pngRepresentation.write(to: imageFileURL)
            
            items.insert(newItem, at: 0)
            saveHistory()
            
            // Cache image
            imageCache[newItem.id] = image
        }
    }
    
    func copyToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let imageData):
            let imageFileURL = imagesDirectoryURL.appendingPathComponent(imageData.filename)
            if let imageData = try? Data(contentsOf: imageFileURL),
               let image = NSImage(data: imageData) {
                let tiffData = image.tiffRepresentation
                pasteboard.setData(tiffData, forType: .tiff)
            }
        }
    }
    
    var filteredItems: [ClipboardItem] {
        if searchTerm.isEmpty {
            return items
        }
        
        return items.filter { item in
            switch item.content {
            case .text(let text):
                return text.lowercased().contains(searchTerm.lowercased())
            case .image:
                return searchTerm.isEmpty || "image".lowercased().contains(searchTerm.lowercased())
            }
        }
    }
    
    private var imageData: NSImage {
        // Helper property to access cached images
        return NSImage()
    }
    
    deinit {
        refreshTimer?.invalidate()
        pasteboardObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension ClipboardItem.ClipboardContent {
    var textValue: String? {
        if case .text(let text) = self {
            return text
        }
        return nil
    }
    
    var imageValue: NSImage? {
        if case .image(let imageData) = self {
            return NSImage(contentsOfFile: imageData.filename)
        }
        return nil
    }
}

extension NSImage {
    var pngRepresentation: Data {
        guard let tiffData = self.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return Data()
        }
        return bitmapRep.representation(using: .png, properties: [:]) ?? Data()
    }
}

extension ClipboardItem.ClipboardContent.ImageData {
    var pngRepresentation: Data {
        let image = NSImage(contentsOfFile: filename)
        return image?.pngRepresentation ?? Data()
    }
}
```

- [ ] **Step 2: Write ClipboardView**

```swift
// cisland/Modules/ClipboardModule/Views/ClipboardView.swift
import SwiftUI

struct ClipboardView: View {
    @StateObject private var clipboardService = ClipboardService.shared
    @FocusState private var searchFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ClipboardSearchField(searchText: $clipboardService.searchTerm)
                .focused($searchFieldFocused)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
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

- [ ] **Step 3: Write ClipboardSearchField**

```swift
// cisland/Modules/ClipboardModule/Views/ClipboardSearchField.swift
import SwiftUI

struct ClipboardSearchField: NSViewRepresentable {
    @Binding var searchText: String
    
    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = "Search clipboard..."
        field.delegate = context.coordinator
        field.backgroundColor = NSColor.black.withAlphaComponent(0.2)
        field.wantsLayer = true
        field.layer?.cornerRadius = 8
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

- [ ] **Step 4: Write ClipboardRow**

```swift
// cisland/Modules/ClipboardModule/Views/ClipboardRow.swift
import SwiftUI

struct ClipboardRow: View {
    let item: ClipboardItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: item.content.textValue != nil ? "doc.text" : "photo")
                .font(.title3)
                .foregroundColor(Color.green.opacity(0.8))
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                switch item.content {
                case .text(let text):
                    Text(text)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                case .image:
                    Image(systemName: "photo")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Timestamp
                Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
```

- [ ] **Step 5: Commit Clipboard service**

```bash
git add cisland/Services/ClipboardService.swift cisland/Modules/ClipboardModule/Views
git commit -m "feat: implement Clipboard service (monitoring, history, search) and views"
```

### Task 3.3: Complete View Layer

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Views/ExpandedIslandView.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Views/TabBarView.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Views/ModuleIcon.swift`

- [ ] **Step 1: Write ExpandedIslandView**

```swift
// cisland/Views/ExpandedIslandView.swift
import SwiftUI

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

- [ ] **Step 2: Write TabBarView**

```swift
// cisland/Views/TabBarView.swift
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
```

- [ ] **Step 3: Write ModuleIcon**

```swift
// cisland/Views/ModuleIcon.swift
import SwiftUI

struct ModuleIcon: View {
    let module: IslandModule
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: module.tabIcon)
                .font(.title2)
                .foregroundColor(isActive ? module.accentColor : .white.opacity(0.6))
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            
            if isActive {
                Capsule()
                    .fill(module.accentColor)
                    .frame(height: 3)
            }
        }
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 4: Commit view layer completion**

```bash
git add cisland/Views/ExpandedIslandView.swift cisland/Views/TabBarView.swift cisland/Views/ModuleIcon.swift
git commit -m "feat: complete view layer (ExpandedIslandView, TabBarView, ModuleIcon)"
```

## Phase 4: Integration and Main App

### Task 4.1: Create AppDelegate and Main App

**Files:**
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/App/AppDelegate.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/App/DynamicIslandApp.swift`
- Create: `/Users/claus/code/claude_code/island/cisland/cisland/Info.plist`

- [ ] **Step 1: Write DynamicIslandApp**

```swift
// cisland/App/DynamicIslandApp.swift
import SwiftUI

@main
struct DynamicIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        EmptyScene()
    }
}

struct EmptyScene: Scene {
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .windowStyle(HiddenWindowStyle())
    }
}

struct HiddenWindowStyle: WindowStyle {
    init() {}
    
    func makeWindowController(for window: NSWindow) -> NSWindowController {
        let controller = NSWindowController()
        window.setIsVisible(false)
        return controller
    }
}
```

- [ ] **Step 2: Write AppDelegate**

```swift
// cisland/App/AppDelegate.swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: IslandWindowController?
    private var moduleRegistry: ModuleRegistry?
    private var statusItem: NSStatusItem?
    private var hotkey: Hotkey?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupModuleRegistry()
        setupWindowController()
        setupStatusBarItem()
        setupGlobalHotkey()
    }
    
    private func setupModuleRegistry() {
        moduleRegistry = ModuleRegistry()
        moduleRegistry?.register(InfoModule())
        moduleRegistry?.register(ClipboardModule())
        moduleRegistry?.switchToModule(at: 0)
    }
    
    private func setupWindowController() {
        guard let moduleRegistry = moduleRegistry else { return }
        windowController = IslandWindowController(moduleRegistry: moduleRegistry)
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }
        
        button.image = NSImage(systemSymbolName: "dock.arrow.down.rectangle", accessibilityDescription: "Toggle Island")
        button.imagePosition = .imageOnly
        button.action = #selector(toggleIsland)
        button.target = self
    }
    
    private func setupGlobalHotkey() {
        hotkey = Hotkey(keyCode: kVK_ANSI_O, modifiers: [.command, .shift])
        hotkey?.keyDownHandler = { [weak self] in
            self?.toggleIsland()
        }
    }
    
    @objc private func toggleIsland() {
        windowController?.toggleIsland()
    }
}

// Simple hotkey implementation
class Hotkey {
    let keyCode: UInt32
    let modifiers: NSEvent.ModifierFlags
    let keyDownHandler: () -> Void
    
    init?(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        
        // Monitor for key down events
        NSEvent.addLocalMonitorForEvents(withHandler: { [weak self] event in
            if event.type == .keyDown,
               event.keyCode == self?.keyCode,
               event.modifierFlags.contains(self?.modifiers ?? []) {
                self?.keyDownHandler()
                return nil // Consume the event
            }
            return event
        })
    }
}
```

- [ ] **Step 3: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: Commit app integration**

```bash
git add cisland/App cisland/Info.plist
git commit -m "feat: integrate main app components (AppDelegate, DynamicIslandApp, Info.plist)"
```

### Task 4.2: Final Integration and Testing

- [ ] **Step 1: Build the project**

```bash
cd /Users/claus/code/claude_code/island
xcodebuild -scheme cisland -configuration Debug build
```

- [ ] **Step 2: Test basic functionality**

```bash
# Open in Xcode to test
open cisland/cisland.xcodeproj
```

- [ ] **Step 3: Final commit**

```bash
git add .
git commit -m "feat: complete Claus Island implementation with Dashboard and Clipboard modules"
```

---

**Plan complete and saved to `docs/superpowers/plans/2026-06-14-claus-island-implementation.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**