import AppKit
import SwiftUI
import Carbon

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    if condition() { print("PASS \(name)") }
    else { failures += 1; print("FAIL \(name)") }
}
let suite = "CursorHalo.Tests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
defaults.set(0.0, forKey: "haloOpacity")
let settings = AppSettings(defaults: defaults)
check(settings.haloOpacity == 0, "saved transparent halo survives reload")
defaults.set(-500.0, forKey: "haloSize")
defaults.set("not a color", forKey: "haloColorHex")
let repaired = AppSettings(defaults: defaults)
check(repaired.haloSize == 20, "corrupt size is bounded")
check(repaired.haloColorHex == "#30D158", "invalid color uses safe default")
settings.apply(.focus)
check(settings.mode == .spotlight && settings.spotlightSize >= 160, "focus preset provides readable spotlight")
settings.apply(.subtle)
check(settings.mode == .halo && settings.haloOpacity <= 0.25, "subtle preset leaves content legible")
settings.haloColorHex = "#112233"
check(AppSettings(defaults: defaults).haloColorHex == "#112233", "custom color persists")
var state = PresentationState()
check(state.isVisible(enabled: true, hideWhenIdle: true, now: 0), "pointer starts visible")
state.recordMovement(at: 1)
check(!state.isVisible(enabled: true, hideWhenIdle: true, now: 4), "idle pointer hides")
state.recordMovement(at: 4)
check(state.isVisible(enabled: true, hideWhenIdle: true, now: 4), "movement restores pointer")
state.locate(at: 5)
check(state.isVisible(enabled: false, hideWhenIdle: true, now: 5.5), "locator works while paused")
check(!state.isVisible(enabled: false, hideWhenIdle: false, now: 7), "locator expires back to paused")
state.locate(at: 8)
state.cancelLocator()
check(!state.isVisible(enabled: false, hideWhenIdle: false, now: 8), "emergency pause cancels locator")
check(PresentationState.allowsDisplay(selected: "all", current: "12"), "automatic follows displays")
check(!PresentationState.allowsDisplay(selected: "99", current: "12"), "unplugged selected display never falls back")
check(PresentationState.allowsDisplay(selected: "12", current: "12"), "selected display works")
defaults.set(Double.nan, forKey: "spotlightSize")
defaults.set(4.0, forKey: "dimOpacity")
defaults.set("Unknown", forKey: "clickEffectType")
defaults.set("Impossible", forKey: "pointerMode")
defaults.set(45.0, forKey: "refreshRate")
let sanitized = AppSettings(defaults: defaults)
check(sanitized.spotlightSize == 220 && sanitized.dimOpacity == 0.8, "nonfinite and excessive spotlight values are safe")
check([30.0, 60.0].contains(sanitized.refreshRate), "stored refresh rate matches a supported choice")
check(sanitized.clickEffectType == "Ripple" && sanitized.mode == .halo, "unknown enum values recover")
settings.reduceMotion = true
check(settings.effectiveReduceMotion, "explicit reduce motion always applies")
let view = HaloOverlayView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
settings.mode = .spotlight
settings.spotlightSize = 200
let center = CGPoint(x: 400, y: 300)
view.render(at: center, style: OverlayStyle(settings))
check(!view.dimLayer.isHidden && !view.haloLayer.isHidden, "spotlight renders both layers")
check(view.dimLayer.path?.contains(center, using: .evenOdd) == false, "spotlight leaves cursor content clear")
check(view.dimLayer.path?.contains(CGPoint(x: 20, y: 20), using: .evenOdd) == true, "spotlight dims surrounding content")
let originalPath = view.haloLayer.path
view.render(at: CGPoint(x: 410, y: 300), style: OverlayStyle(settings))
check(view.haloLayer.path === originalPath, "moving pointer reuses halo geometry")
settings.mode = .halo
view.render(at: center, style: OverlayStyle(settings))
check(view.dimLayer.isHidden, "switching to halo removes dimming")
for _ in 0..<40 { view.pulse(at: center, settings: settings) }
check(view.activeEffectCount <= 10, "rapid clicks have a bounded layer count")
view.hide()
check(view.dimLayer.isHidden && view.haloLayer.isHidden && view.activeEffectCount == 0, "pause clears halo, dimming and transient effects immediately")
view.render(at: center, style: OverlayStyle(settings))
check(!view.haloLayer.isHidden, "resume restores unchanged cached style")
settings.mode = .spotlight
check(!OverlayStyle(settings, locating: true).spotlight, "locator does not unexpectedly dim the screen")
if let screen = NSScreen.screens.first {
    let window = OverlayWindow(screen: screen)
    check(window.ignoresMouseEvents && !window.canBecomeKey && !window.canBecomeMain, "overlay cannot intercept clicks or keyboard focus")
    check(window.localPoint(CGPoint(x: screen.frame.minX + 7, y: screen.frame.minY + 9)) == CGPoint(x: 7, y: 9), "screen coordinates become local coordinates")
    window.close()
    settings.isEnabled = false
    let controller = PresentationController(settings: settings)
    check(!controller.isRendering, "paused controller has no display callbacks")
    controller.toggle()
    check(controller.isRendering, "starting enables display callbacks")
    controller.suppressed = true
    check(!controller.isRendering, "settings panel suspends display callbacks")
    controller.suppressed = false
    check(controller.isRendering, "closing settings resumes active tools")
    controller.pause()
    controller.locate()
    check(!settings.isEnabled && controller.isRendering, "locator temporarily runs without changing saved enabled state")
    RunLoop.main.run(until: Date().addingTimeInterval(1.4))
    check(!controller.isRendering, "expired locator stops display callbacks")
    controller.locate()
    controller.pause()
    check(!controller.isRendering, "emergency pause immediately stops locator callbacks")
    controller.stop()
    check(!controller.isRendering, "controller shutdown releases display link")
}
let previewView = PointerPreviewView(frame: .zero)
previewView.configure(settings: settings, pulseID: 0)
previewView.frame = CGRect(x: 0, y: 0, width: 360, height: 88)
previewView.layout()
check(previewView.haloLayer.position == CGPoint(x: 230.4, y: 44), "preview follows final layout rather than an early zero-size frame")
previewView.frame = CGRect(x: 0, y: 0, width: 400, height: 100)
previewView.layout()
check(previewView.haloLayer.position == CGPoint(x: 256, y: 50), "preview stays centered after layout changes")
let hotKeys = HotKeyManager()
var triggers = 0
let registered = hotKeys.register(id: 99, keyCode: UInt32(kVK_F18)) { triggers += 1 }
check(registered == noErr, "Carbon shortcut registration succeeds")
var hotEvent: EventRef?
CreateEvent(nil, OSType(kEventClassKeyboard), UInt32(kEventHotKeyPressed), 0, EventAttributes(kEventAttributeUserEvent), &hotEvent)
if let hotEvent {
    var identifier = EventHotKeyID(signature: OSType(0x48414c4f), id: 99)
    SetEventParameter(hotEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), MemoryLayout<EventHotKeyID>.size, &identifier)
    SendEventToEventTarget(hotEvent, GetApplicationEventTarget())
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    check(triggers == 1, "Carbon handler dispatches the registered action")
    hotKeys.unregister()
    SendEventToEventTarget(hotEvent, GetApplicationEventTarget())
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    check(triggers == 1, "unregistered shortcuts cannot dispatch an action")
    ReleaseEvent(hotEvent)
} else { check(false, "Carbon event creation succeeds") }
if failures > 0 { exit(1) }
print("All checks passed")
