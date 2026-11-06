import SwiftUI
import AppKit

struct PointerPreview: NSViewRepresentable {
    @ObservedObject var settings: AppSettings
    var pulseID: Int
    func makeNSView(context: Context) -> PointerPreviewView { PointerPreviewView(frame: .zero) }
    func updateNSView(_ view: PointerPreviewView, context: Context) {
        view.configure(settings: settings, pulseID: pulseID)
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    var toggle: () -> Void
    var locate: () -> Void
    @State private var tab = 0
    @State private var previewPulseID = 0
    @State private var screens = NSScreen.screens

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("CursorHalo").font(HaloTheme.title)
                    Text(settings.isEnabled ? "Pointer tools are on" : "Pointer tools are paused")
                        .font(HaloTheme.caption).foregroundStyle(HaloTheme.secondary)
                }
                Spacer()
                Button(action: toggle) {
                    Label(settings.isEnabled ? "Pause" : "Start", systemImage: settings.isEnabled ? "pause.fill" : "play.fill")
                        .frame(minWidth: 62)
                }
                .buttonStyle(.borderedProminent)
                .tint(HaloTheme.primaryAction)
                .help("Toggle pointer tools. Command-Shift-H")
            }
            Button { previewPulseID += 1 } label: { preview }
                .buttonStyle(.plain)
                .help("Test click feedback without leaving settings")
            HStack(spacing: 8) {
                Text("Presets").font(HaloTheme.label)
                Spacer()
                ForEach(PresentationPreset.allCases, id: \.self) { preset in
                    Button(preset.rawValue) { settings.apply(preset) }
                        .help(presetHelp(preset))
                }
            }
            Picker("Settings", selection: $tab) {
                Text("Pointer").tag(0)
                Text("Meeting").tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if tab == 0 { pointerControls } else { meetingControls }
                }
                .padding(.vertical, 2)
                .padding(.trailing, 4)
            }
            .frame(height: 292)
            Divider()
            HStack {
                Button(action: locate) { Label("Locate pointer", systemImage: "scope") }
                    .help("Briefly highlight the pointer. Command-Option-Shift-L")
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            Text("Share your entire screen to include the pointer overlay.")
                .font(HaloTheme.caption)
                .foregroundStyle(HaloTheme.secondary)
        }
        .font(HaloTheme.body)
        .foregroundStyle(HaloTheme.text)
        .tint(HaloTheme.accent)
        .padding(20)
        .frame(width: 400)
        .background(HaloTheme.surface)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screens = NSScreen.screens
        }
    }

    private var preview: some View {
        ZStack(alignment: .leading) {
            HaloTheme.preview
            VStack(alignment: .leading, spacing: 6) {
                Text("Live preview").font(HaloTheme.label)
                Text("Click to test feedback.").font(HaloTheme.caption).foregroundStyle(HaloTheme.secondary)
            }.padding(14)
            PointerPreview(settings: settings, pulseID: previewPulseID).allowsHitTesting(false).accessibilityHidden(true)
            GeometryReader { geometry in
                Image(systemName: "cursorarrow")
                    .font(HaloTheme.cursor)
                    .position(x: geometry.size.width * 0.64 + 6, y: geometry.size.height * 0.5 + 9)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 88)
        .clipShape(RoundedRectangle(cornerRadius: HaloTheme.radius))
        .overlay(RoundedRectangle(cornerRadius: HaloTheme.radius).stroke(HaloTheme.divider, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live preview: \(settings.mode.rawValue), \(Int(settings.haloSize)) point halo, \(Int(settings.haloOpacity * 100)) percent fill. Activate to test click feedback.")
    }

    private var pointerControls: some View {
        Group {
            Picker("Pointer style", selection: $settings.mode) {
                ForEach(PointerMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            slider("Halo size", value: $settings.haloSize, range: 20...300, step: 2, display: "\(Int(settings.haloSize)) pt")
            slider("Fill opacity", value: $settings.haloOpacity, range: 0...1, step: 0.05, display: "\(Int(settings.haloOpacity * 100))%")
            HStack {
                ColorPicker("Halo color", selection: Binding(get: { settings.haloColor }, set: { settings.haloColor = $0 }), supportsOpacity: false)
                Spacer(minLength: 20)
                Toggle("Outline", isOn: $settings.showOutline)
            }
            Divider()
            HStack {
                Toggle("Click feedback", isOn: $settings.enableClickPulse)
                Spacer()
                ColorPicker("Click color", selection: Binding(get: { settings.clickColor }, set: { settings.clickColor = $0 }), supportsOpacity: false)
                    .labelsHidden().accessibilityLabel("Click color")
                    .disabled(!settings.enableClickPulse)
            }
            Group {
                Picker("Click effect", selection: $settings.clickEffectType) {
                    Text("Ripple").tag("Ripple")
                    Text("Double").tag("Double Ripple")
                    Text("Flash").tag("Solid Flash")
                    Text("Target").tag("Focus Target")
                }.pickerStyle(.segmented)
                slider("Click size", value: $settings.clickEffectScale, range: 1.2...3, step: 0.1,
                       display: String(format: "%.1f×", settings.clickEffectScale))
            }.disabled(!settings.enableClickPulse)
        }
    }

    private var meetingControls: some View {
        Group {
            if settings.mode == .spotlight {
                slider("Spotlight size", value: $settings.spotlightSize, range: 100...600, step: 10, display: "\(Int(settings.spotlightSize)) pt")
                slider("Screen dimming", value: $settings.dimOpacity, range: 0.1...0.8, step: 0.05, display: "\(Int(settings.dimOpacity * 100))%")
            }
            Picker("Display", selection: $settings.selectedDisplay) {
                Text("Follow pointer").tag("all")
                ForEach(screens, id: \.displayIdentifier) { screen in
                    Text(screen.localizedName).tag(screen.displayIdentifier)
                }
                if settings.selectedDisplay != "all" && !screens.contains(where: { $0.displayIdentifier == settings.selectedDisplay }) {
                    Text("Selected display disconnected").tag(settings.selectedDisplay)
                }
            }
            Toggle("Hide after 2 seconds idle", isOn: $settings.hideWhenIdle)
            Toggle("Show right clicks as dashed rings", isOn: $settings.rightClickPulse)
                .disabled(!settings.enableClickPulse)
            Toggle("Reduce motion", isOn: $settings.reduceMotion)
                .help("System Reduce Motion is always respected. Click feedback becomes a brief static ring.")
            Picker("Refresh rate", selection: $settings.refreshRate) {
                Text("Efficient (30 fps)").tag(30.0)
                Text("Smooth (60 fps)").tag(60.0)
            }
            Divider()
            VStack(spacing: 7) {
                shortcut("Toggle tools", keys: "⌘ ⇧ H")
                shortcut("Switch spotlight", keys: "⌘ ⌥ ⇧ S")
                shortcut("Locate pointer", keys: "⌘ ⌥ ⇧ L")
                shortcut("Pause all effects", keys: "⌘ ⌥ ⇧ X")
            }
            ForEach(settings.shortcutErrors, id: \.self) { error in
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(HaloTheme.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, display: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(display).monospacedDigit().foregroundStyle(HaloTheme.secondary)
            }
            Slider(value: value, in: range, step: step).accessibilityLabel(title).accessibilityValue(display)
        }
    }
    private func shortcut(_ title: String, keys: String) -> some View {
        HStack { Text(title); Spacer(); Text(keys).foregroundStyle(HaloTheme.secondary) }.font(HaloTheme.caption)
    }
    private func presetHelp(_ preset: PresentationPreset) -> String {
        switch preset {
        case .subtle: return "Small translucent green halo for everyday meetings"
        case .demo: return "Larger yellow halo for screen-sharing demonstrations"
        case .focus: return "Dim the surrounding screen with a clear spotlight"
        }
    }
}
