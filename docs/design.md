# CursorHalo presentation upgrade

## Purpose and scope
Keep the native macOS 14+ menu bar app and its zero-dependency build. Improve pointer visibility during meetings with presets, a dimmed spotlight, a temporary locator, display selection, idle hiding, reliable mouse click feedback, and global shortcuts. Preserve existing saved appearance preferences. No keystroke capture or drawing in this version.

## Hallmark design direction
Native adaptation of Hallmark 2.0: a compact workbench with a live pointer preview as its signature. Use system typography, semantic surfaces, one green accent, sentence-case labels, native keyboard-focus states and accessible controls. Support light/dark appearances and Reduce Motion. Web-only CSS, theme scaffolds and sloplint rendering do not apply to AppKit/SwiftUI.

The existing tiny color targets, custom drag-only color wheel and nested scroll controls become native color pickers and labeled controls. Keep the four click effects, colors, outline, scale, and Cmd+Shift+H. Edit all four existing Swift source files and build.sh. Add Settings.swift, PresentationState.swift, PresentationController.swift, Theme.swift, PointerPreviewView.swift, tests and CI. Delete no source files.

## Architecture
AppSettings owns persisted user preferences with bounded values and legacy keys. PresentationState provides testable idle visibility and display filtering. PresentationController owns one display link, click monitors and all overlay windows, and stops the display link when disabled. OverlayWindow renders only changed states with Core Animation. HotKeyManager registers distinct actions and reports conflicts in settings. SettingsView provides a preview, presets and two focused tabs.

## Behavior and failure handling
Pause immediately clears all overlays and transient effects. Locate briefly highlights the cursor even while paused, then returns to the previous state. Spotlight dims only the eligible display containing the cursor. Display IDs persist across launches; unplugging a selected display does not move its overlay onto a private display. Changing displays rebuilds windows safely. Preference values are validated and a saved zero opacity stays zero. Sleep suspends rendering. Click and locator effects respect system or app Reduce Motion. No Accessibility, Input Monitoring or Screen Recording permission is requested.

## Verification
Automated tests cover preference migration, corrupt persisted values, preset configuration, display eligibility, idle visibility, pause/locator lifetime and render-layer cleanup. Compile an optimized app and verify the bundle. Exercise the native UI and shortcuts. Screen-share visibility requires a recipient-side meeting check and will not be claimed as verified by local screenshots.

## Platform references

- [Apple mouse event monitoring](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html): global mouse monitoring is separate from permission-gated key monitoring.
- [Apple display-link lifecycle](https://developer.apple.com/documentation/quartzcore/cadisplaylink): pause callbacks when unused and invalidate on shutdown.
- [Apple Reduce Motion](https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducemotion): honor the system preference.
- [Apple single-window capture filter](https://developer.apple.com/documentation/screencapturekit/sccontentfilter/init(desktopindependentwindow:)): a separate overlay may be absent from a single-window share. Meeting-app behavior still needs recipient-side verification.

## Cursor overlays, version 2.1

User-approved scope: decorative overlays with the native macOS cursor remaining visible. A dedicated Cursors tab offers Laser dot, Crosshair and Target ring at the click point, plus Star, Heart and Paper plane offset above and right of the pointer. None restores the previous appearance. Size is adjustable from 16 to 80 points and color is independent of the halo. Choices persist and are not reset by presentation presets.

CursorArtwork supplies resolution-independent paths to both the picker and production Core Animation layers. Geometry updates only when the shape, size or color changes. The existing controller applies the same pause, idle, display and sleep behavior to the cursor layer. No cursor-hiding APIs, event interception, extra permissions, network assets or animations are introduced. The preview keeps the native-arrow representation visible to show the actual combined appearance.

Validation covers migration defaults, corrupt preferences, all six paths, display position, geometry reuse, size changes, preset preservation, immediate pause cleanup and removal via None. Verify the installed Cursors tab and preview, then run the complete existing suite and GitHub workflow.
