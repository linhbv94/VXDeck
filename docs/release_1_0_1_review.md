# VXDeck 1.0.1 — QA và Phát hành Bản vá & Cải tiến UX

## 1. Tổng quan Bản phát hành
- **Tên ứng dụng:** VXDeck
- **Phiên bản:** 1.0.1
- **Nền tảng:** macOS (Apple Silicon arm64, macOS 14.0+, macOS SDK 27.0 baseline).
- **Trọng tâm bản vá:** Khắc phục triệt để lỗi thoát ứng dụng, sửa lỗi lưu kích cỡ cửa sổ và căn giữa, bổ sung tính năng đổi thứ tự bộ sưu tập, tối ưu hóa cơ chế kéo thả ứng dụng đồng bộ và chống mất app khi chọn tệp.

## 2. Chi tiết các Bản vá & Nâng cấp Kỹ thuật
1. **Khắc phục lỗi treo / deadlock khi click ra ngoài hoặc thoát app:**
   - Xóa bỏ việc sleep trong `applicationShouldTerminate` gây deadlock giữa AppKit modal runloop và Swift Concurrency MainActor; trả về `.terminateNow`.
   - Nâng cấp `EventMonitor` bắt cả global và local mouse down để click ra ngoài (desktop, secondary monitor, dock, menubar) luôn kích hoạt đóng app tức thì.
   - Thêm cơ chế timeout structured flush 2.0s và fallback `exit(0)` sạch sẽ, giải quyết triệt để lỗi còn dấu chấm dưới icon Dock.
2. **Khắc phục lỗi lưu Width và lỗi cửa sổ bị dính sát mép trái màn hình khi mở lại:**
   - `AppDelegate`: Đưa `await DeckStore.shared.initialize()` lên chạy trước khi tạo `DeckPanel`. Căn giữa ngang chính xác trên màn hình chứa con trỏ chuột (`visibleFrame.origin.x + (visibleFrame.width - width) / 2`).
   - `DeckPanel`: Khóa chặt `updateHeight` chỉ điều chỉnh chiều cao và Y, không ghi đè X và Width; bỏ logic frame width > 100 ép về 620.
   - `DeckRootView`: Thay thế `DragGesture` của SwiftUI bằng `ResizeTrackingNSView` (AppKit native tracking với `NSEvent.mouseLocation` theo tọa độ màn hình toàn cục), kéo mép trái/mép phải mượt 100% không giật, tự động lưu và flush `window_width` xuống đĩa khi nhả chuột; đệm `padding(.vertical, 16)` không lòi ra ngoài viền bo góc.
3. **Thêm cơ chế đổi thứ tự bộ sưu tập (Collection Reorder):**
   - Thêm nút mũi tên `[↑]` `[↓]` trên header từng collection trong Edit Mode, có kiểm tra biên đầu/cuối và cập nhật `displayOrder`.
4. **Khắc phục lỗi kéo thả App thi thoảng không ăn ("drag thả ra nothing happened") & mất app khi thêm:**
   - Bỏ callback bất đồng bộ `NSItemProvider.loadItem` dễ bị race condition; commit drop đồng bộ trực tiếp qua `store.draggingItemId`.
   - Kích hoạt lại `DeckPanel` và flush ngay khi chọn file app từ `NSOpenPanel`.

## 3. Kiểm thử Tự động & Bằng chứng Nghiệm thu
- `swift run VXDeckCoreTests`: **7/7 test suites PASS 100%**:
  1. `testModelSerializationRoundtrip`: PASS
  2. `testDefaultSeedGeneration`: PASS
  3. `testDeckStoreCollectionAndItemOperations`: PASS
  4. `testConfigBackupRecovery`: PASS
  5. `testIconProvider`: PASS
  6. `testSemVerComparison`: PASS
  7. `testAddAppAndImmediateReorderPersistence` & `testCollectionReordering`: PASS
- `scripts/check_macos_sdk.py --artifact build/VXDeck.app`: PASS (SDK Baseline 27.0).
- `codesign --verify --deep --strict build/VXDeck.app`: PASS (`valid on disk`, `satisfies its Designated Requirement`).
- Đóng gói DMG `vxdeck_1.0.1_macos_silicon.dmg` và manifest `latest.json`.

## 4. Tài sản Bản phát hành
- macOS Apple Silicon DMG: `vxdeck_1.0.1_macos_silicon.dmg`
- Manifest cập nhật: `latest.json`
