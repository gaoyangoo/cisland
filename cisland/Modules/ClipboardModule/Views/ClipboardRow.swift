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
                        .fill(item.isText ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                )

            contentView

            Spacer()

            copyButton
        }
        .background(isSelected ? Color(red: 0.027, green: 0.757, blue: 0.376).opacity(0.15) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }

    private var iconView: some View {
        Image(systemName: item.isText ? "doc.text.fill" : "photo.fill")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(item.isText ? .blue : .green)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.isText ? "Text" : "Image")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                Text(item.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if case .text(let text) = item.content {
                Text(text)
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
                    content: .text("This is a sample clipboard item text that demonstrates how the row looks with longer content.")
                ),
                isSelected: false,
                onTap: {}
            )

            ClipboardRow(
                item: ClipboardItem(
                    content: .image(Data())
                ),
                isSelected: true,
                onTap: {}
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
