# VXDeck 1.0.0 — QA và Phát hành Bản đầu tiên

## 1. Tổng quan Sản phẩm & Phạm vi MVP
- **Tên ứng dụng:** VXDeck
- **Phiên bản:** 1.0.0
- **Nền tảng:** macOS (Apple Silicon arm64, macOS 14.0+, macOS SDK 27.0 baseline).
- **Mục tiêu:** Bảng sưu tập ứng dụng nổi (Curated Transient App Launcher) nhẹ tênh, mở nhanh từ Dock, nhóm ứng dụng theo danh mục (Collections), sắp xếp kéo thả và khởi chạy 1-chạm (1-Click Launch).

## 2. Kết quả Rà soát QA & Xử lý Khuyến nghị
- Đã hoàn tất xử lý toàn bộ các khuyến nghị từ đợt review độc lập của Codex CLI (commit `21296d1`):
  1. Đảm bảo flush dữ liệu cấu hình đồng bộ khi ứng dụng nhận sự kiện `applicationShouldTerminate`.
  2. Bổ sung revision guard và cơ chế atomic staging file (`deck_config.json.tmp`) chống ghi đè ngược.
  3. Tách biệt hoàn toàn sandbox test (`tempDir`) khỏi `~/Library/Application Support/VXDeck`.
  4. Xác thực bundle `.app` hợp lệ khi người dùng thêm ứng dụng.
  5. Bảo vệ phiên chỉnh sửa (Edit Mode), ngăn ngừa callback đóng popup ngoài ý muốn.
  6. Sửa nút xác nhận đổi tên collection bảo toàn nội dung draft.
  7. Cải tiến độ mượt mà khi kéo thả sắp xếp ứng dụng (drag session token, drop line indicator).
- **Cải tiến Updater mượt mà:**
  1. Hỗ trợ đối chiếu SemVer số học (`DeckStore.isNewerVersion`) loại bỏ triệt để lỗi so sánh chuỗi.
  2. Cơ chế kiểm tra cập nhật kênh đôi: ưu tiên `latest.json` (zero rate limit), dự phòng GitHub Releases API.
  3. Bổ sung nút "Tải bộ cài .dmg" và hiển thị release notes trực tiếp trên modal Cài đặt.
  4. Hiển thị chấm thông báo (Notification Dot) trên nút Cài đặt ở Header khi phát hiện bản mới.
  5. Kiểm tra cập nhật ngầm sau 2.5s khởi động app không gây giật lag UI.

## 3. Kiểm thử Tự động & Bằng chứng Nghiệm thu
- `swift run VXDeckCoreTests`: 5/5 test suites PASS 100% (Model serialization, default seed, isolated sandbox operations, backup recovery, icon provider, semver comparison).
- `bundle_app.sh` & `package_release.sh`: Build release binary, đóng gói `.app` bundle và đóng gói `vxdeck_1.0.0_macos_silicon.dmg` (1.6MB).
- `codesign -vvv --deep --strict build/VXDeck.app`: PASS (`valid on disk`, `satisfies its Designated Requirement`).
- `otool -l build/VXDeck.app/Contents/MacOS/VXDeck`: PASS (`LC_BUILD_VERSION platform 1 minos 14.0 sdk 27.0`).
- Sinh manifest `latest.json` với SHA-256 và size chuẩn xác.

## 4. Tài sản Bản phát hành
- macOS Apple Silicon DMG: `vxdeck_1.0.0_macos_silicon.dmg`
- Manifest cập nhật: `latest.json`
