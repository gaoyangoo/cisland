//
//  ClipboardModule.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//
//

import Foundation
import SwiftUI
import AppKit

/// Clipboard module for managing clipboard history and monitoring
@MainActor
public class ClipboardModule: ObservableObject, IslandModule {
    // MARK: - IslandModule Protocol Properties

    @MainActor
    public var id: String { "clipboard" }
    public var displayName: String { "Clipboard" }
    public var tabIcon: String {
        "clipboard.fill"
    }
    public var accentColor: Color {
        Color(red: 0.2, green: 0.6, blue: 0.9)
    }
    public var expandedHeight: CGFloat {
        500
    }

    public var expandedView: AnyView {
        AnyView(body)
    }

    // MARK: - Clipboard Properties

    /// Clipboard items storage
    @Published private var clipboardItems: [ClipboardItem] = []
    /// Maximum number of clipboard items to keep
    private let maxItems = 50
    /// Timer for clipboard monitoring
    private var clipboardMonitor: Timer?

    // MARK: - Initializer

    public init() {}

    // MARK: - Public Interface

    public var body: some View {
        VStack(spacing: 0) {
            moduleHeader()
            contentView()
        }
    }

    /// Initialize the clipboard monitoring
    public func initialize() {
        startClipboardMonitoring()
    }

    /// Stop clipboard monitoring when module is inactive
    public func deinitialize() {
        stopClipboardMonitoring()
    }

    /// Get current clipboard items
    func getClipboardItems() -> [ClipboardItem] {
        return clipboardItems.reversed() // Most recent first
    }

    // MARK: - Private Views

    private func moduleHeader() -> some View {
        ModuleHeaderView(
            title: "Clipboard",
            icon: Image(systemName: tabIcon),
            accentColor: accentColor
        )
    }

    private func contentView() -> some View {
        VStack(spacing: 16) {
            // Clear button
            HStack {
                Spacer()
                Button(action: clearClipboardHistory) {
                    Text("Clear History")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 16)
            }

            // Clipboard items list
            ScrollView {
                LazyVStack(spacing: 8) {
                    if clipboardItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clipboard")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("No clipboard items yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        ForEach(getClipboardItems(), id: \.id) { item in
                            ClipboardItemView(item: item, onDelete: { self.deleteItem($0) })
                        }
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Clipboard Monitoring

    private func startClipboardMonitoring() {
        clipboardMonitor = Timer.scheduledTimer(
            withTimeInterval: 0.5, // Check every 0.5 seconds
            repeats: true
        ) { [weak self] _ in
            self?.checkClipboardContents()
        }
    }

    private func stopClipboardMonitoring() {
        clipboardMonitor?.invalidate()
        clipboardMonitor = nil
    }

    private func checkClipboardContents() {
        let pasteboard = NSPasteboard.general

        // Check for text content
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            addClipboardItem(.text(text))
        }

        // Check for image content
        if let image = pasteboard.data(forType: .tiff), !image.isEmpty {
            addClipboardItem(.image(image))
        }
    }

    // MARK: - Clipboard Management

    private func addClipboardItem(_ content: ClipboardContent) {
        let newItem = ClipboardItem(content: content)

        // Remove duplicate items (check if same content exists)
        clipboardItems.removeAll { existingItem in
            switch (existingItem.content, content) {
            case (.text(let existingText), .text(let newText)):
                return existingText == newText
            case (.image(let existingData), .image(let newData)):
                return existingData == newData
            default:
                return false
            }
        }

        clipboardItems.insert(newItem, at: 0) // Add to beginning

        // Keep only the most recent items
        if clipboardItems.count > maxItems {
            clipboardItems.removeLast(clipboardItems.count - maxItems)
        }
    }

    private func deleteItem(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems.remove(at: index)
        }
    }

    private func clearClipboardHistory() {
        clipboardItems.removeAll()
    }
}

// MARK: - Clipboard Item View
private struct ClipboardItemView: View {
    let item: ClipboardItem
    let onDelete: (ClipboardItem) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon based on content type
            ZStack {
                Circle()
                    .fill(item.isText ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: item.isText ? "doc.text" : "photo")
                    .font(.system(size: 18))
                    .foregroundColor(item.isText ? .blue : .green)
            }

            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                Text(item.isText ? "Text" : "Image")
                    .font(.caption.bold())
                    .foregroundColor(.primary)

                if let text = item.textContent, !text.isEmpty {
                    Text(text)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("Content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic(true)
                }

                Text(item.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Delete button
            Button(action: { onDelete(item) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}


// MARK: - Module Header View
private struct ModuleHeaderView: View {
    let title: String
    let icon: Image
    let accentColor: Color

    var body: some View {
        HStack {
            icon
                .font(.title2)
                .foregroundColor(accentColor)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
    }
}