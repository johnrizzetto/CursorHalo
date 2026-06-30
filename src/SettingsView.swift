import SwiftUI

// MARK: - Color Hex Helpers
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

// MARK: - App State (Shared Defaults)
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }
    @Published var haloSize: Double {
        didSet { UserDefaults.standard.set(haloSize, forKey: "haloSize") }
    }
    @Published var haloOpacity: Double {
        didSet { UserDefaults.standard.set(haloOpacity, forKey: "haloOpacity") }
    }
    @Published var haloColorHex: String {
        didSet { UserDefaults.standard.set(haloColorHex, forKey: "haloColorHex") }
    }
    @Published var haloColorBrightness: Double {
        didSet { UserDefaults.standard.set(haloColorBrightness, forKey: "haloColorBrightness") }
    }
    @Published var showOutline: Bool {
        didSet { UserDefaults.standard.set(showOutline, forKey: "showOutline") }
    }
    @Published var enableClickPulse: Bool {
        didSet { UserDefaults.standard.set(enableClickPulse, forKey: "enableClickPulse") }
    }
    @Published var clickColorHex: String {
        didSet { UserDefaults.standard.set(clickColorHex, forKey: "clickColorHex") }
    }
    @Published var clickColorBrightness: Double {
        didSet { UserDefaults.standard.set(clickColorBrightness, forKey: "clickColorBrightness") }
    }
    @Published var clickEffectType: String {
        didSet { UserDefaults.standard.set(clickEffectType, forKey: "clickEffectType") }
    }
    @Published var clickEffectScale: Double {
        didSet { UserDefaults.standard.set(clickEffectScale, forKey: "clickEffectScale") }
    }
    
    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "isEnabled") as? Bool ?? true
        self.haloSize = UserDefaults.standard.double(forKey: "haloSize") == 0 ? 44.0 : UserDefaults.standard.double(forKey: "haloSize")
        self.haloOpacity = UserDefaults.standard.double(forKey: "haloOpacity") == 0 ? 0.6 : UserDefaults.standard.double(forKey: "haloOpacity")
        self.haloColorHex = UserDefaults.standard.string(forKey: "haloColorHex") ?? "#30D158"
        self.haloColorBrightness = UserDefaults.standard.object(forKey: "haloColorBrightness") as? Double ?? 1.0
        self.showOutline = UserDefaults.standard.object(forKey: "showOutline") as? Bool ?? true
        self.enableClickPulse = UserDefaults.standard.object(forKey: "enableClickPulse") as? Bool ?? true
        self.clickColorHex = UserDefaults.standard.string(forKey: "clickColorHex") ?? "#FF9500"
        self.clickColorBrightness = UserDefaults.standard.object(forKey: "clickColorBrightness") as? Double ?? 1.0
        self.clickEffectType = UserDefaults.standard.string(forKey: "clickEffectType") as? String ?? "Ripple"
        self.clickEffectScale = UserDefaults.standard.double(forKey: "clickEffectScale") == 0 ? 1.7 : UserDefaults.standard.double(forKey: "clickEffectScale")
    }
    
    var haloColor: Color {
        get { Color(hex: haloColorHex) }
        set { haloColorHex = newValue.toHex() }
    }
    
    var clickColor: Color {
        get { Color(hex: clickColorHex) }
        set { clickColorHex = newValue.toHex() }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    
    @State private var isHaloWheelExpanded: Bool = false
    @State private var isPulseWheelExpanded: Bool = false
    
    let presets = [
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#30D158", // Green
        "#0A84FF", // Blue
        "#BF5AF2", // Purple
        "#FF2D55", // Pink
        "#FF69B4"  // Hot Pink
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("CursorHalo")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Toggle("", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // ScrollView for content to fit all sections beautifully
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Halo Customization Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HALO STYLE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        // Size Slider (up to 300px)
                        VStack(spacing: 4) {
                            HStack {
                                Text("Size")
                                Spacer()
                                Text("\(Int(settings.haloSize)) px")
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                            
                            Slider(value: $settings.haloSize, in: 20...300, step: 2)
                                .tint(settings.haloColor)
                        }
                        
                        // Opacity Slider
                        VStack(spacing: 4) {
                            HStack {
                                Text("Opacity")
                                Spacer()
                                Text("\(Int(settings.haloOpacity * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                            
                            Slider(value: $settings.haloOpacity, in: 0.1...1.0, step: 0.05)
                                .tint(settings.haloColor)
                        }
                        
                        // Color Presets
                        HStack(spacing: 8) {
                            Text("Color")
                                .font(.subheadline)
                            Spacer()
                            
                            HStack(spacing: 6) {
                                ForEach(presets, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 14, height: 14)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: settings.haloColorHex == hex ? 1.5 : 0)
                                        )
                                        .shadow(radius: settings.haloColorHex == hex ? 1 : 0)
                                        .onTapGesture {
                                            settings.haloColorHex = hex
                                            settings.haloColorBrightness = 1.0 // Reset brightness for presets
                                        }
                                }
                            }
                        }
                        
                        // Custom Color Wheel Panel
                        VStack(spacing: 8) {
                            Button(action: {
                                withAnimation {
                                    isHaloWheelExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text("Custom Color Wheel")
                                        .font(.subheadline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(isHaloWheelExpanded ? 90 : 0))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            if isHaloWheelExpanded {
                                HStack(spacing: 16) {
                                    ColorWheelView(
                                        color: Binding(
                                            get: { settings.haloColor },
                                            set: { settings.haloColor = $0 }
                                        ),
                                        brightness: $settings.haloColorBrightness
                                    )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Brightness")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Slider(value: $settings.haloColorBrightness, in: 0.0...1.0, step: 0.05)
                                            .tint(settings.haloColor)
                                    }
                                }
                                .padding(.top, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                        // Show Outline Toggle
                        HStack {
                            Text("Show Outline")
                                .font(.subheadline)
                            Spacer()
                            Toggle("", isOn: $settings.showOutline)
                                .toggleStyle(.switch)
                                .scaleEffect(0.8)
                                .labelsHidden()
                        }
                    }
                    
                    Divider()
                    
                    // Click Effects Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("CLICK EFFECT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("", isOn: $settings.enableClickPulse)
                                .toggleStyle(.switch)
                                .scaleEffect(0.8)
                                .labelsHidden()
                        }
                        
                        if settings.enableClickPulse {
                            // Click Effect Style Selector (Segmented Picker)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Style")
                                    .font(.subheadline)
                                Picker("", selection: $settings.clickEffectType) {
                                    Text("Ripple").tag("Ripple")
                                    Text("Double").tag("Double Ripple")
                                    Text("Flash").tag("Solid Flash")
                                    Text("Focus").tag("Focus Target")
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }
                            
                            // Effect Scale Multiplier Slider
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Effect Scale")
                                    Spacer()
                                    Text(String(format: "%.1fx", settings.clickEffectScale))
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                                
                                Slider(value: $settings.clickEffectScale, in: 1.0...3.0, step: 0.1)
                                    .tint(settings.clickColor)
                            }
                            
                            // Pulse color presets
                            HStack {
                                Text("Pulse Color")
                                    .font(.subheadline)
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    ForEach(presets.prefix(5), id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: settings.clickColorHex == hex ? 1.5 : 0)
                                            )
                                            .shadow(radius: settings.clickColorHex == hex ? 1 : 0)
                                            .onTapGesture {
                                                settings.clickColorHex = hex
                                                settings.clickColorBrightness = 1.0
                                            }
                                    }
                                }
                            }
                            
                            // Pulse Color Wheel Panel
                            VStack(spacing: 8) {
                                Button(action: {
                                    withAnimation {
                                        isPulseWheelExpanded.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text("Custom Pulse Wheel")
                                            .font(.subheadline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .rotationEffect(.degrees(isPulseWheelExpanded ? 90 : 0))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                if isPulseWheelExpanded {
                                    HStack(spacing: 16) {
                                        ColorWheelView(
                                            color: Binding(
                                                get: { settings.clickColor },
                                                set: { settings.clickColor = $0 }
                                            ),
                                            brightness: $settings.clickColorBrightness
                                        )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Brightness")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Slider(value: $settings.clickColorBrightness, in: 0.0...1.0, step: 0.05)
                                                .tint(settings.clickColor)
                                        }
                                    }
                                    .padding(.top, 4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 280) // Restrict scroll area size to fit inside popover
            
            Divider()
            
            // Footer Info & Actions
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.secondary)
                    Text("Shortcut: ⌘ ⇧ H")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit CursorHalo")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(VisualEffectView().ignoresSafeArea())
    }
}

// MARK: - Beautiful Custom Color Wheel View
struct ColorWheelView: View {
    @Binding var color: Color
    @Binding var brightness: Double
    
    @State private var handlePosition: CGPoint = .zero
    let diameter: CGFloat = 80 // Compact size to fit comfortably in popover
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Color Wheel Gradient (mathematically maps sRGB HSB spectrum)
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: .red, location: 0.0),
                                .init(color: .orange, location: 0.083),
                                .init(color: .yellow, location: 0.167),
                                .init(color: .green, location: 0.333),
                                .init(color: Color(red: 0, green: 1, blue: 1), location: 0.5), // Cyan
                                .init(color: .blue, location: 0.667),
                                .init(color: .purple, location: 0.75),
                                .init(color: Color(red: 1, green: 0, blue: 1), location: 0.833), // Magenta
                                .init(color: .red, location: 1.0)
                            ]),
                            center: .center
                        )
                    )
                
                // Saturation Overlay (white center fading out)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.white, .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: diameter / 2
                        )
                    )
                    .blendMode(.screen)
                
                // Brightness shading
                Circle()
                    .fill(Color.black.opacity(1.0 - brightness))
                
                // Selector Handle Indicator
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .shadow(radius: 2)
                    .frame(width: 12, height: 12)
                    .position(handlePosition)
            }
            .contentShape(Circle()) // Ensures the whole circle responds to drag gestures
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateColor(at: value.location, in: geometry.size)
                    }
            )
            .onAppear {
                setHandlePositionFromColor(in: geometry.size)
            }
            .onChange(of: color) { _ in
                setHandlePositionFromColor(in: geometry.size)
            }
            .onChange(of: brightness) { newBrightness in
                // Apply brightness adjustments to the current color hue and saturation
                let hsb = color.getHSB()
                color = Color(hue: hsb.hue, saturation: hsb.saturation, brightness: newBrightness)
            }
        }
        .frame(width: diameter, height: diameter)
    }
    
    private func updateColor(at point: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y // y increases downwards in SwiftUI coordinates
        
        let radius = diameter / 2
        let distance = sqrt(dx*dx + dy*dy)
        let saturation = min(distance / radius, 1.0)
        
        // Clockwise angle calculation matching AngularGradient direction
        var angle = atan2(dy, dx)
        if angle < 0 { angle += 2 * .pi }
        let hue = angle / (2 * .pi)
        
        color = Color(hue: hue, saturation: saturation, brightness: brightness)
        
        let clampedDist = min(distance, radius)
        handlePosition = CGPoint(
            x: center.x + clampedDist * cos(angle),
            y: center.y + clampedDist * sin(angle)
        )
    }
    
    private func setHandlePositionFromColor(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = diameter / 2
        
        let hsb = color.getHSB()
        let angle = hsb.hue * 2 * .pi
        let dist = hsb.saturation * Double(radius)
        
        handlePosition = CGPoint(
            x: center.x + CGFloat(dist * cos(angle)),
            y: center.y + CGFloat(dist * sin(angle))
        )
    }
}

// MARK: - Visual Effect (Vibrancy / Glassmorphism) View
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
