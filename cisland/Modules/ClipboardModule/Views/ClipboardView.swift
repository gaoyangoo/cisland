import SwiftUI

struct ClipboardView: View {
    @StateObject private var clipboardService = ClipboardService()
    @State private var selectedItems: Set<UUID> = []
    @State private var showingClearAlert = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            ScrollView {
                LazyVStack(spacing: 4) {
                    if clipboardService.filteredItems.isEmpty {
                        EmptyStateView(searchTerm: clipboardService.searchTerm)
                    } else {
                        ForEach(clipboardService.filteredItems) { item in
                            ClipboardRow(
                                item: item,
                                isSelected: selectedItems.contains(item.id),
                                onTap: {
                                    clipboardService.copyToClipboard(item)
                                }
                            )
                            .onTapGesture(count: 2) {
                                selectedItems.insert(item.id)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(.controlBackgroundColor))

            footerView
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headerView: some View {
        HStack {
            Text("Clipboard")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button(action: {
                showingClearAlert = true
            }) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
            }
            .help("Clear all clipboard items")
        }
        .alert("Clear Clipboard", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clipboardService.items.removeAll()
                selectedItems.removeAll()
            }
        } message: {
            Text("This will permanently remove all clipboard items. Are you sure?")
        }
    }

    private var footerView: some View {
        HStack {
            Text("\(clipboardService.filteredItems.count) items")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if !selectedItems.isEmpty {
                Text("\(selectedItems.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct EmptyStateView: View {
    let searchTerm: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            if searchTerm.isEmpty {
                Text("No clipboard items yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                Text("No items match \"\(searchTerm)\"")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Text("Copied text will appear here automatically")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}