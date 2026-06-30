# CursorHalo

CursorHalo is a native, super lightweight, high-performance macOS menu bar utility that draws a customizable spotlight or halo around your mouse cursor.

It compiles down to a single native binary of only **253 KB** with **zero third-party dependencies**!

---

## Features

- **Zero-Permission Mouse Tracking:** Coordinates are polled using screen V-Sync (`CADisplayLink`), avoiding intrusive Accessibility prompts and consuming near-zero CPU.
- **Zero-Permission Global Hotkey:** Toggle the spotlight instantly from any application using **`Cmd + Shift + H`** (powered by Carbon HotKeys).
- **Segmented Click Animations:** Select between multiple dynamic ripple styles on mouse clicks:
  - **Ripple:** Standard expanding ring.
  - **Double:** Two sequential expanding rings.
  - **Flash:** A solid filled circle flash.
  - **Focus:** A target crosshair shrinking down to the cursor.
- **Custom Color Wheel & Brightness Slider:** Choose custom colors directly inside the glassmorphic menu bar popover using a custom sRGB color wheel and brightness controls.
- **Show Outline Toggle:** Turn off borders to create a soft, borderless spotlight halo.

---

## Installation & How to Build

To compile and run CursorHalo on any macOS laptop (macOS 14+):

1. **Clone the repository:**
   ```bash
   git clone https://github.com/johnrizzetto/CursorHalo.git
   cd CursorHalo
   ```

2. **Build the application:**
   Make the build script executable and compile:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

3. **Launch:**
   ```bash
   open CursorHalo.app
   ```

To close the app, click the concentric circles icon in your Mac's status bar and select **Quit CursorHalo**.
