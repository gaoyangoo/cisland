import Foundation
import AppKit

// MARK: - ClipboardContent Enum
enum ClipboardContent: Codable {
    case text(String)
    case image(Data)

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .value)
        case .image(let data):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .value)
            self = .text(text)
        case "image":
            let data = try container.decode(Data.self, forKey: .value)
            self = .image(data)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container,
                                                 debugDescription: "Invalid content type")
        }
    }
}

// MARK: - ClipboardItem Struct
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date

    init(id: UUID = UUID(), content: ClipboardContent, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - ClipboardItem Convenience Methods
extension ClipboardItem {
    var isText: Bool {
        if case .text = content {
            return true
        }
        return false
    }

    var isImage: Bool {
        if case .image = content {
            return true
        }
        return false
    }

    var textContent: String? {
        if case .text(let text) = content {
            return text
        }
        return nil
    }

    var imageData: Data? {
        if case .image(let data) = content {
            return data
        }
        return nil
    }

    var nsImage: NSImage? {
        guard let imageData = imageData else { return nil }
        return NSImage(data: imageData)
    }
}