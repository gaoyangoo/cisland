import SwiftUI
import AppKit

// MARK: - Data Model

struct KeyValueItem: Identifiable, Codable {
    let id: UUID
    let key: String
    let value: String
    let icon: String

    init(key: String, value: String, icon: String = "doc.on.doc") {
        self.id = UUID()
        self.key = key
        self.value = value
        self.icon = icon
    }
}

// MARK: - Module

@MainActor
public final class KeyValueModule: ObservableObject, IslandModule {
    public var id: String { "keyvalue" }
    public var displayName: String { "Snippets" }
    public var tabIcon: String { "list.clipboard" }
    public var accentColor: Color { Color(red: 0.35, green: 0.55, blue: 0.85) }
    public var expandedHeight: CGFloat { 400 }

    public var expandedView: AnyView {
        AnyView(KeyValueContentView())
    }

    public init() {}

    public func initialize() {}

    /// Default snippets - can be persisted later
    static let defaultItems: [KeyValueItem] = [
        KeyValueItem(key: "Email", value: "hello@example.com", icon: "envelope"),
        KeyValueItem(key: "Phone", value: "+86 138-0000-0000", icon: "phone"),
        KeyValueItem(key: "Address", value: "北京市朝阳区xxx路xx号", icon: "house"),
        KeyValueItem(key: "WeChat", value: "my_wechat_id", icon: "message"),
        KeyValueItem(key: "GitHub", value: "github.com/username", icon: "link"),
        KeyValueItem(key: "Bank Card", value: "6222 **** **** 1234", icon: "creditcard"),
        KeyValueItem(key: "ID Number", value: "110101 **** **** 1234", icon: "person.text.rectangle"),
    ]
}

// MARK: - Content View

struct KeyValueContentView: View {
    @State private var items: [KeyValueItem] = KeyValueModule.defaultItems
    @State private var copiedID: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(items) { item in
                    kvRow(item)
                }
            }
            .padding(12)
        }
    }

    private func kvRow(_ item: KeyValueItem) -> some View {
        Button(action: { copy(item) }) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue.opacity(0.7))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.key)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                    Text(item.value)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer()

                if copiedID == item.id {
                    Text("Copied!")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func copy(_ item: KeyValueItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.value, forType: .string)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedID = item.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { copiedID = nil }
        }
    }
}
