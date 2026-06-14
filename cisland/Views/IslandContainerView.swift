import SwiftUI

/// Main container view with compact/expanded states and tap gestures
@MainActor
public struct IslandContainerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("islandBackgroundStyle") private var backgroundStyle: IslandBackground = .glass
    @State private var isExpanded: Bool = false

    private let modules: [any IslandModule]

    public init(modules: [any IslandModule]) {
        self.modules = modules
    }

    public var body: some View {
        ZStack {
            // Background layer
            backgroundLayer

            // Main content layers
            if isExpanded {
                expandedView
            } else {
                compactView
            }
        }
        .frame(width: 300, height: IslandSize.compactHeight)
        .onTapGesture {
            handleTap()
        }
        .gesture(longPressGesture)
        .onAppear {
            setupTapGesture()
        }
        .onChange(of: isExpanded) { _, newValue in
            if newValue {
                handleExpansion()
            }
        }
    }

    // MARK: - Background Layer
    private var backgroundLayer: some View {
        IslandShape()
            .fill(
                backgroundStyle.material
                    .opacity(0.6)
                    .opacity(0.2)
            )
            .background(backgroundStyle.baseColor)
    }

    // MARK: - Compact View
    private var compactView: some View {
        HStack(spacing: 8) {
            // Active module icon
            if let activeModule = modules.first {
                Image(systemName: modules.first?.tabIcon ?? "circle.fill")
                    .frame(width: 24, height: 24)
            }

            // Activity indicators
            HStack(spacing: 4) {
                ForEach(Array(modules.prefix(3).enumerated()), id: \.element) { index, module in
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2, height: 2)
                        .opacity(index == 0 ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: index)
                }
            }

            Spacer()

            // Background style toggle
            Button(action: {
                backgroundStyle = backgroundStyle == .glass ? .dark : .glass
            }) {
                Image(systemName: backgroundStyle == .glass ? "drop.fill" : "circle.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 10))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(spacing: 12) {
            // Header with title and close button
            HStack {
                if let activeModule = modules.first {
                    Text(modules.first?.displayName ?? "Island")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: {
                    isExpanded = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Content from active module
            if let activeModule = modules.first {
                modules.first?.expandedView
                    .padding(.horizontal, 16)
            }

            // Module indicators
            HStack(spacing: 8) {
                ForEach(modules.prefix(3).indices, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? Color.primary : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Gestures and Actions
    private var longPressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if abs(value.translation.height) > 50 {
                    isExpanded = true
                }
            }
    }

    private func handleTap() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }

    private func handleExpansion() {
        // Handle expansion logic here
        print("Island expanded")
    }

    private func setupTapGesture() {
        // Set up additional gesture handling if needed
    }
}