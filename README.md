# 🍉 Claus Island

> A macOS Dynamic Island-style floating utility panel built with SwiftUI.

Claus Island is a lightweight, always-accessible floating panel that lives below your menu bar. It provides quick access to Music, Calendar, Weather, Clipboard history, and editable Snippets — all through a beautifully animated tabbed interface.

## ✨ Features

| Module | Description |
|--------|-------------|
| 🎵 **Music** | Now-playing track info with artist, album art, and playback state |
| 📅 **Calendar** | Weekly date strip with today highlight + real-time gradient clock |
| ☀️ **Weather** | Live temperature and conditions via Open-Meteo API with CoreLocation |
| 📋 **Clipboard** | History with search, text + image support, arrow-key navigation, JSON persistence |
| 📝 **Snippets** | Editable key-value entries — single-click to copy, double-click to edit |
| ⌨️ **Global Hotkey** | Toggle the panel from anywhere with `⇧⌘O` |
| 🎨 **Dark UI** | Frosted glass material, monospaced typography, matchedGeometryEffect animations |

## 🚀 Quick Start

### Requirements

- macOS 14.0+
- Xcode 16+ (Swift 5.10)

### Build & Run

```bash
git clone https://github.com/gaoyangoo/cisland.git
cd cisland
open cisland.xcodeproj   # ⌘R to build and run
```

The app runs as a menu bar accessory — look for the 🍉 icon in your status bar, or press `⇧⌘O` to toggle the panel. No Dock icon, no clutter.

## 🏗️ Architecture

Claus Island uses a **plugin-based module architecture**. Each feature implements the `IslandModule` protocol and is registered with `ModuleRegistry` at startup.

```
┌──────────────────────────────────────────────────┐
│                   AppDelegate                     │
│        (🍉 menu bar icon, ⌘⇧O global hotkey)      │
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
│   └── DynamicIslandApp.swift         # @main SwiftUI entry point
├── Core/
│   ├── IslandModule.swift             # Module protocol definition
│   ├── ModuleRegistry.swift           # ObservableObject singleton registry
│   ├── Hotkey.swift                   # Carbon RegisterEventHotKey implementation
│   └── Notifications.swift            # Inter-module notification names
├── Models/
│   ├── ClipboardItem.swift            # Text + image clipboard content (Codable)
│   └── IslandSize.swift               # Size enum (small / medium / large)
├── Modules/
│   ├── InfoModule/InfoModule.swift    # Dashboard: Music + Calendar + Weather cards
│   ├── ClipboardModule/               # Clipboard history with search
│   └── KeyValueModule/                # Editable key-value snippets
├── Services/
│   ├── WeatherService.swift           # Open-Meteo API + CoreLocation
│   ├── MusicService.swift             # AppleScript nowplaying polling
│   ├── ClipboardService.swift         # Pasteboard monitoring + JSON persistence
│   └── CalendarService.swift          # Calendar data with periodic refresh
├── Views/
│   ├── IslandContainerView.swift      # Root container, frosted glass background
│   ├── ExpandedIslandView.swift       # Main panel: tab bar + content + all card views
│   ├── CompactView.swift              # Compact module display
│   ├── TabBarView.swift               # Module tab switcher
│   ├── IslandShape.swift              # Custom Dynamic Island shape
│   ├── IslandBackgroundStyle.swift    # Background material options (glass/dark/light)
│   └── ModuleIcon.swift               # Tab icon with active indicator
└── Assets.xcassets/                   # App icon and asset catalog
```

## 🎨 Visual Design

| Property | Value |
|----------|-------|
| Panel width | 480pt |
| Panel height | 290pt (fixed) |
| Background | `.ultraThinMaterial` in dark color scheme |
| Corner radius | 22pt |
| Typography | System monospaced via `Mono` helper enum |
| Tab bar | Capsule pills with `matchedGeometryEffect` transition |
| Accent color | Dark green `(0.05, 0.45, 0.25)` |
| Tab switching | Cross-fade with `←` / `→` arrow keys |

## ⌨️ Keyboard Shortcuts

| Shortcut | Context | Action |
|----------|---------|--------|
| `⇧⌘O` | Global | Toggle Island panel |
| `←` / `→` | Panel open | Switch between tabs |
| `↑` / `↓` | Clipboard tab | Navigate clipboard items |
| `↩` | Snippets tab | Submit new snippet |
| Single-click | Snippets tab | Copy snippet value to clipboard |
| Double-click | Snippets tab | Edit snippet inline |

## 🔌 Services & Data Sources

| Service | Source | Refresh |
|---------|--------|---------|
| Weather | [Open-Meteo API](https://open-meteo.com/) (free, no key) | Every 15 min |
| Music | Local AppleScript via `osascript` | Every 10 sec |
| Clipboard | `NSPasteboard` monitoring | Every 1 sec |
| Calendar | Local `Calendar` + `DateFormatter` | Every 1 sec (clock) |
| Persistence | `~/Library/Application Support/ClausIsland/` (JSON) | On change |

No API keys or external accounts required.

## 📄 License

MIT License — see [LICENSE](./LICENSE) for details.

---

Built with ❤️ using SwiftUI and native macOS APIs.
