# CursorHalo

CursorHalo is a native macOS menu bar app that makes your pointer easier to follow during demos and screen sharing. It uses Swift, AppKit, SwiftUI, and Core Animation, requires macOS 14 or later, and has no third-party runtime dependencies.

## Pointer tools

- **Halo and spotlight:** Show a colored halo around the pointer, or dim the surrounding display with a clear area around it.
- **Subtle, Demo, and Focus presets:** Start with a small halo, a larger demo halo, or a dimmed spotlight, then adjust the appearance.
- **Click feedback:** Choose Ripple, Double Ripple, Solid Flash, or Focus Target. Right clicks can appear as dashed rings.
- **Temporary locator:** Highlight the pointer briefly, including while effects are paused.
- **Display choice:** Follow the pointer across displays or restrict effects to a selected display. A disconnected selection stays selected.
- **Idle hiding:** Optionally hide effects after 2 seconds without pointer movement.
- **Reduce Motion:** Respect the macOS setting or enable it in CursorHalo. Click feedback uses a brief static ring.
- **Refresh rate:** Choose 30 or 60 fps. Actual timing depends on the display and macOS.
- **Appearance controls:** Adjust size, opacity, outline, and click scale. Native color pickers replace the drag-only color wheel. Existing saved colors and supported appearance preferences are preserved when upgrading. Applying a preset changes its appearance settings.

Open the menu bar panel to adjust settings or quit CursorHalo. Effects pass mouse clicks through to the apps underneath. CursorHalo does not request Accessibility, Input Monitoring, or Screen Recording permission.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Cmd + Shift + H` | Toggle pointer tools |
| `Cmd + Option + Shift + S` | Switch between halo and spotlight |
| `Cmd + Option + Shift + L` | Locate the pointer |
| `Cmd + Option + Shift + X` | Pause all effects |

The settings panel reports unavailable shortcuts. Its controls remain available if another app has registered a shortcut.

## Screen sharing

A full-display share generally includes CursorHalo's overlay windows. Sharing a single app or window may omit them. Verify the recipient's view in your meeting app before presenting. Local display behavior does not establish what a meeting participant can see.

## Build and run

Install Xcode Command Line Tools if needed:

```bash
xcode-select --install
```

From the repository directory, run:

```bash
./test.sh
./build.sh
open CursorHalo.app
```

The build targets macOS 14 and uses the current Mac's architecture by default. Set `ARCH` to build for a specific architecture:

```bash
ARCH=arm64 ./build.sh
# Or build for an Intel Mac:
ARCH=x86_64 ./build.sh
```

Each command produces a single-architecture app at `CursorHalo.app`. The build applies a local ad-hoc signature. The app is not notarized.

To reveal the built app in Finder:

```bash
open -R "$PWD/CursorHalo.app"
```

## Development

`AppSettings` persists preferences. `PresentationState` handles idle visibility, locator timing, and display eligibility. `PresentationController` coordinates display timing, click monitoring, and overlay windows. `OverlayWindow` renders the effects, `HotKeyManager` registers shortcuts, and `SettingsView` provides the controls.

`./test.sh` runs the automated tests. GitHub Actions runs tests and builds on macOS 14, verifies the app signature, and uploads a zipped app as a build artifact. This workflow does not publish a release or notarize the app.
