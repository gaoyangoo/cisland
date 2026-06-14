import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    var windowController: NSWindowController?
    var statusBarItem: NSStatusItem?
    var hotkey: Hotkey?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupModuleRegistry()
        setupWindow()
        setupStatusBar()
        setupGlobalHotkey()
    }

    private func setupModuleRegistry() {
        // Initialize module registry
        ModuleRegistry.shared.addModule(StatusBarModule())
        ModuleRegistry.shared.addModule(HotkeyModule())
        ModuleRegistry.shared.addModule(WindowModule())
    }

    private func setupWindow() {
        // Find existing window controller from the project
        // In a real implementation, this would be injected or found through the responder chain
        if let window = NSApplication.shared.windows.first {
            window.title = "Claus Island"
            window.center()

            windowController = NSWindowController(window: window)
            windowController?.showWindow(nil)
        }
    }

    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let statusBarItem = statusBarItem else { return }

        statusBarItem.button?.title = "🎄"
        statusBarItem.button?.toolTip = "Claus Island"

        statusBarItem.button?.action = #selector(statusBarButtonClicked)
        statusBarItem.button?.target = self
    }

    @objc private func statusBarButtonClicked() {
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func setupGlobalHotkey() {
        hotkey = Hotkey(key: .o, modifiers: [.command, .shift]) {
            self.windowController?.showWindow(nil)
            self.windowController?.window?.makeKeyAndOrderFront(nil)
        }
        hotkey?.register()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up
        hotkey?.unregister()
    }
}