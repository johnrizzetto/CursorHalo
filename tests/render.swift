import AppKit
import SwiftUI

@main
struct RenderPreview {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let suite = "CursorHalo.Render.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        settings.apply(.subtle)
        let host = NSHostingView(rootView: SettingsView(settings: settings, toggle: {}, locate: {}))
        let size = host.fittingSize
        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.appearance = NSAppearance(named: .aqua)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("No bitmap") }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("No PNG") }
        let destination = CommandLine.arguments[1]
        try! data.write(to: URL(fileURLWithPath: destination))
        print("Rendered \(Int(size.width))×\(Int(size.height)) settings preview to \(destination)")
        window.close()
    }
}
