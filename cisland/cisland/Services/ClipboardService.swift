import Foundation
import AppKit

class ClipboardService: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchTerm: String = ""

    private let pasteboard = NSPasteboard.general
    private let maxItems = 100
    private let storageDirectory: URL
    private let storageFile: URL

    init() {
        self.storageDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClausIsland")
            .appendingPathComponent("Clipboard")

        self.storageFile = storageDirectory.appendingPathComponent("clipboard_items.json")

        setupStorageDirectory()
        loadItems()
        startMonitoring()
    }

    private func setupStorageDirectory() {
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    private func loadItems() {
        guard let data = try? Data(contentsOf: storageFile),
              let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            return
        }
        self.items = items
    }

    private func saveItems() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: storageFile)
    }

    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkClipboard()
        }
    }

    private func checkClipboard() {
        guard let newText = pasteboard.string(forType: .string),
              !newText.isEmpty,
              !items.contains(where: { $0.type == .text && $0.content == newText }) else {
            return
        }

        let newItem = ClipboardItem(
            id: UUID(),
            type: .text,
            content: newText,
            timestamp: Date(),
            preview: String(newText.prefix(50)) + (newText.count > 50 ? "..." : "")
        )

        addItem(newItem)

        if let newImage = pasteboard.data(forType: .tiff) {
            let imageItem = ClipboardItem(
                id: UUID(),
                type: .image,
                content: "Image",
                timestamp: Date(),
                preview: "Image",
                imageData: newImage
            )
            addItem(imageItem)
        }
    }

    private func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            items.removeLast()
        }
        saveItems()
    }

    var filteredItems: [ClipboardItem] {
        if searchTerm.isEmpty {
            return items
        }
        return items.filter { item in
            if item.type == .text {
                return item.content.lowercased().contains(searchTerm.lowercased())
            } else {
                return item.preview.lowercased().contains(searchTerm.lowercased())
            }
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        if item.type == .text {
            pasteboard.clearContents()
            pasteboard.setString(item.content, forType: .string)
        } else if item.type == .image, let imageData = item.imageData {
            pasteboard.clearContents()
            pasteboard.setData(imageData, forType: .tiff)
        }
    }
}

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ClipboardItemType
    let content: String
    let timestamp: Date
    let preview: String
    var imageData: Data?

    enum ClipboardItemType: String, Codable, Hashable {
        case text = "text"
        case image = "image"
    }
}