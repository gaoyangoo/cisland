import SwiftUI

/// Dynamic Island shape — the top-left and top-right corners first
/// extend outward, then curve inward (concave) to meet the body.
/// Overall width 480 pt; ears are 18 pt each side.
struct IslandShape: Shape {
    let cornerRadius: CGFloat = 22
    let earWidth: CGFloat = 8
    let earHeight: CGFloat = 36

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let r = cornerRadius
        let ew = earWidth
        let eh = earHeight
        let bl = ew                     // body left edge  = 18
        let br = w - ew                 // body right edge = 462

        // ── Left ear: tip at x=0, concave curve into body ──
        p.move(to: CGPoint(x: 0, y: 0))

        // Pull control inside body so the curve dips inward
        p.addQuadCurve(
            to: CGPoint(x: bl, y: eh),
            control: CGPoint(x: bl + 2, y: eh * 0.35)
        )

        // ── Left side ──
        p.addLine(to: CGPoint(x: bl, y: h - r))

        // ── Bottom-left corner ──
        p.addArc(center: CGPoint(x: bl + r, y: h - r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(90),
                 clockwise: true)

        // ── Bottom edge ──
        p.addLine(to: CGPoint(x: br - r, y: h))

        // ── Bottom-right corner ──
        p.addArc(center: CGPoint(x: br - r, y: h - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(0),
                 clockwise: true)

        // ── Right side ──
        p.addLine(to: CGPoint(x: br, y: eh))

        // ── Right ear: concave curve to outer tip ──
        p.addQuadCurve(
            to: CGPoint(x: w, y: 0),
            control: CGPoint(x: br - 2, y: eh * 0.35)
        )

        // ── Top edge ──
        p.addLine(to: CGPoint(x: 0, y: 0))

        p.closeSubpath()
        return p
    }
}
