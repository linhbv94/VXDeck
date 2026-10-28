# 06. Kịch bản Trình diễn & Demo Playbook — VXDeck (`_spec6_demo_presentation`)

> **Tên sản phẩm:** VXDeck (Lightweight Curated Application Launcher Popup)  
> **Thư mục dự án:** `vxdeck`  
> **Phiên bản tài liệu:** 1.0.0  
> **Ngày cập nhật:** 2026-10-28  
> **Tài liệu liên quan:** [00_system_overview.md](00_system_overview.md) | [02_feature_flow.md](02_feature_flow.md) | [03_ui_wireframe.md](03_ui_wireframe.md)

---

## 1. Định hình Thông điệp Cốt lõi & Khoảnh khắc "Wow" (Wow Factor)

### 1.1. Thông điệp Định vị Sản phẩm (Core Value Proposition)
> **"VXDeck — Bảng sưu tập ứng dụng nổi nhẹ tênh dành cho macOS: Mở tức thì từ Dock, nhấp 1-chạm để kích hoạt, sắp xếp không gian tự do theo cách của bạn."**

### 1.2. Ba Khoảnh khắc "Wow" Đắt giá trong Buổi Demo
1. **Khởi động Nhanh như Chớp & Giao diện Nổi Không Viền (Zero-Latency Floating Glass):**
   - Người xem bất ngờ khi click icon trên Dock: Không có cửa sổ nặng nề hiện ra, mà là một bảng điều khiển kính mờ Dark mode nổi bồng bềnh, bo tròn tinh tế, không có thanh title bar hay traffic lights thừa thãi.
2. **Khởi chạy 1-chạm Siêu Tốc (1-Click Snappy Launch):**
   - Click một icon ứng dụng, app mở ngay tức khắc và popup VXDeck tự động biến mất gọn gàng, trả lại 100% không gian làm việc cho người dùng mà không cần bất kỳ thao tác đóng cửa sổ phụ nào.
3. **Kéo Thả Tự do theo Không gian Trực quan (Intuitive Spatial Organization):**
   - Thao tác kéo thả các biểu tượng ứng dụng giữa các nhóm bộ sưu tập mượt mà như trên iPad/iPhone, khắc phục triệt để điểm bất tiện của macOS 26.

---

## 2. Kịch bản Trình diễn Chi tiết theo Thời gian (Timeline Script — 5 Phút)

### Phút 00:00 – 01:00: Nỗi đau Thực tế & Mở Màn
- **Hành động Người trình bày:** Mở máy macOS, rê chuột chỉ vào thanh Dock đông đúc và bật Launchpad/Spotlight.
- **Lời dẫn (Speech):**
  > "Chào mọi người. Trên macOS 26, nhiều người trong chúng ta cảm thấy hụt hẫng vì mất đi khả năng sắp xếp ứng dụng theo không gian trực quan. Thanh Dock thì quá chật chội nếu để nhiều app, còn Spotlight thì bắt buộc phải gõ phím. Hôm nay, tôi xin giới thiệu **VXDeck** — một giải pháp cực kỳ gọn nhẹ: một bảng sưu tập ứng dụng nổi bật lên ngay khi bạn cần, và biến mất ngay khi bạn xong việc."
- **Thao tác demo:** Nhấp chuột vào icon VXDeck trên Dock → Popup nổi xuất hiện ngay lập tức giữa màn hình với hiệu ứng mờ kính cao cấp.

### Phút 01:00 – 02:15: Trải nghiệm Sử dụng Cốt lõi (1-Click Launch)
- **Hành động Người trình bày:**
  1. Rê chuột qua các bộ sưu tập đã được chuẩn bị sẵn: "Thiết Kế", "Lập Trình", "Tiện Ích".
  2. Chỉ ra độ sắc nét của các biểu tượng native Retina và hiệu ứng hover tinh tế.
  3. Nhấp một lần duy nhất vào ứng dụng **Visual Studio Code**.
- **Lời dẫn (Speech):**
  > "Hãy nhìn xem: tôi không cần tìm kiếm hay cuộn qua hàng trăm app. Chỉ cần một cú nhấp chuột duy nhất vào VS Code..."
- **Kết quả hiển thị:**
  - Icon VS Code co nhẹ phản hồi nhấp.
  - Cửa sổ VS Code mở ra trên màn hình.
  - Popup VXDeck tự động ẩn biến mất hoàn toàn.
- **Lời dẫn tiếp:**
  > "App đã mở, và VXDeck tự động biến mất. Không để lại cửa sổ rác, không chiếm màn hình. Giờ nếu tôi cần chuyển sang việc khác..."
- **Thao tác demo:** Nhấp lại icon Dock → VXDeck hiện lại ngay lập tức tại vị trí cũ. Nhấn phím `Escape` hoặc click ra ngoài màn hình → Popup ẩn ngay tức thì.

### Phút 02:15 – 03:45: Tùy biến Sắp xếp & Kéo Thả (Edit Mode & Curation)
- **Hành động Người trình bày:**
  1. Nhấn phím tắt `Cmd + E` (hoặc bấm icon bút chì trên góc phải).
  2. Giao diện chuyển sang chế độ sửa: xuất hiện huy hiệu xóa `(x)` và khung thêm app.
  3. Bấm `[+ Thêm Bộ sưu tập mới]`, đặt tên nhóm là `"Đồ Họa & Video"`.
  4. Bấm `[+ Thêm ứng dụng]`, hộp thoại chọn file hiện ra, chọn nhanh **Figma** và **Photoshop**.
  5. Dùng chuột nhấn giữ icon Photoshop, kéo thả từ nhóm "Đồ Họa" sang nhóm "Thiết Kế".
  6. Rê icon đổi vị trí lên đầu danh sách.
- **Lời dẫn (Speech):**
  > "Chế độ Edit Mode cho phép bạn làm chủ hoàn toàn không gian. Bạn có thể tạo nhóm mới, thêm ứng dụng trực tiếp từ thư mục Applications, và tự do kéo thả sắp xếp icon theo thói quen ngón tay của mình. Mọi thao tác kéo thả diễn ra với độ mượt mà 60fps chuẩn native macOS."
- **Thao tác demo:** Bấm nút `[✓ Hoàn tất]` (hoặc `Cmd + E`) để lưu và trở về chế độ dùng bình thường.

### Phút 03:45 – 04:30: Kiểm chứng Tính Bền vững & An toàn Dữ liệu
- **Hành động Người trình bày:**
  1. Thoát hoàn toàn ứng dụng VXDeck (`Cmd + Q`).
  2. Mở lại VXDeck từ thanh Dock.
- **Lời dẫn (Speech):**
  > "Một điểm then chốt: VXDeck sử dụng cơ chế ghi đĩa nguyên tử (Atomic File Persistence). Khi tôi tắt app hoàn toàn và mở lại, toàn bộ các nhóm và thứ tự kéo thả ban nãy được khôi phục 100% nguyên vẹn. Đặc biệt, VXDeck tuân thủ nguyên tắc Read-Only an toàn: chúng tôi không bao giờ can thiệp hay làm thay đổi các file .app gốc của hệ thống."

### Phút 04:30 – 05:00: Tổng kết & Hỏi Đáp (Q&A)
- **Lời dẫn (Speech):**
  > "Tóm lại, VXDeck mang lại cho bạn: Một bảng chọn ứng dụng nhanh, không quảng cáo, không cloud, không cần quyền admin, chỉ thuần túy phục vụ năng suất làm việc của bạn trên macOS. Cảm ơn mọi người và tôi sẵn sàng trả lời các câu hỏi."

---

## 3. Dữ liệu Mẫu Khởi tạo Demo (Demo Seed Data)

Tệp cấu hình mẫu chuẩn `deck_config.json` phục vụ buổi trình diễn hoàn hảo:

```json
{
  "version": "1.0.0",
  "schema_version": 1,
  "updated_at": "2026-10-28T09:00:00Z",
  "settings": {
    "auto_hide_on_launch": true,
    "columns_count": 5,
    "icon_size": 48,
    "theme_mode": "dark"
  },
  "collections": [
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "title": "Thiết Kế & Sáng Tạo",
      "display_order": 0,
      "is_collapsed": false,
      "items": [
        {
          "id": "a1111111-0000-0000-0000-000000000001",
          "name": "Figma",
          "bundle_id": "com.figma.Desktop",
          "path": "/Applications/Figma.app",
          "display_order": 0,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "a1111111-0000-0000-0000-000000000002",
          "name": "Adobe Photoshop",
          "bundle_id": "com.adobe.Photoshop",
          "path": "/Applications/Adobe Photoshop 2026/Adobe Photoshop 2026.app",
          "display_order": 1,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "a1111111-0000-0000-0000-000000000003",
          "name": "Sketch",
          "bundle_id": "com.bohemiancoding.sketch3",
          "path": "/Applications/Sketch.app",
          "display_order": 2,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "a1111111-0000-0000-0000-000000000004",
          "name": "Illustrator",
          "bundle_id": "com.adobe.illustrator",
          "path": "/Applications/Adobe Illustrator 2026/Adobe Illustrator.app",
          "display_order": 3,
          "added_at": "2026-10-28T09:00:00Z"
        }
      ]
    },
    {
      "id": "22222222-2222-2222-2222-222222222222",
      "title": "Lập Trình & Hệ Thống",
      "display_order": 1,
      "is_collapsed": false,
      "items": [
        {
          "id": "b2222222-0000-0000-0000-000000000001",
          "name": "Visual Studio Code",
          "bundle_id": "com.microsoft.VSCode",
          "path": "/Applications/Visual Studio Code.app",
          "display_order": 0,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "b2222222-0000-0000-0000-000000000002",
          "name": "Xcode",
          "bundle_id": "com.apple.dt.Xcode",
          "path": "/Applications/Xcode.app",
          "display_order": 1,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "b2222222-0000-0000-0000-000000000003",
          "name": "Ghostty",
          "bundle_id": "com.mitchellh.ghostty",
          "path": "/Applications/Ghostty.app",
          "display_order": 2,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "b2222222-0000-0000-0000-000000000004",
          "name": "Docker Desktop",
          "bundle_id": "com.docker.docker",
          "path": "/Applications/Docker.app",
          "display_order": 3,
          "added_at": "2026-10-28T09:00:00Z"
        }
      ]
    },
    {
      "id": "33333333-3333-3333-3333-333333333333",
      "title": "Tiện Ích & Công Việc",
      "display_order": 2,
      "is_collapsed": false,
      "items": [
        {
          "id": "c3333333-0000-0000-0000-000000000001",
          "name": "Google Chrome",
          "bundle_id": "com.google.Chrome",
          "path": "/Applications/Google Chrome.app",
          "display_order": 0,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "c3333333-0000-0000-0000-000000000002",
          "name": "Slack",
          "bundle_id": "com.tinyspeck.slackmacgap",
          "path": "/Applications/Slack.app",
          "display_order": 1,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "c3333333-0000-0000-0000-000000000003",
          "name": "Notion",
          "bundle_id": "notion.id",
          "path": "/Applications/Notion.app",
          "display_order": 2,
          "added_at": "2026-10-28T09:00:00Z"
        },
        {
          "id": "c3333333-0000-0000-0000-000000000004",
          "name": "1Password",
          "bundle_id": "com.1password.1password",
          "path": "/Applications/1Password.app",
          "display_order": 3,
          "added_at": "2026-10-28T09:00:00Z"
        }
      ]
    }
  ]
}
```

---

## 4. Bảng Câu hỏi Thường gặp & Phương án Xử lý Sự cố Demo (FAQ & Contingency)

### 4.1. Câu hỏi Thường gặp từ Stakeholders (FAQ)
1. **Hỏi: VXDeck có làm chậm máy hay tốn RAM khi chạy ngầm không?**  
   *Trả lời:* Hoàn toàn không. VXDeck được viết 100% bằng Swift và AppKit native tối giản. Mục tiêu hiệu năng được kiểm chứng: Khi popup ẩn, mức tiêu thụ CPU tiệm cận 0.0% và RAM chiếm khoảng 25-35MB (chủ yếu là bộ nhớ đệm cache icon Retina đã nạp).
2. **Hỏi: Tại sao không làm phím tắt toàn cầu (Global Hotkey)?**  
   *Trả lời:* Trong phạm vi MVP, mục tiêu là giữ ứng dụng cực kỳ tinh gọn và không đòi hỏi quyền can thiệp hệ thống. Nhấp vào icon Dock là hành vi tự nhiên nhất của người dùng chuột/trackpad. Phím tắt toàn cầu có thể được xem xét như một tính năng tùy chọn trong các phiên bản tiếp theo.
3. **Hỏi: Nếu tôi xóa một app trong VXDeck thì file gốc có bị mất không?**  
   *Trả lời:* Chắc chắn không. VXDeck chỉ lưu trữ đường dẫn và Bundle ID. Xóa trong VXDeck tương tự như việc xóa một bookmark trên trình duyệt web, không bao giờ ảnh hưởng tới tệp cài đặt thật trên ổ đĩa.

### 4.2. Phương án Dự phòng khi Gặp Sự cố Kỹ thuật (Contingency Playbook)

| Tình huống Sự cố | Nguyên nhân có thể | Phương án Xử lý Tức thì tại Buổi Demo |
| :--- | :--- | :--- |
| Click icon Dock nhưng popup không hiện | Cửa sổ bị che bởi màn hình toàn màn hình khác | Bấm phím tắt chuyển Spaces hoặc bấm lại icon Dock lần 2 |
| App đích bấm vào báo "Không tìm thấy" | Ứng dụng mẫu chưa cài trên máy demo | Chuẩn bị trước các app mặc định của macOS như Safari, TextEdit, Calculator |
| Thao tác kéo thả bị giật trên màn hình 144Hz | Chế độ tiết kiệm pin (Low Power Mode) | Tắt Low Power Mode, cắm sạc máy Mac trước buổi demo |
| Tệp cấu hình bị lỗi do thao tác thử nghiệm trước đó | Dữ liệu cũ không đồng bộ schema | Chạy script khôi phục file seed data mẫu 1-chạm (`scripts/reset_demo_data.sh`) |
