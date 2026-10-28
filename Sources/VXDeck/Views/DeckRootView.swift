import SwiftUI
import VXDeckCore

public struct DeckRootView: View {
    @EnvironmentObject var store: DeckStore
    let onCloseRequested: () -> Void
    let onContentSizeChange: () -> Void

    @LocalState private var newGroupTitle = ""

    public var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Header Bar (44pt)
                DeckHeaderView()

                // Main Scroll Area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if store.collections.isEmpty {
                            emptyCollectionsPlaceholder
                        } else {
                            ForEach(store.collections) { collection in
                                CollectionSectionView(
                                    collection: collection,
                                    onLaunchRequested: onCloseRequested
                                )
                            }
                        }

                        if store.isEditMode {
                            addCollectionBottomBar
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                }
                .frame(minHeight: 180, maxHeight: 680)

                // Footer Bar (28pt)
                DeckFooterView()
            }

            // Floating Toast Notification
            if let toast = store.toastMessage {
                ToastOverlayView(message: toast)
                    .padding(.top, 52)
            }
        }
        .frame(minWidth: 440, maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.059, green: 0.067, blue: 0.09).opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            WindowResizeHandle(side: .left, onEnd: onContentSizeChange)
        }
        .overlay(alignment: .trailing) {
            WindowResizeHandle(side: .right, onEnd: onContentSizeChange)
        }
        .sheet(isPresented: $store.showAddCollectionDialog) {
            VStack(spacing: 16) {
                Text("Tạo Bộ Sưu Tập Mới")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                TextField("Ví dụ: Thiết Kế, Lập Trình, Game...", text: $newGroupTitle)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)

                HStack(spacing: 12) {
                    Button("Hủy") {
                        store.isModalOpen = false
                        store.showAddCollectionDialog = false
                        newGroupTitle = ""
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Tạo") {
                        store.isModalOpen = false
                        store.showAddCollectionDialog = false
                        store.createCollection(title: newGroupTitle)
                        newGroupTitle = ""
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
            }
            .padding(20)
            .frame(width: 300)
            .background(Color(red: 0.1, green: 0.12, blue: 0.16))
        }
        .sheet(isPresented: $store.showSettingsModal) {
            DeckSettingsView(onClose: {
                store.isModalOpen = false
                store.showSettingsModal = false
            })
            .environmentObject(store)
        }
        .onChange(of: store.collections) {
            DispatchQueue.main.async {
                onContentSizeChange()
            }
        }
        .onChange(of: store.isEditMode) {
            DispatchQueue.main.async {
                onContentSizeChange()
            }
        }
    }

    private var emptyCollectionsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 36))
                .foregroundColor(Color(red: 0.5, green: 0.55, blue: 0.65))

            Text("Chưa có bộ sưu tập nào")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Text("Bật chế độ chỉnh sửa hoặc nhấn nút bên dưới để tạo nhóm ứng dụng đầu tiên của bạn.")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                store.createCollection(title: "Ứng dụng Của Tôi")
                store.setEditMode(true)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Tạo Nhóm Đầu Tiên")
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.cyan))
                .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var addCollectionBottomBar: some View {
        Button(action: {
            store.isModalOpen = true
            store.showAddCollectionDialog = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                Text("Thêm Bộ sưu tập mới")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.02))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct WindowResizeHandle: View {
    enum Side {
        case left
        case right
    }

    let side: Side
    let onEnd: () -> Void

    @LocalState private var isHovering = false
    @LocalState private var startFrame: NSRect? = nil

    private var deckPanel: DeckPanel? {
        (NSApp.keyWindow as? DeckPanel) ?? (NSApp.windows.first(where: { $0 is DeckPanel }) as? DeckPanel)
    }

    var body: some View {
        Rectangle()
            .fill(isHovering ? Color.cyan.opacity(0.18) : Color.clear)
            .frame(width: 8)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        guard let panel = deckPanel, let screen = panel.screen ?? NSScreen.main else { return }
                        let visibleFrame = screen.visibleFrame

                        if startFrame == nil {
                            startFrame = panel.frame
                        }
                        guard let base = startFrame else { return }

                        let minWidth: CGFloat = 440
                        let maxWidth: CGFloat = min(1400, visibleFrame.width - 40)

                        switch side {
                        case .right:
                            let targetWidth = base.width + value.translation.width
                            let newWidth = max(minWidth, min(maxWidth, targetWidth))
                            let newFrame = NSRect(x: base.origin.x, y: base.origin.y, width: newWidth, height: base.height)
                            panel.setFrame(newFrame, display: true)

                        case .left:
                            let targetWidth = base.width - value.translation.width
                            let newWidth = max(minWidth, min(maxWidth, targetWidth))
                            let actualDiff = base.width - newWidth
                            let newX = base.origin.x + actualDiff
                            let newFrame = NSRect(x: newX, y: base.origin.y, width: newWidth, height: base.height)
                            panel.setFrame(newFrame, display: true)
                        }
                    }
                    .onEnded { _ in
                        guard let panel = deckPanel else {
                            startFrame = nil
                            return
                        }
                        startFrame = nil
                        DeckStore.shared.updateWindowWidth(Double(panel.frame.width))
                        onEnd()
                    }
            )
    }
}
