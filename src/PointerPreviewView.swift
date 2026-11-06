import AppKit

/// SwiftUI can resize a represented view after updateNSView, including through a
/// zero-size intermediate frame. Anchor the preview in AppKit's final layout.
final class PointerPreviewView: HaloOverlayView {
    private var settings: AppSettings?
    private var lastPulseID = 0

    func configure(settings: AppSettings, pulseID: Int) {
        self.settings = settings
        renderPreview()
        if pulseID != lastPulseID {
            lastPulseID = pulseID
            if settings.enableClickPulse { pulse(at: previewPoint, settings: settings) }
        }
        needsLayout = true
    }
    private var previewPoint: CGPoint { CGPoint(x: bounds.width * 0.64, y: bounds.height * 0.5) }
    private func renderPreview() {
        guard let settings, bounds.width > 0, bounds.height > 0 else { return }
        render(at: previewPoint, style: OverlayStyle(settings))
    }
    override func layout() {
        super.layout()
        renderPreview()
    }
}
