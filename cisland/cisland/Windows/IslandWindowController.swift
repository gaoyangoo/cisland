import SwiftUI
import AppKit

class IslandWindowController: NSWindowController {

    // MARK: - Properties

    private var isExpanded: Bool = false
    private var isVisible: Bool = false
    private var panel: IslandPanel
    private var contentSize: CGSize = CGSize(width: 600, height: 400)
    private var collapsedHeight: CGFloat = 60

    // Animation properties
    private let animationDuration: TimeInterval = 0.3
    private let timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    // MARK: - Initialization

    init() {
        self.panel = IslandPanel()
        super.init(window: panel)
        setupWindowController()
        setupNotifications()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupWindowController() {
        let rootView = IslandContentView()
        let hostingView = NSHostingView(rootView: rootView)
        window?.contentView = hostingView
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleModuleSwitch),
            name: .moduleSwitched,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVisibilityToggle),
            name: .islandVisibilityToggled,
            object: nil
        )
    }

    // MARK: - Window Management

    func show() {
        guard !isVisible else { return }

        isVisible = true
        window?.orderFront(nil)

        // Position below menu bar
        positionBelowMenuBar()
    }

    func hide() {
        guard isVisible else { return }

        isVisible = false
        window?.orderOut(nil)
    }

    func toggleVisibility() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func expand() {
        guard !isExpanded else { return }

        isExpanded = true
        animateWindowResize(to: contentSize)
    }

    func collapse() {
        guard isExpanded else { return }

        isExpanded = false
        animateWindowResize(to: CGSize(width: contentSize.width, height: collapsedHeight))
    }

    func toggleExpanded() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    // MARK: - Animation

    private func animateWindowResize(to newSize: CGSize) {
        guard let window = window else { return }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = animationDuration
        NSAnimationContext.current.timingFunction = timingFunction

        window.animator().setFrame(
            NSRect(
                x: window.frame.minX,
                y: window.frame.minY + (window.frame.height - newSize.height),
                width: newSize.width,
                height: newSize.height
            ),
            display: true,
            animate: true
        )

        NSAnimationContext.endGrouping()
    }

    // MARK: - Positioning

    private func positionBelowMenuBar() {
        guard let screen = NSScreen.main else { return }
        guard let window = window else { return }

        let menuBarHeight: CGFloat = 24
        let yPosition = screen.visibleFrame.maxY - menuBarHeight - window.frame.height

        window.setFrame(
            NSRect(
                x: screen.visibleFrame.minX + 20,
                y: yPosition,
                width: window.frame.width,
                height: window.frame.height
            ),
            display: true,
            animate: false
        )
    }

    // MARK: - Notification Handlers

    @objc private func handleModuleSwitch(_ notification: Notification) {
        // Handle module switching logic
        if isVisible {
            // Optionally refresh content or update window appearance
        }
    }

    @objc private func handleVisibilityToggle(_ notification: Notification) {
        toggleVisibility()
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Content View (Placeholder)

struct IslandContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Island")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: toggleExpanded) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            // Content
            if isExpanded {
                VStack(spacing: 16) {
                    Text("Island Content")
                        .font(.title2)
                        .fontWeight(.medium)

                    Spacer()
                }
                .padding()
            }
        }
    }

    @State private var isExpanded: Bool = false

    private func toggleExpanded() {
        isExpanded.toggle()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let moduleSwitched = Notification.Name("moduleSwitched")
    static let islandVisibilityToggled = Notification.Name("islandVisibilityToggled")
}