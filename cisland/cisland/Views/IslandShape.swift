import SwiftUI

/// Custom Shape that creates the Dynamic Island appearance with top overhang
struct IslandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Define Dynamic Island curve parameters
        let cornerRadius: CGFloat = 12.5
        let overhangWidth: CGFloat = 40
        let overhangHeight: CGFloat = 24

        // Create the main rounded rectangle with top overhang
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addLine(to: CGPoint(x: (rect.width - overhangWidth) / 2, y: cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: (rect.width - overhangWidth) / 2 + overhangWidth, y: cornerRadius),
            control1: CGPoint(x: (rect.width - overhangWidth) / 2 + overhangWidth / 2, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.width, y: cornerRadius))
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
                   radius: cornerRadius,
                   startAngle: Angle(degrees: 90),
                   endAngle: Angle(degrees: 0),
                   clockwise: false)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: Angle(degrees: 0),
                   endAngle: Angle(degrees: 90),
                   clockwise: false)
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height - cornerRadius))
        path.addArc(center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: Angle(degrees: 90),
                   endAngle: Angle(degrees: 180),
                   clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.closeSubpath()

        return path
    }
}