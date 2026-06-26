# Info Panel Cards, Snippet Persistence & Theme System — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix card heights, persist snippets to JSON, and add a Day/Night/Glass theme system.

**Architecture:** Two new singletons (`SnippetStore`, `ThemeManager`) follow the existing `ClipboardService` pattern. `KeyValueModule` switches from `@State` to `SnippetStore.shared`. `IslandContainerView` reads `ThemeManager.shared` to set color scheme and background. The settings gear in the tab bar activates a popover with theme options.

**Tech Stack:** SwiftUI, AppKit, Combine (Timer), Foundation (FileManager, JSONEncoder/Decoder, UserDefaults)

---

### Task 1: Fix card heights in InfoDashboardView

**Files:**
- Modify: `Views/ExpandedIslandView.swift:106-115`

- [ ] **Step 1: Add `.frame(height: 118)` to each compact card**

Replace the `InfoDashboardView` body:

```swift
struct InfoDashboardView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            MusicCompactCard()
                .frame(height: 118)
            CalendarCompactCard()
                .frame(height: 118)
            WeatherCompactCard()
                .frame(height: 118)
        }
        .padding(6)
        .frame(height: 130)
    }
}
```

The HStack is already constrained to height 130 with 6px padding, so each card gets 118px. This overrides the internal `maxHeight: .infinity` on each card, making all three identical height.

- [ ] **Step 2: Build and verify**

```bash
cd /Users/claus/code/claude_code/cisland && xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 2: Create SnippetStore service

**Files:**
- Create: `Services/SnippetStore.swift`

- [ ] **Step 1: Create the file**

```swift
import Foundation

/// Persistent store for user snippets (key-value pairs).
/// Follows the same singleton + JSON-file pattern as ClipboardService.
@MainActor
final class SnippetStore: ObservableObject {
    @Published var items: [KeyValueItem] = []

    static let shared = SnippetStore()

    private let storageDirectory: URL
    private let storageFile: URL

    private init() {
        self.storageDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClausIsland")
            .appendingPathComponent("Snippets")

        self.storageFile = storageDirectory.appendingPathComponent("snippets.json")

        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        loadFromDisk()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageFile),
              let decoded = try? JSONDecoder().decode([KeyValueItem].self, from: data) else {
            return
        }
        self.items = decoded
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: storageFile)
    }

    // MARK: - Mutations

    func addItem(key: String, value: String) {
        items.append(KeyValueItem(key: key, value: value))
        saveToDisk()
    }

    func updateItem(id: UUID, key: String, value: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].key = key
        items[idx].value = value
        saveToDisk()
    }

    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        saveToDisk()
    }
}
```

Note: `KeyValueItem` is defined in `Modules/KeyValueModule/KeyValueModule.swift` but has no module-scope qualifiers (it's file-private-ish in usage but the struct itself is public by default in Swift). Since it's in the same module target, `SnippetStore` can reference it directly.

- [ ] **Step 2: Build and verify**

```bash
cd /Users/claus/code/claude_code/cisland && xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 3: Integrate SnippetStore into KeyValueModule

**Files:**
- Modify: `Modules/KeyValueModule/KeyValueModule.swift:41-132`

- [ ] **Step 1: Switch from `@State` to `SnippetStore.shared`**

In `KeyValueContentView`, change:
- `@State private var items: [KeyValueItem] = []` → `@ObservedObject private var store = SnippetStore.shared`
- All `items` references → `store.items`
- `addItem()` → call `store.addItem(key:value:)` then clear fields
- `delete(_:)` → `store.deleteItem(id:)`
- Edit commit → `store.updateItem(id:key:value:)`

Full replacement of `KeyValueContentView` (the `EditableSnippetRow` struct stays the same):

```swift
struct KeyValueContentView: View {
    @ObservedObject private var store = SnippetStore.shared
    @State private var newKey: String = ""
    @State private var newValue: String = ""
    @State private var copiedID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Add new snippet input
            HStack(spacing: 6) {
                TextField("Key", text: $newKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)

                TextField("Value", text: $newValue)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .onSubmit { addItem() }

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(newKey.isEmpty || newValue.isEmpty ? .white.opacity(0.2) : .green)
                }
                .buttonStyle(.plain)
                .disabled(newKey.isEmpty || newValue.isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .cornerRadius(8)
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if store.items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "text.insert")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No snippets yet")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach($store.items) { $item in
                            EditableSnippetRow(
                                item: $item,
                                copiedID: $copiedID,
                                onDelete: { delete(item) },
                                onCopy: { copy(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(height: 260)
    }

    private func addItem() {
        let k = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let v = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty, !v.isEmpty else { return }
        store.addItem(key: k, value: v)
        newKey = ""
        newValue = ""
    }

    private func copy(_ item: KeyValueItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.value, forType: .string)
        withAnimation(.easeInOut(duration: 0.2)) { copiedID = item.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { copiedID = nil }
        }
    }

    private func delete(_ item: KeyValueItem) {
        withAnimation(.easeInOut(duration: 0.15)) {
            store.deleteItem(id: item.id)
        }
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
cd /Users/claus/code/claude_code/cisland && xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 4: Create ThemeManager

**Files:**
- Create: `Core/ThemeManager.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI

// MARK: - Theme Enum

enum AppTheme: String, CaseIterable, Codable {
    case light   // Day — force light color scheme
    case dark    // Night — force dark color scheme
    case glass   // Glass — system color scheme + ultraThinMaterial

    var displayName: String {
        switch self {
        case .light: return "Day"
        case .dark:  return "Night"
        case .glass: return "Glass"
        }
    }

    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark:  return "moon.fill"
        case .glass: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Theme Manager

@MainActor
final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        }
    }

    static let shared = ThemeManager()

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "appTheme"),
           let t = AppTheme(rawValue: raw) {
            theme = t
        } else {
            theme = .dark  // default matches current forced-dark behavior
        }
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
cd /Users/claus/code/claude_code/cisland && xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 5: Update IslandContainerView for theming

**Files:**
- Modify: `Views/IslandContainerView.swift`

- [ ] **Step 1: Replace the hardcoded background with theme-aware logic**

```swift
import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    public init() {}

    public var body: some View {
        ExpandedIslandView()
            .frame(width: 480)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(backgroundMaterial)
                    .environment(\.colorScheme, colorScheme)
            )
    }

    private var colorScheme: ColorScheme {
        switch themeManager.theme {
        case .light: return .light
        case .dark:  return .dark
        case .glass: return .dark  // glass defaults to dark appearance but no forced scheme on the material below
        }
    }

    private var backgroundMaterial: some ShapeStyle {
        switch themeManager.theme {
        case .light: return Color.white.opacity(0.15)
        case .dark:  return .ultraThinMaterial
        case .glass: return .ultraThinMaterial
        }
    }
}
```

Wait — for `.glass`, we want to NOT force a color scheme. But `.environment(\.colorScheme, ...)` is a view modifier. The cleanest approach:

Actually, let me use a conditional modifier approach. Since `.environment(\.colorScheme, .dark)` on the *background* only affects the background, not the content. The content (`ExpandedIslandView`) inherits whatever the hosting window provides. Since it's an NSPanel with no window-level color scheme set, it follows the system.

The real approach: apply `.environment(\.colorScheme, ...)` on the `ExpandedIslandView()` itself, not just the background. And for `.glass`, don't force any scheme — let the system decide.

**Corrected version:**

```swift
import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    public init() {}

    public var body: some View {
        ExpandedIslandView()
            .frame(width: 480)
            .environment(\.colorScheme, forcedColorScheme)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(backgroundMaterial)
            )
    }

    /// `nil` for glass — lets the system decide (no forced scheme).
    private var forcedColorScheme: ColorScheme? {
        switch themeManager.theme {
        case .light: return .light
        case .dark:  return .dark
        case .glass: return nil
        }
    }

    private var backgroundMaterial: some ShapeStyle {
        switch themeManager.theme {
        case .light: return .regularMaterial
        case .dark:  return .ultraThinMaterial
        case .glass: return .ultraThinMaterial
        }
    }
}
```

Hmm, `.environment(\.colorScheme, nil)` — does that work? No, `ColorScheme?` isn't how the environment key works. Better approach: conditionally apply the modifier.

```swift
import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    public init() {}

    public var body: some View {
        content
            .frame(width: 480)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(backgroundMaterial)
            )
    }

    @ViewBuilder
    private var content: some View {
        switch themeManager.theme {
        case .light:
            ExpandedIslandView()
                .environment(\.colorScheme, .light)
        case .dark:
            ExpandedIslandView()
                .environment(\.colorScheme, .dark)
        case .glass:
            ExpandedIslandView()
        }
    }

    private var backgroundMaterial: some ShapeStyle {
        switch themeManager.theme {
        case .light: return .regularMaterial
        case .dark:  return .ultraThinMaterial
        case .glass: return .ultraThinMaterial
        }
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
cd /Users/claus/code/claude_code/cisland && xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 6: Enable settings gear + theme popover

**Files:**
- Modify: `Views/ExpandedIslandView.swift:84-91` (gear button), add popover state

- [ ] **Step 1: Add popover state and enable the gear button**

At the top of `ExpandedIslandView`, add:
```swift
@State private var showSettings = false
```

Replace the disabled gear button (lines 84-91) with:

```swift
Button(action: { showSettings.toggle() }) {
    Image(systemName: "gearshape")
        .font(.system(size: 9, weight: .medium))
        .foregroundColor(.white.opacity(0.55))
        .padding(3)
}
.buttonStyle(.plain)
.popover(isPresented: $showSettings, arrowEdge: .bottom) {
    ThemePickerView()
}
```

- [ ] **Step 2: Add the ThemePickerView**

At the end of `Views/ExpandedIslandView.swift`, after the `ClipboardContentView` struct, add:

```swift
// MARK: - Theme Picker

private struct ThemePickerView: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Text("Appearance")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    themeManager.theme = theme
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: theme.iconName)
                            .font(.system(size: 12))
                            .frame(width: 20)
                            .foregroundColor(themeManager.theme == theme ? .accentColor : .primary.opacity(0.6))

                        Text(theme.displayName)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.8))

                        Spacer()

                        if themeManager.theme == theme {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.vertical, 4)
        }
        .frame(width: 160)
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 3: Build and verify**

```bash
cd /Users/claus/code/claude_code/cisland && xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 7: Final build verification

- [ ] **Step 1: Clean build**

```bash
cd /Users/claus/code/claude_code/cisland && xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Debug clean build 2>&1 | tail -10
```

Expected: `** BUILD SUCCEEDED **`
