import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    var panel: NSPanel?
    var statusItem: NSStatusItem?
    var hotkey: Hotkey?

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
    }

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

            let rootView = IslandContainerView()
            let hosting = NSHostingView(rootView: rootView)
            hosting.autoresizingMask = [.width, .height]
            p.contentView = hosting
            panel = p
        }

        guard let p = panel, let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let x = screen.visibleFrame.midX - width / 2
        let y = screen.visibleFrame.maxY - 240
        p.setFrame(NSRect(x: x, y: y, width: width, height: 240), display: true)
        p.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupGlobalHotkey() {
        hotkey = Hotkey(key: .o, modifiers: [.command, .shift]) { [weak self] in
            DispatchQueue.main.async { self?.togglePanel() }
        }
        hotkey?.register()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        hotkey?.unregister()
    }
}
