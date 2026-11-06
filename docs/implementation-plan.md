# Implementation plan

Goal: deliver a native presentation utility with useful controls and bounded idle work.
Spec: design.md. Stack: Swift, AppKit, SwiftUI, Core Animation, Carbon. macOS 14+.

- [x] Extract settings, preserve legacy keys, validate bounds, and add presets. Test zero opacity, invalid data and reloads.
- [x] Add testable visibility state with display filtering, idle timeout and temporary locator lifecycle. Test transitions and unplugged display IDs.
- [x] Build cached overlay layers and a single controller. Pause and sleep stop refresh callbacks. Verify clearing effects and click-through panels.
- [x] Extend Carbon shortcuts with conflict reporting and an emergency pause.
- [x] Recompose the native panel around a preview and Pointer/Meeting tabs, semantic theme tokens and native controls.
- [x] Add portable build/test scripts and macOS CI. Build, run tests, exercise UI, update documentation and push GitHub.

Review focus: zero opacity persistence; disabled-state wakeups; temporary effect cancellation; disconnected selected display; full-screen and application-window screen-sharing differences.

## Verification limits

Native controls and preview were exercised in the installed app. Carbon registration and action routing are tested, but automated key injection did not trigger global shortcuts. A physical keyboard check and recipient-side screen-sharing check remain manual.
