# Design: Info Panel Cards, Snippet Persistence & Theme System

**Date:** 2026-06-26
**Project:** cisland (Claus Island) — macOS Dynamic Island-style floating panel

## Overview

Three improvements to the cisland macOS app:

1. Fix uneven card heights in the Info dashboard
2. Persist snippet key-value pairs to disk
3. Add a theme system with Day/Night/Glass modes, accessible via a settings gear

---

## 1. Card Height Fix

### Problem

The three compact cards in `InfoDashboardView` (`MusicCompactCard`, `CalendarCompactCard`, `WeatherCompactCard`) are laid out in an HStack but render at different heights depending on their internal content.

### Solution

Apply a uniform `.frame(height: 140)` to each compact card in the HStack. This ensures identical height regardless of content variation. If a card's content overflows, it is clipped or truncated within the fixed frame.

**File:** `Views/ExpandedIslandView.swift`
**Change:** Add `.frame(height: 140)` to `MusicCompactCard`, `CalendarCompactCard`, and `WeatherCompactCard` in `InfoDashboardView`.

---

## 2. Snippet Persistence — `SnippetStore`

### Problem

`KeyValueModule` stores `KeyValueItem` items in a local `@State` variable. Items are lost when the app quits or the panel closes.

### Solution

Create a new `SnippetStore` service following the `ClipboardService` pattern:

- **Location:** `Services/SnippetStore.swift`
- **Type:** `@MainActor` singleton class conforming to `ObservableObject`
- **Storage:** JSON file at `~/Library/Application Support/ClausIsland/Snippets/snippets.json`
- **Model:** Uses the existing `KeyValueItem` struct (already `Codable` & `Identifiable`)
- **Behavior:** Loads all items from disk on init. Saves to disk on every mutation (add, update, delete). Skips save if contents are unchanged.

### API

```swift
@MainActor
final class SnippetStore: ObservableObject {
    static let shared = SnippetStore()

    @Published var items: [KeyValueItem] = []

    func addItem(key: String, value: String)
    func updateItem(id: UUID, key: String, value: String)
    func deleteItem(id: UUID)

    private func loadFromDisk()
    private func saveToDisk()
}
```

### Integration

`KeyValueModule`'s `KeyValueContentView` switches from `@State private var items` to `@ObservedObject private var store = SnippetStore.shared`, reading `store.items` and calling `store.addItem`/`store.updateItem`/`store.deleteItem`.

**Files changed:**
- `Services/SnippetStore.swift` — **new file**
- `Modules/KeyValueModule/KeyValueModule.swift` — switch from `@State` to `SnippetStore`

---

## 3. Theme System — `ThemeManager`

### Problem

The app has no theme system. Colors are hardcoded, `IslandContainerView` forces `.environment(\.colorScheme, .dark)`, and the settings gear button in the tab bar is disabled.

### Solution

Create a `ThemeManager` singleton that:

- Defines three theme modes: **Light** (Day), **Dark** (Night), **Glass** (transparent)
- Persists the user's choice in `UserDefaults`
- Is consumed by `IslandContainerView` to set `colorScheme` and background material
- Is writable via a popover triggered by the settings gear button

### Theme Enum

```swift
enum AppTheme: String, CaseIterable, Codable {
    case light   // Day — force light color scheme
    case dark    // Night — force dark color scheme
    case glass   // Glass — use system color scheme + ultraThinMaterial background
}
```

### Theme Manager

**File:** `Core/ThemeManager.swift`

```swift
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "appTheme"),
           let t = AppTheme(rawValue: raw) {
            theme = t
        } else {
            theme = .dark  // default matches current behavior
        }
    }
}
```

### Settings UI

- **Enable** the existing gear `Image(systemName: "gearshape")` button in the tab bar (remove `.disabled(true)`)
- On tap, present a **popover** anchored to the gear button with three tappable rows:

| Theme | SF Symbol | Description |
|-------|-----------|-------------|
| Light (Day) | `sun.max.fill` | Light appearance |
| Dark (Night) | `moon.fill` | Dark appearance |
| Glass | `circle.lefthalf.filled` | Transparent, follows system |

- The currently selected theme shows a checkmark
- Tapping a row sets `ThemeManager.shared.theme`

### Container Integration

`IslandContainerView` reads `@ObservedObject var themeManager = ThemeManager.shared` and applies:

- **Light/Dark:** `.environment(\.colorScheme, theme == .light ? .light : .dark)` and `.background(theme-specific material)`
- **Glass:** No forced `.colorScheme` (system default) + `.ultraThinMaterial` background (current behavior)

### Files Changed

| File | Action |
|------|--------|
| `Core/ThemeManager.swift` | **New** — theme singleton |
| `Views/ExpandedIslandView.swift` | Enable gear button; add popover with theme picker |
| `Views/IslandContainerView.swift` | Read `ThemeManager` to set color scheme and background |
| `App/AppDelegate.swift` | Pass `ThemeManager` as environment object (or use singleton pattern) |

---

## Summary of All File Changes

| File | Action |
|------|--------|
| `Views/ExpandedIslandView.swift` | Fix card heights + enable gear + theme popover |
| `Services/SnippetStore.swift` | **New** — persistent snippet storage |
| `Core/ThemeManager.swift` | **New** — theme singleton with UserDefaults |
| `Modules/KeyValueModule/KeyValueModule.swift` | Switch `@State items` → `SnippetStore.shared.items` |
| `Views/IslandContainerView.swift` | Apply theme from `ThemeManager` |
| `App/AppDelegate.swift` | Inject `ThemeManager` as environment object |
