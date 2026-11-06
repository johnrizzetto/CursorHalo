import AppKit

enum CursorStyle: String, CaseIterable {
    case none = "None"
    case laser = "Laser dot"
    case crosshair = "Crosshair"
    case target = "Target ring"
    case star = "Star"
    case heart = "Heart"
    case plane = "Paper plane"

    static let presentation: [CursorStyle] = [.laser, .crosshair, .target]
    static let playful: [CursorStyle] = [.star, .heart, .plane]
    var isPlayful: Bool { Self.playful.contains(self) }
    var isFilled: Bool { ![.none, .crosshair, .target].contains(self) }
    func offset(size: CGFloat) -> CGPoint {
        isPlayful ? CGPoint(x: size / 2 + 12, y: size / 2 + 12) : .zero
    }
}

/// Centered, resolution-independent artwork shared by the picker and overlays.
enum CursorArtwork {
    static func position(for style: CursorStyle, size: CGFloat, at point: CGPoint, in bounds: CGRect) -> CGPoint {
        guard style.isPlayful else { return point }
        let offset = style.offset(size: size)
        let margin = size / 2 + 3
        var x = point.x + offset.x
        var y = point.y + offset.y
        if x + margin > bounds.maxX { x = point.x - offset.x }
        if y + margin > bounds.maxY { y = point.y - offset.y }
        x = max(bounds.minX + margin, min(bounds.maxX - margin, x))
        y = max(bounds.minY + margin, min(bounds.maxY - margin, y))
        return CGPoint(x: x, y: y)
    }

    static func path(for style: CursorStyle, size: CGFloat) -> CGPath {
        let p = CGMutablePath()
        switch style {
        case .none: break
        case .laser:
            p.addEllipse(in: CGRect(x: -0.5, y: -0.5, width: 1, height: 1))
        case .crosshair:
            for sign: CGFloat in [-1, 1] {
                p.move(to: CGPoint(x: 0.18 * sign, y: 0))
                p.addLine(to: CGPoint(x: 0.5 * sign, y: 0))
                p.move(to: CGPoint(x: 0, y: 0.18 * sign))
                p.addLine(to: CGPoint(x: 0, y: 0.5 * sign))
            }
        case .target:
            p.addEllipse(in: CGRect(x: -0.5, y: -0.5, width: 1, height: 1))
            p.addEllipse(in: CGRect(x: -0.13, y: -0.13, width: 0.26, height: 0.26))
        case .star:
            for index in 0..<10 {
                let angle = CGFloat.pi / 2 + CGFloat(index) * .pi / 5
                let radius: CGFloat = index.isMultiple(of: 2) ? 0.5 : 0.22
                let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                if index == 0 { p.move(to: point) } else { p.addLine(to: point) }
            }
            p.closeSubpath()
        case .heart:
            p.move(to: CGPoint(x: 0, y: -0.46))
            p.addCurve(to: CGPoint(x: -0.47, y: 0.18), control1: CGPoint(x: -0.12, y: -0.30), control2: CGPoint(x: -0.47, y: -0.08))
            p.addCurve(to: CGPoint(x: 0, y: 0.25), control1: CGPoint(x: -0.47, y: 0.5), control2: CGPoint(x: -0.12, y: 0.5))
            p.addCurve(to: CGPoint(x: 0.47, y: 0.18), control1: CGPoint(x: 0.12, y: 0.5), control2: CGPoint(x: 0.47, y: 0.5))
            p.addCurve(to: CGPoint(x: 0, y: -0.46), control1: CGPoint(x: 0.47, y: -0.08), control2: CGPoint(x: 0.12, y: -0.30))
            p.closeSubpath()
        case .plane:
            p.move(to: CGPoint(x: 0.5, y: 0.5))
            p.addLine(to: CGPoint(x: -0.5, y: 0.16))
            p.addLine(to: CGPoint(x: -0.10, y: -0.08))
            p.addLine(to: CGPoint(x: 0.10, y: -0.5))
            p.closeSubpath()
            p.move(to: CGPoint(x: -0.10, y: -0.08))
            p.addLine(to: CGPoint(x: 0.5, y: 0.5))
        }
        var transform = CGAffineTransform(scaleX: size, y: size)
        return p.copy(using: &transform) ?? p
    }
}
