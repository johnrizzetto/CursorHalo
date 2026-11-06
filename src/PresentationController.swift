import AppKit
import QuartzCore
import Combine

final class PresentationController: NSObject {
    private let settings: AppSettings
    private var windows: [OverlayWindow] = []
    private var displayLink: CADisplayLink?
    private var settingsObservation: AnyCancellable?
    private var monitors: [Any] = []
    private var state = PresentationState()
    private var locatorExpiry: DispatchWorkItem?
    private var previousPosition: CGPoint?
    var isRendering: Bool { displayLink?.isPaused == false }
    private var sleeping = false
    var suppressed = false { didSet { reconcile() } }

    init(settings: AppSettings = .shared) {
        self.settings = settings
        super.init()
        rebuildWindows()
        settingsObservation = settings.objectWillChange.sink { [weak self] in
            // Published notifications arrive before assignment; read on the next main-loop turn.
            DispatchQueue.main.async { self?.reconcile() }
        }
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] in self?.clicked($0) }) {
            monitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.clicked(event)
            return event
        }) { monitors.append(monitor) }
        NotificationCenter.default.addObserver(self, selector: #selector(rebuildWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
        workspace.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        workspace.addObserver(self, selector: #selector(accessibilityChanged), name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
        state.recordMovement(at: CACurrentMediaTime())
        reconcile()
    }

    @objc private func rebuildWindows() {
        displayLink?.invalidate()
        displayLink = nil
        windows.forEach { $0.overlayView.hide(); $0.close() }
        windows = NSScreen.screens.map { OverlayWindow(screen: $0) }
        // One screen-based link supplies coordinates for all windows, including when none is visible.
        if let screen = NSScreen.screens.first {
            displayLink = screen.displayLink(target: self, selector: #selector(frame))
            displayLink?.isPaused = true
            displayLink?.add(to: .main, forMode: .common)
        }
        reconcile()
    }

    func toggle() {
        if settings.isEnabled { pause() }
        else { settings.isEnabled = true; state.recordMovement(at: CACurrentMediaTime()); reconcile() }
    }
    func pause() {
        locatorExpiry?.cancel()
        locatorExpiry = nil
        state.cancelLocator()
        settings.isEnabled = false
        reconcile()
    }
    func toggleSpotlight() {
        settings.mode = settings.mode == .spotlight ? .halo : .spotlight
        settings.isEnabled = true
        state.recordMovement(at: CACurrentMediaTime())
        reconcile()
    }
    func locate() {
        locatorExpiry?.cancel()
        state.locate(at: CACurrentMediaTime())
        let expiry = DispatchWorkItem { [weak self] in self?.reconcile() }
        locatorExpiry = expiry
        // Expire even when the display stops producing refresh callbacks.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25, execute: expiry)
        reconcile()
    }
    @objc private func willSleep() { sleeping = true; state.cancelLocator(); reconcile() }
    @objc private func didWake() { sleeping = false; state.recordMovement(at: CACurrentMediaTime()); rebuildWindows() }
    @objc private func accessibilityChanged() {
        windows.forEach { $0.overlayView.hide() }
        reconcile()
    }

    private func reconcile() {
        let running = !sleeping && !suppressed && (settings.isEnabled || state.isLocating(at: CACurrentMediaTime()))
        let rate = Float(settings.refreshRate)
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: rate, preferred: rate)
        displayLink?.isPaused = !running
        if running { updateFrame() }
        else { windows.forEach { $0.overlayView.hide(); $0.orderOut(nil) } }
    }
    @objc private func frame(_ link: CADisplayLink) { updateFrame() }

    private func updateFrame() {
        let now = CACurrentMediaTime()
        let position = NSEvent.mouseLocation
        if previousPosition != position {
            previousPosition = position
            state.recordMovement(at: now)
        }
        let locating = state.isLocating(at: now)
        if !settings.isEnabled && !locating { reconcile(); return }
        let visible = state.isVisible(enabled: settings.isEnabled, hideWhenIdle: settings.hideWhenIdle, now: now)
        let style = OverlayStyle(settings, locating: locating)
        for window in windows {
            let eligible = visible && window.screenRef.frame.contains(position)
                && PresentationState.allowsDisplay(selected: settings.selectedDisplay, current: window.screenRef.displayIdentifier)
            if eligible {
                window.overlayView.render(at: window.localPoint(position), style: style)
                if !window.isVisible { window.orderFrontRegardless() }
            } else if window.isVisible {
                window.overlayView.hide()
                window.orderOut(nil)
            }
        }
    }

    private func clicked(_ event: NSEvent) {
        guard settings.isEnabled && !suppressed && !sleeping && settings.enableClickPulse else { return }
        let right = event.type == .rightMouseDown
        guard !right || settings.rightClickPulse else { return }
        state.recordMovement(at: CACurrentMediaTime())
        updateFrame()
        let point = NSEvent.mouseLocation
        for window in windows where window.isVisible && window.screenRef.frame.contains(point) {
            window.overlayView.pulse(at: window.localPoint(point), settings: settings, rightClick: right)
        }
    }

    func stop() {
        locatorExpiry?.cancel()
        locatorExpiry = nil
        displayLink?.invalidate()
        displayLink = nil
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
        windows.forEach { $0.overlayView.hide(); $0.close() }
        windows.removeAll()
        settingsObservation?.cancel()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
