# Báo Cáo Đánh Giá & Phản Biện Bộ Đặc Tả Kỹ Thuật VXDeck — Codex CLI

> **Mã phiên chạy:** `20261028_025420_codex_06edf799`  
> **Thời gian:** 2026-10-28 09:57:20 UTC+7  
> **Chế độ:** Chỉ đọc (Read-only sandbox), không sửa nguồn, không gọi CLI khác.  
> **Nguồn đánh giá:** Toàn bộ 7 tài liệu đặc tả tại `vxdeck/docs/spec/` và tài liệu phạm vi [VXDeck_MVP_Scope.md](../../VXDeck_MVP_Scope.md).

---

## 1. Kết luận Tổng quan từ Codex
**Đánh giá: Cần bổ sung và chuẩn hóa trước khi dùng bộ spec làm contract triển khai.**  
Hướng tiếp cận kiến trúc Pure Swift + SwiftUI + AppKit (`NSPanel`, `NSWorkspace`, `NSOpenPanel`) và SPM là hoàn toàn khả thi và phù hợp với phạm vi MVP. Tuy nhiên, bộ spec đang tồn tại một số mâu thuẫn kỹ thuật và khoảng hở có thể dẫn đến mất dữ liệu khi kéo thả/thoát app, mở nhầm ứng dụng hoặc xung đột vòng đời popup.

---

## 2. Chi tiết các Khuyến nghị theo Mức độ Ưu tiên

### [P1 — Nghiêm trọng / Cần xử lý ngay]

#### 1. Contract `reorder_items` chưa thực thi đúng với FSM và Swift Models
- **Vấn đề:** 
  - Tại `02_feature_flow.md`, `reorder_items` khai báo điều kiện `window_state == .editActive`, nhưng trong FSM sự kiện thả (Drop) xảy ra khi đang ở trạng thái `DRAGGING`.
  - `CollectionModel` là Swift `struct` (Value Type): Việc lấy collection ra biến cục bộ `let source_collection` rồi gọi `remove` là không hợp lệ cú pháp Swift (`let` là bất biến), đồng thời sửa biến cục bộ không tự cập nhật vào mảng `collections` của `DeckStore`.
  - Kéo thả trong cùng một Collection nếu thao tác trên 2 biến bản sao sẽ tính sai chỉ mục sau khi rút phần tử.
- **Giải pháp:**
  - Thiết kế một hàm transaction duy nhất trong `DeckStore`: tìm kiếm item nguồn bằng `item_id`, kiểm tra Collection đích, phân tách rõ 2 nhánh: trong cùng Collection (dùng `move(fromOffsets:toOffset:)`) và khác Collection.
  - Cập nhật trực tiếp trên mảng `@Published var collections` trong store dưới `MainActor` và tái đánh số `displayOrder`.
  - Nếu drop lỗi hoặc hủy giữa chừng thì giữ nguyên cả 2 nhóm.

#### 2. Nhận diện Ứng dụng & Fallback Bundle ID cần chặt chẽ (Chống mở nhầm app)
- **Vấn đề:**
  - `02_feature_flow.md` chỉ kiểm tra path tồn tại trên ổ đĩa. Nếu một ứng dụng khác cùng tên được cài đè vào path cũ, hệ thống sẽ mở nhầm app đó.
  - Khi path bị mất, tự động chuyển sang kết quả của `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` có thể mở sai bản cài đặt khác nếu máy có nhiều phiên bản (ví dụ bản Beta vs bản Stable).
- **Giải pháp:**
  - Khi thêm app: Đọc và lưu cả `bundle_id` và `path`.
  - Khi khởi chạy: Kiểm tra tệp tại `path` có tồn tại không VÀ đối chiếu `bundle_id` của tệp đó có khớp với `bundle_id` đã lưu không.
  - Nếu path mất: Dùng `bundle_id` tìm kiếm ứng viên. Nếu tìm thấy ứng viên duy nhất hợp lệ, tự động cập nhật path. Nếu có nhiều ứng viên hoặc không chứng minh được danh tính, chuyển thẻ sang trạng thái `Unavailable` và yêu cầu người dùng định vị lại thay vì tự ý mở ứng dụng.

#### 3. Xung đột Sự kiện giữa Click Outside và Dock Activation
- **Vấn đề:**
  - `04_api_data.md` quy định ẩn popup khi nhận sự kiện click ngoài (`NSEvent.addGlobalMonitorForEvents`). Khi người dùng click vào icon VXDeck trên Dock, thao tác click đó cũng là một "click ngoài" đối với cửa sổ popup.
  - Thứ tự callback không xác định: Nếu click ngoài bắt trước → ẩn popup; sau đó `applicationShouldHandleReopen` chạy → thấy popup đang ẩn nên lại hiện lên, làm hỏng hoàn toàn hành vi toggle.
  - Ngoài ra, `01_business_process.md` tại sơ đồ quy định đưa popup lên trước, trong khi bảng decision table lại ghi là ẩn (Toggle).
- **Giải pháp:**
  - **Chốt chuẩn theo Scope MVP gốc:** **Dock activation luôn là hành động Show / Bring-to-Front**. Nếu popup đang ẩn → Hiện popup. Nếu popup đang hiện nhưng bị che → Đưa popup lên trước (Order Front).
  - Hành động ẩn popup chỉ do: Click chuột ra ngoài (Outside Click), nhấn phím `Escape`, hoặc sau khi 1-Click Launch thành công. Điều này triệt tiêu hoàn toàn race condition với Dock!
  - `applicationShouldHandleReopen` luôn trả về `false` sau khi gọi `makeKeyAndOrderFront` để chặn hành vi mặc định của AppKit.

#### 4. Concurrency trong Launch Callback & Chống Callback Ẩn Nhầm Phiên Mới
- **Vấn đề:**
  - `openApplication(at:configuration:completionHandler:)` chạy completion handler trên một luồng nền ngẫu nhiên (concurrent queue). Nếu cập nhật UI hoặc gọi `panel.orderOut` trực tiếp sẽ vi phạm thread safety của AppKit.
  - Nếu người dùng bấm mở app A, sau đó bấm mở lại ngay popup hoặc chuyển sang Edit Mode, completion callback hoặc delay timer của lượt mở trước có thể chạy trễ và vô tình ẩn cửa sổ của phiên làm việc mới.
- **Giải pháp:**
  - Bao bọc toàn bộ mã xử lý completion bên trong `DispatchQueue.main.async` hoặc `@MainActor`.
  - Chỉ ẩn popup khi `completionHandler` trả về thành công (Error == nil) VÀ cài đặt `auto_hide_on_launch == true`.
  - Thêm một biến định danh phiên hiển thị (`visibility_generation: Int` hoặc `session_id`). Khi popup được mở lại hoặc chuyển sang `editActive`, tăng generation lên; callback kiểm tra nếu generation đã đổi thì bỏ qua lệnh `orderOut`.

#### 5. Đảm bảo Lưu Trữ Đĩa (Single Writer & Flush khi Thoát Ứng Dụng)
- **Vấn đề:**
  - Với debounce 300ms, nếu người dùng kéo thả sắp xếp xong và bấm `Cmd + Q` thoát app ngay, dữ liệu trong bộ đếm thời gian (timer) có thể bị mất trước khi kịp ghi đĩa.
  - Nếu có nhiều lời gọi save đồng thời, snapshot cũ có thể hoàn tất rename sau snapshot mới, gây ghi đè ngược.
- **Giải pháp:**
  - Thiết kế `ConfigManager` theo dạng Single Serial Writer (Actor hoặc Serial DispatchQueue).
  - Mỗi bản snapshot lưu kèm số thứ tự sửa đổi (`revision: Int`), từ chối ghi đè nếu revision đến sau thấp hơn revision hiện hành trên đĩa.
  - Bổ sung hàm `flush()` ép ghi ngay lập tức: Gọi `flush()` khi người dùng bấm "Hoàn tất" Edit Mode và trong `applicationWillTerminate` của `AppDelegate`.
  - Khi phát hiện tệp JSON bị lỗi cú pháp, đổi tên tệp hỏng thành `deck_config.json.corrupt.<timestamp>` để người dùng có thể khôi phục, không tự động ghi đè tệp rỗng lên dữ liệu của người dùng.

---

### [P2 — Cải thiện / Hoàn thiện]

#### 6. Đồng bộ Tuyệt đối giữa JSON Schema và Swift Models
- **Vấn đề:**
  - Trong `04_api_data.md`, Schema JSON quy định các trường `updated_at`, `theme_mode`, `is_collapsed`, nhưng thuộc tính `required` của Schema và Swift `Decodable` chưa đồng bộ.
  - Swift `JSONDecoder` mặc định giải mã Date theo `deferredToDate` (giây từ mốc 2001), trong khi chuỗi JSON lưu dạng ISO 8601 (`"2026-10-28T09:00:00Z"`). Nếu không thiết lập `decoder.dateDecodingStrategy = .iso8601`, app sẽ crash khi nạp tệp.
  - Độ dài tên nhóm: Schema ghi tối đa 60, QA ghi tối đa 50.
- **Giải pháp:**
  - Cấu hình rõ ràng: `encoder.dateEncodingStrategy = .iso8601` và `decoder.dateDecodingStrategy = .iso8601`.
  - Thống nhất độ dài tên bộ sưu tập: Tối đa 50 ký tự trên toàn bộ Schema, UI và QA.
  - Cung cấp `init(from decoder: Decoder)` có fallback mặc định an toàn cho các trường tùy chọn để tương thích ngược.

#### 7. Hoàn thiện Contract Focus, Keyboard & Hộp thoại Modal
- **Vấn đề:**
  - Cửa sổ nổi `NSPanel` cần khai báo rõ `canBecomeKey = true` để nhận sự kiện bàn phím (`Escape`, `Cmd+E`).
  - Khi mở `NSOpenPanel` để thêm ứng dụng, cần bảo vệ cửa sổ cha không bị ẩn khi người dùng tương tác với dialog chọn file.
- **Giải pháp:**
  - Cấu hình `DeckPanel`: Override `var canBecomeKey: Bool { return true }`.
  - Phân luồng phím `Escape`:
    1. Nếu đang mở picker/modal → Đóng picker/modal.
    2. Nếu đang ở `Edit Mode` → Thoát về `View Mode`.
    3. Nếu đang ở `View Mode` → Ẩn popup.
  - Khi mở `NSOpenPanel`: Đặt `is_modal_open = true`, tạm khóa trình theo dõi click ngoài cho đến khi dialog đóng lại.

#### 8. Hoàn thiện Logic Kéo Thả (Drag & Drop)
- **Giải pháp:**
  - Xác thực `item_id` tồn tại trong Collection tại thời điểm commit drop.
  - Ngăn chặn kéo thả tạo ứng dụng trùng lặp trong cùng một Collection.
  - Hỗ trợ drop vào vùng trống của Collection rỗng.
  - Đảm bảo thuộc tính `bundle_id` nếu không có thì gán `nil` rõ ràng thay vì chuỗi rỗng `""`.

#### 9. Hoàn thiện Bundle Metadata & Pin SDK 27.0
- **Giải pháp:**
  - Khai báo đầy đủ các khóa bundle trong `Info.plist`: `CFBundleExecutable = VXDeck`, `CFBundleIdentifier = com.ztools.vxdeck`, `CFBundlePackageType = APPL`, `CFBundleIconFile = AppIcon`, `LSMinimumSystemVersion = 14.0`, `NSHighResolutionCapable = true`.
  - Tuân thủ baseline SDK 27.0 của suite VXUtilities, kiểm tra metadata bằng script `check_macos_sdk.py`.
  - Ký số ad-hoc: `codesign --force --sign - VXDeck.app` (không ép `--deep` trên các bundle con không cần thiết).

#### 10. Quản lý Hiển thị Biểu tượng & Trạng thái Unavailable
- **Giải pháp:**
  - Đảm bảo hiển thị Retina: Sử dụng `NSImage` với kích thước logical `48×48pt`, nạp representation độ phân giải cao (`@2x`).
  - Cache biểu tượng trong RAM bằng `NSCache<NSString, NSImage>`.
  - Khi mở popup, tự động kiểm tra nhanh tính tồn tại của file để cập nhật `is_available`. Nếu app bị mất, hiển thị thẻ mờ kèm nút menu "Định vị lại ứng dụng..." hoặc "Xóa khỏi danh sách".

#### 11. Chuẩn hóa Bảng Nghiệm thu QA & Bố cục Giao diện
- **Giải pháp:**
  - Trong `05_qa_acceptance.md`: Đổi toàn bộ trạng thái `PASS` được ghi sẵn thành `CHƯA KIỂM THỬ` (Chờ nghiệm thu runtime).
  - Bổ sung kịch bản kiểm thử: Đổi tên Collection, khôi phục tệp cấu hình lỗi (`.corrupt`), và lưu khi thoát đột ngột.
  - Thống nhất kích thước giao diện: Chiều cao tối đa `min(760pt, 80% screen_height)`, chiều cao footer `28pt`.
  - Bổ sung ứng dụng thứ 12 vào bộ seed data (Collection Tiện ích: Chrome, Slack, Notion, 1Password) để đạt chuẩn 12 app như mô tả.

---

### [P3 — Tối ưu hóa lâu dài]
- Thống nhất toàn bộ đơn vị hiển thị trong tài liệu là `pt` (Points) thay vì `px` phù hợp với hệ thống tọa độ native của macOS AppKit/SwiftUI.
- Đổi các cam kết mang tính tiếp thị ("zero latency", "0% CPU") thành các chỉ số kỹ thuật đo lường cụ thể trong QA checklist.
- Cấu trúc các file mã nguồn Swift theo quy chuẩn `snake_case` (ví dụ `app_delegate.swift`, `deck_panel.swift`, `config_manager.swift`), giữ các file đặc thù của SPM như `Package.swift`.
