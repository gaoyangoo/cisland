import Foundation

/// Persistent store for user snippets (key-value pairs).
/// Follows the same singleton + JSON-file pattern as ClipboardService.
@MainActor
final class SnippetStore: ObservableObject {
    @Published var items: [KeyValueItem] = []

    static let shared = SnippetStore()

    private let storageDirectory: URL
    private let storageFile: URL

    private init() {
        self.storageDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClausIsland")
            .appendingPathComponent("Snippets")

        self.storageFile = storageDirectory.appendingPathComponent("snippets.json")

        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        loadFromDisk()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageFile),
              let decoded = try? JSONDecoder().decode([KeyValueItem].self, from: data) else {
            return
        }
        self.items = decoded
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: storageFile)
    }

    // MARK: - Mutations

    func addItem(key: String, value: String) {
        items.append(KeyValueItem(key: key, value: value))
        saveToDisk()
    }

    func updateItem(id: UUID, key: String, value: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].key = key
        items[idx].value = value
        saveToDisk()
    }

    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        saveToDisk()
    }
}
