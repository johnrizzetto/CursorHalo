#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Output folder name
APP_DIR="CursorHalo.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

# Create standard macOS App Bundle directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "Compiling CursorHalo Swift sources..."
swiftc -O \
  -sdk "$(xcrun --show-sdk-path)" \
  -target "${ARCH:-$(uname -m)}-apple-macosx14.0" \
  -framework Cocoa \
  -framework SwiftUI \
  -framework QuartzCore \
  -framework Carbon \
  src/*.swift \
  -o "$MACOS_DIR/CursorHalo"

# Create Info.plist to specify app properties, minimum system requirements, and LSUIElement (run as menu bar accessory)
cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>CursorHalo</string>
    <key>CFBundleIdentifier</key>
    <string>com.johnrizzetto.CursorHalo</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CursorHalo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1</string>
    <key>CFBundleVersion</key>
    <string>3</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --sign - "$APP_DIR"
plutil -lint "$APP_DIR/Contents/Info.plist"
echo "CursorHalo.app built successfully!"
