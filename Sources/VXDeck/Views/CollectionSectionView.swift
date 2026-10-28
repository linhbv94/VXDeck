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

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 88, maximum: 104), spacing: 12)]
    }

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

            // Dynamic Adaptive Grid of App Items
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(collection.items.sorted(by: { $0.displayOrder < $1.displayOrder })) { item in
                    if store.isEditMode {
                        AppCardView(
                            item: item,
                            collectionId: collection.id,
                            onLaunchRequested: onLaunchRequested
                        )
                        .onDrag {
                            store.draggingItemId = item.id
                            store.draggingCollectionId = collection.id
                            return NSItemProvider(object: "\(collection.id.uuidString):\(item.id.uuidString)" as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: AppCardDropDelegate(
                                item: item,
                                collectionId: collection.id,
                                store: store
                            )
                        )
                    } else {
                        AppCardView(
                            item: item,
                            collectionId: collection.id,
                            onLaunchRequested: onLaunchRequested
                        )
                    }
                }

                if store.isEditMode {
                    AddAppCardPlaceholder(collectionId: collection.id)
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
}
