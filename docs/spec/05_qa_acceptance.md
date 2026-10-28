# 05. Tiêu chuẩn Nghiệm thu & QA Checklist — VXDeck (`_spec5_qa_acceptance`)

> **Tên sản phẩm:** VXDeck (Lightweight Curated Application Launcher Popup)  
> **Thư mục dự án:** `vxdeck`  
> **Phiên bản tài liệu:** 1.0.0  
> **Ngày cập nhật:** 2026-10-28  
> **Tài liệu nguồn phạm vi:** [VXDeck_MVP_Scope.md](../../VXDeck_MVP_Scope.md)  
> **Tài liệu liên quan:** [00_system_overview.md](00_system_overview.md) | [02_feature_flow.md](02_feature_flow.md)

---

## 1. Mục đích & Phạm vi

Tài liệu này định nghĩa toàn bộ tiêu chuẩn nghiệm thu (Acceptance Criteria) theo chuẩn Gherkin, ma trận các trường hợp biên và kịch bản lỗi (Edge Cases & Negative Scenarios), quy tắc kiểm định tính hợp lệ dữ liệu (Validation Rules) và danh mục kiểm thử bàn giao (QA Checklist) cho ứng dụng VXDeck trên macOS.

---

## 2. Tiêu chuẩn Nghiệm thu theo Cú pháp Gherkin (Acceptance Criteria)

### Kịch bản 1: Kích hoạt hiển thị Popup từ Dock lần đầu
```gherkin
Scenario: Hiển thị popup nổi không viền khi click icon trên Dock
  Given Ứng dụng VXDeck đang chạy ngầm hoặc vừa được mở từ Dock
  And Cửa sổ popup hiện đang ở trạng thái ẩn (HIDDEN)
  When Người dùng nhấp chuột vào biểu tượng VXDeck trên thanh Dock
  Then Một cửa sổ popup nổi (NSPanel) xuất hiện ngay lập tức trên màn hình
  And Cửa sổ hoàn toàn không có thanh tiêu đề OS và không có các nút traffic lights
  And Cửa sổ có độ rộng cố định 620px với các góc bo tròn 16px
  And Độ sâu bóng đổ hiển thị nổi rõ ràng phía trên các cửa sổ ứng dụng khác
```

### Kịch bản 2: Khởi chạy Ứng dụng 1-chạm & Tự động ẩn Popup (Happy Path)
```gherkin
Scenario: Nhấp 1-chạm vào icon ứng dụng để mở và tự động ẩn popup
  Given Cửa sổ VXDeck đang hiển thị ở chế độ bình thường (VIEW_ACTIVE)
  And Bộ sưu tập "Thiết Kế" đang hiển thị ứng dụng "Figma" hợp lệ
  When Người dùng nhấp chuột trái một lần vào thẻ ứng dụng "Figma"
  Then Thẻ icon có hiệu ứng nhấp co lại nhẹ (scale 94%) trong 80ms
  And Hệ thống gọi NSWorkspace mở ứng dụng Figma
  And Cửa sổ popup VXDeck tự động biến mất mượt mà sau 120ms
  And Tiến trình VXDeck vẫn chạy trên Dock, không bị thoát (Does NOT quit)
  And Focus của hệ điều hành được chuyển giao hoàn toàn cho ứng dụng Figma
```

### Kịch bản 3: Ẩn Popup bằng Phím Escape hoặc Click ra ngoài
```gherkin
Scenario: Người dùng bấm Escape hoặc nhấp chuột ngoài cửa sổ để ẩn popup
  Given Cửa sổ VXDeck đang hiển thị ở chế độ bình thường (VIEW_ACTIVE)
  When Người dùng nhấn phím cứng Escape trên bàn phím
    Or Người dùng nhấp chuột vào một điểm bất kỳ bên ngoài khung cửa sổ VXDeck
  Then Cửa sổ popup VXDeck lập tức ẩn đi
  And Khi nhấp lại vào biểu tượng Dock, popup xuất hiện trở lại với nguyên vẹn nội dung
```

### Kịch bản 4: Chuyển đổi Bật / Tắt Chế độ Chỉnh sửa (Edit Mode)
```gherkin
Scenario: Bật và tắt chế độ chỉnh sửa an toàn
  Given Cửa sổ VXDeck đang hiển thị ở chế độ bình thường (VIEW_ACTIVE)
  When Người dùng nhấp vào nút "Chỉnh sửa" (biểu tượng bút chì)
    Or Người dùng nhấn tổ hợp phím tắt Cmd + E
  Then Giao diện chuyển sang chế độ EDIT_ACTIVE
  And Nút bút chì đổi thành nút "Hoàn tất" (biểu tượng dấu tích xanh)
  And Mỗi thẻ ứng dụng hiển thị thêm huy hiệu nút xóa đỏ [x] góc trên bên trái
  And Cơ chế tự ẩn cửa sổ khi mất focus tạm thời bị vô hiệu hóa
  When Người dùng nhấp lại nút "Hoàn tất" hoặc phím Cmd + E
  Then Giao diện trở về VIEW_ACTIVE và các huy hiệu chỉnh sửa biến mất
```

### Kịch bản 5: Tạo Bộ sưu tập mới và Thêm Ứng dụng từ /Applications
```gherkin
Scenario: Tạo Collection mới và thêm ứng dụng qua hộp thoại chọn file native
  Given Người dùng đang ở chế độ chỉnh sửa (EDIT_ACTIVE)
  When Người dùng nhấp nút "+ Thêm Bộ sưu tập mới"
  And Nhập tên bộ sưu tập "Lập Trình Web"
  Then Bộ sưu tập mới xuất hiện trong danh sách với 0 ứng dụng
  When Người dùng nhấp nút "+ Thêm ứng dụng" trong nhóm "Lập Trình Web"
  Then Hộp thoại native NSOpenPanel xuất hiện tại thư mục /Applications
  When Người dùng chọn ứng dụng "Visual Studio Code.app" và bấm Open
  Then Ứng dụng xuất hiện ngay lập tức trong nhóm với icon native Retina và tên "Code"
  And Tệp deck_config.json được cập nhật ghi nguyên tử xuống đĩa
```

### Kịch bản 6: Kéo Thả Sắp Xếp Icon trong cùng Collection
```gherkin
Scenario: Sắp xếp lại thứ tự ứng dụng trong nội bộ bộ sưu tập
  Given Người dùng đang ở chế độ chỉnh sửa (EDIT_ACTIVE)
  And Bộ sưu tập đang có 3 ứng dụng: [A, B, C]
  When Người dùng nhấn giữ và kéo thẻ icon [C] thả vào giữa [A] và [B]
  Then Thứ tự trong danh sách hiển thị chuyển thành: [A, C, B]
  And Thao tác kéo không kích hoạt lệnh mở ứng dụng [C]
  When Người dùng thoát ứng dụng VXDeck và mở lại
  Then Thứ tự [A, C, B] vẫn được bảo toàn nguyên vẹn
```

### Kịch bản 7: Kéo Thả Di Chuyển Ứng Dụng Xuyên Bộ Sưu Tập
```gherkin
Scenario: Chuyển ứng dụng từ Collection A sang Collection B
  Given Người dùng đang ở chế độ chỉnh sửa (EDIT_ACTIVE)
  And Collection A có ứng dụng "Slack", Collection B rỗng
  When Người dùng kéo thẻ "Slack" từ Collection A và thả vào khung Collection B
  Then "Slack" biến mất khỏi Collection A và xuất hiện tại Collection B
  And Thay đổi được lưu ngay lập tức vào tệp cấu hình
```

### Kịch bản 8: Xóa Shortcut và Xóa Collection (An toàn Tuyệt đối)
```gherkin
Scenario: Xóa shortcut hoặc bộ sưu tập mà không làm ảnh hưởng tệp gốc trên máy
  Given Người dùng đang ở chế độ chỉnh sửa (EDIT_ACTIVE)
  When Người dùng bấm huy hiệu xóa đỏ [x] trên thẻ "Figma"
  Then Thẻ "Figma" biến mất khỏi giao diện VXDeck
  And Tệp gốc /Applications/Figma.app trên ổ đĩa vẫn nguyên vẹn 100%
  When Người dùng bấm nút xóa cả bộ sưu tập "Thiết Kế"
  And Xác nhận đồng ý trên hộp thoại cảnh báo
  Then Bộ sưu tập biến mất khỏi cấu hình VXDeck
  And Không có bất kỳ tệp ứng dụng nào trên macOS bị xóa hoặc gỡ cài đặt
```

### Kịch bản 9: Xử lý Ứng dụng Bị Di chuyển hoặc Gỡ cài đặt (Unavailable State)
```gherkin
Scenario: Ứng dụng trong danh sách đã bị người dùng xóa khỏi thư mục /Applications
  Given Trong danh sách VXDeck có ứng dụng "OldApp" đã bị xóa khỏi ổ đĩa
  When Người dùng mở popup VXDeck
  Then Thẻ "OldApp" hiển thị ở trạng thái mờ (Grayscale) kèm icon tam giác cảnh báo
  When Người dùng nhấp vào thẻ "OldApp"
  Then Popup không bị ẩn và không mở sai ứng dụng khác
  And Hiển thị popover thông báo: "Không tìm thấy ứng dụng tại đường dẫn cũ. Bạn có muốn định vị lại hoặc xóa khỏi danh sách?"
```

### Kịch bản 10: Cuộn Dọc Danh Sách Dài Mượt Mà
```gherkin
Scenario: Hiển thị mượt mà khi danh sách có nhiều bộ sưu tập vượt quá chiều cao màn hình
  Given Người dùng đã tạo 8 bộ sưu tập với tổng cộng hơn 50 ứng dụng
  When Popup VXDeck hiển thị
  Then Chiều cao cửa sổ tự động dừng lại ở mức tối đa an toàn (80% chiều cao màn hình)
  And Vùng nội dung bên trong cuộn dọc mượt mà bằng con lăn chuột hoặc trackpad
  And Thanh cuộn hiển thị siêu mảnh, tự ẩn khi không cuộn
  And Header và Footer vẫn cố định ở hai đầu, không bị cuộn trôi
```

### Kịch bản 11: Đổi tên Bộ sưu tập Trực tiếp (Inline Rename)
```gherkin
Scenario: Người dùng đổi tên bộ sưu tập trong chế độ Edit Mode
  Given Người dùng đang ở chế độ chỉnh sửa (EDIT_ACTIVE)
  When Người dùng nhấp đúp hoặc bấm icon bút chì cạnh tiêu đề "Nhóm Cũ"
  And Nhập tên mới "Công Cụ Thiết Kế" (tối đa 50 ký tự) và nhấn phím Enter
  Then Tiêu đề nhóm cập nhật thành "Công Cụ Thiết Kế"
  And Thay đổi được lưu nguyên tử xuống tệp cấu hình
```

### Kịch bản 12: Định vị lại Ứng dụng Không Khả Dụng (Relink Missing App)
```gherkin
Scenario: Người dùng định vị lại đường dẫn cho ứng dụng bị di chuyển
  Given Trong danh sách có thẻ "Sketch" ở trạng thái Unavailable
  When Người dùng nhấp vào thẻ và chọn "Định vị lại ứng dụng..."
  Then Hộp thoại NSOpenPanel xuất hiện
  When Người dùng chọn tệp Sketch.app tại đường dẫn mới và xác nhận
  Then Thẻ Sketch trở về trạng thái bình thường (màu sắc đầy đủ)
  And Đường dẫn mới được lưu bền vững vào deck_config.json
```

### Kịch bản 13: Xử lý Tệp Cấu hình Bị Hỏng Cú pháp (Corrupt File Recovery)
```gherkin
Scenario: Ứng dụng khởi động khi tệp JSON cấu hình bị hỏng nội dung ngoài ý muốn
  Given Tệp ~/Library/Application Support/VXDeck/deck_config.json chứa dữ liệu JSON lỗi
  When Khởi chạy ứng dụng VXDeck
  Then Ứng dụng không bị crash
  And Tệp hỏng được đổi tên thành deck_config.json.corrupt.<timestamp> để lưu vết
  And Ứng dụng khôi phục từ tệp .bak gần nhất (nếu có) hoặc khởi tạo giao diện rỗng an toàn
```

### Kịch bản 14: Thoát Ứng dụng Đột ngột sau khi Kéo thả (Flush on Terminate)
```gherkin
Scenario: Người dùng sắp xếp icon và nhấn Cmd+Q thoát app ngay trong khoảng thời gian debounce
  Given Người dùng vừa kéo thả sắp xếp 3 ứng dụng trong Edit Mode
  When Người dùng nhấn Cmd + Q thoát ứng dụng ngay lập tức (dưới 300ms)
  Then Hàm applicationWillTerminate kích hoạt flush() đồng bộ dữ liệu đang chờ xuống đĩa
  When Người dùng mở lại ứng dụng VXDeck
  Then Thứ tự sắp xếp mới nhất được bảo toàn trọn vẹn 100%
```

---

## 3. Ma trận Edge Cases & Kiểm thử Tiêu cực (Negative Testing Matrix)

| ID | Tình huống Biên / Tiêu cực | Hành vi Kỳ vọng của Hệ thống | Trạng thái Nghiệm thu |
| :--- | :--- | :--- | :--- |
| **EC-01** | Bấm liên tục vào icon Dock 5 lần trong 1 giây | Cửa sổ đưa lên trước mượt mà, không sinh thêm tiến trình hay cửa sổ đúp | CHƯA KIỂM THỬ |
| **EC-02** | Chọn tệp không phải `.app` trong `NSOpenPanel` | Panel khóa bộ lọc chỉ chọn được `.app`; nếu chọn thư mục thường sẽ bị từ chối | CHƯA KIỂM THỬ |
| **EC-03** | Đang kéo thẻ icon thì thả chuột ra ngoài viền màn hình | Thao tác kéo bị hủy an toàn, thẻ quay về vị trí ban đầu trong danh sách | CHƯA KIỂM THỬ |
| **EC-04** | Nhấp chuột rất nhanh (Rapid Click) vào thẻ app | Chỉ gửi 1 lệnh `openApplication` duy nhất, không kích hoạt app nhiều lần | CHƯA KIỂM THỬ |
| **EC-05** | Tệp `deck_config.json` bị người dùng xóa thủ công ngoài Finder | Tự động tái tạo tệp mặc định mới với trạng thái rỗng mà không bị crash | CHƯA KIỂM THỬ |
| **EC-06** | Thao tác kéo thả 10 lần liên tục trong 1 giây | Debounce 300ms gom các lượt cập nhật, chỉ ghi đĩa 1-2 lần, không nghẽn I/O | CHƯA KIỂM THỬ |
| **EC-07** | Đang mở hộp thoại `NSOpenPanel` thì click ra ngoài | Hộp thoại modal giữ focus cho đến khi bấm Open hoặc Cancel; không tự đóng app | CHƯA KIỂM THỬ |
| **EC-08** | Chạy trên hệ thống nhiều màn hình (Dual Monitors) | Popup xuất hiện chính xác trên màn hình hiện tại đang có con trỏ chuột/Dock | CHƯA KIỂM THỬ |

---

## 4. Bảng Quy tắc Kiểm tra Dữ liệu (Validation Rules)

| Trường dữ liệu | Quy tắc Kiểm tra (Frontend & Backend) | Phản hồi khi Vi phạm |
| :--- | :--- | :--- |
| `collection.title` | Tối thiểu 1 ký tự, tối đa 50 ký tự; tự động `trim()` khoảng trắng hai đầu; không được để trống | Viền đỏ nhẹ quanh ô nhập; thông báo: "Tên nhóm không được để trống" |
| `app.path` | Bắt buộc kết thúc bằng phần mở rộng `.app`; tệp phải tồn tại trên ổ đĩa tại thời điểm thêm | Bỏ qua tệp và thông báo: "Vui lòng chọn tệp ứng dụng hợp lệ (.app)" |
| `app.bundle_id` | Định dạng chuỗi nhận diện ngược (Reverse Domain, ví dụ `com.company.app`) | Lưu `nil` nếu app nội bộ không khai báo `CFBundleIdentifier` |
| `items.count` | Không giới hạn số lượng app trong 1 Collection (tự động wrap lưới xuống dòng) | Không giới hạn; lưới mở rộng linh hoạt |

---

## 5. QA Handoff Checklist (Danh mục Bàn giao)

### A. Kiểm tra Biên dịch & Đóng gói (Build & Package)
- [ ] Lệnh `swift build -c release` biên dịch thành công không cảnh báo (0 errors, 0 warnings).
- [ ] Kịch bản `bundle_app.sh` đóng gói thành công tệp `VXDeck.app` có cấu trúc bundle hợp lệ.
- [ ] Kiểm tra chữ ký số ad-hoc: `codesign --verify --deep --strict VXDeck.app` trả về `valid on disk`.
- [ ] Khởi chạy thành công qua lệnh `open VXDeck.app` và xuất hiện icon trên thanh Dock.

### B. Kiểm tra Giao diện & Trải nghiệm (UI/UX)
- [ ] Popup hiển thị không viền, không có thanh title bar hay traffic lights.
- [ ] Bo góc 16px sắc nét, bóng đổ nổi bật chuẩn Dark mode `#0f1117`.
- [ ] Icon app hiển thị sắc nét ở độ phân giải Retina (48×48pt).
- [ ] Header và Footer cố định, vùng giữa cuộn dọc mượt mà khi có nhiều nhóm.

### C. Kiểm tra Chức năng & Tương tác (Functional)
- [ ] Nhấp 1-chạm mở đúng ứng dụng đích qua `NSWorkspace`.
- [ ] Popup tự ẩn sau khi mở app; tiến trình VXDeck vẫn chạy nền trên Dock.
- [ ] Phím `Escape` và click bên ngoài cửa sổ ẩn popup ngay lập tức.
- [ ] Edit Mode hoạt động ổn định: Không tự ẩn cửa sổ khi đang kéo hoặc chọn file.
- [ ] Thêm ứng dụng qua `NSOpenPanel` nạp đúng tên và biểu tượng.
- [ ] Kéo thả sắp xếp thứ tự trong cùng nhóm và chuyển nhóm hoạt động mượt mà.
- [ ] Khởi động lại máy hoặc tắt mở lại app: Toàn bộ thứ tự sắp xếp được giữ nguyên 100%.
- [ ] Xóa shortcut và xóa Collection không làm mất bất kỳ tệp ứng dụng gốc nào trên máy.
