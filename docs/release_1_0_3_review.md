# VXDeck 1.0.3 — QA và Phát hành Bản vá Giao diện Tab Cập nhật

## 1. Tổng quan Bản phát hành
- **Tên ứng dụng:** VXDeck
- **Phiên bản:** 1.0.3
- **Nền tảng:** macOS (Apple Silicon arm64, macOS 14.0+, macOS SDK 27.0 baseline).
- **Trọng tâm bản phát hành:** Khắc phục lỗi bố cục UI tại tab Cập nhật (Settings): tái cấu trúc nút Cập nhật thành card full-width phẳng, loại bỏ nút tải DMG thủ công không cần thiết, sắp xếp hàng nút phụ đối xứng thanh thoát.

## 2. Chi tiết Cải tiến Giao diện
1. **Tái cấu trúc Nút Cập nhật Chính:**
   - Thay vì ép 4 nút vào một hàng ngang 460px khiến text bị ngắt dòng co cụm theo chiều dọc, nút **"Cập nhật & Khởi động lại ngay"** được thiết kế thành một Card độc lập full-width.
   - Text trải thẳng 1 dòng duy nhất, icon `arrow.triangle.2.circlepath.circle.fill` đồng bộ, màu nền Electric Cyan tinh tế và viền phát sáng nhẹ.
2. **Loại bỏ Nút tải DMG thủ công:**
   - Đã xóa bỏ nút "Tải bộ cài .dmg" khỏi UI vì luồng In-place Auto-update đã hoạt động ổn định và thay thế hoàn toàn thao tác kéo thả thủ công.
3. **Hàng Nút Phụ Thanh thoát:**
   - Đặt 2 nút "Kiểm tra lại" và "Xem trên GitHub" thành một hàng phụ phía dưới với style phẳng (border viền xám mờ), phân tách rạch ròi giữa hành động chính và các tiện ích tra cứu.

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
- Đóng gói DMG `vxdeck_1.0.3_macos_silicon.dmg` và manifest `latest.json`.

## 4. Tài sản Bản phát hành
- macOS Apple Silicon DMG: `vxdeck_1.0.3_macos_silicon.dmg`
- Manifest cập nhật: `latest.json`
