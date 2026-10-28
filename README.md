# VXDeck — Curated Application Launcher Popup for macOS

> **VXDeck** là bảng sưu tập ứng dụng nổi (Curated Application Launcher Board) dạng popup nhẹ tênh dành riêng cho macOS (Apple Silicon & Intel).  
> Ứng dụng giúp người dùng phân nhóm và sắp xếp không gian các công cụ thường dùng theo danh mục (Collections), mở tức thì từ Dock, và kích hoạt ứng dụng mong muốn chỉ với 1-chạm (1-Click Launch).

---

## 1. Tôn chỉ Sản phẩm (Product Principles)

- **Không tái tạo Launchpad toàn màn hình:** VXDeck là một popup không viền (`borderless floating NSPanel`) gọn gàng, xuất hiện trên màn hình hiện tại khi bấm biểu tượng Dock.
- **Không cạnh tranh với Spotlight / Raycast:** Không quét toàn bộ ổ đĩa, không chạy service nền nặng nề, không bắt buộc người dùng phải gõ bàn phím khi chỉ muốn kích hoạt bằng chuột/trackpad.
- **Chỉ hiển thị ứng dụng do người dùng chủ động chọn (Explicit Curation):** Không tự động đổ hàng trăm app vào bảng. Người dùng tự tạo các nhóm làm việc (Thiết kế, Lập trình, Văn phòng...) và thêm đúng những app mình dùng hàng ngày.
- **Khởi chạy 1-chạm (1-Click Launch):** Nhấp chuột một lần để mở app qua native `NSWorkspace` API, popup tự động ẩn mượt mà ngay sau đó.
- **An toàn tuyệt đối (Read & Launch Only):** Chỉ lưu Bundle ID và đường dẫn tệp. Tuyệt đối không bao giờ chỉnh sửa, di chuyển hoặc xóa các gói `.app` gốc trên máy. Xóa shortcut hoặc xóa Collection chỉ tác động tới cấu hình của VXDeck.
- **Offline 100% & Zero-Privilege:** Không tài khoản, không đám mây, không theo dõi (telemetry), không yêu cầu quyền Admin hay quyền Accessibility.

---

## 2. Hệ thống Đặc tả Kỹ thuật (Specification Suite)

Bộ đặc tả kỹ thuật hoàn chỉnh làm Ground Truth cho quá trình triển khai tại thư mục [docs/spec/](docs/spec/):

1. [00_system_overview.md](docs/spec/00_system_overview.md) — Tổng quan hệ thống, tôn chỉ sản phẩm, ma trận độ khó kỹ thuật, ngăn xếp công nghệ và lộ trình Vertical Slice.
2. [01_business_process.md](docs/spec/01_business_process.md) — Quy trình nghiệp vụ vĩ mô, chu trình SIPOC, sơ đồ Swimlane BPMN 2.0 và ma trận quyết định an toàn dữ liệu.
3. [02_feature_flow.md](docs/spec/02_feature_flow.md) — Chi tiết 7 luồng người dùng, Sequence Diagrams, Finite State Machine (FSM) và Machine-Readable Logic Contracts.
4. [03_ui_wireframe.md](docs/spec/03_ui_wireframe.md) — Bố cục hình học 620pt popup không viền, bản vẽ ASCII wireframe cho View Mode và Edit Mode, cây phân cấp SwiftUI, bảng design tokens Dark-first (`#0f1117`, Electric Cyan).
5. [04_api_data.md](docs/spec/04_api_data.md) — Kiến trúc dữ liệu `deck_config.json`, quy trình ghi nguyên tử (Atomic Write via Staging File), Draft 2020-12 JSON Schema, Swift Models (`Codable`, `Identifiable`, `Sendable`), giao ước AppKit `NSWorkspace` / `NSPanel` và UTI kéo thả `com.vxdeck.app-item`.
6. [05_qa_acceptance.md](docs/spec/05_qa_acceptance.md) — 14 kịch bản nghiệm thu Gherkin bao phủ 100% MVP Scope, 8 ca kiểm thử biên/tiêu cực (Edge Cases) và QA Handoff Checklist.
7. [06_demo_presentation.md](docs/spec/06_demo_presentation.md) — Kịch bản demo 5 phút, bộ dữ liệu mẫu (Seed Data) 12 app thực tế, bộ câu hỏi thường gặp (FAQ) và phương án xử lý sự cố.

---

## 3. Ngăn xếp Công nghệ (Tech Stack)

- **Ngôn ngữ:** Swift 6.0+
- **Giao diện:** SwiftUI (Grid layout, View/Edit mode, Dark-first styling)
- **Hệ thống & Cửa sổ:** AppKit (`NSPanel`, `NSApplicationDelegate`, `NSWorkspace`, `NSOpenPanel`, `NSEvent`)
- **Quản lý bản dựng:** Swift Package Manager (`Package.swift`) kết hợp Xcode Command Line Tools (CLT)
- **Baseline hệ điều hành:** macOS 14.0+ (Tối ưu hóa sâu cho macOS 26 / SDK 27.0)

---

## 4. Tài liệu Tham khảo

- [VXDeck_MVP_Scope.md](VXDeck_MVP_Scope.md) — Tài liệu phạm vi MVP ban đầu.
- [docs/codex_review_spec_response.md](docs/codex_review_spec_response.md) — Báo cáo phản biện độc lập từ Codex CLI.
