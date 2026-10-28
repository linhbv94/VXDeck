import SwiftUI
import AppKit
import UniformTypeIdentifiers
import VXDeckCore

public struct AddAppCardPlaceholder: View {
    @EnvironmentObject var store: DeckStore
    let collectionId: UUID

    @LocalState private var isHovered = false
    private let placeholderId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    private var showLeadingIndicator: Bool {
        guard store.isEditMode, store.isDraggingApp, store.draggingItemId != nil, let target = store.dropTarget else { return false }
        return target.collectionId == collectionId && target.itemId == placeholderId && target.edge == .leading
    }

    public var body: some View {
        Button(action: openAppPicker) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isHovered ? .cyan : Color(red: 0.6, green: 0.65, blue: 0.72))

                Text("Thêm App")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isHovered ? .cyan : Color(red: 0.6, green: 0.65, blue: 0.72))
            }
            .frame(maxWidth: .infinity, minHeight: 86, maxHeight: 86)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isHovered ? Color.cyan.opacity(0.8) : Color.white.opacity(0.18),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isHovered ? Color.cyan.opacity(0.06) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if showLeadingIndicator {
                DropIndicatorLine()
                    .offset(x: -6)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrop(
            of: [UTType.text],
            delegate: PlaceholderDropDelegate(
                collectionId: collectionId,
                placeholderId: placeholderId,
                store: store
            )
        )
        .help("Thêm ứng dụng .app vào nhóm này")
    }

    private func openAppPicker() {
        store.isModalOpen = true

        let openPanel = NSOpenPanel()
        openPanel.title = "Chọn ứng dụng để thêm vào VXDeck"
        openPanel.message = "Chọn một hoặc nhiều ứng dụng (.app) để thêm vào bộ sưu tập"
        openPanel.prompt = "Thêm"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.allowsMultipleSelection = true
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
            NSApp.activate(ignoringOtherApps: true)
            (NSApp.keyWindow ?? NSApp.windows.first(where: { $0 is DeckPanel }))?.makeKeyAndOrderFront(nil)

            guard response == .OK else { return }

            for url in openPanel.urls {
                _ = store.addApp(toCollectionId: collectionId, path: url.path)
            }
            Task {
                await store.flush()
            }
        }
    }
}

public struct PlaceholderDropDelegate: DropDelegate {
    let collectionId: UUID
    let placeholderId: UUID
    let store: DeckStore

    public init(collectionId: UUID, placeholderId: UUID, store: DeckStore) {
        self.collectionId = collectionId
        self.placeholderId = placeholderId
        self.store = store
    }

    public func dropUpdated(info: DropInfo) -> DropProposal? {
        guard store.isEditMode, store.isDraggingApp else {
            store.dropTarget = nil
            return DropProposal(operation: .forbidden)
        }
        store.dropTarget = DropTargetState(collectionId: collectionId, itemId: placeholderId, edge: .leading)
        return DropProposal(operation: .move)
    }

    public func dropExited(info: DropInfo) {
        if store.dropTarget?.collectionId == collectionId && store.dropTarget?.itemId == placeholderId {
            store.dropTarget = nil
        }
    }

    public func performDrop(info: DropInfo) -> Bool {
        guard store.isEditMode else {
            store.cancelDrag()
            return false
        }
        let session = store.currentDragSessionId
        let fallbackSourceColId = store.draggingCollectionId
        let fallbackDraggedItemId = store.draggingItemId

        store.cancelDrag()

        guard let provider = info.itemProviders(for: [UTType.text]).first else {
            if let draggedId = fallbackDraggedItemId, let sourceId = fallbackSourceColId {
                self.commitDrop(draggedItemId: draggedId, sourceColId: sourceId)
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
                    self.commitDrop(draggedItemId: iId, sourceColId: sId)
                }
            }
        }
        return true
    }

    private func commitDrop(draggedItemId: UUID, sourceColId: UUID) {
        store.cancelDrag()

        if sourceColId == self.collectionId {
            self.store.moveItemToEnd(itemId: draggedItemId, inCollectionId: self.collectionId)
        } else {
            self.store.moveItem(itemId: draggedItemId, fromCollectionId: sourceColId, toCollectionId: self.collectionId, relativeTo: nil, edge: .trailing)
        }
    }
}
