import Foundation
import AppKit

class ClipboardService: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchTerm: String = ""

    static let shared = ClipboardService()

    private let pasteboard = NSPasteboard.general
    private let maxItems = 100
    private let storageDirectory: URL
    private let storageFile: URL
    private var monitorTimer: Timer?
    private var isMonitoring = false

    private init() {
        self.storageDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClausIsland")
            .appendingPathComponent("Clipboard")

        self.storageFile = storageDirectory.appendingPathComponent("clipboard_items.json")

        setupStorageDirectory()
        loadItems()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
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
        guard !isMonitoring else { return }
        isMonitoring = true
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func checkClipboard() {
        // Check for text content
        if let newText = pasteboard.string(forType: .string),
           !newText.isEmpty,
           !items.contains(where: { item in
               if case .text(let existingText) = item.content {
                   return existingText == newText
               }
               return false
           }) {
            let newItem = ClipboardItem(content: .text(newText))
            addItem(newItem)
        }

        // Check for image content
        if let newImage = pasteboard.data(forType: .tiff),
           !items.contains(where: { item in
               if case .image(let existingData) = item.content {
                   return existingData == newImage
               }
               return false
           }) {
            let imageItem = ClipboardItem(content: .image(newImage))
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
            switch item.content {
            case .text(let text):
                return text.lowercased().contains(searchTerm.lowercased())
            case .image:
                return false
            }
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let data):
            pasteboard.setData(data, forType: .tiff)
        }
    }
}
