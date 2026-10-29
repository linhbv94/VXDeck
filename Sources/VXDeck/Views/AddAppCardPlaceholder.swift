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

                Text(store.localized("Thêm App"))
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
        .help(store.localized("Thêm ứng dụng .app vào nhóm này"))
    }

    private func openAppPicker() {
        guard !store.isModalOpen,
              let parent = (NSApp.delegate as? AppDelegate)?.panel,
              parent.isVisible,
              parent.attachedSheet == nil else { return }
        store.isModalOpen = true

        let openPanel = NSOpenPanel()
        openPanel.title = store.localized("Chọn ứng dụng để thêm vào VXDeck")
        openPanel.message = store.localized("Chọn một hoặc nhiều ứng dụng (.app) để thêm vào bộ sưu tập")
        openPanel.prompt = store.localized("Thêm")
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

        AppPickerDelegate.present(openPanel, on: parent) { response in
            store.isModalOpen = false

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
        guard let draggedId = store.draggingItemId,
              let sourceId = store.draggingCollectionId else {
            store.cancelDrag()
            return false
        }
        store.cancelDrag()

        commitDrop(draggedItemId: draggedId, sourceColId: sourceId)
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
