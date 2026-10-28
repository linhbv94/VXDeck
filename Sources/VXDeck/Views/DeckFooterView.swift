import SwiftUI
import VXDeckCore

public struct DeckFooterView: View {
    @EnvironmentObject var store: DeckStore

    public var body: some View {
        HStack(spacing: 12) {
            // Shortcut Pills
            HStack(spacing: 8) {
                ShortcutPill(key: "esc", label: store.isEditMode ? "Hoàn tất" : "Đóng")
                ShortcutPill(key: "⌘E", label: store.isEditMode ? "Xong" : "Sửa")
            }

            Spacer()

            // Mode Hint Label
            Text(store.isEditMode ? "Kéo để sắp xếp • Bấm (x) để xóa" : "Nhấp một chạm để mở app")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
        }
        .frame(height: 28)
        .padding(.horizontal, 16)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.7))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .top
        )
    }
}

private struct ShortcutPill: View {
    let key: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.8))
        }
    }
}
