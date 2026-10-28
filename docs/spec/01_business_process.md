# 01. Quy trình Nghiệp vụ — VXDeck (`_spec1_business_process`)

> **Tên sản phẩm:** VXDeck (Lightweight Curated Application Launcher Popup)  
> **Thư mục dự án:** `vxdeck`  
> **Phiên bản tài liệu:** 1.0.0  
> **Ngày cập nhật:** 2026-10-28  
> **Tài liệu liên quan:** [00_system_overview.md](00_system_overview.md) | [02_feature_flow.md](02_feature_flow.md)

---

## 1. Mục đích & Phạm vi Nghiệp vụ

Tài liệu này chuẩn hóa toàn bộ các quy trình nghiệp vụ ở cấp độ **Vĩ mô (Macro Business Processes)** của VXDeck, mô tả sự phối hợp chặt chẽ giữa 5 chủ thể (Actors & Systems):
1. **Người dùng (User):** Thao tác chuột, bàn phím và trực giác sắp xếp không gian làm việc.
2. **Giao diện VXDeck (UI Presentation):** Lưới biểu tượng, bảng bộ sưu tập và chế độ chỉnh sửa.
3. **Bộ điều khiển Cửa sổ (Windowing Controller):** Quản lý trạng thái hiển thị, focus, sự kiện click ngoài.
4. **Bộ lưu trữ Cấu hình Cục bộ (Config & Storage Engine):** Đọc và ghi dữ liệu nguyên tử vào ổ đĩa.
5. **Hệ điều hành macOS (LaunchServices & NSWorkspace):** Quản lý biểu tượng Dock, giải mã Bundle ID, trích xuất icon và khởi chạy tiến trình ứng dụng.

---

## 2. Mô hình SIPOC (Supplier — Input — Process — Output — Customer)

### 2.1. SIPOC 1: Quy trình Kích hoạt & Khởi chạy Ứng dụng (1-Click Launch)
- **Supplier (Nhà cung cấp):** Người dùng, macOS LaunchServices.
- **Input (Đầu vào):** Thao tác click biểu tượng VXDeck trên Dock; thao tác click vào icon app mục tiêu; cấu hình `deck_config.json`.
- **Process (Quy trình):**
  1. macOS gửi sự kiện `reopen` tới VXDeck.
  2. VXDeck kiểm tra trạng thái: nếu cửa sổ đang ẩn → hiển thị popup tại màn hình tương ứng.
  3. Người dùng nhấp chuột một lần (single-click) vào biểu tượng ứng dụng mong muốn.
  4. Hệ thống kiểm tra tính khả dụng của file `.app` (dựa trên Bundle ID / File Path).
  5. Gọi `NSWorkspace.shared.openApplication` để kích hoạt app mục tiêu.
  6. Tự động ẩn popup VXDeck (mặc định) và chuyển giao focus cho app vừa mở.
- **Output (Đầu ra):** Ứng dụng mục tiêu mở ra màn hình; popup VXDeck ẩn gọn gàng; không để lại cửa sổ rác.
- **Customer (Người thụ hưởng):** Người dùng (tiết kiệm thời gian, không bị ngắt quãng dòng suy nghĩ).

### 2.2. SIPOC 2: Quy trình Thêm Ứng dụng vào Bộ sưu tập (Add App Curation)
- **Supplier (Nhà cung cấp):** Người dùng, Hệ thống tệp macOS (`/Applications`, `~/Applications`).
- **Input (Đầu vào):** Thao tác click nút `[+ Thêm ứng dụng]` trong một Collection; tệp `.app` được chọn từ hộp thoại `NSOpenPanel`.
- **Process (Quy trình):**
  1. Người dùng chọn Collection muốn nạp thêm app.
  2. Hệ thống mở hộp thoại chọn tệp native `NSOpenPanel` có bộ lọc chỉ cho chọn thư mục gói `.app`.
  3. Người dùng trỏ tới app và bấm Open.
  4. Hệ thống trích xuất Metadata: Tên hiển thị (`CFBundleDisplayName` / `CFBundleName`), Bundle Identifier (`CFBundleIdentifier`), đường dẫn tuyệt đối, và icon native.
  5. Kiểm tra tính trùng lặp trong Collection.
  6. Thêm bản ghi mới vào danh sách trong RAM và kích hoạt ghi nguyên tử xuống đĩa.
- **Output (Đầu ra):** Biểu tượng app mới xuất hiện ngay lập tức trong Collection; file cấu hình được cập nhật an toàn.
- **Customer (Người thụ hưởng):** Người dùng (tùy biến được danh sách làm việc theo đúng ý muốn).

### 2.3. SIPOC 3: Quy trình Tùy biến Sắp xếp (Edit Mode & Drag-and-Drop)
- **Supplier (Nhà cung cấp):** Người dùng (Cử chỉ kéo thả chuột).
- **Input (Đầu vào):** Chuyển sang Edit Mode (qua nút bấm hoặc phím tắt `Cmd + E`); thao tác kéo thả icon.
- **Process (Quy trình):**
  1. Người dùng kích hoạt Edit Mode → Giao diện chuyển sang trạng thái biên tập (hiển thị nút xóa, tay cầm kéo).
  2. Hệ thống tạm thời khóa cơ chế tự ẩn cửa sổ khi mất focus.
  3. Người dùng kéo một icon trong cùng Collection hoặc thả sang Collection khác.
  4. Hệ thống cập nhật lại chỉ mục thứ tự (`display_order`) của các phần tử.
  5. Ghi nhận thay đổi xuống đĩa với cơ chế tiết lưu (Debounce 300ms).
  6. Người dùng bấm "Xong" (`Checkmark`) để trở lại View Mode bình thường.
- **Output (Đầu ra):** Bảng sưu tập được sắp xếp theo đúng vị trí không gian người dùng mong muốn; không xảy ra lỗi click nhầm mở app khi đang kéo.
- **Customer (Người thụ hưởng):** Người dùng cá nhân hóa hoàn toàn giao diện làm việc.

---

## 3. Biểu đồ Quy trình Nghiệp vụ (BPMN 2.0 / Swimlane Diagrams)

### 3.1. Swimlane 1: Khởi động Popup từ Dock & Mở Ứng dụng Mục tiêu (Happy Path)

```mermaid
graph TB
    subgraph User_Lane [Người Dùng]
        U1[Click icon VXDeck trên Dock] --> U2[Quan sát popup nổi hiện lên]
        U2 --> U3{Muốn làm gì?}
        U3 -- Click chọn App --> U4[Nhấp 1-chạm vào icon App]
        U3 -- Đổi ý / Không dùng --> U5[Bấm Escape hoặc Click ra ngoài]
    end

    subgraph Window_Controller_Lane [Điều Khiển Cửa Sổ AppKit]
        U1 --> W1[Nhận sự kiện applicationShouldHandleReopen]
        W1 --> W2{Popup đang hiện?}
        W2 -- Chưa hiện --> W3[Tính toán vị trí & Hiển thị NSPanel]
        W2 -- Đang hiện --> W4[Giữ nguyên vị trí hoặc đưa lên trước]
        W3 --> U2
        W4 --> U2
        U5 --> W5[Ẩn NSPanel mượt mà]
    end

    subgraph App_Launcher_Lane [Động Cơ Khởi Chạy Ứng Dụng]
        U4 --> L1[Tra cứu Bundle ID & File Path]
        L1 --> L2{Tệp .app tồn tại?}
        L2 -- Có tồn tại --> L3[Gọi NSWorkspace.openApplication]
        L2 -- Bị mất/xóa --> L4[Hiển thị cảnh báo Không khả dụng]
        L3 --> L5[Phát tín hiệu kích hoạt thành công]
        L5 --> W5
    end

    subgraph OS_System_Lane [Hệ Điều Hành macOS]
        L3 --> S1[LaunchServices nạp App lên màn hình]
        S1 --> S2[Focus chuyển giao sang App mục tiêu]
    end
```

### 3.2. Swimlane 2: Quản lý Bộ sưu tập & Thêm Ứng dụng trong Edit Mode

```mermaid
graph TB
    subgraph User_Action [Người Dùng]
        E1[Bấm nút Chỉnh sửa / Cmd+E] --> E2[Giao diện chuyển sang Edit Mode]
        E2 --> E3{Chọn tác vụ biên tập}
        E3 -- Tạo nhóm mới --> E4[Nhập tên Collection mới]
        E3 -- Thêm App vào nhóm --> E5[Click nút + Thêm ứng dụng]
        E3 -- Xóa App khỏi nhóm --> E6[Click biểu tượng dấu trừ trên thẻ App]
        E3 -- Hoàn tất --> E7[Bấm nút Xong / Cmd+E]
    end

    subgraph UI_State_Lane [Giao Diện SwiftUI]
        E1 --> V1[Kích hoạt jiggle nhẹ & hiện icon xóa]
        V1 --> E2
        E5 --> V2[Mở hộp thoại NSOpenPanel]
        V2 --> V3[Người dùng chọn file .app]
        V3 --> V4[Trích xuất icon, tên hiển thị, bundle ID]
        V4 --> V5[Cập nhật UI lưới hiển thị tức thì]
        E6 --> V6[Xóa thẻ khỏi Collection trên màn hình]
        E7 --> V7[Ẩn các nút chỉnh sửa, trở lại View Mode]
    end

    subgraph Config_Storage_Lane [Lưu Trữ Cấu Hình Cục Bộ]
        E4 --> C1[Tạo CollectionModel mới trong RAM]
        V5 --> C2[Gán AppItemModel vào Collection]
        V6 --> C3[Loại bỏ AppItemModel khỏi mảng RAM]
        C1 --> C4[Ghi nguyên tử xuống deck_config.json]
        C2 --> C4
        C3 --> C4
        C4 --> C5[Bảo toàn cấu hình bền vững]
    end
```

### 3.3. Swimlane 3: Kéo Thả Sắp Xếp (Drag-and-Drop) & Bảo Vệ Cấu Hình

```mermaid
graph TB
    subgraph Drag_User_Lane [Người Dùng]
        D1[Ở Edit Mode: Nhấn giữ chuột vào thẻ App] --> D2[Rê chuột di chuyển icon]
        D2 --> D3{Thả chuột tại đâu?}
        D3 -- Vị trí mới trong cùng Collection --> D4[Thả vào vị trí đích]
        D3 -- Thả sang Collection khác --> D5[Thả vào khung Collection mới]
        D3 -- Thả ra ngoài khoảng trống --> D6[Thả chuột ra ngoài]
    end

    subgraph Drag_UI_Lane [SwiftUI Drag Coordinator]
        D1 --> U1[Bắt đầu DragSession với UTI com.vxdeck.app-item]
        U1 --> U2[Hiển thị Preview mờ theo con trỏ chuột]
        D4 --> U3[Tính toán lại vị trí xen kẽ trong mảng]
        D5 --> U4[Chuyển item sang Collection đích]
        D6 --> U5[Hủy thao tác, icon trở về vị trí cũ]
    end

    subgraph Persistence_Lane [Bộ Lưu Trữ Cấu Hình]
        U3 --> P1[Cập nhật display_order trong DeckStore]
        U4 --> P1
        P1 --> P2[Bộ đếm Debounce 300ms]
        P2 --> P3[Ghi an toàn ra file tạm .deck_config.json.tmp]
        P3 --> P4[Đổi tên nguyên tử đè lên deck_config.json]
    end
```

---

## 4. Ma trận Quyết định Nghiệp vụ (Decision Tables / Matrices)

### 4.1. Ma trận 1: Hành vi Đóng / Ẩn Popup (Dismissal Policy)

| ID | Trạng thái hiện tại | Sự kiện kích hoạt (Event) | Hành động của Hệ thống | Trạng thái Cửa sổ sau đó |
| :--- | :--- | :--- | :--- | :--- |
| **D1** | View Mode (Bình thường) | Click vào một App hợp lệ | Gọi `openApplication` → Kiểm tra `auto_hide_on_launch` → Ẩn popup khi thành công | Ẩn (`Hidden`) |
| **D2** | View Mode (Bình thường) | Nhấn phím cứng `Escape` | Ẩn popup ngay lập tức | Ẩn (`Hidden`) |
| **D3** | View Mode (Bình thường) | Click chuột ra ngoài cửa sổ | Ẩn popup ngay lập tức | Ẩn (`Hidden`) |
| **D4** | Bất kỳ (Ẩn hoặc Hiện) | Click icon VXDeck trên thanh Dock | **Luôn Hiện / Đưa lên trước** (`makeKeyAndOrderFront`), triệt tiêu xung đột với click ngoài | Hiện (`Active View`) |
| **D5** | Edit Mode (Đang sửa) | Click ra ngoài hoặc mất focus | **KHÔNG ẨN CỬA SỔ** (Bảo vệ phiên sửa) | Giữ nguyên (`Active Edit`) |
| **D6** | Edit Mode (Đang sửa) | Mở hộp thoại `NSOpenPanel` | **KHÔNG ẨN CỬA SỔ** (Khóa click ngoài, giữ panel mẹ phía sau) | Giữ nguyên (`Modal Open`) |
| **D7** | Edit Mode (Đang sửa) | Đang kéo rê chuột (Dragging) | **KHÔNG ẨN CỬA SỔ** dù con trỏ ra ngoài viền | Giữ nguyên (`Dragging`) |
| **D8** | Edit Mode (Đang sửa) | Nhấn phím cứng `Escape` | Thoát khỏi Edit Mode, quay về View Mode | Hiện (`Active View`) |

### 4.2. Ma trận 2: Khởi chạy Ứng dụng & Xử lý Trạng thái Ngoại lệ

| ID | Trạng thái của Ứng dụng đích | Kiểm tra Bundle ID | Kiểm tra File Path | Hành động của VXDeck | Phản hồi Giao diện |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **L1** | Ứng dụng bình thường | Trùng khớp Bundle ID | Tệp tồn tại ở path đã lưu | Mở ứng dụng ngay qua `NSWorkspace` | Ẩn popup nếu `auto_hide = true` |
| **L2** | Tệp bị thay thế tại path cũ | Không khớp Bundle ID | Có tệp nhưng khác Bundle ID | **Từ chối mở để chống nhầm app** | Hiển thị cảnh báo: Tệp tại đường dẫn không khớp định danh |
| **L3** | Ứng dụng đã bị di chuyển thư mục | Trùng khớp Bundle ID | Không thấy ở path cũ | Dò tìm ứng viên qua Bundle ID; nếu duy nhất và chứng minh được danh tính thì cập nhật path | Mở app và lưu path mới; nếu không chắc chắn thì yêu cầu định vị lại |
| **L4** | Ứng dụng đã bị gỡ cài đặt hoàn toàn | Không tìm thấy | Không tồn tại | Không mở ứng dụng; giữ nguyên popup | Bật popover: "Không tìm thấy app. Xóa hoặc định vị lại?" |
| **L5** | Ứng dụng đang chạy sẵn ngầm | Trùng khớp Bundle ID | Tệp tồn tại | Kích hoạt (bring to front) app đó | Chuyển focus sang app đó mượt mà |
| **L6** | Tệp bị mất quyền đọc/thực thi | Trùng khớp Bundle ID | Tệp bị khóa quyền | Báo lỗi hệ thống qua thông báo nhẹ | Hiển thị tooltip lỗi quyền truy cập |

### 4.3. Ma trận 3: Trùng lặp Shortcut & Xóa Bộ sưu tập

| ID | Tình huống Nghiệp vụ | Quy tắc Xử lý của VXDeck | Lý do Nghiệp vụ & Ràng buộc An toàn |
| :--- | :--- | :--- | :--- |
| **R1** | Thêm 1 app vào cùng 1 Collection 2 lần | **Chặn trùng lặp:** Hiển thị thông báo "Ứng dụng này đã có trong nhóm" | Tránh làm bừa bộn và rối mắt lưới icon. |
| **R2** | Thêm 1 app xuất hiện ở 2 Collection khác nhau | **Cho phép hoàn toàn:** Ví dụ Figma vừa nằm ở nhóm "Thiết kế" vừa ở "Dự án A" | Tôn trọng tự do phân loại theo bối cảnh làm việc của người dùng. |
| **R3** | Người dùng xóa 1 shortcut trong Collection | **Chỉ xóa bản ghi cấu hình** trong `deck_config.json` | **Tuyệt đối KHÔNG gỡ cài đặt** hay xóa file `.app` trong máy. |
| **R4** | Người dùng xóa toàn bộ một Collection | Hiển thị hộp thoại xác nhận: "Xóa nhóm X? (Các ứng dụng cài trên máy sẽ không bị ảnh hưởng)" | Ngăn ngừa thao tác bấm nhầm; bảo đảm tính an toàn dữ liệu 100%. |
| **R5** | Người dùng xóa app trên máy qua Finder | VXDeck giữ nguyên shortcut ở trạng thái `Unavailable` cho đến khi người dùng chủ động xóa | Người dùng nhận biết được sự thay đổi để có thể cài lại hoặc dọn dẹp. |
