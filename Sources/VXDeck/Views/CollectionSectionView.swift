import SwiftUI
import UniformTypeIdentifiers
import VXDeckCore

public struct CollectionSectionView: View {
    @EnvironmentObject var store: DeckStore
    let collection: CollectionModel
    let onLaunchRequested: () -> Void

    @LocalState private var isEditingTitle = false
    @LocalState private var titleDraft = ""
    @LocalState private var showDeleteConfirm = false

    private let columns = [
        GridItem(.fixed(100), spacing: 14),
        GridItem(.fixed(100), spacing: 14),
        GridItem(.fixed(100), spacing: 14),
        GridItem(.fixed(100), spacing: 14),
        GridItem(.fixed(100), spacing: 14)
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Title & Actions
            HStack(spacing: 8) {
                if isEditingTitle {
                    TextField("Tên nhóm", text: $titleDraft, onCommit: {
                        store.updateCollectionTitle(collectionId: collection.id, title: titleDraft)
                        isEditingTitle = false
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)))
                    .frame(maxWidth: 240)
                } else {
                    Text(collection.title.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.8, green: 0.84, blue: 0.88))
                        .onTapGesture {
                            if store.isEditMode {
                                titleDraft = collection.title
                                isEditingTitle = true
                            }
                        }

                    Text("(\(collection.items.count))")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                }

                Spacer()

                if store.isEditMode {
                    HStack(spacing: 6) {
                        Button(action: {
                            if isEditingTitle {
                                store.updateCollectionTitle(collectionId: collection.id, title: titleDraft)
                                isEditingTitle = false
                            } else {
                                titleDraft = collection.title
                                isEditingTitle = true
                            }
                        }) {
                            Image(systemName: isEditingTitle ? "checkmark" : "pencil")
                                .font(.system(size: 11))
                                .foregroundColor(isEditingTitle ? .cyan : Color(red: 0.7, green: 0.75, blue: 0.8))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .help(isEditingTitle ? "Lưu tên mới" : "Đổi tên nhóm")

                        Button(action: {
                            store.isModalOpen = true
                            showDeleteConfirm = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.98, green: 0.44, blue: 0.52))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .help("Xóa nhóm này")
                        .alert("Xóa nhóm '\(collection.title)'?", isPresented: $showDeleteConfirm) {
                            Button("Xóa", role: .destructive) {
                                store.isModalOpen = false
                                store.deleteCollection(collectionId: collection.id)
                            }
                            Button("Hủy", role: .cancel) {
                                store.isModalOpen = false
                            }
                        } message: {
                            Text("Tất cả lối tắt ứng dụng trong nhóm này sẽ bị xóa khỏi VXDeck (không xóa ứng dụng gốc trên máy).")
                        }
                    }
                }
            }
            .padding(.horizontal, 4)

            // Grid of App Items
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(collection.items.sorted(by: { $0.displayOrder < $1.displayOrder })) { item in
                    AppCardView(
                        item: item,
                        collectionId: collection.id,
                        onLaunchRequested: onLaunchRequested
                    )
                    .onDrag {
                        guard store.isEditMode else { return NSItemProvider() }
                        return NSItemProvider(object: "\(collection.id.uuidString):\(item.id.uuidString)" as NSString)
                    }
                    .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                        handleDrop(providers: providers, targetItemId: item.id)
                    }
                }

                if store.isEditMode {
                    AddAppCardPlaceholder(collectionId: collection.id)
                        .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                            handleDrop(providers: providers, targetItemId: nil)
                        }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.02))
        )
    }

    private func handleDrop(providers: [NSItemProvider], targetItemId: UUID?) -> Bool {
        guard store.isEditMode, let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (itemData, error) in
            guard let data = itemData as? Data ?? (itemData as? String)?.data(using: .utf8),
                  let str = String(data: data, encoding: .utf8) else {
                return
            }

            let parts = str.components(separatedBy: ":")
            guard parts.count == 2,
                  let sourceColId = UUID(uuidString: parts[0]),
                  let draggedItemId = UUID(uuidString: parts[1]) else {
                return
            }

            DispatchQueue.main.async {
                guard self.store.isEditMode else { return }

                // Resolve strictly against current store collections
                guard let sourceCol = self.store.collections.first(where: { $0.id == sourceColId }),
                      let currentTargetCol = self.store.collections.first(where: { $0.id == self.collection.id }),
                      let sourceIndex = sourceCol.items.firstIndex(where: { $0.id == draggedItemId }) else {
                    return
                }

                if sourceColId == self.collection.id {
                    // Reorder within same collection
                    let targetIndex: Int
                    if let targetId = targetItemId, let idx = currentTargetCol.items.firstIndex(where: { $0.id == targetId }) {
                        targetIndex = idx
                    } else {
                        targetIndex = currentTargetCol.items.count
                    }
                    self.store.reorderItems(inCollectionId: self.collection.id, from: sourceIndex, to: targetIndex)
                } else {
                    // Move across collections
                    let targetIndex: Int? = targetItemId.flatMap { id in
                        currentTargetCol.items.firstIndex(where: { $0.id == id })
                    }
                    self.store.moveItem(
                        itemId: draggedItemId,
                        fromCollectionId: sourceColId,
                        toCollectionId: self.collection.id,
                        targetIndex: targetIndex
                    )
                }
            }
        }
        return true
    }
}
