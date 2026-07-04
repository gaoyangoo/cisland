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
    @ObservedObject private var store = SnippetStore.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var copiedID: UUID?
    @FocusState private var isSearchFocused: Bool
    @State private var selectedID: UUID?
    @State private var showingSheet = false
    @State private var sheetTitle = ""
    @State private var sheetKey = ""
    @State private var sheetValue = ""
    @State private var editingItemID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header with + button
            HStack {
                Spacer()
                Button(action: {
                    sheetTitle = "New Snippet"
                    sheetKey = ""
                    sheetValue = ""
                    editingItemID = nil
                    showingSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingSheet, arrowEdge: .top) {
                    SnippetEditSheet(
                        title: sheetTitle,
                        key: $sheetKey,
                        value: $sheetValue,
                        onSave: {
                            let k = sheetKey.trimmingCharacters(in: .whitespacesAndNewlines)
                            let v = sheetValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !k.isEmpty, !v.isEmpty {
                                if let id = editingItemID {
                                    store.updateItem(id: id, key: k, value: v)
                                } else {
                                    store.addItem(key: k, value: v)
                                }
                            }
                        },
                        onDismiss: { showingSheet = false }
                    )
                    .environment(\.colorScheme, theme.colors.colorScheme)
                    .background(.ultraThinMaterial)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 2)

            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.colors.textMuted)
                TextField("Search snippets...", text: $store.searchTerm)
                    .textFieldStyle(.plain)
                    .font(Mono.regular(10))
                    .foregroundColor(theme.colors.text)
                    .focused($isSearchFocused)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(theme.colors.searchFieldBackground)
            .cornerRadius(6)
            .padding(.top, 4)

            if store.filteredItems.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "text.insert")
                        .font(.system(size: 22))
                        .foregroundColor(theme.colors.emptyIcon)
                    Text("No snippets yet")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(theme.colors.emptyText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(store.filteredItems) { item in
                                EditableSnippetRow(
                                    item: binding(for: item),
                                    copiedID: $copiedID,
                                    isSelected: selectedID == item.id,
                                    onDelete: { delete(item) },
                                    onCopy: { copy(item) },
                                    onUpdate: { store.updateItem(id: item.id, key: item.key, value: item.value) },
                                    onEditRequest: {
                                        sheetTitle = "Edit Snippet"
                                        sheetKey = item.key
                                        sheetValue = item.value
                                        editingItemID = item.id
                                        showingSheet = true
                                    }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .snippetMoveUp)) { _ in
                        moveSelection(.up, proxy: proxy)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .snippetMoveDown)) { _ in
                        moveSelection(.down, proxy: proxy)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .snippetEnter)) { _ in
                        handleEnter()
                    }
                }
            }
        }
        .frame(height: 260)
        .onAppear { autoSelectFirst() }
        .onChange(of: store.filteredItems.map(\.id)) { _ in autoSelectFirst() }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            isSearchFocused = true
        }
    }

    private func autoSelectFirst() {
        let list = store.filteredItems
        if let first = list.first, selectedID == nil || !list.contains(where: { $0.id == selectedID }) {
            selectedID = first.id
        }
    }

    private func binding(for item: KeyValueItem) -> Binding<KeyValueItem> {
        Binding(
            get: { self.store.items.first(where: { $0.id == item.id }) ?? item },
            set: { newValue in
                self.store.updateItem(id: item.id, key: newValue.key, value: newValue.value)
            }
        )
    }

    private func moveSelection(_ direction: MoveCommandDirection, proxy: ScrollViewProxy) {
        let list = store.filteredItems
        guard !list.isEmpty else { return }
        let currentIdx = list.firstIndex(where: { $0.id == selectedID })
        switch direction {
        case .up:
            let next = currentIdx.map { max($0 - 1, 0) } ?? 0
            selectedID = list[next].id
            proxy.scrollTo(selectedID, anchor: .center)
        case .down:
            let next = currentIdx.map { min($0 + 1, list.count - 1) } ?? 0
            selectedID = list[next].id
            proxy.scrollTo(selectedID, anchor: .center)
        default:
            break
        }
    }

    private func handleEnter() {
        guard let id = selectedID,
              let item = store.filteredItems.first(where: { $0.id == id }) else { return }
        copy(item)
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
            store.deleteItem(id: item.id)
        }
    }
}

// MARK: - Editable Row

private struct EditableSnippetRow: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Binding var item: KeyValueItem
    @Binding var copiedID: UUID?
    let isSelected: Bool
    let onDelete: () -> Void
    let onCopy: () -> Void
    let onUpdate: () -> Void
    let onEditRequest: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.key)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(theme.colors.textMuted)
                Text(item.value)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(theme.colors.text)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { onCopy() }

            if copiedID == item.id {
                Text("Copied")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }

            Button(action: onEditRequest) {
                Image(systemName: "pencil")
                    .font(.system(size: 9))
                    .foregroundColor(theme.colors.textMuted)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(theme.colors.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? Color.accentColor.opacity(0.25) : theme.colors.snippetRow)
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
}

// MARK: - Edit sheet (glass background, like theme picker)

private struct SnippetEditSheet: View {
    @ObservedObject private var theme = ThemeManager.shared
    let title: String
    @Binding var key: String
    @Binding var value: String
    let onSave: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(theme.colors.textSecondary)

            TextField("Key", text: $key)
                .textFieldStyle(.plain)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(theme.colors.text)
                .padding(8)
                .background(theme.colors.searchFieldBackground)
                .cornerRadius(6)

            TextField("Value", text: $value)
                .textFieldStyle(.plain)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(theme.colors.text)
                .padding(8)
                .background(theme.colors.searchFieldBackground)
                .cornerRadius(6)

            HStack {
                Button("Cancel") { onDismiss() }
                    .font(.system(size: 10))
                Spacer()
                Button("Save") { onSave(); onDismiss() }
                    .font(.system(size: 10, weight: .semibold))
                    .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
        .environment(\.colorScheme, theme.colors.colorScheme)
    }
}
