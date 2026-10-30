import SwiftUI
import UniformTypeIdentifiers
import VXDeckCore

public struct DeckRootView: View {
    @EnvironmentObject var store: DeckStore
    @ObservedObject private var updater = AppUpdateController.shared
    let onCloseRequested: () -> Void
    let onContentSizeChange: () -> Void
    let onHeightMeasured: (CGFloat) -> Void

    @LocalState private var newGroupTitle = ""
    @LocalState private var isHoveringResizeEdge = false

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
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geo.size.height)
                        }
                    )
                }

                // Footer Bar (28pt)
                DeckFooterView()
            }

            // Floating Toast Notification
            if let toast = store.toastMessage {
                ToastOverlayView(message: toast)
                    .padding(.top, 52)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if updater.noticeVisible {
                DeckUpdateCard(notice: true).environmentObject(store).frame(maxWidth: 384).padding(20)
            }
        }
        .frame(minWidth: 440, maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.059, green: 0.067, blue: 0.09).opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isHoveringResizeEdge ? Color.cyan.opacity(0.4) : Color.white.opacity(0.10),
                            lineWidth: isHoveringResizeEdge ? 1.5 : 1.0
                        )
                        .animation(.easeInOut(duration: 0.18), value: isHoveringResizeEdge)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onDrop(of: [UTType.text], isTargeted: nil) { _ in
            store.cancelDrag()
            return false
        }
        .overlay(alignment: .leading) {
            WindowResizeHandle(
                side: .left,
                onHoverChanged: { isHoveringResizeEdge = $0 },
                onEnd: onContentSizeChange
            )
            .padding(.vertical, 16)
        }
        .overlay(alignment: .trailing) {
            WindowResizeHandle(
                side: .right,
                onHoverChanged: { isHoveringResizeEdge = $0 },
                onEnd: onContentSizeChange
            )
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $store.showAddCollectionDialog, onDismiss: {
            store.isModalOpen = false
            newGroupTitle = ""
        }) {
            VStack(spacing: 16) {
                Text(store.localized("Tạo Bộ Sưu Tập Mới"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                TextField(store.localized("Ví dụ: Thiết Kế, Lập Trình, Game..."), text: $newGroupTitle)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)

                HStack(spacing: 12) {
                    Button(store.localized("Hủy")) {
                        store.isModalOpen = false
                        store.showAddCollectionDialog = false
                        newGroupTitle = ""
                    }
                    .keyboardShortcut(.cancelAction)

                    Button(store.localized("Tạo")) {
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
        .sheet(isPresented: $store.showSettingsModal, onDismiss: {
            store.isModalOpen = false
        }) {
            DeckSettingsView(onClose: {
                store.isModalOpen = false
                store.showSettingsModal = false
            })
            .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: UpdateApplicationTermination.willTerminate)) { _ in
            store.showSettingsModal = false
            store.showAddCollectionDialog = false
            store.isModalOpen = false
        }
        .onPreferenceChange(ContentHeightPreferenceKey.self) { measuredHeight in
            guard measuredHeight > 20 else { return }
            let totalHeight = measuredHeight + 44 + 28
            onHeightMeasured(totalHeight)
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

            Text(store.localized("Chưa có bộ sưu tập nào"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Text(store.localized("Bật chế độ chỉnh sửa hoặc nhấn nút bên dưới để tạo nhóm ứng dụng đầu tiên của bạn."))
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                store.createCollection(title: store.localized("Ứng dụng Của Tôi"))
                store.setEditMode(true)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text(store.localized("Tạo Nhóm Đầu Tiên"))
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
                Text(store.localized("Thêm Bộ sưu tập mới"))
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

struct ContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct WindowResizeHandle: View {
    enum Side {
        case left
        case right
    }

    let side: Side
    let onHoverChanged: (Bool) -> Void
    let onEnd: () -> Void

    @LocalState private var isHovering = false

    var body: some View {
        ZStack(alignment: side == .left ? .leading : .trailing) {
            ResizeTrackingRepresentable(side: side) { hovering in
                isHovering = hovering
                onHoverChanged(hovering)
            } onEnded: {
                onEnd()
            }

            // Refined glowing indicator pill safely centered and inset from window corners
            if isHovering {
                ZStack {
                    Capsule()
                        .fill(Color.cyan.opacity(0.35))
                        .frame(width: 6, height: 44)
                        .blur(radius: 2.5)

                    Capsule()
                        .fill(Color.cyan.opacity(0.9))
                        .frame(width: 3, height: 38)
                }
                .padding(side == .left ? .leading : .trailing, 1.5)
                .allowsHitTesting(false)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(width: 12)
    }
}

private struct ResizeTrackingRepresentable: NSViewRepresentable {
    let side: WindowResizeHandle.Side
    let onHoverChanged: (Bool) -> Void
    let onEnded: () -> Void

    func makeNSView(context: Context) -> ResizeTrackingNSView {
        let view = ResizeTrackingNSView()
        view.side = side
        view.onHoverChanged = onHoverChanged
        view.onEnded = onEnded
        return view
    }

    func updateNSView(_ nsView: ResizeTrackingNSView, context: Context) {
        nsView.side = side
        nsView.onHoverChanged = onHoverChanged
        nsView.onEnded = onEnded
    }
}

private final class ResizeTrackingNSView: NSView {
    var side: WindowResizeHandle.Side = .right
    var onHoverChanged: ((Bool) -> Void)?
    var onEnded: (() -> Void)?

    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        NSCursor.resizeLeftRight.push()
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.pop()
        onHoverChanged?(false)
    }

    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else { return }
        let initialMouseLoc = NSEvent.mouseLocation
        let initialFrame = window.frame
        guard let screen = window.screen ?? NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame

        let minWidth: CGFloat = 440
        let maxWidth: CGFloat = min(1400, visibleFrame.width - 40)

        while true {
            guard let nextEvent = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else {
                continue
            }
            if nextEvent.type == .leftMouseUp {
                break
            }

            let currentMouseLoc = NSEvent.mouseLocation
            let deltaX = currentMouseLoc.x - initialMouseLoc.x

            switch side {
            case .right:
                let targetWidth = initialFrame.width + deltaX
                let newWidth = max(minWidth, min(maxWidth, targetWidth))
                let newFrame = NSRect(
                    x: initialFrame.origin.x,
                    y: initialFrame.origin.y,
                    width: newWidth,
                    height: initialFrame.height
                )
                window.setFrame(newFrame, display: true)

            case .left:
                let targetWidth = initialFrame.width - deltaX
                let newWidth = max(minWidth, min(maxWidth, targetWidth))
                let actualDiff = initialFrame.width - newWidth
                let newX = initialFrame.origin.x + actualDiff
                let newFrame = NSRect(
                    x: newX,
                    y: initialFrame.origin.y,
                    width: newWidth,
                    height: initialFrame.height
                )
                window.setFrame(newFrame, display: true)
            }
        }

        let finalWidth = Double(window.frame.width)
        DeckStore.shared.updateWindowWidth(finalWidth)
        Task {
            await DeckStore.shared.flush()
        }
        onEnded?()
    }
}
