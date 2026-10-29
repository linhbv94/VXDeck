# Nhiệm vụ: Tham vấn & Review Thành phẩm Triển khai Ứng dụng VXDeck v1.0 MVP

Vai trò: Chỉ tham vấn/review chỉ đọc; không sửa nguồn; không gọi agent khác.
Tuân thủ AGENTS.md, tiếng Việt chuyên nghiệp, UTF-8, snake_case và tuyệt đối không dùng LaTeX.

## 1. Bối cảnh dự án
Dự án **VXDeck** — bảng sưu tập ứng dụng nổi dạng popup (Curated Application Launcher Board) dành riêng cho macOS (Apple Silicon & Intel).
- Tài liệu phạm vi gốc: `vxdeck/VXDeck_MVP_Scope.md`.
- Hệ thống 7 đặc tả kỹ thuật: `vxdeck/docs/spec/` (đã được Codex review và thông qua trước đó).
- Toàn bộ mã nguồn đã được triển khai hoàn chỉnh bằng Swift 6 Native + AppKit (`NSPanel`) + SwiftUI, biên dịch và đóng gói thành công thành `build/VXDeck.app` trên macOS SDK 27.0 baseline.

## 2. Các tệp mã nguồn và cấu trúc triển khai cần review

### A. Core Library (`vxdeck/Sources/VXDeckCore/`):
- `Models/`:
  - `AppItemModel.swift`: DTO ứng dụng, custom label, runtime availability, CodingKeys snake_case.
  - `CollectionModel.swift`: DTO nhóm ứng dụng, danh sách items, isCollapsed.
  - `DeckSettings.swift`: Cài đặt autoHideOnLaunch, columnsCount (5), iconSize (48), themeMode ("dark").
  - `DeckConfig.swift`: Schema root version 1.0.0, schemaVersion 1, ISO 8601 timestamps, hàm `defaultSeed()` khởi tạo 5 ứng dụng hệ thống cơ bản.
- `Services/`:
  - `IconProvider.swift`: Trích xuất biểu tượng native Retina 48×48pt qua `NSWorkspace.shared.icon`, in-memory cache `NSCache<NSString, NSImage>` 300 mục, an toàn tương thích macOS 14+.
  - `AppLauncher.swift`: Khởi chạy ứng dụng qua `NSWorkspace.shared.openApplication`, xác thực đối chiếu bundle ID và file path chống giả mạo, fallback tra cứu Bundle Identifier, xử lý ngoại lệ `AppLauncherError`.
- `Store/`:
  - `ConfigManager.swift`: Swift `actor` quản lý ghi đĩa tuần tự hóa qua staging file `.deck_config.json.tmp.<uuid>`, gọi `fsync()`, atomic replace, sao lưu `.bak`, tự động cô lập file hỏng thành `.corrupt.<timestamp>` và hàm `flush()` ép ghi đồng bộ khi thoát app.
  - `DeckStore.swift`: `@MainActor ObservableObject` điều phối dữ liệu tập trung, chống trùng lặp ứng dụng, reorder transaction chuẩn xác, cross-collection item move, quản lý `windowSessionId` chống ẩn nhầm popup, cờ `isModalOpen` bảo vệ bên ngoài click khi mở `NSOpenPanel`.

### B. AppKit & SwiftUI Frontend (`vxdeck/Sources/VXDeck/`):
- `Window/`:
  - `DeckPanel.swift`: Kế thừa `NSPanel`, cấu hình `.borderless`, `.nonactivatingPanel`, `.floating` level, `canBecomeKey = true`, tự động căn giữa màn hình phía trên Dock, điều hướng bàn phím `Escape` và `Cmd+E` tại cấp AppKit responder.
  - `EventMonitor.swift`: Lắng nghe sự kiện click chuột bên ngoài toàn cục (`NSEvent.addGlobalMonitorForEvents`), tự động ẩn popup khi ở View Mode và khóa click ngoài khi ở Edit Mode hoặc khi mở modal con.
- `Views/`:
  - `LocalState.swift`: Custom property wrapper tuân thủ `DynamicProperty` bọc `SwiftUI.State`, giải quyết triệt để sự thiếu vắng của external macro plugin `SwiftUIMacros` trên môi trường Command Line Tools độc lập.
  - `DeckRootView.swift`: Khung hiển thị nổi Glassmorphism kích thước chuẩn 620pt, bo góc 16pt, viền tinh tế 1pt, bóng đổ sâu 2xl, thanh cuộn ẩn chỉ báo.
  - `DeckHeaderView.swift`: Nhận diện thương hiệu "VXDeck" với tia sét Electric Cyan, nút Thêm Nhóm mới, nút gạt Chỉnh sửa / Hoàn tất.
  - `CollectionSectionView.swift`: Tiêu đề nhóm inline editable, badge số lượng, lưới 5 cột ứng dụng, hỗ trợ kéo thả UTI `com.vxdeck.app-item` trong nhóm và liên nhóm.
  - `AppCardView.swift`: Thẻ ứng dụng 96×86pt, icon 48×48pt, tên app 11px 2 dòng, hiệu ứng co nhấn 80ms, 1-click launch, huy hiệu xóa [x] ở Edit Mode, context menu "Hiện trong Finder" / "Đổi tên" / "Xóa".
  - `AddAppCardPlaceholder.swift`: Thẻ nét đứt thêm app ở cuối mỗi nhóm trong Edit Mode, mở `NSOpenPanel` native chọn tệp `.app`.
  - `DeckFooterView.swift`: Phím tắt `[esc]` Đóng/Hoàn tất, `[⌘E]` Sửa/Xong, nhãn hướng dẫn tương tác.
  - `ToastOverlayView.swift`: Thông báo nổi nhẹ nhàng mượt mà ở đầu cửa sổ.
- `App/`:
  - `main.swift`: Bootstrap entry point chuẩn AppKit.
  - `AppDelegate.swift`: Tuân thủ nguyên tắc Dock activation: nhấp icon Dock luôn luôn Show / Bring to Front (`panel.showPanel()`), quản lý `applicationWillTerminate` gọi `ConfigManager.flush()`.

### C. Kiểm thử & Đóng gói:
- `Tests/VXDeckTests/DeckCoreTests.swift`: Bộ kiểm thử tự động độc lập 4 test suites bao phủ serialization roundtrip, default seed, DeckStore operations (thêm, chặn trùng, reorder, xóa) và IconProvider.
- `scripts/bundle_app.sh`: Script biên dịch Release với linker flag `-platform_version macos 14.0 27.0`, tự động tạo `build/VXDeck.app` kèm `Info.plist` và `AppIcon.icns`, ký số ad-hoc.
- `Package.swift`: Định nghĩa target `VXDeckCore`, `VXDeck`, và `VXDeckCoreTests`.

## 3. Bằng chứng kiểm chứng thực tế đã chạy
1. `swift run VXDeckCoreTests`: Đạt 4/4 suites PASS (100%).
2. `scripts/bundle_app.sh`: Build production thành công trong 0.31s (incremental) / 72s (clean).
3. `python3 _summary/standard_codes/check_macos_sdk.py --artifact vxdeck/build/VXDeck.app`: Đạt `"baseline_sdk": "27.0"`, `"sdk_slices": ["27.0"]`, `"pass": true`.
4. `codesign --verify --deep --strict vxdeck/build/VXDeck.app`: Đạt `valid on disk` và `satisfies its Designated Requirement`.
5. `open vxdeck/build/VXDeck.app`: Khởi chạy live thành công (PID 17821), file `~/Library/Application Support/VXDeck/deck_config.json` sinh đúng 100% schema.

## 4. Trọng tâm yêu cầu Codex đánh giá & phản biện
Codex hãy rà soát kỹ lưỡng toàn bộ mã nguồn trên và cho ý kiến phản biện:
1. **Kiến trúc Concurrency & Bộ nhớ (Swift 6 & Actor Isolation):**
   - Sự phối hợp giữa `ConfigManager` (actor) và `DeckStore` (`@MainActor`): có điểm nào có nguy cơ race condition, re-entrancy bug, hoặc thất thoát dữ liệu khi người dùng thao tác nhanh không?
   - Cửa sổ `DeckPanel` và `EventMonitor`: việc dùng `Task { @MainActor in ... }` trong monitor closure có thể xảy ra trường hợp nào khiến panel bị treo hoặc không nhận sự kiện không?
2. **Trải nghiệm Người Dùng & Quản lý Cửa sổ macOS:**
   - Window lifecycle của `DeckPanel` (borderless floating popup): Việc gán `canBecomeKey = true`, bắt sự kiện phím tại `keyDown(with:)` và ẩn popup khi click ngoài đã tối ưu cho workflow macOS chưa? Có phát sinh vấn đề khi chạy trên hệ thống đa màn hình (multi-monitor) không?
   - Kéo thả sắp xếp (`onDrag` / `onDrop`): Cơ chế chuyển payload `sourceColId:draggedItemId` và tính toán index đích có trường hợp edge case nào làm lệch thứ tự không?
3. **Giải pháp kỹ thuật `LocalState`:**
   - Đánh giá tính an toàn, khả năng tương thích lâu dài và độ tin cậy của property wrapper `LocalState` thay thế `@State` để vượt qua rào cản thiếu `SwiftUIMacros` của Command Line Tools.
4. **Hardening & Khuyến nghị Cải tiến:**
   - Các điểm cần gia cố thêm trước khi phát hành chính thức (error recovery, accessibility, multi-display positioning, v.v.).

## 5. Định dạng đầu ra mong muốn
- Đánh giá tổng quan chất lượng thành phẩm (Đạt yêu cầu MVP / Cần chỉnh sửa).
- Phân loại rõ ràng các kiến nghị:
  - **[P1 - Khuyến nghị Nghiêm trọng]**: Cần sửa ngay trước khi dùng thực tế (nếu có).
  - **[P2 - Cải thiện / Hoàn thiện Trải nghiệm]**: Đề xuất nâng cao tính ổn định và thẩm mỹ.
  - **[P3 - Tối ưu hóa Tương lai]**: Các tính năng mở rộng khi lên v1.1.
- Dẫn chứng cụ thể tên file, dòng mã và lý do kỹ thuật.
