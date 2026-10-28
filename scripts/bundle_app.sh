#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_DIR}"

APP_NAME="VXDeck"
BUNDLE_ID="com.ztools.vxdeck"
VERSION="${1:-1.0.1}"
BUILD_DIR="${PROJECT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Building ${APP_NAME} in Release mode via Swift Package Manager with SDK 27.0..."
swift build -c release --product "${APP_NAME}" -Xlinker -platform_version -Xlinker macos -Xlinker 14.0 -Xlinker 27.0

echo "==> Assembling ${APP_NAME}.app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy icon & assets
if [ -f "${PROJECT_DIR}/icon.icns" ]; then
    cp "${PROJECT_DIR}/icon.icns" "${RESOURCES_DIR}/AppIcon.icns"
    echo "==> Copied icon.icns to AppIcon.icns"
else
    echo "Warning: icon.icns not found in ${PROJECT_DIR}"
fi

if [ -f "${PROJECT_DIR}/Resources/qr.png" ]; then
    cp "${PROJECT_DIR}/Resources/qr.png" "${RESOURCES_DIR}/qr.png"
    echo "==> Copied qr.png to Resources"
fi

# Generate Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Ad-hoc code signing ${APP_BUNDLE}..."
codesign --force --deep --sign - "${APP_BUNDLE}"
codesign -v "${APP_BUNDLE}"

echo "==> Successfully created ${APP_BUNDLE}!"
