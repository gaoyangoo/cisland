# 🍉 Claus Island

> A macOS Dynamic Island-style floating utility panel built with SwiftUI.

Claus Island is a lightweight, always-accessible floating panel that lives below your menu bar. It provides quick access to Music, Calendar, Weather, Clipboard history, and editable Snippets — all through a beautifully animated tabbed interface with light and dark theme support.

## ✨ Features

| Module | Description |
|--------|-------------|
| 🎵 **Music** | Now-playing track with full-bleed album art, artist overlay, and playback state |
| 📅 **Calendar** | Weekly date strip with today highlight, real-time gradient clock, lunar date, month in English + Chinese |
| ☀️ **Weather** | Live temperature and conditions via Open-Meteo API with CoreLocation |
| 📋 **Clipboard** | History with search, text + image support, arrow-key navigation, JSON persistence |
| 📝 **Snippets** | Editable key-value entries — click to copy, keyboard navigation, inline editing |
| ⌨️ **Global Hotkey** | Toggle the panel from anywhere with `⇧⌘O` |
| 🎨 **Themes** | Light / Dark mode toggle, semantic color palette, persistent preference |

## 🚀 Quick Start

### Requirements

- macOS 14.0+
- Xcode 16+ (Swift 5.10)

### Build & Run

```bash
git clone https://github.com/gaoyangoo/cisland.git
cd cisland
xcodegen generate --spec project.yml  # generate xcodeproj
xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Debug build
open cisland.xcodeproj               # ⌘R to build and run
```

The app runs as a menu bar accessory — look for the ⎈ icon in your status bar, or press `⇧⌘O` to toggle the panel. No Dock icon, no clutter.

## 🏗️ Architecture

Claus Island uses a **plugin-based module architecture**. Each feature implements the `IslandModule` protocol and is registered with `ModuleRegistry` at startup.

```
┌──────────────────────────────────────────────────┐
│                   AppDelegate                     │
│        (⎈ menu bar icon, ⇧⌘O global hotkey)       │
└──────────────────────┬───────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│                   FloatingPanel                   │
│             (NSPanel, borderless, .floating)      │
│  ┌────────────────────────────────────────────┐  │
│  │            IslandContainerView              │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │         ExpandedIslandView            │  │  │
│  │  │    (module content + bottom tab bar)  │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│                ModuleRegistry                     │
│  ┌───────────┬──────────────┬─────────────────┐  │
│  │   Info    │  Clipboard   │    Snippets      │  │
│  │  Module   │   Module     │  (KeyValue)      │  │
│  └───────────┴──────────────┴─────────────────┘  │
└──────────────────────────────────────────────────┘
```

### IslandModule Protocol

```swift
public protocol IslandModule: Identifiable, ObservableObject, Hashable {
    var id: String { get }
    var displayName: String { get }
    var tabIcon: String { get }
    var accentColor: Color { get }
    var expandedHeight: CGFloat { get }
    var expandedView: AnyView { get }
    func initialize()
}
```

### Project Structure

```
cisland/
├── App/
│   ├── AppDelegate.swift              # Lifecycle, module registration, hotkey, menu bar
│   └── cislandApp.swift               # @main SwiftUI entry point
├── Core/
│   ├── IslandModule.swift             # Module protocol definition
│   ├── ModuleRegistry.swift           # ObservableObject singleton registry
│   ├── Hotkey.swift                   # Carbon RegisterEventHotKey implementation
│   ├── Notifications.swift            # Inter-module notification names
│   └── ThemeManager.swift             # Light/dark theme system with semantic colors
├── Models/
│   ├── ClipboardItem.swift            # Text + image clipboard content (Codable)
│   └── IslandSize.swift               # Size enum (small / medium / large)
├── Modules/
│   ├── InfoModule/
│   │   ├── InfoModule.swift           # Dashboard module aggregating Music + Calendar + Weather
│   │   ├── Models/CalendarData.swift  # Calendar data model
│   │   └── Views/                     # MusicCard, CalendarCard, WeatherCard, DashboardView
│   ├── ClipboardModule/
│   │   ├── ClipboardModule.swift      # Clipboard history module
│   │   └── Views/                     # ClipboardRow, ClipboardSearchField, ClipboardView
│   ├── KeyValueModule/
│   │   └── KeyValueModule.swift       # Editable key-value snippet module
│   ├── HotkeyModule.swift             # Global hotkey module
│   ├── StatusBarModule.swift          # Menu bar status item module
│   └── WindowModule.swift             # Window management module
├── Services/
│   ├── WeatherService.swift           # Open-Meteo API + CoreLocation
│   ├── MusicService.swift             # MediaRemote framework via /usr/bin/swift hook
│   ├── ClipboardService.swift         # Pasteboard monitoring + JSON persistence
│   ├── CalendarService.swift          # Calendar data with periodic refresh
│   └── SnippetStore.swift             # Editable key-value persistence (JSON)
├── Views/
│   ├── IslandContainerView.swift      # Root container with custom IslandShape background
│   ├── ExpandedIslandView.swift       # Main panel: tab bar + all card/row views
│   ├── CompactView.swift              # Compact module display
│   ├── TabBarView.swift               # Module tab switcher
│   ├── IslandShape.swift              # Custom Dynamic Island bezier shape
│   ├── IslandBackgroundStyle.swift    # Background style utilities
│   └── ModuleIcon.swift               # Tab icon with active indicator
├── hooks/
│   └── nowplaying.swift               # MediaRemote now-playing hook (copied to bundle Resources)
├── Assets.xcassets/                   # App icon and asset catalog
└── project.yml                        # XcodeGen project specification
```

## 🎨 Visual Design

| Property | Value |
|----------|-------|
| Panel width | 492pt (content) + 28pt padding = 520pt total |
| Panel height | 303pt |
| Dark background | `Color(white: 0.08)` — opaque dark gray |
| Light background | `Color(white: 0.94)` — opaque light gray |
| Card background (dark) | Pure black |
| Card background (light) | Pure white |
| Corner radius | 22pt (island shape) |
| Typography | System monospaced via `Mono` helper enum |
| Tab bar | Capsule pills with `matchedGeometryEffect` transition |
| Accent color | Dark green `(0.05, 0.45, 0.25)` |
| Tab switching | Cross-fade with `←` / `→` arrow keys |

## ⌨️ Keyboard Shortcuts

| Shortcut | Context | Action |
|----------|---------|--------|
| `⇧⌘O` | Global | Toggle Island panel |
| `←` / `→` | Panel open | Switch between tabs |
| `↑` / `↓` | Clipboard / Snippets | Navigate items |
| `↩` | Clipboard | Copy selected item + dismiss panel |
| `↩` | Snippets | Copy selected snippet value |
| Single-click | Clipboard row | Select + copy to clipboard |
| Double-click | Snippet row | Edit snippet inline |

## 🔌 Services & Data Sources

| Service | Source | Refresh |
|---------|--------|---------|
| Weather | [Open-Meteo API](https://open-meteo.com/) (free, no key) | Every 15 min |
| Music | MediaRemote private framework via `/usr/bin/swift` | Every 5 sec |
| Clipboard | `NSPasteboard` monitoring | Every 1 sec |
| Calendar | Local `Calendar` + `DateFormatter` | Every 1 sec (clock) |
| Persistence | `~/Library/Application Support/ClausIsland/` (JSON) | On change |

No API keys or external accounts required.

## 📦 Download

Latest release: **[Cisland-1.0.0.dmg](./download/Cisland-1.0.0.dmg)**

See [RELEASES.md](./RELEASES.md) for full changelog and download links.

## 📄 Versioning

See [VERSION.md](./VERSION.md) for semantic versioning policy.

## 📄 License

MIT License — see [LICENSE](./LICENSE) for details.

---

Built with ❤️ using SwiftUI and native macOS APIs.
