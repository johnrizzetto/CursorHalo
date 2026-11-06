import AppKit
import QuartzCore
import SwiftUI

struct OverlayStyle: Equatable {
    let size: CGFloat
    let opacity: CGFloat
    let color: String
    let outline: Bool
    let spotlight: Bool
    let spotlightSize: CGFloat
    let dimOpacity: CGFloat

    init(_ settings: AppSettings, locating: Bool = false) {
        size = locating ? max(100, settings.haloSize) : settings.haloSize
        opacity = locating ? 0.15 : settings.haloOpacity
        color = settings.haloColorHex
        outline = locating || settings.showOutline
        spotlight = settings.mode == .spotlight && !locating
        spotlightSize = settings.spotlightSize
        dimOpacity = settings.dimOpacity
    }
}

/// Layer geometry is rebuilt only when style, position or viewport changes.
class HaloOverlayView: NSView {
    let haloLayer = CAShapeLayer()
    let dimLayer = CAShapeLayer()
    private let effectsLayer = CALayer()
    private var cachedStyle: OverlayStyle?
    private var cachedPosition: CGPoint?
    private var cachedBounds: CGRect?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.addSublayer(dimLayer)
        layer?.addSublayer(haloLayer)
        layer?.addSublayer(effectsLayer)
        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = NSColor.black.cgColor
        haloLayer.lineWidth = 2
        // A dark outer edge keeps bright rings readable on white documents.
        haloLayer.shadowColor = NSColor.black.cgColor
        haloLayer.shadowOpacity = 0.35
        haloLayer.shadowRadius = 1
        haloLayer.shadowOffset = .zero
        hide()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func render(at position: CGPoint, style: OverlayStyle) {
        let styleChanged = cachedStyle != style
        let positionChanged = cachedPosition != position
        let boundsChanged = cachedBounds != bounds
        guard styleChanged || positionChanged || boundsChanged || haloLayer.isHidden else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        haloLayer.isHidden = false
        haloLayer.position = position
        dimLayer.isHidden = !style.spotlight
        if styleChanged {
            let color = NSColor(Color(hex: style.color)).cgColor
            haloLayer.path = CGPath(ellipseIn: CGRect(x: -style.size / 2, y: -style.size / 2,
                                                    width: style.size, height: style.size), transform: nil)
            haloLayer.fillColor = color.copy(alpha: style.opacity)
            haloLayer.strokeColor = style.outline ? color.copy(alpha: 1) : nil
            haloLayer.shadowPath = haloLayer.path
            dimLayer.opacity = Float(style.dimOpacity)
        }
        if style.spotlight && (styleChanged || positionChanged || boundsChanged) {
            let path = CGMutablePath()
            path.addRect(bounds)
            let diameter = style.spotlightSize
            path.addEllipse(in: CGRect(x: position.x - diameter / 2, y: position.y - diameter / 2,
                                      width: diameter, height: diameter))
            dimLayer.path = path
        }
        CATransaction.commit()
        cachedStyle = style
        cachedPosition = position
        cachedBounds = bounds
    }

    func hide() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        haloLayer.isHidden = true
        dimLayer.isHidden = true
        effectsLayer.sublayers?.forEach { $0.removeAllAnimations(); $0.removeFromSuperlayer() }
        CATransaction.commit()
    }

    func pulse(at point: CGPoint, settings: AppSettings, rightClick: Bool = false) {
        let color = NSColor(settings.clickColor).cgColor
        let reduced = settings.effectiveReduceMotion
        let count = settings.clickEffectType == "Double Ripple" && !reduced ? 2 : 1
        for index in 0..<count {
            // Bound the number of layers during rapid clicking.
            if (effectsLayer.sublayers?.count ?? 0) >= 10 {
                effectsLayer.sublayers?.first?.removeFromSuperlayer()
            }
            let pulse = CAShapeLayer()
            let diameter = CGFloat(settings.haloSize)
            let radius = diameter / 2
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -radius, y: -radius, width: diameter, height: diameter))
            if settings.clickEffectType == "Focus Target" {
                for sign: CGFloat in [-1, 1] {
                    path.move(to: CGPoint(x: sign * (radius + 8), y: 0))
                    path.addLine(to: CGPoint(x: sign * (radius - 5), y: 0))
                    path.move(to: CGPoint(x: 0, y: sign * (radius + 8)))
                    path.addLine(to: CGPoint(x: 0, y: sign * (radius - 5)))
                }
            }
            pulse.path = path
            pulse.position = point
            pulse.strokeColor = color
            pulse.fillColor = settings.clickEffectType == "Solid Flash" ? color.copy(alpha: 0.35) : nil
            pulse.lineWidth = rightClick ? 3 : 2
            pulse.lineDashPattern = rightClick ? [5, 3] : nil
            effectsLayer.addSublayer(pulse)
            if reduced {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak pulse] in pulse?.removeFromSuperlayer() }
                continue
            }
            let scale = CABasicAnimation(keyPath: "transform.scale")
            let focus = settings.clickEffectType == "Focus Target"
            scale.fromValue = focus ? settings.clickEffectScale : 1
            scale.toValue = focus ? 1 : settings.clickEffectScale
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0
            let group = CAAnimationGroup()
            group.animations = [scale, fade]
            group.duration = 0.32
            group.beginTime = CACurrentMediaTime() + Double(index) * 0.09
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            // Delayed rings stay invisible until their own animation starts.
            pulse.opacity = 0
            pulse.add(group, forKey: "click")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak pulse] in pulse?.removeFromSuperlayer() }
        }
    }
    var activeEffectCount: Int { effectsLayer.sublayers?.count ?? 0 }
}

extension NSScreen {
    var displayIdentifier: String {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.stringValue ?? "unknown"
    }
}

final class OverlayWindow: NSPanel {
    let screenRef: NSScreen
    let overlayView: HaloOverlayView
    init(screen: NSScreen) {
        screenRef = screen
        overlayView = HaloOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        super.init(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        isReleasedWhenClosed = false
        contentView = overlayView
        setAccessibilityElement(false)
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    func localPoint(_ global: CGPoint) -> CGPoint {
        CGPoint(x: global.x - screenRef.frame.minX, y: global.y - screenRef.frame.minY)
    }
}
