import AppKit
import Foundation

// MARK: - Size Constants

struct WindowSizeConstants {
    static let defaultWidth: CGFloat = 600
    static let defaultHeight: CGFloat = 400
    static let collapsedHeight: CGFloat = 60
    static let menuBarHeight: CGFloat = 24
    static let standardMargin: CGFloat = 20
    static let animationDuration: TimeInterval = 0.3
    static let shadowRadius: CGFloat = 10
    static let cornerRadius: CGFloat = 8
    static let WindowUtils.defaultDuration: TimeInterval = 0.3
}

// MARK: - Window Configuration

struct WindowConfiguration {
    let size: CGSize
    let position: CGPoint
    let level: NSWindow.Level
    let title: String
    let isMovable: Bool
    let isResizable: Bool
    let hasShadow: Bool
    let backgroundColor: NSColor

    static let `default` = WindowConfiguration(
        size: CGSize(width: WindowSizeConstants.defaultWidth, height: WindowSizeConstants.defaultHeight),
        position: CGPoint(x: WindowSizeConstants.standardMargin, y: WindowSizeConstants.standardMargin),
        level: .floating,
        title: "Island",
        isMovable: true,
        isResizable: true,
        hasShadow: true,
        backgroundColor: NSColor.clear
    )
}

// MARK: - Window Position Utils

struct WindowPosition {
    static func belowMenuBar(on screen: NSScreen = NSScreen.main ?? NSScreen()) -> CGPoint {
        let menuBarHeight: CGFloat = 24
        let yPosition = screen.visibleFrame.maxY - menuBarHeight - WindowSizeConstants.defaultHeight
        return CGPoint(x: screen.visibleFrame.minX + WindowSizeConstants.standardMargin, y: yPosition)
    }

    static func centerOnScreen(size: CGSize, on screen: NSScreen = NSScreen.main ?? NSScreen()) -> CGPoint {
        let x = (screen.visibleFrame.width - size.width) / 2
        let y = (screen.visibleFrame.height - size.height) / 2
        return CGPoint(x: x, y: y)
    }

    static func defaultPosition(size: CGSize) -> CGPoint {
        return CGPoint(x: WindowSizeConstants.standardMargin, y: WindowSizeConstants.standardMargin)
    }
}

// MARK: - Window Animation Utils

class WindowAnimator {
    private let timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    private static let WindowUtils.defaultDuration = WindowSizeConstants.animationDuration

    func animateResize(
        window: NSWindow,
        to newSize: CGSize,
        duration: TimeInterval = WindowUtils.defaultDuration,
        completion: (() -> Void)? = nil
    ) {
        guard let currentWindow = window else { return }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = duration
        NSAnimationContext.current.timingFunction = timingFunction

        currentWindow.animator().setFrame(
            NSRect(
                x: currentWindow.frame.minX,
                y: currentWindow.frame.minY + (currentWindow.frame.height - newSize.height),
                width: newSize.width,
                height: newSize.height
            ),
            display: true,
            animate: true
        )

        NSAnimationContext.endGrouping()

        // Schedule completion callback
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion?()
        }
    }

    func animatePosition(
        window: NSWindow,
        to newPosition: CGPoint,
        duration: TimeInterval = WindowUtils.defaultDuration
    ) {
        guard let currentWindow = window else { return }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = duration
        NSAnimationContext.current.timingFunction = timingFunction

        currentWindow.animator().setFrame(
            NSRect(
                x: newPosition.x,
                y: newPosition.y,
                width: currentWindow.frame.width,
                height: currentWindow.frame.height
            ),
            display: true,
            animate: true
        )

        NSAnimationContext.endGrouping()
    }

    func fadeIn(window: NSWindow, duration: TimeInterval = WindowUtils.defaultDuration) {
        window.alphaValue = 0.0

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = duration
        NSAnimationContext.current.timingFunction = timingFunction

        window.animator().alphaValue = 1.0
        NSAnimationContext.endGrouping()
    }

    func fadeOut(window: NSWindow, duration: TimeInterval = WindowUtils.defaultDuration, completion: (() -> Void)? = nil) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = duration
        NSAnimationContext.current.timingFunction = timingFunction

        window.animator().alphaValue = 0.0
        NSAnimationContext.endGrouping()

        // Schedule completion callback
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion?()
        }
    }
}

// MARK: - Window Management Utils

class WindowManager {
    private static var shared = WindowManager()
    private var openWindows: [String: NSWindow] = [:]
    private var windowAnimator = WindowAnimator()

    static func shared() -> WindowManager {
        return shared
    }

    func registerWindow(identifier: String, window: NSWindow) {
        openWindows[identifier] = window
    }

    func getWindow(identifier: String) -> NSWindow? {
        return openWindows[identifier]
    }

    func unregisterWindow(identifier: String) {
        openWindows.removeValue(forKey: identifier)
    }

    func bringToFront(identifier: String) {
        guard let window = getWindow(identifier: identifier) else { return }
        window.makeKeyAndOrderFront(nil)
    }

    func sendToBack(identifier: String) {
        guard let window = getWindow(identifier: identifier) else { return }
        window.orderOut(nil)
    }

    func toggleVisibility(identifier: String) {
        guard let window = getWindow(identifier: identifier) else { return }

        if window.isVisible {
            sendToBack(identifier: identifier)
        } else {
            bringToFront(identifier: identifier)
        }
    }

    func animateWindow(identifier: String, with animation: (NSWindow) -> Void) {
        guard let window = getWindow(identifier: identifier) else { return }

        animation(window)
    }
}

// MARK: - Window Validation

struct WindowValidator {
    static func validateWindowPosition(_ position: CGPoint, size: CGSize, screen: NSScreen = NSScreen.main ?? NSScreen()) -> Bool {
        let rect = NSRect(x: position.x, y: position.y, width: size.width, height: size.height)
        return screen.visibleFrame.contains(rect)
    }

    static func validateWindowSize(_ size: CGSize) -> Bool {
        return size.width > 0 && size.height > 0
    }

    static func ensureWindowOnScreen(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }

        let windowFrame = window.frame
        let visibleFrame = screen.visibleFrame

        // Check if window is completely outside visible frame
        if !visibleFrame.intersects(windowFrame) {
            // Reposition window to default position
            let newPosition = WindowPosition.defaultPosition(size: windowFrame.size)
            window.setFrame(
                NSRect(x: newPosition.x, y: newPosition.y, width: windowFrame.width, height: windowFrame.height),
                display: true,
                animate: false
            )
        }
    }
}