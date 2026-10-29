import SwiftUI
import VXDeckCore

public struct DeckHeaderView: View {
    @EnvironmentObject var store: DeckStore
    @ObservedObject private var updater = AppUpdateController.shared

    public var body: some View {
        HStack(spacing: 12) {
            // Brand Logo & Title
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cyan)

                Text("VXDeck")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                if store.isEditMode {
                    Text(store.localized("• Chế độ sửa"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.cyan)
                }
            }

            Spacer()

            // Header Actions
            HStack(spacing: 8) {
                if store.isEditMode {
                    Button(action: {
                        store.isModalOpen = true
                        store.showAddCollectionDialog = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text(store.localized("Nhóm mới"))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .foregroundColor(Color(red: 0.85, green: 0.9, blue: 0.95))
                    }
                    .buttonStyle(.plain)
                    .help(store.localized("Tạo nhóm bộ sưu tập mới"))
                }

                // Edit Mode Toggle Button
                Button(action: {
                    store.toggleEditMode()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: store.isEditMode ? "checkmark" : "pencil")
                            .font(.system(size: 11, weight: .semibold))
                        Text(store.isEditMode ? store.localized("Hoàn tất") : store.localized("Chỉnh sửa"))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(store.isEditMode ? Color.cyan : Color.white.opacity(0.08))
                    )
                    .foregroundColor(store.isEditMode ? .black : Color(red: 0.85, green: 0.9, blue: 0.95))
                }
                .buttonStyle(.plain)
                .help(store.isEditMode ? store.localized("Hoàn tất chỉnh sửa [⌘E]") : store.localized("Bật chế độ chỉnh sửa [⌘E]"))

                // Settings Button
                Button(action: {
                    store.isModalOpen = true
                    store.showSettingsModal = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .foregroundColor(Color(red: 0.85, green: 0.9, blue: 0.95))

                        if updater.noticeVisible {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 7, height: 7)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .help(updater.noticeVisible ? store.localized("Có bản cập nhật mới! Cài đặt & Giới thiệu [⌘,]") : store.localized("Cài đặt & Giới thiệu [⌘,]"))
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.7)
                WindowDragBackground()
            }
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

public struct WindowDragBackground: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSView {
        WindowDragView()
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class WindowDragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
