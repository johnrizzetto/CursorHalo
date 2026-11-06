#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
swiftc -sdk "$(xcrun --show-sdk-path)" -framework Cocoa -framework SwiftUI -framework QuartzCore -framework Carbon src/Settings.swift src/PresentationState.swift src/OverlayWindow.swift src/PointerPreviewView.swift src/PresentationController.swift src/HotKey.swift tests/main.swift -o "$TEST_DIR/tests"
"$TEST_DIR/tests"
