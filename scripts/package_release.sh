#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

VERSION="${1:-1.0.4}"
APP_NAME="VXDeck"
BUILD_DIR="${PROJECT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="vxdeck_${VERSION}_macos_silicon.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
STAGING_DIR="${BUILD_DIR}/dmg_staging"

# 1. Bundle .app
"${SCRIPT_DIR}/bundle_app.sh" "${VERSION}"

# 2. Prepare DMG staging
echo "==> Preparing DMG staging..."
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

# 3. Create DMG
echo "==> Packaging DMG: ${DMG_PATH}..."
hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING_DIR}" -ov -format UDZO "${DMG_PATH}"
rm -rf "${STAGING_DIR}"

# 4. Authenticated updater manifest. Signing key must match the compiled trust anchor.
echo "==> Signing latest.json..."
"${VXDECK_SIGNING_PYTHON:-python3}" "${SCRIPT_DIR}/sign_update_manifest.py" \
    --package "${DMG_PATH}" --version "${VERSION}" --architecture macos_silicon \
    --output "${BUILD_DIR}/latest.json"

echo "==> Packaged successfully: ${DMG_NAME}, latest.json"
