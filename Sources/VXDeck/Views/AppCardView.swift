import SwiftUI
import AppKit
import UniformTypeIdentifiers
import VXDeckCore

public struct AppCardView: View {
    @EnvironmentObject var store: DeckStore
    let item: AppItemModel
    let collectionId: UUID
    let onLaunchRequested: () -> Void

    @LocalState private var isHovered = false
    @LocalState private var isPressed = false
    @LocalState private var isEditingLabel = false
    @LocalState private var labelText = ""

    private var iconImage: NSImage {
        IconProvider.shared.icon(forPath: item.path, targetSize: NSSize(width: 48, height: 48))
    }

    private var showLeadingIndicator: Bool {
        guard store.isEditMode, store.isDraggingApp, store.draggingItemId != nil, let target = store.dropTarget else { return false }
        return target.collectionId == collectionId && target.itemId == item.id && target.edge == .leading
    }

    private var showTrailingIndicator: Bool {
        guard store.isEditMode, store.isDraggingApp, store.draggingItemId != nil, let target = store.dropTarget else { return false }
        return target.collectionId == collectionId && target.itemId == item.id && target.edge == .trailing
    }

    public var body: some View {
        if store.isEditMode {
            cardContent
        } else {
            cardContent
                .onTapGesture {
                    launchApp()
                }
        }
    }

    private var cardContent: some View {
        VStack(spacing: 6) {
            iconBadgeView
            labelContentView
        }
        .frame(maxWidth: .infinity, minHeight: 86, maxHeight: 86)
        .padding(.vertical, 4)
        .background(backgroundCardView)
        .contentShape(Rectangle())
        .opacity(store.draggingItemId == item.id ? 0.35 : 1.0)
        .overlay(alignment: .leading) {
            if showLeadingIndicator {
                DropIndicatorLine()
                    .offset(x: -6)
            }
        }
        .overlay(alignment: .trailing) {
            if showTrailingIndicator {
                DropIndicatorLine()
                    .offset(x: 6)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            contextMenuButtons
        }
    }

    @ViewBuilder
    private var iconBadgeView: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .opacity(item.isAvailable ? 1.0 : 0.45)
                .grayscale(item.isAvailable ? 0.0 : 1.0)
                .scaleEffect(isPressed ? 0.92 : (isHovered && !store.isEditMode ? 1.05 : 1.0))
                .animation(.easeOut(duration: 0.15), value: isPressed)
                .animation(.easeOut(duration: 0.18), value: isHovered)

            if !item.isAvailable {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.98, green: 0.75, blue: 0.14))
                    .offset(x: 4, y: -4)
            }

            if store.isEditMode {
                Button(action: {
                    store.removeApp(itemId: item.id, fromCollectionId: collectionId)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.98, green: 0.44, blue: 0.52))
                        .background(Circle().fill(Color.black.opacity(0.8)))
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
                .help("Xóa ứng dụng này khỏi nhóm")
            }
        }
        .frame(width: 52, height: 52)
    }

    @ViewBuilder
    private var labelContentView: some View {
        if isEditingLabel {
            TextField("Tên hiển thị", text: $labelText, onCommit: {
                store.updateAppLabel(itemId: item.id, inCollectionId: collectionId, customLabel: labelText.isEmpty ? nil : labelText)
                isEditingLabel = false
            })
            .textFieldStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.15)))
            .frame(width: 88)
        } else {
            Text(item.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(item.isAvailable ? (isHovered ? .white : Color(red: 0.94, green: 0.96, blue: 0.98)) : Color(red: 0.6, green: 0.6, blue: 0.6))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 88, height: 26, alignment: .top)
                .onTapGesture {
                    if store.isEditMode {
                        labelText = item.customLabel ?? item.name
                        isEditingLabel = true
                    }
                }
        }
    }

    @ViewBuilder
    private var backgroundCardView: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(isHovered ? Color.white.opacity(store.isEditMode ? 0.05 : 0.08) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(store.isEditMode ? Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
            )
    }

    @ViewBuilder
    private var contextMenuButtons: some View {
        if !store.isEditMode && item.isAvailable {
            Button("Khởi chạy") {
                launchApp()
            }
        }
        if !item.isAvailable {
            Button("Định vị lại ứng dụng...") {
                relinkApp()
            }
        }
        Button("Đổi tên hiển thị...") {
            labelText = item.customLabel ?? item.name
            isEditingLabel = true
        }
        Divider()
        Button("Hiện trong Finder") {
            let resolvedURL = AppLauncher.shared.resolveTargetURL(for: item) ?? URL(fileURLWithPath: item.path)
            NSWorkspace.shared.activateFileViewerSelecting([resolvedURL])
        }
        Divider()
        Button(role: .destructive, action: {
            store.removeApp(itemId: item.id, fromCollectionId: collectionId)
        }) {
            Text("Xóa khỏi nhóm")
        }
    }

    private func relinkApp() {
        store.isModalOpen = true
        let openPanel = NSOpenPanel()
        openPanel.title = "Định vị lại ứng dụng '\(item.displayName)'"
        openPanel.message = "Chọn tệp ứng dụng .app thay thế trên ổ đĩa"
        openPanel.prompt = "Chọn"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.allowedContentTypes = [
            .applicationBundle,
            .application,
            .symbolicLink,
            .aliasFile
        ]
        openPanel.delegate = AppPickerDelegate.shared

        openPanel.begin { response in
            store.isModalOpen = false
            guard response == .OK, let selectedURL = openPanel.url else { return }
            _ = store.relinkApp(itemId: item.id, inCollectionId: collectionId, newPath: selectedURL.path)
        }
    }

    private func launchApp() {
        guard !store.isEditMode else { return }
        guard item.isAvailable else {
            store.showToast("Ứng dụng không tồn tại: \(item.path)")
            return
        }

        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.isPressed = false
        }

        let sessionId = store.windowSessionId
        Task {
            do {
                try await AppLauncher.shared.launch(item: item)
                if store.settings.autoHideOnLaunch
                    && store.windowSessionId == sessionId
                    && !store.isEditMode
                    && !store.isModalOpen {
                    onLaunchRequested()
                }
            } catch {
                store.showToast("Không thể mở: \(error.localizedDescription)")
            }
        }
    }
}

public struct AppCardDropDelegate: DropDelegate {
    let item: AppItemModel
    let collectionId: UUID
    let store: DeckStore

    public init(item: AppItemModel, collectionId: UUID, store: DeckStore) {
        self.item = item
        self.collectionId = collectionId
        self.store = store
    }

    public func dropEntered(info: DropInfo) {
        guard store.isEditMode, store.isDraggingApp else { return }
        updateDropTarget(info: info)
    }

    public func dropUpdated(info: DropInfo) -> DropProposal? {
        guard store.isEditMode, store.isDraggingApp, let draggingId = store.draggingItemId, draggingId != item.id else {
            store.dropTarget = nil
            return DropProposal(operation: .forbidden)
        }
        updateDropTarget(info: info)
        return DropProposal(operation: .move)
    }

    private func updateDropTarget(info: DropInfo) {
        guard store.isDraggingApp, let draggingId = store.draggingItemId, draggingId != item.id else {
            store.dropTarget = nil
            return
        }
        // Determine whether hover is on leading or trailing side of card
        let edge: DropTargetState.Edge = (info.location.x < 48) ? .leading : .trailing
        if store.dropTarget?.collectionId != collectionId || store.dropTarget?.itemId != item.id || store.dropTarget?.edge != edge {
            store.dropTarget = DropTargetState(collectionId: collectionId, itemId: item.id, edge: edge)
        }
    }

    public func dropExited(info: DropInfo) {
        if store.dropTarget?.itemId == item.id {
            store.dropTarget = nil
        }
    }

    public func performDrop(info: DropInfo) -> Bool {
        guard store.isEditMode else {
            store.cancelDrag()
            return false
        }
        let session = store.currentDragSessionId
        let targetEdge = store.dropTarget?.edge ?? .trailing
        let fallbackSourceColId = store.draggingCollectionId
        let fallbackDraggedItemId = store.draggingItemId

        store.cancelDrag()

        guard let provider = info.itemProviders(for: [UTType.text]).first else {
            if let draggedId = fallbackDraggedItemId, let sourceId = fallbackSourceColId {
                self.commitDrop(draggedItemId: draggedId, sourceColId: sourceId, edge: targetEdge)
            }
            return true
        }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (itemData, error) in
            let str = (itemData as? Data).flatMap { String(data: $0, encoding: .utf8) } ?? (itemData as? String)
            let parts = str?.components(separatedBy: ":")

            let resolvedSourceId = (parts != nil && parts!.count == 2 ? UUID(uuidString: parts![0]) : nil) ?? fallbackSourceColId
            let resolvedItemId = (parts != nil && parts!.count == 2 ? UUID(uuidString: parts![1]) : nil) ?? fallbackDraggedItemId

            DispatchQueue.main.async {
                guard self.store.isEditMode, self.store.currentDragSessionId == session || self.store.currentDragSessionId == nil else {
                    return
                }
                if let sId = resolvedSourceId, let iId = resolvedItemId {
                    self.commitDrop(draggedItemId: iId, sourceColId: sId, edge: targetEdge)
                }
            }
        }
        return true
    }

    private func commitDrop(draggedItemId: UUID, sourceColId: UUID, edge: DropTargetState.Edge) {
        store.cancelDrag()
        guard draggedItemId != item.id else { return }

        if sourceColId == collectionId {
            store.reorderItem(itemId: draggedItemId, inCollectionId: collectionId, relativeTo: item.id, edge: edge)
        } else {
            store.moveItem(itemId: draggedItemId, fromCollectionId: sourceColId, toCollectionId: collectionId, relativeTo: item.id, edge: edge)
        }
    }
}
