import AppKit
import SwiftUI
import Combine
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var controller: PresentationController!
    private var hotKeys: HotKeyManager!
    private var settingsObservation: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Only one instance should own the shortcuts and screen overlays.
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: "com.johnrizzetto.CursorHalo")
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if let existing = others.first {
            existing.activate(options: [])
            NSApp.terminate(nil)
            return
        }
        NSApp.setActivationPolicy(.accessory)
        controller = PresentationController()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.target = self
            button.action = #selector(togglePopover)
        }
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: SettingsView(
            settings: .shared,
            toggle: { [weak self] in self?.controller.toggle() },
            locate: { [weak self] in
                self?.popover.performClose(nil)
                self?.controller.locate()
            }))
        popover.contentSize = popover.contentViewController?.view.fittingSize ?? NSSize(width: 400, height: 650)
        settingsObservation = AppSettings.shared.$isEnabled.sink { [weak self] enabled in self?.updateIcon(enabled: enabled) }
        registerShortcuts()
        if CommandLine.arguments.contains("--settings") { showPopover() }
    }
    private func updateIcon(enabled: Bool) {
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: enabled ? "circle.circle.fill" : "circle.circle",
                               accessibilityDescription: enabled ? "CursorHalo, on" : "CursorHalo, paused")
        button.image?.isTemplate = true
        button.toolTip = "CursorHalo: \(enabled ? "on" : "paused"). Command-Shift-H to toggle."
    }
    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown { popover.performClose(sender) } else { showPopover() }
    }
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        controller?.suppressed = true
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPopover()
        return true
    }
    private func registerShortcuts() {
        hotKeys = HotKeyManager()
        let entries: [(UInt32, UInt32, String, () -> Void)] = [
            (1, UInt32(kVK_ANSI_H), "⌘⇧H", { [weak self] in self?.controller.toggle() }),
            (2, UInt32(kVK_ANSI_S), "⌘⌥⇧S", { [weak self] in self?.controller.toggleSpotlight() }),
            (3, UInt32(kVK_ANSI_L), "⌘⌥⇧L", { [weak self] in self?.popover.performClose(nil); self?.controller.locate() }),
            (4, UInt32(kVK_ANSI_X), "⌘⌥⇧X", { [weak self] in self?.controller.pause() })
        ]
        for (id, key, label, action) in entries {
            let result = hotKeys.register(id: id, keyCode: key, extraModifiers: id == 1 ? 0 : UInt32(optionKey), action: action)
            if result != noErr {
                AppSettings.shared.shortcutErrors.append(result == eventHotKeyExistsErr
                    ? "\(label) is in use by another app. Use the panel controls."
                    : "\(label) is unavailable (\(result)). Use the panel controls.")
            }
        }
    }
    func popoverShouldClose(_ popover: NSPopover) -> Bool { !(NSApp.keyWindow is NSColorPanel) }
    func popoverWillClose(_ notification: Notification) {
        NSColorPanel.shared.orderOut(nil)
        controller.suppressed = false
    }
    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
        hotKeys?.unregister()
    }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
