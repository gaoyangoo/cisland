import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    var panel: NSPanel?
    var statusItem: NSStatusItem?
    var hotkey: Hotkey?
    private var arrowMonitor: Any?
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        ModuleRegistry.shared.addModule(InfoModule())
        ModuleRegistry.shared.addModule(ClipboardModule())
        ModuleRegistry.shared.addModule(KeyValueModule())

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item
        if let button = item.button {
            button.title = "⚡"
            button.target = self
            button.action = #selector(togglePanel)
            button.sendAction(on: [.leftMouseDown])
        }

        setupGlobalHotkey()
        setupArrowKeyMonitor()

        // Resize window when tab changes via click
        cancellable = ModuleRegistry.shared.$activeModuleIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resizePanelIfVisible()
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
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: width, height: 240),
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

            let rootView = IslandContainerView(onHeightChange: { [weak self] h in
                self?.contentHeight = h
                self?.resizePanelIfVisible()
            })
            let hosting = NSHostingView(rootView: rootView)
            hosting.autoresizingMask = [.width, .height]
            p.contentView = hosting
            panel = p
        }

        guard let p = panel, let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let x = screen.visibleFrame.midX - width / 2
        let h = contentHeight
        let y = screen.visibleFrame.maxY - h

        p.setFrame(NSRect(x: x, y: y, width: width, height: h), display: true)
        p.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var contentHeight: CGFloat = 160

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
            case 123: // Left arrow
                let prev = (registry.activeModuleIndex - 1 + count) % count
                registry.setActiveModule(at: prev)
                self.resizePanelIfVisible()
                return nil
            case 124: // Right arrow
                let next = (registry.activeModuleIndex + 1) % count
                registry.setActiveModule(at: next)
                self.resizePanelIfVisible()
                return nil
            default:
                return event
            }
        }
    }

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

    func applicationWillTerminate(_ aNotification: Notification) {
        hotkey?.unregister()
        if let m = arrowMonitor { NSEvent.removeMonitor(m) }
    }
}
