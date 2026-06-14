import SwiftUI

struct ClipboardRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconView
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(item.type == .text ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                )

            contentView

            Spacer()

            copyButton
        }
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            // Could show context menu here
        }
    }

    private var iconView: some View {
        Image(systemName: item.type == .text ? "doc.text.fill" : "photo.fill")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(item.type == .text ? .blue : .green)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.preview)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                Text(item.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if item.type == .text {
                Text(item.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private var copyButton: some View {
        Button(action: onTap) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
        .help("Copy to clipboard")
    }
}

struct ClipboardRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ClipboardRow(
                item: ClipboardItem(
                    id: UUID(),
                    type: .text,
                    content: "This is a sample clipboard item text that demonstrates how the row looks with longer content.",
                    timestamp: Date().addingTimeInterval(-3600),
                    preview: "This is a sample clipboard item..."
                ),
                isSelected: false,
                onTap: {}
            )

            ClipboardRow(
                item: ClipboardItem(
                    id: UUID(),
                    type: .image,
                    content: "Image",
                    timestamp: Date(),
                    preview: "Image preview",
                    imageData: Data()
                ),
                isSelected: true,
                onTap: {}
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
}