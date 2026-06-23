import SwiftUI
import AppKit

// MARK: - Data Model

struct KeyValueItem: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String

    init(key: String, value: String) {
        self.id = UUID()
        self.key = key
        self.value = value
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

    /// Default snippets — empty, user populates via input.
}

// MARK: - Content View

struct KeyValueContentView: View {
    @State private var items: [KeyValueItem] = []
    @State private var newKey: String = ""
    @State private var newValue: String = ""
    @State private var copiedID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Add new snippet input
            HStack(spacing: 6) {
                TextField("Key", text: $newKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)

                TextField("Value", text: $newValue)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .onSubmit { addItem() }

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(newKey.isEmpty || newValue.isEmpty ? .white.opacity(0.2) : .green)
                }
                .buttonStyle(.plain)
                .disabled(newKey.isEmpty || newValue.isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .cornerRadius(8)
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "text.insert")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No snippets yet")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach($items) { $item in
                            EditableSnippetRow(
                                item: $item,
                                copiedID: $copiedID,
                                onDelete: { delete(item) },
                                onCopy: { copy(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(height: 260)
    }

    private func addItem() {
        let k = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let v = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty, !v.isEmpty else { return }
        items.append(KeyValueItem(key: k, value: v))
        newKey = ""
        newValue = ""
    }

    private func copy(_ item: KeyValueItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.value, forType: .string)
        withAnimation(.easeInOut(duration: 0.2)) { copiedID = item.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { copiedID = nil }
        }
    }

    private func delete(_ item: KeyValueItem) {
        withAnimation(.easeInOut(duration: 0.15)) {
            items.removeAll { $0.id == item.id }
        }
    }
}

// MARK: - Editable Row

private struct EditableSnippetRow: View {
    @Binding var item: KeyValueItem
    @Binding var copiedID: UUID?
    let onDelete: () -> Void
    let onCopy: () -> Void

    @State private var editingKey: String = ""
    @State private var editingValue: String = ""
    @State private var isEditing = false
    @FocusState private var focusedField: Field?

    enum Field { case key, value }

    var body: some View {
        HStack(spacing: 8) {
            if isEditing {
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Key", text: $editingKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .focused($focusedField, equals: .key)
                        .onSubmit { focusedField = .value }
                    TextField("Value", text: $editingValue)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .focused($focusedField, equals: .value)
                        .onSubmit { commitEdit() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: commitEdit) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.key)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                    Text(item.value)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    beginEdit()
                }

                if copiedID == item.id {
                    Text("Copied")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.25))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isEditing ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture(count: 1) {
            if !isEditing { onCopy() }
        }
    }

    private func beginEdit() {
        editingKey = item.key
        editingValue = item.value
        isEditing = true
        focusedField = .key
    }

    private func commitEdit() {
        let k = editingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let v = editingValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !k.isEmpty { item.key = k }
        if !v.isEmpty { item.value = v }
        isEditing = false
        focusedField = nil
    }
}
