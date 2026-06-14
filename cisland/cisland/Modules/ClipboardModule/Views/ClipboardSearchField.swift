import SwiftUI

struct ClipboardSearchField: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.placeholderString = "Search clipboard items..."
        searchField.delegate = context.coordinator
        searchField.sizeToFit()
        return searchField
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        private let parent: ClipboardSearchField

        init(_ parent: ClipboardSearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let searchField = obj.object as? NSSearchField else { return }
            parent.text = searchField.stringValue
        }
    }
}

extension ClipboardSearchField {
    func frame(width: CGFloat) -> some View {
        self
            .frame(width: width)
    }
}