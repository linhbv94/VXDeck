#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

VERSION="${1:-1.0.3}"
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

# 4. Generate latest.json
echo "==> Generating latest.json..."
DMG_SHA256=$(shasum -a 256 "${DMG_PATH}" | awk '{print $1}')
DMG_SIZE=$(stat -f%z "${DMG_PATH}")

cat <<EOF > "${BUILD_DIR}/latest.json"
{
  "version": "${VERSION}",
  "tag_name": "v${VERSION}",
  "pub_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "notes": "VXDeck v${VERSION} — Cải tiến giao diện tab Cập nhật: Nút tự động cập nhật full-width phẳng phiu, loại bỏ nút tải DMG thủ công.",
  "html_url": "https://github.com/linhbv94/VXDeck/releases/tag/v${VERSION}",
  "download_url": "https://github.com/linhbv94/VXDeck/releases/download/v${VERSION}/${DMG_NAME}",
  "sha256": "${DMG_SHA256}",
  "size": ${DMG_SIZE}
}
EOF

echo "==> Packaged successfully!"
echo "    - DMG: ${DMG_PATH} ($(ls -lh "${DMG_PATH}" | awk '{print $5}'))"
echo "    - latest.json: ${BUILD_DIR}/latest.json"
