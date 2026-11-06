import SwiftUI
import AppKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else {
            return "#FF3B30"
        }
        let components = nsColor.cgColor.components ?? [1, 0, 0, 1]
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    func getHSB() -> (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        guard let rgbColor = NSColor(self).usingColorSpace(.deviceRGB) else {
            return (0, 0, 1, 1)
        }
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        rgbColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (Double(h), Double(s), Double(b), Double(a))
    }
}


enum PointerMode: String, CaseIterable { case halo = "Halo", spotlight = "Spotlight" }
enum PresentationPreset: String, CaseIterable { case subtle = "Subtle", demo = "Demo", focus = "Focus" }

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let defaults: UserDefaults
    @Published var isEnabled: Bool { didSet { defaults.set(isEnabled, forKey: "isEnabled") } }
    @Published var haloSize: Double { didSet { defaults.set(haloSize, forKey: "haloSize") } }
    @Published var haloOpacity: Double { didSet { defaults.set(haloOpacity, forKey: "haloOpacity") } }
    @Published var haloColorHex: String { didSet { defaults.set(haloColorHex, forKey: "haloColorHex") } }
    @Published var showOutline: Bool { didSet { defaults.set(showOutline, forKey: "showOutline") } }
    @Published var enableClickPulse: Bool { didSet { defaults.set(enableClickPulse, forKey: "enableClickPulse") } }
    @Published var clickColorHex: String { didSet { defaults.set(clickColorHex, forKey: "clickColorHex") } }
    @Published var clickEffectType: String { didSet { defaults.set(clickEffectType, forKey: "clickEffectType") } }
    @Published var clickEffectScale: Double { didSet { defaults.set(clickEffectScale, forKey: "clickEffectScale") } }
    @Published var spotlightSize: Double { didSet { defaults.set(spotlightSize, forKey: "spotlightSize") } }
    @Published var dimOpacity: Double { didSet { defaults.set(dimOpacity, forKey: "dimOpacity") } }
    @Published var hideWhenIdle: Bool { didSet { defaults.set(hideWhenIdle, forKey: "hideWhenIdle") } }
    @Published var rightClickPulse: Bool { didSet { defaults.set(rightClickPulse, forKey: "rightClickPulse") } }
    @Published var reduceMotion: Bool { didSet { defaults.set(reduceMotion, forKey: "reduceMotion") } }
    @Published var selectedDisplay: String { didSet { defaults.set(selectedDisplay, forKey: "selectedDisplay") } }
    @Published var refreshRate: Double { didSet { defaults.set(refreshRate, forKey: "refreshRate") } }
    @Published var mode: PointerMode { didSet { defaults.set(mode.rawValue, forKey: "pointerMode") } }
    @Published var cursorStyle: CursorStyle { didSet { defaults.set(cursorStyle.rawValue, forKey: "cursorStyle") } }
    @Published var cursorSize: Double { didSet { defaults.set(cursorSize, forKey: "cursorSize") } }
    @Published var cursorColorHex: String { didSet { defaults.set(cursorColorHex, forKey: "cursorColorHex") } }
    @Published var shortcutErrors: [String] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.object(forKey: "isEnabled") as? Bool ?? true
        haloSize = Self.bounded(defaults.object(forKey: "haloSize") as? Double ?? 44, 20...300, fallback: 44)
        haloOpacity = Self.bounded(defaults.object(forKey: "haloOpacity") as? Double ?? 0.22, 0...1, fallback: 0.22)
        haloColorHex = Self.validColor(defaults.object(forKey: "haloColorHex") as? String ?? "#30D158", fallback: "#30D158")
        showOutline = defaults.object(forKey: "showOutline") as? Bool ?? true
        enableClickPulse = defaults.object(forKey: "enableClickPulse") as? Bool ?? true
        clickColorHex = Self.validColor(defaults.object(forKey: "clickColorHex") as? String ?? "#FF9500", fallback: "#FF9500")
        clickEffectType = Self.validEffect(defaults.object(forKey: "clickEffectType") as? String ?? "Ripple")
        clickEffectScale = Self.bounded(defaults.object(forKey: "clickEffectScale") as? Double ?? 1.7, 1.2...3, fallback: 1.7)
        spotlightSize = Self.bounded(defaults.object(forKey: "spotlightSize") as? Double ?? 220, 100...600, fallback: 220)
        dimOpacity = Self.bounded(defaults.object(forKey: "dimOpacity") as? Double ?? 0.45, 0.1...0.8, fallback: 0.45)
        hideWhenIdle = defaults.object(forKey: "hideWhenIdle") as? Bool ?? false
        rightClickPulse = defaults.object(forKey: "rightClickPulse") as? Bool ?? true
        reduceMotion = defaults.object(forKey: "reduceMotion") as? Bool ?? false
        selectedDisplay = defaults.object(forKey: "selectedDisplay") as? String ?? "all"
        refreshRate = defaults.double(forKey: "refreshRate") == 30 ? 30 : 60
        cursorStyle = CursorStyle(rawValue: defaults.string(forKey: "cursorStyle") ?? "") ?? .none
        cursorSize = Self.bounded(defaults.object(forKey: "cursorSize") as? Double ?? 32, 16...80, fallback: 32)
        cursorColorHex = Self.validColor(defaults.string(forKey: "cursorColorHex") ?? "#FF9500", fallback: "#FF9500")
        mode = PointerMode(rawValue: defaults.string(forKey: "pointerMode") ?? "") ?? .halo
    }

    static func bounded(_ value: Double, _ range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : fallback
    }
    static func validColor(_ value: String, fallback: String) -> String {
        // Keep the 3-, 6-, and 8-digit formats supported by version 1.
        let hex = value.hasPrefix("#") ? String(value.dropFirst()) : value
        return [3, 6, 8].contains(hex.count) && hex.allSatisfy(\.isHexDigit) ? "#" + hex : fallback
    }
    static let clickEffects = ["Ripple", "Double Ripple", "Solid Flash", "Focus Target"]
    static func validEffect(_ value: String) -> String { clickEffects.contains(value) ? value : "Ripple" }
    var effectiveReduceMotion: Bool { reduceMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    var haloColor: Color { get { Color(hex: haloColorHex) } set { haloColorHex = newValue.toHex() } }
    var cursorColor: Color { get { Color(hex: cursorColorHex) } set { cursorColorHex = newValue.toHex() } }
    var clickColor: Color { get { Color(hex: clickColorHex) } set { clickColorHex = newValue.toHex() } }

    func apply(_ preset: PresentationPreset) {
        showOutline = true
        enableClickPulse = true
        clickEffectType = "Ripple"
        clickEffectScale = 1.7
        clickColorHex = "#FF9500"
        switch preset {
        case .subtle:
            mode = .halo; haloSize = 40; haloOpacity = 0.16; haloColorHex = "#30D158"
        case .demo:
            mode = .halo; haloSize = 64; haloOpacity = 0.26; haloColorHex = "#FFCC00"
        case .focus:
            mode = .spotlight; haloSize = 44; haloOpacity = 0.12; haloColorHex = "#30D158"
            spotlightSize = 240; dimOpacity = 0.45
        }
    }
}
