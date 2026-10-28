**Kết luận: Cần chỉnh sửa trước khi nghiệm thu MVP.** Kiến trúc phân tách Core/AppKit/SwiftUI hợp lý, nhưng còn lỗi bảo toàn cấu hình, xác thực ứng dụng và bảo vệ phiên chỉnh sửa. Các bằng chứng build và 4 suites PASS trong task chưa bao phủ những lỗi này.

Tôi chỉ đọc mã nguồn và tài liệu; không sửa file, không chạy app/build/test, không gọi agent khác. Kiểm tra artifact bằng `file` xác nhận binary hiện tại chỉ có **arm64**.

**[P1 — Khuyến nghị nghiêm trọng]**

1. **Luồng thoát không thực sự chờ lưu xong.**  
   Tại [AppDelegate.swift:37](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeck/App/AppDelegate.swift:37), `applicationWillTerminate` tạo `Task` rồi chặn main thread bằng semaphore. Task kế thừa MainActor nên không thể tiến hành khi main thread đang bị chặn; sau một giây timeout, ứng dụng tiếp tục thoát. Đồng thời, [ConfigManager.swift:133](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Store/ConfigManager.swift:133) có `flush()` rỗng, không quản lý hay chờ các save task của store.  
   **Hậu quả:** chỉnh sửa rồi thoát ngay có thể mất thay đổi; mỗi lần thoát còn bị chờ timeout. Cần một luồng kết thúc bất đồng bộ có theo dõi save đang chờ và chỉ cho phép thoát khi snapshot cuối đã được ghi hoặc lỗi được xử lý.

2. **Actor chưa bảo đảm snapshot mới nhất thắng.**  
   [DeckStore.swift:50](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Store/DeckStore.swift:50) tạo một Task độc lập cho mỗi snapshot. `revision` tại [ConfigManager.swift:122](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Store/ConfigManager.swift:122) chỉ tăng sau khi ghi, không được gắn vào snapshot và không từ chối snapshot cũ.  
   Actor bảo đảm loại trừ truy cập đồng thời, nhưng không bảo đảm FIFO giữa các task chờ actor. Vì vậy, mã hiện tại thiếu cơ chế chống ghi đè ngược như đặc tả yêu cầu. Cần cấp revision tại thời điểm thay đổi và kiểm tra revision trong writer, hoặc dùng một pipeline lưu có thứ tự và chờ được. Đây là rủi ro từ thiết kế, chưa phải lỗi đã tái hiện runtime. [Đặc tả Swift Actors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md).

3. **Kiểm thử đang đọc/ghi cấu hình thật của người dùng.**  
   [DeckCoreTests.swift:89](/Users/vic/_Work/VXUtilities/vxdeck/Tests/VXDeckTests/DeckCoreTests.swift:89) tạo `DeckStore()` mặc định rồi `initialize()`. `ConfigManager` dùng cố định Application Support thật tại [ConfigManager.swift:11](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Store/ConfigManager.swift:11). Các thao tác tạo/xóa/reorder trong test đều phát sinh save thật.  
   Đặc biệt, test tìm nhóm bằng tiêu đề `"Nhóm Kiểm Thử"`; nếu người dùng đã có nhóm cùng tên, test có thể chọn và xóa nhóm đó. Cần inject thư mục fixture riêng trước khi chạy lại bộ test.

4. **Xác thực ứng dụng vẫn có nhánh chấp nhận mục tiêu không hợp lệ.**  
   [DeckStore.swift:105](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Store/DeckStore.swift:105) dùng điều kiện `extension == "app" || fileExists`: đường dẫn tồn tại bất kỳ đều được nhận, và đường dẫn `.app` không tồn tại cũng được nhận.  
   Tại [AppLauncher.swift:29](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Services/AppLauncher.swift:29), khi đã lưu bundle ID nhưng không đọc được bundle/bundle ID thực tế, hàm vẫn `return url`. Fallback cũng chọn ngay kết quả LaunchServices, chưa giải quyết trường hợp nhiều bản cài đặt cùng bundle ID.  
   Cần kiểm tra đồng thời phần mở rộng, tồn tại và bundle hợp lệ; khi không xác minh được định danh thì yêu cầu định vị lại. Hiện chưa đủ căn cứ cho tuyên bố “chống giả mạo”.

5. **Callback launch có thể đóng popup giữa phiên chỉnh sửa.**  
   [AppCardView.swift:138](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeck/Views/AppCardView.swift:138) chỉ kiểm tra `autoHideOnLaunch` và session ID. Chuyển sang Edit Mode không đổi session ID, callback cũng không kiểm tra `isEditMode` hoặc `isModalOpen`.  
   Kịch bản: mở app → lập tức bật Chỉnh sửa → launch hoàn tất → popup bị ẩn, đồng thời `hidePanel()` thoát Edit Mode. Cần kiểm tra trạng thái hiện tại trước khi ẩn. Context menu “Khởi chạy” cũng đang hoạt động trong Edit Mode.

**[P2 — Cải thiện / hoàn thiện trải nghiệm]**

6. **Nút xác nhận đổi tên nhóm làm mất nội dung vừa nhập.**  
   [CollectionSectionView.swift:58](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeck/Views/CollectionSectionView.swift:58) luôn gán `titleDraft = collection.title` trước khi toggle. Khi bấm dấu check, draft mới bị thay bằng tên cũ rồi được lưu lại. Nhấn Enter đi qua nhánh khác nên không mắc lỗi này. Cần chỉ khởi tạo draft khi bắt đầu sửa.

7. **Kéo thả dùng snapshot cũ tại thời điểm commit.**  
   [CollectionSectionView.swift:132](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeck/Views/CollectionSectionView.swift:132) tải payload bất đồng bộ rồi tìm index trên `collection` mà view đã capture. Nếu dữ liệu thay đổi trước callback, index có thể trỏ sang item khác; Edit Mode cũng không được kiểm tra lại trước mutation.  
   Cần resolve source/target bằng UUID trên store hiện tại trong cùng transaction. Ngoài ra:
   - Payload thực dùng `UTType.text`, khác contract `com.vxdeck.app-item`.
   - `.onDrag` được gắn cả trong View Mode.
   - [DeckStore.swift:215](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Store/DeckStore.swift:215) chỉ clamp giới hạn trên; `targetIndex < 0` có thể gây crash khi gọi API store.

   Công thức giảm index khi di chuyển xuống trong `reorderItems` phù hợp với quy ước **chèn trước vị trí đích**, không tự thân là lỗi lệch một vị trí.

8. **Lỗi lưu bị che khỏi người dùng.**  
   [DeckStore.swift:55](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Store/DeckStore.swift:55) chỉ `print` lỗi, trong khi UI vẫn báo thao tác thành công. [ConfigManager.swift:104](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Store/ConfigManager.swift:104) bỏ qua lỗi synchronize và backup.  
   Khi hết dung lượng hoặc mất quyền ghi, người dùng có thể tưởng dữ liệu đã được lưu. Cần trạng thái chưa lưu, thông báo lỗi và cơ chế retry; không nên mô tả việc ép ghi và backup là được bảo đảm khi lỗi đang bị bỏ qua.

9. **Event monitor còn nguy cơ xử lý nhầm phiên popup mới.**  
   [DeckPanel.swift:59](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeck/Window/DeckPanel.swift:59) chuyển sự kiện vào Task nhưng không capture session tại lúc nhận sự kiện; sau đó đọc vị trí chuột hiện tại thay vì vị trí gắn với sự kiện.  
   Với click Dock, nếu reopen chạy trước Task xử lý click ngoài, Task có thể ẩn ngay popup vừa hiện. `windowSessionId` hiện chỉ bảo vệ callback launch. Cần ràng buộc callback monitor với phiên hiển thị và kiểm thử cả hai thứ tự callback. Tôi chưa thấy cơ sở kết luận Task này tự gây deadlock; vấn đề chính là thứ tự và trạng thái.

10. **Chưa bảo đảm vị trí đa màn hình và phím tắt khi đang nhập liệu.**  
    [DeckPanel.swift:81](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeck/Window/DeckPanel.swift:81) chọn `NSScreen.main`, không chọn màn hình chứa con trỏ/Dock và không clamp toàn bộ kích thước vào `visibleFrame`.  
    `canBecomeKey = true` là phù hợp, nhưng override `keyDown` tại dòng 35 chưa bảo đảm Escape/Cmd+E luôn tới window khi TextField đang là first responder. Cần kiểm thử với focus tại từng ô nhập và triển khai command/key-equivalent phù hợp với responder chain. [Hướng dẫn xử lý bàn phím của Apple](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/HandlingKeyEvents/HandlingKeyEvents.html).

11. **Recovery và ứng dụng di chuyển chưa hoàn tất contract.**  
    [DeckConfig.swift:32](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeckCore/Models/DeckConfig.swift:32) chấp nhận thiếu trường và schema version chưa hỗ trợ; ví dụ `{}` được decode thành cấu hình rỗng thay vì kích hoạt recovery. Cần phân biệt migration hợp lệ với cấu hình không hợp lệ.  
    Fallback launch chưa cập nhật path đã resolve; icon và “Hiện trong Finder” vẫn dùng path cũ. UI cũng chưa có “Định vị lại ứng dụng…” như QA yêu cầu.

**Đánh giá `LocalState`**

[LocalState.swift:7](/Users/vic/_Work/VXUtilities/vxdeck/Sources/VXDeck/Views/LocalState.swift:7) là wrapper mỏng quanh `SwiftUI.State`, có `DynamicProperty`, setter và Binding được chuyển tiếp. Tôi **không thấy lỗi xác định từ mã hiện tại**, cũng chưa có lý do yêu cầu bỏ giải pháp này.

Tuy nhiên, build thành công chưa chứng minh khả năng thay thế hoàn toàn `@State`. Cần runtime QA cho cập nhật view, Binding của TextField/sheet, và việc giữ state khi danh sách reorder hoặc view được tạo lại. Nên coi đây là workaround cần kiểm chứng theo toolchain.

**[P3 — Tối ưu hóa tương lai]**

- Giới hạn API AppKit/icon về MainActor thay vì dựa rộng vào `@unchecked Sendable`.
- Bổ sung keyboard activation, accessibility label/action cho thẻ app đang dùng `onTapGesture`.
- Chuẩn hóa tên file mới theo `snake_case`; tách phần tạo nhóm đang trùng giữa header và root.
- Hoàn thiện debounce và test thứ tự bằng UUID thực tế: test reorder hiện chỉ kiểm tra `displayOrder`, nên chưa chứng minh đúng app đã chuyển vị trí.

**Giới hạn bằng chứng nghiệm thu**

Artifact hiện tại là **arm64**, chưa phải bằng chứng hỗ trợ Intel; script cũng chưa chỉ định build hai kiến trúc. Bộ test hiện chưa bao phủ persistence/recovery, callback trễ, launcher identity hay window lifecycle. Trước khi chốt MVP, cần kiểm chứng riêng các kịch bản sửa rồi thoát ngay, lỗi ghi đĩa, app bị thay thế/di chuyển, callback launch khi chuyển Edit Mode, Dock reopen và đa màn hình.