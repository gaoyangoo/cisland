import SwiftUI

class IslandPanel: NSPanel {

    // MARK: - Initialization

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        setupPanel()
    }

    convenience init() {
        let rect = NSRect(x: 0, y: 0, width: 600, height: 400)
        self.init(contentRect: rect, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)
    }

    // MARK: - Setup

    private func setupPanel() {
        // Panel properties
        level = .floating
        isMovable = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
        hasShadow = true

        // Background appearance
        backgroundColor = NSColor.clear
        isOpaque = false

        // Title bar
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        toolbarStyle = .unified

        // Collection behavior
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Window level is set above with level = .floating
    }

    // MARK: - Override Methods

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }

    // MARK: - Public Methods

    func toggleAlwaysOnTop() {
        if level == .floating {
            level = .normal
        } else {
            level = .floating
        }
    }

    func setAlwaysOnTop(_ onTop: Bool) {
        level = onTop ? .floating : .normal
    }
}