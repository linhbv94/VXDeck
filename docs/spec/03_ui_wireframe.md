# 03. Đặc tả Giao diện & Wireframe — VXDeck (`_spec3_ui_wireframe`)

> **Tên sản phẩm:** VXDeck (Lightweight Curated Application Launcher Popup)  
> **Thư mục dự án:** `vxdeck`  
> **Phiên bản tài liệu:** 1.1.0  
> **Ngày cập nhật:** 2026-10-29  
> **Quy chuẩn tuân thủ:** [desktop_ui_standards.md](../../../_summary/standard_docs/desktop_ui_standards.md) và [master_theme.md](../../../_summary/standard_docs/master_theme.md)  
> **Tài liệu liên quan:** [00_system_overview.md](00_system_overview.md) | [02_feature_flow.md](02_feature_flow.md)

---

## 1. Triết lý Thiết kế & Định dạng Cửa sổ

### 1.1. Bố cục Tổng thể & Kích thước Hình học (Geometry & Metrics)
- **Hình thức cửa sổ:** Cửa sổ nổi dạng Popup không viền (`borderless floating NSPanel`), hoàn toàn không có thanh tiêu đề OS hay các nút điều khiển traffic lights.
- **Kích thước chuẩn (theo đơn vị điểm ảnh logic pt của macOS):**
  - **Chiều rộng cố định (Width):** `620pt` (được tính toán tối ưu cho lưới 5 cột ứng dụng với độ rộng mỗi ô 100pt và khoảng cách đều đặn).
  - **Chiều cao thích ứng (Adaptive Height):** Tối thiểu `260pt`, tối đa `min(760pt, 80% screen_height)`. Khi nội dung nhiều hơn chiều cao tối đa, vùng thân tự động bật thanh cuộn dọc mảnh siêu mượt.
  - **Bo góc cửa sổ (Corner Radius):** `16pt` bo cong mềm mại chuẩn phong cách macOS hiện đại.
  - **Đường viền ngoài (Border):** `1pt solid rgba(255, 255, 255, 0.10)` (Dark) / `1pt solid rgba(0, 0, 0, 0.08)` (Light).
  - **Độ sâu bóng đổ (Elevation Shadow):** `shadow-2xl` (`0 25pt 50pt -12pt rgba(0, 0, 0, 0.55)`), tạo cảm giác bảng điều khiển nổi bồng bềnh ngay phía trên các cửa sổ ứng dụng khác.

### 1.2. Phân vùng Cấu trúc Giao diện (3 Phân Vùng Chính)

```text
┌────────────────────────────────────────────────────────────┐
│ 1. HEADER BAR (Chiều cao cố định 44pt)                     │
│    [Logo + VXDeck]               [+] Nhóm   [✏️ Sửa / Xong]│
├────────────────────────────────────────────────────────────┤
│ 2. MAIN SCROLL AREA (Vùng cuộn nội dung tự do)             │
│    ┌──────────────────────────────────────────────────┐    │
│    │ Collection 1: Thiết Kế & Đồ Họa (4)              │    │
│    │ [ Figma ] [ Sketch ] [ Photoshop ] [ Illustrator]│    │
│    ├──────────────────────────────────────────────────┤    │
│    │ Collection 2: Lập Trình & Terminal (5)           │    │
│    │ [ VS Code ] [ Xcode ] [ Ghostty ] [ Docker ] ... │    │
│    ├──────────────────────────────────────────────────┤    │
│    │ Collection 3: Tiện Ích Văn Phòng (4)             │    │
│    │ [ Chrome ] [ Slack ] [ Notion ] [ 1Password ]    │    │
│    └──────────────────────────────────────────────────┘    │
├────────────────────────────────────────────────────────────┤
│ 3. FOOTER BAR (Chiều cao cố định 28pt)                     │
│    [ESC] Đóng   •   [⌘E] Sửa   •   Nhấp 1-chạm để mở app   │
└────────────────────────────────────────────────────────────┘
```

---

## 2. Bản vẽ Khung Dây (ASCII Wireframes)

### 2.1. Chế độ Xem & Khởi chạy Bình thường (View Mode — Mặc định)

```text
+------------------------------------------------------------------+
|  [⚡ VXDeck]                              [+ Nhóm]  [✏️ Chỉnh sửa] |
+------------------------------------------------------------------+
|                                                                  |
|  THIẾT KẾ & SÁNG TẠO  (4)                                        |
|  +--------+   +--------+   +--------+   +--------+               |
|  | (Icon) |   | (Icon) |   | (Icon) |   | (Icon) |               |
|  | Figma  |   | Sketch |   | PS     |   | AI     |               |
|  +--------+   +--------+   +--------+   +--------+               |
|                                                                  |
|  LẬP TRÌNH & HỆ THỐNG  (5)                                       |
|  +--------+   +--------+   +--------+   +--------+   +--------+  |
|  | (Icon) |   | (Icon) |   | (Icon) |   | (Icon) |   | (Icon) |  |
|  |VS Code |   | Xcode  |   | Ghostty|   | Docker |   | TableP |  |
|  +--------+   +--------+   +--------+   +--------+   +--------+  |
|                                                                  |
|  GIAO TIẾP & CÔNG VIỆC  (3)                                      |
|  +--------+   +--------+   +--------+                            |
|  | (Icon) |   | (Icon) |   | (Icon) |                            |
|  | Chrome |   | Slack  |   | Notion |                            |
|  +--------+   +--------+   +--------+                            |
|                                                                  |
+------------------------------------------------------------------+
|  esc Đóng   •   ⌘E Chế độ sửa   •   Nhấp một chạm để mở app      |
+------------------------------------------------------------------+
```

### 2.2. Chế độ Biên tập & Kéo thả (Edit Mode)

```text
+------------------------------------------------------------------+
|  [⚡ VXDeck • Chế độ sửa]                           [✓ Hoàn tất] |
+------------------------------------------------------------------+
|                                                                  |
|  THIẾT KẾ & SÁNG TẠO  [✎] [🗑]                                    |
|  +-(x)----+   +-(x)----+   +-(x)----+   +-(x)----+   +--------+  |
|  | (Icon) |   | (Icon) |   | (Icon) |   | (Icon) |   |   +    |  |
|  | Figma  |   | Sketch |   | PS     |   | AI     |   |Thêm App|  |
|  | [:::]  |   | [:::]  |   | [:::]  |   | [:::]  |   | (Nét đứt| |
|  +--------+   +--------+   +--------+   +--------+   +--------+  |
|                                                                  |
|  LẬP TRÌNH & HỆ THỐNG  [✎] [🗑]                                   |
|  +-(x)----+   +-(x)----+                                         |
|  | (Icon) |   | (Icon) |                                         |
|  |VS Code |   | Xcode  |    <-- [Vạch chỉ báo thả màu Cyan]      |
|  | [:::]  |   | [:::]  |                                         |
|  +--------+   +--------+                                         |
|                                                                  |
|  +------------------------------------------------------------+  |
|  |             + Thêm Bộ sưu tập mới (Nét đứt)                 |  |
|  +------------------------------------------------------------+  |
|                                                                  |
+------------------------------------------------------------------+
|  Kéo để sắp xếp lại vị trí  •  Bấm (x) để xóa  •  esc Quay lại    |
+------------------------------------------------------------------+
```

---

## 3. Cây Phân cấp Thành phần Giao diện (SwiftUI Component Hierarchy)

```text
DeckPanel (AppKit Custom NSPanel)
└── NSHostingView
    └── DeckRootView
        ├── DeckHeaderView
        │   ├── AppBrandBadge (Logo icon 16×16 + Tên "VXDeck" 13px weight 600)
        │   ├── Spacer()
        │   ├── AddCollectionButton (Chỉ hiện khi ở Edit Mode hoặc hover)
        │   └── EditModeToggleButton (Icon Pencil ⟷ Checkmark, nền nhấn nhẹ)
        │
        ├── DeckScrollView (Custom ScrollView, showsIndicators = false)
        │   └── LazyVStack(spacing: 20)
        │       ├── ForEach(collections)
        │       │   └── CollectionSectionView
        │       │       ├── CollectionHeaderView
        │       │       │   ├── InlineEditableTitle (Chữ 12px weight 600, hỗ trợ sửa tên)
        │       │       │   ├── ItemCountBadge (Số lượng app, chữ 10px muted)
        │       │       │   ├── Spacer()
        │       │       │   └── CollectionActionsMenu (Nút sửa, nút xóa collection)
        │       │       │
        │       │       └── LazyVGrid(columns: 5, spacing: 14)
        │       │           ├── ForEach(items)
        │       │           │   └── AppCardView
        │       │           │       ├── IconContainer (48×48pt native Retina icon)
        │       │           │       │   ├── AppNativeIcon
        │       │           │       │   ├── DeleteBadge (Huy hiệu đỏ [x] ở Edit Mode)
        │       │           │       │   └── UnavailableBadge (Biểu tượng tam giác vàng nếu app bị mất)
        │       │           │       ├── AppTitleLabel (11px, tối đa 2 dòng, lineLimit 2)
        │       │           │       └── DragHandleOverlay (Kích hoạt khi ở Edit Mode)
        │       │           │
        │       │           └── AddAppCardPlaceholder (Khung nét đứt + icon +, mở NSOpenPanel)
        │       │
        │       └── AddCollectionBottomBar (Khung nét đứt dưới cùng danh sách)
        │
        └── DeckFooterView (Thanh trạng thái 24px)
            ├── ShortcutPills (Pill nền tối phím [Esc], [⌘E])
            ├── Spacer()
            └── ModeHintLabel (Chữ 10px màu muted hướng dẫn người dùng)
```

---

## 4. Bảng Tokens Thiết Kế & Màu Sắc Hệ Thống

Tuân thủ nghiêm ngặt theo [master_theme.md](../../../_summary/standard_docs/master_theme.md) và phong cách chung của bộ tiện ích VXUtilities:

### 4.1. Màu sắc Bề mặt & Viền (Surfaces & Borders)

| Thành phần Token | Dark Mode (Mặc định) | Light Mode (Phụ trợ) | Ý nghĩa sử dụng |
| :--- | :--- | :--- | :--- |
| **`panel_background`** | `rgba(15, 17, 23, 0.88)` | `rgba(248, 250, 252, 0.92)` | Nền cửa sổ popup có hiệu ứng mờ (Backdrop Blur 24px) |
| **`card_surface`** | `rgba(255, 255, 255, 0.03)` | `rgba(0, 0, 0, 0.02)` | Nền của từng thẻ ứng dụng khi hover |
| **`card_surface_hover`**| `rgba(255, 255, 255, 0.08)` | `rgba(0, 0, 0, 0.05)` | Nền thẻ khi chuột hover qua |
| **`border_subtle`** | `rgba(255, 255, 255, 0.08)` | `rgba(0, 0, 0, 0.08)` | Viền phân cách các khu vực và viền ngoài cửa sổ |
| **`border_focus`** | `rgba(6, 182, 212, 0.50)` | `rgba(6, 182, 212, 0.60)` | Viền sáng khi thả kéo (Drop target indicator) |
| **`accent_cyan`** | `#06b6d4` (`#22d3ee`) | `#0891b2` | Màu điểm nhấn cho nút bấm, badge và icon kích hoạt |
| **`danger_rose`** | `#fb7185` (`#f43f5e`) | `#e11d48` | Huy hiệu xóa [x], nút xác nhận xóa Collection |
| **`warning_amber`** | `#fbbf24` | `#d97706` | Cảnh báo app bị di chuyển/không tìm thấy file |

### 4.2. Kiểu Chữ & Kích Thước (Typography Tokens)

| Vai trò | Phông chữ | Cỡ chữ | Weight | Màu sắc (Dark) |
| :--- | :--- | :--- | :--- | :--- |
| **App Title Header** | System Default (`.system`) | `13px` | `600` (Semi-bold) | `#f8fafc` (Slate 50) |
| **Collection Title** | System Default (`.system`) | `12px` | `600` (Semi-bold) | `#cbd5e1` (Slate 300) |
| **App Card Label** | System Default (`.system`) | `11px` | `500` (Medium) | `#f1f5f9` (Slate 100) |
| **Item Count Badge** | Monospace (`.monospaced`) | `10px` | `400` (Regular) | `#94a3b8` (Slate 400) |
| **Footer Shortcut** | Monospace (`.monospaced`) | `10px` | `500` (Medium) | `#94a3b8` (Slate 400) |

---

## 5. Ma trận Trạng thái Thành phần UI (Component States Matrix)

### 5.1. Thẻ Ứng Dụng (`AppCardView`)

| Trạng thái (State) | Biểu tượng (Icon 48×48) | Nhãn tên (Label) | Nền thẻ (Container) | Phản hồi tương tác |
| :--- | :--- | :--- | :--- | :--- |
| **Default (Tĩnh)** | Màu gốc native Retina 100% | Chữ trắng xám `#f1f5f9` | Trong suốt | Không |
| **Hover (Rê chuột)** | Tăng độ sáng nhẹ (brightness 1.05) | Chữ trắng sáng `#ffffff` | Bo viền sáng mờ, nền sáng `0.06` | Con trỏ chuyển thành `pointingHand` |
| **Active (Nhấp click)**| Co lại nhẹ (`scale 0.94`), 80ms | Giữ nguyên | Nền nhấn `rgba(6, 182, 212, 0.15)` | Phản hồi nhấp mượt mà, mở app |
| **Edit Mode (Đang sửa)**| Thêm huy hiệu đỏ `(x)` góc trái trên | Giữ nguyên | Hiệu ứng rung nhẹ (jiggle 1 độ) | Click mở menu / bấm (x) để xóa |
| **Dragging (Đang kéo)**| Độ mờ giảm còn 40% (`opacity 0.4`)| Mờ 40% | Nền trong suốt | Ảnh kéo bán trong suốt theo con trỏ |
| **Drop Target (Vị trí thả)**| Dịch sang bên để chừa chỗ | Dịch chuyển theo | Vạch đứng phát quang màu Cyan `2px` | Báo vị trí chèn mới chuẩn xác |
| **Unavailable (Mất app)**| Trắng đen (Grayscale 100%) + mờ 50% | Chữ vàng cam gạch ngang nhẹ | Viền nét đứt cảnh báo màu vàng | Click mở thông báo định vị lại |

### 5.2. Khung Thêm Ứng Dụng Mới (`AddAppCardPlaceholder`)
- **Hiển thị:** Chỉ xuất hiện ở cuối mỗi Collection khi đang ở chế độ **Edit Mode**.
- **Kích thước:** Chiều rộng 96px, chiều cao 84px tương đương `AppCardView`.
- **Giao diện:** Viền nét đứt mảnh `border-dashed border-slate-600/60`, ở giữa là dấu cộng `+` màu `text-slate-400`.
- **Hover:** Đổi màu viền sang nét đứt Cyan `border-cyan-400/80`, dấu cộng sáng màu Cyan, con trỏ đổi sang `pointingHand`.
- **Click:** Kích hoạt mở hộp thoại chọn ứng dụng native `NSOpenPanel`.

---

## 6. Mô tả Visual Wireframe Dành cho AI UI Generation & Demo Prompts

```text
A sleek, modern macOS borderless floating launcher popup widget, designed with premium Dark Mode glassmorphism aesthetic (#0F1117 background with 85% opacity and 24px backdrop blur). The popup window has smooth 16px rounded corners, delicate 1px translucent border, and subtle deep drop shadow. 

The top header (44px) features a minimalist 'VXDeck' brand badge with an Electric Cyan lightning icon on the left, an 'Add Group' text button, and an active 'Edit' toggle button with a pencil icon on the right. 

The main content is a clean vertically stacked collection board:
1. First collection titled 'Design & Creative' with an item count badge '4', displaying a wrapping grid of high-resolution native macOS app icons (Figma, Sketch, Photoshop, Illustrator) with crisp 11px white labels underneath.
2. Second collection titled 'Development' with 5 icons (VS Code, Xcode, Ghostty, Docker, TablePlus).
Each app card is 96px wide, featuring a 48x48px native Retina icon with subtle hover glow. 

At the bottom is a discreet 28px footer displaying minimalist shortcut hints: [esc] Close, [Cmd+E] Edit, 'Click once to launch'. Ultra-clean desktop density, Cupertino design philosophy, zero visual clutter.
```


## Đồng bộ UI suite — Codex tiếp quản ngày2026-10-29

Theo [Settings](../../../_summary/standard_docs/settings_standards.md), [song ngữ](../../../_summary/standard_docs/bilingual_standards.md) và [updater](../../../_summary/standard_docs/auto_update_standards.md). Mục này cập nhật các mô tả cũ trái ranh giới General; không thay engine hoặc tự đánh dấu Specs ready/QA/release.

| Tab / surface | Key / owner | Capability, apply và persist |
|---|---|---|
| Chung | `DeckSettings.themeMode` | Hiển thị Dark hiện hành; không tạo4mode giả khi shell chỉ có Dark |
| Chung | `DeckSettings.language` | vi/en; Codable backward-compatible, persist trong config; đổi language không reset collection/data |
| Cửa sổ & khởi chạy | `autoHideOnLaunch`, `windowWidth` | Giữ popup click ngoài ẩn và resize; tách khỏi General |
| Updates | `AppUpdateController.shared` | Settings/notice/header cùng owner process; bỏ checker GitHubAPI/DMG unsigned trong Settings/DeckStore |

Settings header56/sidebar192/footer56, body scroll; About tên/version/tác giả/GitHub + mô tả ngắn; Support chỉ QR đóng gói hoặc placeholder, không đọc đường dẫn source máy dev. Notice trong popup góc dưới phải20/max384, job không phụ thuộc popup; install flush store và controller handoff/quit sauACK. Không thêm titlebar/menubar cho Deck. Bản dịch shell/Settings theo locale store; dynamic UI copy dùng localizedFormat theo instance store và giữ nguyên arguments user; native popup/updater E2E còn cần audit, không chứng nhận BI đầy đủ.

Bằng chứng/checks và giới hạn: [báo cáo Codex](../../../_summary/agents_handoff/suite_ui_codex_20261029_result.md). ST/BI/AU/TB native acceptance chỉ đạt khi có evidence phù hợp; source/build không tự đạt runtime.

### QA correction2026-10-29

Updater prepare gọi `try await store.flushForUpdate()` để chặn cài khi không ghi được preference. Thử lại sau khi lỗi lưu được khắc phục phải lưu snapshot mới và giữ draft/language. `flush()` best-effort dùng ở luồng cũ không phải bằng chứng đã lưu thành công cho updater. Chưa publish; native popup và handoff/readback còn QA riêng.

## Cập nhật Feedback 2026-10-29 (Anti UI)
- Glyph Header: Đổi icon tia sét (`bolt.fill`) sang icon bộ sưu tập ứng dụng (`square.grid.2x2.fill`).
- Settings Title: Bỏ icon bánh răng ở tiêu đề, hiển thị dạng text thuần 'Cài đặt VXDeck' / 'VXDeck Settings'.



## Feedback20261029 — component Settings theo Media

- [Hợp đồng chung](../../../_summary/standard_docs/settings_standards.md) và [nguồn component](../../../_summary/standard_codes/settings_ui/index.md) là nguồn chuẩn; không dùng ghi nhận "chỉ đổi header" ở lượt Anti đầu làm nghiệm thu các panel.
- Title VXabc Settings, không gear. General Theme→Language, Updates/banner+state, About/identity+GitHub+description, Support/banner+copy Media+QR. Chỉ mode theme thật; dữ liệu/config/updater job giữ owner hiện có.
- DevSync vendor webview helper + copy sinh + cùng CSS; Deck vendor helper SwiftUI + copy sinh, giữ popup và business bindings. Manifest và gate trước packaging bắt lỗi lệch nguồn.
- Native visual, entry point, min-size/scroll/keyboard và update E2E cần evidence riêng; build/hash không tự đạt. Windows giữ SVG+tên rồi menu trái, gear trước đúng một cụm controls phải. Deck không thêm shell/menu không cần thiết.
