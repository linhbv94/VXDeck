# 04. Kiến trúc Dữ liệu & Native Bridge Contracts — VXDeck (`_spec4_api_data`)

> **Tên sản phẩm:** VXDeck (Lightweight Curated Application Launcher Popup)  
> **Thư mục dự án:** `vxdeck`  
> **Phiên bản tài liệu:** 1.0.0  
> **Ngày cập nhật:** 2026-10-28  
> **Tài liệu liên quan:** [00_system_overview.md](00_system_overview.md) | [02_feature_flow.md](02_feature_flow.md)

---

## 1. Mục đích & Phạm vi

Tài liệu này đặc tả toàn bộ kiến trúc lưu trữ dữ liệu cục bộ (Local Persistence Schema), cấu trúc đối tượng trong bộ nhớ (In-Memory Swift Models), giao ước kết nối hệ điều hành macOS (Native AppKit / LaunchServices Contracts), cơ chế ghi tệp nguyên tử (Atomic File I/O) và ma trận mã lỗi hệ thống.

---

## 2. Kiến trúc Lưu trữ Cục bộ (Local Persistence Schema)

### 2.1. Đường dẫn Tệp & Quy tắc Quản lý Thư mục
- **Thư mục cấu hình ứng dụng:** `~/Library/Application Support/VXDeck/`
  - Nếu thư mục chưa tồn tại, ứng dụng tự động khởi tạo khi khởi động với quyền truy cập an toàn của người dùng hiện tại (`0755`).
- **Tệp cấu hình chính:** `~/Library/Application Support/VXDeck/deck_config.json`
- **Tệp cấu hình dự phòng (Backup):** `~/Library/Application Support/VXDeck/deck_config.json.bak`
- **Tệp tạm ghi nguyên tử (Staging):** `~/Library/Application Support/VXDeck/.deck_config.json.tmp.<uuid>`

### 2.2. Quy trình Ghi File Nguyên tử & Bảo Vệ Dữ liệu (Atomic Write Protocol)
Để đảm bảo tệp cấu hình không bao giờ bị hư hỏng (corrupted) hoặc bị cắt cụt (truncated) nếu xảy ra mất điện, sập nguồn hoặc tắt app đột ngột trong lúc đang kéo thả sắp xếp:

```text
┌────────────────────────────────────────────────────────────────────────┐
│               QUY TRÌNH GHI NGUYÊN TỬ (ATOMIC WRITE FLOW)               │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Encode RAM Model -> UTF-8 JSON Data (dateEncodingStrategy = .iso8601)│
│ 2. Quản lý tuần tự hóa qua Single Serial Actor (ConfigManager)          │
│ 3. Tạo tệp tạm: .deck_config.json.tmp.<UUID>                           │
│ 4. Ghi toàn bộ dữ liệu vào tệp tạm                                     │
│ 5. Gọi fsync() (hoặc FileHandle.synchronize()) ép dữ liệu xuống đĩa    │
│ 6. Đổi tên nguyên tử (Atomic Rename / replaceItemAt):                  │
│    .deck_config.json.tmp.<UUID> -> deck_config.json                    │
│ 7. Gắn số thứ tự sửa đổi (revision: Int) chống ghi đè ngược            │
│ 8. Hỗ trợ flush() ép ghi đồng bộ khi thoát ứng dụng                    │
│ 9. Khi tệp JSON hỏng: đổi tên thành .corrupt.<timestamp>, không xóa đè │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Lược đồ JSON Schema Chuẩn (Machine-Readable JSON Schema)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "VXDeckConfig",
  "description": "Cấu hình lưu trữ bộ sưu tập ứng dụng và thiết lập giao diện VXDeck",
  "type": "object",
  "required": ["version", "schema_version", "updated_at", "settings", "collections"],
  "properties": {
    "version": {
      "type": "string",
      "description": "Phiên bản ứng dụng VXDeck (ví dụ 1.0.0)"
    },
    "schema_version": {
      "type": "integer",
      "description": "Phiên bản cấu trúc dữ liệu để phục vụ di trú (migration)",
      "minimum": 1
    },
    "updated_at": {
      "type": "string",
      "format": "date-time",
      "description": "Thời điểm lưu dữ liệu gần nhất theo chuẩn ISO 8601"
    },
    "settings": {
      "type": "object",
      "required": ["auto_hide_on_launch", "columns_count", "icon_size", "theme_mode"],
      "properties": {
        "auto_hide_on_launch": {
          "type": "boolean",
          "default": true,
          "description": "Tự động ẩn popup sau khi click khởi chạy một ứng dụng"
        },
        "columns_count": {
          "type": "integer",
          "default": 5,
          "minimum": 3,
          "maximum": 8,
          "description": "Số lượng cột trong lưới ứng dụng"
        },
        "icon_size": {
          "type": "integer",
          "default": 48,
          "description": "Kích thước icon hiển thị (48pt)"
        },
        "theme_mode": {
          "type": "string",
          "enum": ["dark", "light", "system"],
          "default": "dark",
          "description": "Chế độ giao diện hiển thị"
        }
      }
    },
    "collections": {
      "type": "array",
      "description": "Danh sách các bộ sưu tập ứng dụng xếp theo thứ tự",
      "items": {
        "type": "object",
        "required": ["id", "title", "display_order", "is_collapsed", "items"],
        "properties": {
          "id": {
            "type": "string",
            "format": "uuid",
            "description": "Định danh duy nhất của bộ sưu tập"
          },
          "title": {
            "type": "string",
            "minLength": 1,
            "maxLength": 50,
            "description": "Tên nhóm bộ sưu tập (tối đa 50 ký tự)"
          },
          "display_order": {
            "type": "integer",
            "minimum": 0,
            "description": "Thứ tự sắp xếp hiển thị từ trên xuống dưới"
          },
          "is_collapsed": {
            "type": "boolean",
            "default": false,
            "description": "Trạng thái thu gọn nhóm"
          },
          "items": {
            "type": "array",
            "description": "Danh sách các ứng dụng thuộc bộ sưu tập này",
            "items": {
              "type": "object",
              "required": ["id", "name", "path", "display_order", "added_at"],
              "properties": {
                "id": {
                  "type": "string",
                  "format": "uuid",
                  "description": "Định danh duy nhất của shortcut ứng dụng"
                },
                "name": {
                  "type": "string",
                  "description": "Tên hiển thị mặc định của ứng dụng"
                },
                "custom_label": {
                  "type": ["string", "null"],
                  "description": "Tên gợi nhớ do người dùng đặt lại (nếu có)"
                },
                "bundle_id": {
                  "type": ["string", "null"],
                  "description": "CFBundleIdentifier bền vững (ví dụ com.figma.Desktop)"
                },
                "path": {
                  "type": "string",
                  "description": "Đường dẫn tuyệt đối tới tệp .app trên ổ đĩa"
                },
                "display_order": {
                  "type": "integer",
                  "minimum": 0,
                  "description": "Thứ tự sắp xếp trong lưới của bộ sưu tập"
                },
                "added_at": {
                  "type": "string",
                  "format": "date-time",
                  "description": "Thời điểm thêm ứng dụng vào nhóm theo ISO 8601"
                }
              }
            }
          }
        }
      }
    }
  }
}
```

---

## 4. Đặc tả Swift Models (In-Memory Contracts)

Các cấu trúc dữ liệu được định nghĩa bằng ngôn ngữ Swift chuẩn, kế thừa `Codable`, `Identifiable`, `Equatable` và `Sendable`:

```swift
import Foundation

// MARK: - Root Configuration
public struct DeckConfig: Codable, Equatable, Sendable {
    public var version: String
    public var schemaVersion: Int
    public var updatedAt: Date
    public var settings: DeckSettings
    public var collections: [CollectionModel]
    
    public init(
        version: String = "1.0.0",
        schemaVersion: Int = 1,
        updatedAt: Date = Date(),
        settings: DeckSettings = DeckSettings(),
        collections: [CollectionModel] = []
    ) {
        self.version = version
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.settings = settings
        self.collections = collections
    }
    
    enum CodingKeys: String, CodingKey {
        case version
        case schemaVersion = "schema_version"
        case updatedAt = "updated_at"
        case settings
        case collections
    }
}

// MARK: - Deck Settings
public struct DeckSettings: Codable, Equatable, Sendable {
    public var autoHideOnLaunch: Bool
    public var columnsCount: Int
    public var iconSize: Int
    public var themeMode: String
    
    public init(
        autoHideOnLaunch: Bool = true,
        columnsCount: Int = 5,
        iconSize: Int = 48,
        themeMode: String = "dark"
    ) {
        self.autoHideOnLaunch = autoHideOnLaunch
        self.columnsCount = columnsCount
        self.iconSize = iconSize
        self.themeMode = themeMode
    }
    
    enum CodingKeys: String, CodingKey {
        case autoHideOnLaunch = "auto_hide_on_launch"
        case columnsCount = "columns_count"
        case iconSize = "icon_size"
        case themeMode = "theme_mode"
    }
}

// MARK: - Collection Model
public struct CollectionModel: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var displayOrder: Int
    public var isCollapsed: Bool
    public var items: [AppItemModel]
    
    public init(
        id: UUID = UUID(),
        title: String,
        displayOrder: Int = 0,
        isCollapsed: Bool = false,
        items: [AppItemModel] = []
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
        self.isCollapsed = isCollapsed
        self.items = items
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case displayOrder = "display_order"
        case isCollapsed = "is_collapsed"
        case items
    }
}

// MARK: - App Item Model
public struct AppItemModel: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var customLabel: String?
    public var bundleId: String?
    public var path: String
    public var displayOrder: Int
    public var addedAt: Date
    
    // Thuộc tính runtime không lưu vào JSON
    public var isAvailable: Bool = true
    
    public init(
        id: UUID = UUID(),
        name: String,
        customLabel: String? = nil,
        bundleId: String? = nil,
        path: String,
        displayOrder: Int = 0,
        addedAt: Date = Date(),
        isAvailable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.customLabel = customLabel
        self.bundleId = bundleId
        self.path = path
        self.displayOrder = displayOrder
        self.addedAt = addedAt
        self.isAvailable = isAvailable
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case customLabel = "custom_label"
        case bundleId = "bundle_id"
        case path
        case displayOrder = "display_order"
        case addedAt = "added_at"
    }
}
```

---

## 5. Giao ước Tích hợp Hệ điều hành (Native OS Integration Contracts)

### 5.1. Khởi chạy Ứng dụng Mục tiêu (`AppLauncherBridge`)
- **API sử dụng:** `NSWorkspace.shared.openApplication(at:configuration:completionHandler:)`
- **Tham số cấu hình:**
  ```swift
  let configuration = NSWorkspace.OpenConfiguration()
  configuration.activates = true
  configuration.addsToRecentItems = true
  ```
- **Hành vi xử lý lỗi:** Nếu URL tệp không tồn tại, tự động chuyển sang tra cứu bằng `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)`. Nếu vẫn không tìm thấy, trả về mã lỗi `ERR_APP_NOT_FOUND`.

### 5.2. Trích xuất Biểu tượng Native & Bộ nhớ Đệm (`IconProviderBridge`)
- **API sử dụng:** `NSWorkspace.shared.icon(forFile: path)`
- **Kích thước kết xuất:** Yêu cầu `NSImage.size = NSSize(width: 96, height: 96)` (để hiển thị sắc nét ở kích thước 48×48pt trên màn hình Retina 2x).
- **Cơ chế Caching:** Lưu trữ trong `NSCache<NSString, NSImage>` với khóa là `path` để không lặp lại thao tác I/O đọc tài nguyên đồ họa từ đĩa.

### 5.3. Điều khiển Cửa sổ Nổi & Quản lý Phím (`WindowPolicyBridge`)
- **Lớp đối tượng:** `DeckPanel` kế thừa trực tiếp từ `NSPanel`.
- **Cấu hình thuộc tính:**
  ```swift
  self.styleMask = [.borderless, .nonactivatingPanel]
  self.isFloatingPanel = true
  self.level = .floating
  self.isOpaque = false
  self.backgroundColor = .clear
  self.hasShadow = true
  
  // Bảo đảm nhận sự kiện bàn phím phím Escape và Cmd+E
  override var canBecomeKey: Bool { return true }
  override var canBecomeMain: Bool { return true }
  ```
- **Theo dõi Click Bên Ngoài (Outside Click Monitor):**
  - Đăng ký `NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown])`.
  - Khi có sự kiện nhấp chuột ngoài vùng hiển thị của `panel.frame`:
    - Nếu `is_modal_open == true` (đang mở hộp thoại `NSOpenPanel` hoặc alert xác nhận): **Bỏ qua sự kiện, không ẩn cửa sổ**.
    - Nếu đang ở `viewActive`: Thực hiện ẩn cửa sổ mượt mà (`panel.orderOut(nil)`).
    - Nếu đang ở `editActive`: **Bỏ qua sự kiện**, giữ nguyên cửa sổ để bảo vệ phiên chỉnh sửa của người dùng.
- **Phân luồng phím `Escape`:**
  - Nếu `is_modal_open == true`: Đóng modal con.
  - Nếu `window_state == .editActive`: Chuyển về `.viewActive`, kích hoạt `flush()` lưu đĩa.
  - Nếu `window_state == .viewActive`: Ẩn popup (`orderOut`).

---

## 6. Giao ước Kéo Thả (Drag & Drop UTI Protocol)

- **Uniform Type Identifier (UTI):** `com.vxdeck.app-item`
- **Đóng gói Payload Kéo thả:**
  Khi bắt đầu kéo một thẻ app, dữ liệu được truyền qua `NSItemProvider`:
  ```json
  {
    "item_id": "9B1DE05F-0B8A-4CEE-B5E3-A12B16B9590E",
    "source_collection_id": "5C2096CD-841F-43BB-958B-CE5A64C09E01",
    "source_index": 2
  }
  ```
- **Xác thực Thả (Drop Validation & Safety):**
  - Vùng nhận thả chỉ chấp nhận UTI `com.vxdeck.app-item`.
  - Tại thời điểm commit drop: Kiểm tra `item_id` thực sự tồn tại trong danh mục nguồn.
  - Chống trùng lặp: Nếu Collection đích đã tồn tại ứng dụng có cùng `bundle_id` hoặc `path`, thao tác thả sẽ bị từ chối và icon quay về vị trí cũ an toàn.
  - Hỗ trợ thả vào Collection rỗng: Tự động chèn tại vị trí `targetIndex = 0`.

---

## 7. Ma trận Mã Lỗi Hệ Thống (Error Matrix)

| Mã Lỗi (Code) | Tên Lỗi (Name) | Nguyên nhân kích hoạt | Biện pháp Phục hồi / Phản hồi |
| :--- | :--- | :--- | :--- |
| `ERR_APP_NOT_FOUND` | Application Not Found | Đường dẫn file `.app` không tồn tại và không tìm thấy Bundle ID trên hệ thống | Đánh dấu thẻ là `Unavailable`, hiển thị popup gợi ý định vị lại hoặc xóa |
| `ERR_LAUNCH_FAILED` | Launch Execution Failed | macOS từ chối mở app do lỗi bảo mật, Gatekeeper hoặc quyền thực thi | Giữ nguyên popup, hiển thị toast thông báo lỗi nguyên bản từ macOS |
| `ERR_CONFIG_CORRUPT` | Configuration Corrupted | Tệp `deck_config.json` bị hỏng cú pháp JSON | Đổi tên tệp hỏng thành `.corrupt.<timestamp>`, khôi phục từ `.bak` nếu có; nếu không tạo cấu hình rỗng |
| `ERR_ATOMIC_SAVE_FAILED`| Atomic Write Failed | Ổ đĩa đầy hoặc thư mục Application Support bị khóa quyền ghi | Thử lại 3 lần; nếu thất bại hiển thị cảnh báo bộ nhớ cho người dùng |
| `ERR_INVALID_APP_BUNDLE`| Invalid App Bundle | Người dùng chọn một thư mục hoặc file không phải bundle `.app` chuẩn | Bỏ qua tệp đó, hiển thị thông báo: "Chỉ chấp nhận các tệp ứng dụng .app" |
| `ERR_DUPLICATE_ITEM` | Duplicate Item In Group | Thêm ứng dụng đã có sẵn trong Collection hiện tại | Không tạo thêm thẻ mới, rung nhẹ thẻ đã có để báo hiệu vị trí |
| `ERR_INVALID_APP_BUNDLE`| Invalid App Bundle | Người dùng chọn một thư mục hoặc file không phải bundle `.app` chuẩn | Bỏ qua tệp đó, hiển thị thông báo: "Chỉ chấp nhận các tệp ứng dụng .app" |
| `ERR_DUPLICATE_ITEM` | Duplicate Item In Group | Thêm ứng dụng đã có sẵn trong Collection hiện tại | Không tạo thêm thẻ mới, rung nhẹ thẻ đã có để báo hiệu vị trí |
