import Foundation

@MainActor
public extension DeckStore {
    func localized(_ text: String) -> String {
        guard settings.language == "en" else { return text }
        return deckEnglish[text] ?? text
    }
    func localizedFormat(_ text: String, _ values: CVarArg...) -> String {
        String(format: localized(text), arguments: values)
    }

}

private let deckEnglish: [String: String] = [
    "Bật chế độ chỉnh sửa [⌘E]": "Enable edit mode [⌘E]",
    "Bật chế độ chỉnh sửa hoặc nhấn nút bên dưới để tạo nhóm ứng dụng đầu tiên của bạn.": "Enable edit mode or use the button below to create your first app collection.",
    "Chưa có bộ sưu tập nào": "No collections yet",
    "Chỉnh sửa": "Edit",
    "Chọn": "Select",
    "Chọn một hoặc nhiều ứng dụng (.app) để thêm vào bộ sưu tập": "Select one or more applications (.app) to add to the collection",
    "Chọn tệp ứng dụng .app thay thế trên ổ đĩa": "Choose a replacement .app on disk",
    "Chọn ứng dụng để thêm vào VXDeck": "Choose applications to add to VXDeck",
    "Cài đặt & Giới thiệu [⌘,]": "Settings & About [⌘,]",
    "Có bản cập nhật mới! Cài đặt & Giới thiệu [⌘,]": "Update available! Settings & About [⌘,]",
    "Di chuyển nhóm lên trên": "Move collection up",
    "Di chuyển nhóm xuống dưới": "Move collection down",
    "Hiện trong Finder": "Reveal in Finder",
    "Hoàn tất": "Done",
    "Hoàn tất chỉnh sửa [⌘E]": "Finish editing [⌘E]",
    "Hủy": "Cancel",
    "Khởi chạy": "Launch",
    "Kéo viền đổi cỡ": "Drag edge to resize",
    "Kéo để sắp xếp • Bấm (x) để xóa": "Drag to reorder • Click (x) to remove",
    "Lưu tên mới": "Save new name",
    "Nhóm mới": "New collection",
    "Nhấp một chạm để mở app": "Click to launch an app",
    "Sửa": "Edit",
    "Xong": "Done",
    "Thêm": "Add",
    "Thêm App": "Add app",
    "Thêm Bộ sưu tập mới": "Add collection",
    "Thêm ứng dụng .app vào nhóm này": "Add applications to this collection",
    "Tên hiển thị": "Display name",
    "Tên nhóm": "Collection name",
    "Tạo": "Create",
    "Tạo Bộ Sưu Tập Mới": "Create collection",
    "Tạo Nhóm Đầu Tiên": "Create first collection",
    "Tạo nhóm bộ sưu tập mới": "Create an app collection",
    "Tất cả lối tắt ứng dụng trong nhóm này sẽ bị xóa khỏi VXDeck (không xóa ứng dụng gốc trên máy).": "All shortcuts in this collection will be removed from VXDeck. Original applications on disk will be kept.",
    "Ví dụ: Thiết Kế, Lập Trình, Game...": "For example: Design, Development, Games…",
    "Xóa": "Remove",
    "Xóa khỏi nhóm": "Remove from collection",
    "Xóa nhóm này": "Remove this collection",
    "Xóa ứng dụng này khỏi nhóm": "Remove this application from the collection",
    "Đóng": "Close",
    "Định vị lại ứng dụng...": "Relocate application…",
    "Đổi tên hiển thị...": "Rename display label…",
    "Đổi tên nhóm": "Rename collection",
    "Ứng dụng Của Tôi": "My applications",
    "• Chế độ sửa": "• Edit mode",
    "Chỉ chấp nhận các tệp ứng dụng .app hợp lệ": "Only valid .app bundles are accepted",
    "Không thể đọc thông tin bundle ứng dụng": "Cannot read the application bundle",
    "Đường dẫn mới không phải là tệp .app hợp lệ": "The new path is not a valid .app bundle",
    "Ứng dụng được chọn không khớp định danh với ứng dụng cũ": "The selected application has a different identity",
    "Đã định vị lại ứng dụng thành công": "Application relocated",
    "Ứng dụng đã tồn tại ở nhóm đích": "The application already exists in the destination collection",
    "Bộ sưu tập mới": "New collection",
    "Bộ sưu tập": "Collection",
    "Đã khôi phục cài đặt mặc định": "Defaults restored",
    "Định vị lại ứng dụng '%@'": "Relocate application '%@'",
    "Ứng dụng không tồn tại: %@": "Application not found: %@",
    "Không thể mở: %@": "Could not open: %@",
    "Xóa nhóm '%@'?": "Remove collection '%@'?",
    "Ứng dụng '%@' đã có trong nhóm": "Application '%@' is already in this collection",
    "Đã thêm %@": "Added %@",
    "Đã xóa %@": "Removed %@",
    "Đã thêm nhóm '%@'": "Added collection '%@'",
    "Đã xóa nhóm '%@'": "Removed collection '%@'",
    "Lỗi lưu cấu hình: %@": "Could not save settings: %@"
]
