#!/bin/bash
set -euo pipefail

APP_NAME="NotchCatwalk"
SWIFT_FILE="NotchCatwalkApp.swift"
APP_BUNDLE="${APP_NAME}.app"

# Clean previous build
rm -rf "${APP_BUNDLE}"

# Compile
swiftc -parse-as-library \
    -framework SwiftUI \
    -framework Cocoa \
    -framework AppKit \
    -o "${APP_NAME}" \
    "${SWIFT_FILE}"

# Create .app bundle structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mv "${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Generate Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>NotchCatwalk</string>
    <key>CFBundleIdentifier</key>
    <string>com.chigichan24.NotchCatwalk</string>
    <key>CFBundleName</key>
    <string>NotchCatwalk</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "Built ${APP_BUNDLE}"
echo ""
echo "Run with:  open ${APP_BUNDLE}"
echo "Quit with: pkill ${APP_NAME}"
