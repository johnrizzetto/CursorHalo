import QuartzCore
import AppKit
import SwiftUI

// MARK: - Halo Overlay Content View
class HaloOverlayView: NSView {
    var haloLayer: CAShapeLayer!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayers() {
        haloLayer = CAShapeLayer()
        haloLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Add subtle shadow for premium styling
        haloLayer.shadowColor = NSColor.black.cgColor
        haloLayer.shadowOpacity = 0.25
        haloLayer.shadowRadius = 4
        haloLayer.shadowOffset = CGSize(width: 0, height: -1)
        
        self.layer?.addSublayer(haloLayer)
    }
    
    func updateHalo(size: CGFloat, colorHex: String, opacity: CGFloat, isEnabled: Bool, isMouseOnScreen: Bool) {
        guard isEnabled && isMouseOnScreen else {
            haloLayer.isHidden = true
            return
        }
        haloLayer.isHidden = false
        
        let radius = size / 2
        let color = NSColor(Color(hex: colorHex)).cgColor
        
        // Redraw circular path if properties change
        let rect = CGRect(x: -radius, y: -radius, width: size, height: size)
        let path = CGPath(ellipseIn: rect, transform: nil)
        haloLayer.path = path
        
        // Filled center and conditional outer border ring
        haloLayer.fillColor = color.copy(alpha: opacity)
        if AppSettings.shared.showOutline {
            haloLayer.strokeColor = color.copy(alpha: 0.9)
            haloLayer.lineWidth = 1.5
        } else {
            haloLayer.strokeColor = nil
            haloLayer.lineWidth = 0
        }
    }
    
    func triggerPulse(at position: CGPoint, size: CGFloat, colorHex: String) {
        let settings = AppSettings.shared
        let effectType = settings.clickEffectType
        let multiplier = CGFloat(settings.clickEffectScale)
        let color = NSColor(Color(hex: colorHex)).cgColor
        
        switch effectType {
        case "Double Ripple":
            createRipple(at: position, size: size, multiplier: multiplier, color: color, delay: 0.0)
            createRipple(at: position, size: size, multiplier: multiplier, color: color, delay: 0.08)
        case "Solid Flash":
            createSolidFlash(at: position, size: size, multiplier: multiplier, color: color)
        case "Focus Target":
            createFocusTarget(at: position, size: size, multiplier: multiplier, color: color)
        default: // "Ripple"
            createRipple(at: position, size: size, multiplier: multiplier, color: color, delay: 0.0)
        }
    }
    
    private func createRipple(at position: CGPoint, size: CGFloat, multiplier: CGFloat, color: CGColor, delay: TimeInterval) {
        let pulse = CAShapeLayer()
        pulse.position = position
        pulse.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let startRadius = size / 2
        let startRect = CGRect(x: -startRadius, y: -startRadius, width: size, height: size)
        pulse.path = CGPath(ellipseIn: startRect, transform: nil)
        
        pulse.fillColor = color.copy(alpha: 0.22)
        pulse.strokeColor = color.copy(alpha: 0.9)
        pulse.lineWidth = 2.0
        
        pulse.shadowColor = color
        pulse.shadowOpacity = 0.3
        pulse.shadowRadius = 6
        pulse.shadowOffset = .zero
        
        self.layer?.addSublayer(pulse)
        
        let targetScale = multiplier
        
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue = targetScale
        scaleAnim.duration = 0.25
        scaleAnim.beginTime = CACurrentMediaTime() + delay
        scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = delay > 0 ? 0.0 : 1.0
        opacityAnim.toValue = 0.0
        opacityAnim.duration = 0.25
        opacityAnim.beginTime = CACurrentMediaTime() + delay
        opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            pulse.removeFromSuperlayer()
        }
        
        pulse.add(scaleAnim, forKey: "scale")
        pulse.add(opacityAnim, forKey: "opacity")
        
        pulse.opacity = 0.0
        pulse.transform = CATransform3DMakeScale(targetScale, targetScale, 1.0)
        
        CATransaction.commit()
    }
    
    private func createSolidFlash(at position: CGPoint, size: CGFloat, multiplier: CGFloat, color: CGColor) {
        let flash = CAShapeLayer()
        flash.position = position
        flash.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let startRadius = size / 2
        let startRect = CGRect(x: -startRadius, y: -startRadius, width: size, height: size)
        flash.path = CGPath(ellipseIn: startRect, transform: nil)
        
        flash.fillColor = color.copy(alpha: 0.6)
        flash.strokeColor = nil
        
        flash.shadowColor = color
        flash.shadowOpacity = 0.5
        flash.shadowRadius = 10
        flash.shadowOffset = .zero
        
        self.layer?.addSublayer(flash)
        
        let targetScale = multiplier
        
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue = targetScale
        scaleAnim.duration = 0.22
        scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 1.0
        opacityAnim.toValue = 0.0
        opacityAnim.duration = 0.22
        opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            flash.removeFromSuperlayer()
        }
        
        flash.add(scaleAnim, forKey: "scale")
        flash.add(opacityAnim, forKey: "opacity")
        
        flash.opacity = 0.0
        flash.transform = CATransform3DMakeScale(targetScale, targetScale, 1.0)
        
        CATransaction.commit()
    }
    
    private func createFocusTarget(at position: CGPoint, size: CGFloat, multiplier: CGFloat, color: CGColor) {
        let target = CAShapeLayer()
        target.position = position
        target.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let startMultiplier = multiplier
        let startSize = size * startMultiplier
        let startRadius = startSize / 2
        let startRect = CGRect(x: -startRadius, y: -startRadius, width: startSize, height: startSize)
        target.path = CGPath(ellipseIn: startRect, transform: nil)
        
        target.fillColor = nil
        target.strokeColor = color.copy(alpha: 0.9)
        target.lineWidth = 1.5
        
        // Target crosshair indicators
        let crossLength: CGFloat = 6.0
        let crossPath = CGMutablePath()
        crossPath.move(to: CGPoint(x: 0, y: startRadius))
        crossPath.addLine(to: CGPoint(x: 0, y: startRadius - crossLength))
        crossPath.move(to: CGPoint(x: 0, y: -startRadius))
        crossPath.addLine(to: CGPoint(x: 0, y: -startRadius + crossLength))
        crossPath.move(to: CGPoint(x: -startRadius, y: 0))
        crossPath.addLine(to: CGPoint(x: -startRadius + crossLength, y: 0))
        crossPath.move(to: CGPoint(x: startRadius, y: 0))
        crossPath.addLine(to: CGPoint(x: startRadius - crossLength, y: 0))
        
        let linesLayer = CAShapeLayer()
        linesLayer.path = crossPath
        linesLayer.strokeColor = color.copy(alpha: 0.8)
        linesLayer.lineWidth = 1.2
        target.addSublayer(linesLayer)
        
        self.layer?.addSublayer(target)
        
        // Shrinks from outer bound inwards
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue = 1.0 / startMultiplier
        scaleAnim.duration = 0.22
        scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0.5
        opacityAnim.toValue = 1.0
        opacityAnim.duration = 0.15
        
        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.fromValue = 1.0
        fadeAnim.toValue = 0.0
        fadeAnim.duration = 0.08
        fadeAnim.beginTime = 0.15
        
        let group = CAAnimationGroup()
        group.animations = [scaleAnim, opacityAnim, fadeAnim]
        group.duration = 0.23
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            target.removeFromSuperlayer()
        }
        
        target.add(group, forKey: "focusGroup")
        
        target.opacity = 0.0
        target.transform = CATransform3DMakeScale(1.0 / startMultiplier, 1.0 / startMultiplier, 1.0)
        
        CATransaction.commit()
    }
}

// MARK: - Transparent Fullscreen Overlay Window
class OverlayWindow: NSPanel {
    let screenRef: NSScreen
    let overlayView: HaloOverlayView
    private var renderLink: CADisplayLink?
    private var wasLeftPressed = false
    
    init(screen: NSScreen) {
        self.screenRef = screen
        self.overlayView = HaloOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Set transparent and click-through properties
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.level = .screenSaver // Renders on top of dock, menu bar, and other apps
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.contentView = overlayView
        
        setupDisplayLink()
    }
    
    private func setupDisplayLink() {
        renderLink = self.displayLink(target: self, selector: #selector(displayLinkFired))
        renderLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func displayLinkFired(_ link: CADisplayLink) {
        let settings = AppSettings.shared
        let mouseLoc = NSEvent.mouseLocation
        
        let screenFrame = screenRef.frame
        let isMouseOnScreen = screenFrame.contains(mouseLoc)
        
        // Convert screen (global, y-up) to window-local coordinates
        let relativeX = mouseLoc.x - screenFrame.minX
        let relativeY = mouseLoc.y - screenFrame.minY
        let mousePos = CGPoint(x: relativeX, y: relativeY)
        
        // Update layer coordinate and styling properties instantly without lagging animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayView.haloLayer.position = mousePos
        overlayView.updateHalo(
            size: CGFloat(settings.haloSize),
            colorHex: settings.haloColorHex,
            opacity: CGFloat(settings.haloOpacity),
            isEnabled: settings.isEnabled,
            isMouseOnScreen: isMouseOnScreen
        )
        CATransaction.commit()
        
        // Edge detection for mouse clicks (left click)
        if settings.isEnabled && isMouseOnScreen {
            let isLeftPressed = (NSEvent.pressedMouseButtons & 1) != 0
            if isLeftPressed && !wasLeftPressed {
                if settings.enableClickPulse {
                    overlayView.triggerPulse(
                        at: mousePos,
                        size: CGFloat(settings.haloSize),
                        colorHex: settings.clickColorHex
                    )
                }
            }
            wasLeftPressed = isLeftPressed
        } else {
            wasLeftPressed = false
        }
    }
    
    func stop() {
        renderLink?.invalidate()
        renderLink = nil
    }
    
    deinit {
        stop()
    }
}
