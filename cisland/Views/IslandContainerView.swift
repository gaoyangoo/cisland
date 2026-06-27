import SwiftUI

// MARK: - Flared-Top Panel Shape

/// A panel shape where the top spans the full width and the body tapers inward
/// via quadratic bezier curves. The contrast between wide top and narrower body
/// creates a subtle "flared opening" silhouette.
private struct FlaredTopShape: Shape {
    /// How much the body is inset from the top edge on each side.
    var bodyInset: CGFloat = 16
    /// Vertical distance over which the bezier transitions from wide top to inset body.
    var flareHeight: CGFloat = 24
    /// Corner radius for the bottom.
    var bottomRadius: CGFloat = 22

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let L = rect.minX, R = rect.maxX
        let T = rect.minY, B = rect.maxY
        let s = bodyInset

        // ── top edge (full width) ──
        p.move(to: CGPoint(x: L, y: T))
        p.addLine(to: CGPoint(x: R, y: T))

        // ── top-right bezier: concave inward ──
        p.addQuadCurve(
            to: CGPoint(x: R - s, y: T + flareHeight),
            control: CGPoint(x: R - s * 0.7, y: T + flareHeight * 0.25)
        )

        // ── right side (inset) ──
        p.addLine(to: CGPoint(x: R - s, y: B - bottomRadius))

        // ── bottom-right corner ──
        p.addQuadCurve(
            to: CGPoint(x: R - s - bottomRadius, y: B),
            control: CGPoint(x: R - s, y: B)
        )

        // ── bottom edge ──
        p.addLine(to: CGPoint(x: L + s + bottomRadius, y: B))

        // ── bottom-left corner ──
        p.addQuadCurve(
            to: CGPoint(x: L + s, y: B - bottomRadius),
            control: CGPoint(x: L + s, y: B)
        )

        // ── left side (inset) ──
        p.addLine(to: CGPoint(x: L + s, y: T + flareHeight))

        // ── top-left bezier: concave inward ──
        p.addQuadCurve(
            to: CGPoint(x: L, y: T),
            control: CGPoint(x: L + s * 0.7, y: T + flareHeight * 0.25)
        )

        p.closeSubpath()
        return p
    }
}

// MARK: - Container

public struct IslandContainerView: View {
    @ObservedObject private var registry = ModuleRegistry.shared
    @State private var isVisible = false
    var onDismiss: (() -> Void)?

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    private static let bodyInset: CGFloat    = 16
    private static let contentWidth: CGFloat = 480 - 16 * 2   // 448

    public var body: some View {
        ExpandedIslandView(onDismiss: onDismiss)
            .frame(width: Self.contentWidth)
            .padding(.top, 6)
            .frame(width: 480)
            .background(
                FlaredTopShape()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .scaleEffect(y: isVisible ? 1 : 0, anchor: .top)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                isVisible = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    isVisible = true
                }
            }
    }
}
