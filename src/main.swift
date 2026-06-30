import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var overlayWindows: [OverlayWindow] = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app behaves purely as a menu bar accessory (hides Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupOverlayWindows()
        setupGlobalHotkey()
        
        // React to monitor configuration/layout changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Elegant concentric rings symbol for the CursorHalo menu bar icon
            if let image = NSImage(systemSymbolName: "circle.circle.fill", accessibilityDescription: "CursorHalo settings") {
                image.isTemplate = true // Responds to light/dark menu bar modes automatically
                button.image = image
            }
            
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Setup SwiftUI settings popover panel
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 380)
        popover.behavior = .transient // Closes automatically when user clicks away
        popover.contentViewController = NSHostingController(rootView: SettingsView())
        popover.delegate = self
        self.popover = popover
    }
    
    private func setupOverlayWindows() {
        // Clear any active screens to avoid memory leaks
        for window in overlayWindows {
            window.stop()
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        
        // Create an overlay window for every active display screen
        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }
    }
    
    @objc private func screensDidChange(_ notification: Notification) {
        // Recalculate overlay window coordinates to support monitor hotplugging/resolution modifications
        setupOverlayWindows()
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Force window focus to ensure controls respond immediately to user clicks
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    private func setupGlobalHotkey() {
        // Setup global hotkey: Cmd + Shift + H
        // Virtual Key Code: 'H' is 4 in Carbon Virtual Key Codes
        let keyCode: UInt32 = 4
        // Modifier Flags: cmdKey (0x0100) | shiftKey (0x0200) -> 768
        let modifiers = UInt32(cmdKey | shiftKey)
        
        HotKeyManager.shared.register(keyCode: keyCode, modifiers: modifiers)
        HotKeyManager.shared.onTrigger = {
            // Toggles active state globally via AppSettings
            AppSettings.shared.isEnabled.toggle()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup loop resources
        for window in overlayWindows {
            window.stop()
        }
        HotKeyManager.shared.unregister()
    }
    
    // MARK: - NSPopoverDelegate methods to allow ColorPicker interaction
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        // Prevent closing the popover when clicking inside the system Color Panel
        if let keyWindow = NSApp.keyWindow, keyWindow is NSColorPanel {
            return false
        }
        return true
    }
    
    func popoverWillClose(_ notification: Notification) {
        // Dismiss the color panel along with the popover
        NSColorPanel.shared.orderOut(nil)
    }
}

// MARK: - App Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
