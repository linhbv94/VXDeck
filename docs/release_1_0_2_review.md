# VXDeck 1.0.2 — QA và Phát hành Cơ chế Tự động Cập nhật Đè 1-Chạm

## 1. Tổng quan Bản phát hành
- **Tên ứng dụng:** VXDeck
- **Phiên bản:** 1.0.2
- **Nền tảng:** macOS (Apple Silicon arm64, macOS 14.0+, macOS SDK 27.0 baseline).
- **Trọng tâm bản phát hành:** Triển khai cơ chế In-place Auto-update và tự khởi động lại (restart) mượt mà 1-chạm, thay thế hoàn toàn thao tác tải DMG và kéo thả thủ công.

## 2. Chi tiết Tính năng & Nâng cấp Kỹ thuật
1. **Dịch vụ `AppUpdater` (`VXDeckCore/Services/AppUpdater.swift`):**
   - Tải file DMG ngầm trực tiếp từ `download_url` trong manifest `latest.json` bằng `URLSession`.
   - Mount DMG ngầm bằng lệnh hệ thống `hdiutil attach -nobrowse -readonly`.
   - Sinh background bash helper script chạy độc lập:
     - Giám sát tiến trình PID cũ của VXDeck và chờ app thoát hoàn toàn.
     - Sao chép đè bundle mới từ ổ đĩa mount vào `/Applications/VXDeck.app` (hoặc đường dẫn app bundle hiện tại).
     - Unmount DMG bằng `hdiutil detach -force`.
     - Xóa file DMG và script tạm trong `/tmp`.
     - Kích hoạt lại ứng dụng mới bằng `/usr/bin/open <targetAppPath>`.
   - Xử lý lỗi an toàn: `AppUpdaterError` phân loại rõ `invalidURL`, `downloadFailed`, `mountFailed`, `sourceAppNotFound`, `cannotDetermineTargetApp`.
2. **Giao diện Cập nhật `DeckSettingsView.swift`:**
   - Hiển thị nút chính nổi bật: **"Cập nhật & Khởi động lại"** (icon `arrow.triangle.2.circlepath.circle.fill`).
   - Hiển thị thanh tiến trình và thông báo trạng thái trực quan: "Đang tải bản cập nhật...", "Đang chuẩn bị cập nhật...".
   - Nút "Tải bộ cài .dmg" và "Xem trên GitHub" được giữ lại làm tùy chọn phụ.
3. **Kiểm thử tự động:**
   - Thêm test suite `testAppUpdaterErrors` trong `DeckCoreTests.swift`.
   - Cả **8/8 test suites PASS 100%**.

## 3. Kiểm thử Tự động & Bằng chứng Nghiệm thu
- `swift run VXDeckCoreTests`: **8/8 test suites PASS 100%**:
  1. `testModelSerializationRoundtrip`: PASS
  2. `testDefaultSeedGeneration`: PASS
  3. `testDeckStoreCollectionAndItemOperations`: PASS
  4. `testConfigBackupRecovery`: PASS
  5. `testIconProvider`: PASS
  6. `testSemVerComparison`: PASS
  7. `testAddAppAndImmediateReorderPersistence` & `testCollectionReordering`: PASS
  8. `testAppUpdaterErrors`: PASS
- `scripts/check_macos_sdk.py --artifact build/VXDeck.app`: PASS (SDK Baseline 27.0).
- `codesign --verify --deep --strict build/VXDeck.app`: PASS (`valid on disk`, `satisfies its Designated Requirement`).
- Đóng gói DMG `vxdeck_1.0.2_macos_silicon.dmg` và manifest `latest.json`.

## 4. Tài sản Bản phát hành
- macOS Apple Silicon DMG: `vxdeck_1.0.2_macos_silicon.dmg`
- Manifest cập nhật: `latest.json`
