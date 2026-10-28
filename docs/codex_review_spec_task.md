# Nhiệm vụ: Tham vấn & Review Bộ Tài liệu Đặc tả Kỹ thuật VXDeck

Vai trò: Chỉ tham vấn/review chỉ đọc; không sửa nguồn; không gọi agent khác.
Tuân thủ AGENTS.md, tiếng Việt chuyên nghiệp, UTF-8, snake_case và tuyệt đối không dùng LaTeX.

## 1. Bối cảnh dự án
Dự án **VXDeck** — bảng sưu tập ứng dụng nổi dạng popup (Curated Application Launcher Board) dành riêng cho macOS (Apple Silicon & Intel).
- Tài liệu phạm vi gốc (Single Source of Scope): `vxdeck/VXDeck_MVP_Scope.md`.
- Quy chuẩn thiết kế giao diện: `.agents/desktop_ui_standards.md` và `_summary/master_theme.md`.

Bộ tài liệu đặc tả (Docs / Spec Suite) gồm 7 tài liệu tại thư mục `vxdeck/docs/spec/`:
- `vxdeck/docs/spec/00_system_overview.md`: Tổng quan hệ thống, tôn chỉ sản phẩm (không cạnh tranh Spotlight/Launchpad, curated collection board nổi), ma trận độ khó kỹ thuật, ngăn xếp công nghệ Swift 6 + SwiftUI + AppKit NSPanel, cây thư mục dự án và lộ trình Vertical Slice.
- `vxdeck/docs/spec/01_business_process.md`: 3 chu trình SIPOC, 3 sơ đồ Swimlane BPMN 2.0 (1-Click Launch, Add App, Drag & Drop), 3 ma trận quyết định nghiệp vụ (Dismissal Policy, Launch & Fallback, Duplicate & Safe Deletion).
- `vxdeck/docs/spec/02_feature_flow.md`: 7 luồng người dùng chi tiết, 2 sơ đồ Sequence Diagrams, FSM vòng đời cửa sổ (6 trạng thái) và FSM thẻ icon, 4 giao ước thực thi logic máy đọc được (toggle, launch, add, reorder).
- `vxdeck/docs/spec/03_ui_wireframe.md`: Bố cục hình học 620px borderless popup, bo góc 16px, bóng đổ 2xl, bản vẽ ASCII wireframe cho cả View Mode và Edit Mode, cây phân cấp SwiftUI, bảng design tokens Dark-first (#0f1117, Electric Cyan), ma trận trạng thái UI thẻ app và visual wireframe prompts.
- `vxdeck/docs/spec/04_api_data.md`: Cấu trúc lưu trữ cục bộ `~/Library/Application Support/VXDeck/deck_config.json`, cơ chế ghi tệp nguyên tử (Atomic Write via Staging File), Draft 2020-12 JSON Schema, định nghĩa Swift Models chuẩn (Codable, Identifiable, Sendable), giao ước AppKit NSWorkspace / NSPanel, giao thức kéo thả UTI `com.vxdeck.app-item` và ma trận mã lỗi hệ thống.
- `vxdeck/docs/spec/05_qa_acceptance.md`: 10 kịch bản nghiệm thu Gherkin bao phủ 100% MVP Scope, 8 ca kiểm thử biên/tiêu cực (EC-01 đến EC-08), quy tắc validation dữ liệu và QA Handoff Checklist.
- `vxdeck/docs/spec/06_demo_presentation.md`: Kịch bản demo 5 phút, bộ dữ liệu mẫu (Seed Data) 3 nhóm với 12 app thực tế, bộ FAQ và phương án ứng phó sự cố tại buổi demo.

## 2. Yêu cầu Review & Phản biện từ Codex
Codex hãy đọc kỹ toàn bộ 7 file spec trên và đưa ra phản biện, nhận xét chuyên sâu tập trung vào 4 trọng tâm:
1. **Tính khả thi và độ hoàn thiện kiến trúc:**
   - Việc xây dựng app bằng Swift 6 + AppKit (`NSPanel`, `NSWorkspace`, `NSOpenPanel`) + SwiftUI kết hợp SPM CLI (không dùng full Xcode IDE) có gặp rào cản nào về cấu trúc bundle, resource, entitlements hoặc Designated Requirement trên macOS 26 / SDK 27.0 không?
   - Cửa sổ nổi không viền `NSPanel` (`styleMask = [.borderless, .nonactivatingPanel]`, `level = .floating`): Hành vi bắt sự kiện click ngoài (`NSEvent.addGlobalMonitorForEvents`), toggle từ Dock (`applicationShouldHandleReopen`), và cách bảo vệ cửa sổ không bị ẩn khi ở Edit Mode hoặc khi mở `NSOpenPanel` đã đủ chặt chẽ chưa?
2. **Kéo thả & Tương tác Lưới ứng dụng (Drag & Drop Reordering):**
   - Sự phân tách giữa View Mode (1-Click Launch) và Edit Mode (Drag & Drop, Delete badge) đã giải quyết triệt để xung đột giữa cử chỉ nhấp chuột và kéo thả chưa?
   - Giao thức UTI `com.vxdeck.app-item` và việc cập nhật `display_order` giữa các Collection có điểm nghẽn hay nguy cơ race condition nào không?
3. **Tính nhất quán chéo (Cross-Spec Consistency):**
   - Đối chiếu giữa `02_feature_flow.md`, `03_ui_wireframe.md` và `04_api_data.md`: Các thuộc tính trong Swift Models (`AppItemModel`, `CollectionModel`, `DeckConfig`) và JSON Schema có đồng bộ tuyệt đối về naming (snake_case trong JSON, camelCase trong Swift) và các trường bắt buộc không?
   - Cơ chế trích xuất icon Retina native (`NSWorkspace.shared.icon(forFile:)`), caching và xử lý trạng thái Unavailable khi app bị di chuyển/xóa đã đầy đủ chưa?
4. **Bẫy tiềm ẩn (Gotchas) & Đề xuất hành động trước khi triển khai Vertical Slice:**
   - Những lưu ý quan trọng để khi tiến hành tạo Package.swift và dựng Vertical Slice (Cửa sổ nổi mở từ Dock -> 1 Collection -> 1 App -> 1-Click Launch -> Tự ẩn -> Lưu đĩa) thành công ngay từ lượt đầu tiên.

## 3. Định dạng đầu ra mong muốn
- Đánh giá tổng quan (Đạt / Cần bổ sung).
- Phân loại nhận xét theo mức độ ưu tiên: [P1 - Nghiêm trọng / Cần xử lý ngay], [P2 - Cải thiện / Hoàn thiện], [P3 - Tối ưu hóa lâu dài].
- Nhận xét kỹ thuật gãy gọn, cụ thể, có căn cứ.
