import Cocoa
import SwiftUI
import Combine

/// NSPanel subclass that allows becoming key window so text fields work.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var panel: FloatingPanel?
    var statusItem: NSStatusItem?
    var hotkey: Hotkey?
    private var arrowMonitor: Any?
    private var themeObserver: AnyCancellable?

    /// Fixed panel height — tall enough for all tabs (Clipboard=290)
    private static let panelHeight: CGFloat = 290

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        ModuleRegistry.shared.addModule(InfoModule())
        ModuleRegistry.shared.addModule(ClipboardModule())
        ModuleRegistry.shared.addModule(KeyValueModule())

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item
        if let button = item.button {
            button.title = "🍉"
            button.target = self
            button.action = #selector(togglePanel)
            button.sendAction(on: [.leftMouseDown])
        }

        setupGlobalHotkey()
        setupArrowKeyMonitor()
        observeTheme()
    }

    // MARK: - Theme

    private func observeTheme() {
        Task { @MainActor in
            themeObserver = ThemeManager.shared.$theme
                .sink { [weak self] theme in
                    guard let panel = self?.panel else { return }
                    let appearance: NSAppearance.Name = (theme == .light) ? .aqua : .darkAqua
                    panel.appearance = NSAppearance(named: appearance)
                }
        }
    }

    // MARK: - Toggle Panel

    @objc func togglePanel() {
        if let p = panel, p.isVisible {
            p.orderOut(nil)
            return
        }
        showPanel()
    }

    private func showPanel() {
        let width: CGFloat = 480

        if panel == nil {
            let p = FloatingPanel(
                contentRect: NSRect(x: 0, y: 0, width: width, height: Self.panelHeight),
                styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.level = .floating
            p.isMovable = false
            p.hidesOnDeactivate = false
            p.hasShadow = false
            p.backgroundColor = .clear
            p.isOpaque = false
            p.titlebarAppearsTransparent = true
            p.titleVisibility = .hidden
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "dark"
            p.appearance = NSAppearance(named: savedTheme == "light" ? .aqua : .darkAqua)

            let rootView = IslandContainerView()
            let hosting = NSHostingView(rootView: rootView)
            hosting.autoresizingMask = [.width, .height]
            p.contentView = hosting
            panel = p
        }

        guard let p = panel, let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let x = screen.visibleFrame.midX - width / 2
        let y = screen.visibleFrame.maxY - Self.panelHeight

        p.setFrame(NSRect(x: x, y: y, width: width, height: Self.panelHeight), display: true)
        p.orderFront(nil)
    }

    // MARK: - Global Hotkey (Shift+Cmd+O)

    private func setupGlobalHotkey() {
        hotkey = Hotkey(key: .o, modifiers: [.command, .shift]) { [weak self] in
            DispatchQueue.main.async { self?.togglePanel() }
        }
        hotkey?.register()
    }

    // MARK: - Arrow Key Monitor (Tab Switching)

    private func setupArrowKeyMonitor() {
        arrowMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.panel?.isVisible == true else { return event }
            let registry = ModuleRegistry.shared
            let count = registry.modules.count
            switch event.keyCode {
            case 123:
                let prev = (registry.activeModuleIndex - 1 + count) % count
                registry.setActiveModule(at: prev)
                return nil
            case 124:
                let next = (registry.activeModuleIndex + 1) % count
                registry.setActiveModule(at: next)
                return nil
            default:
                return event
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        hotkey?.unregister()
        if let m = arrowMonitor { NSEvent.removeMonitor(m) }
    }
}
