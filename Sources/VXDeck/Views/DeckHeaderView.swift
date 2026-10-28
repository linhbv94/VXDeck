import SwiftUI
import VXDeckCore

public struct DeckHeaderView: View {
    @EnvironmentObject var store: DeckStore
    @LocalState private var showAddGroupDialog = false
    @LocalState private var newGroupTitle = ""

    public var body: some View {
        HStack(spacing: 12) {
            // Brand Logo & Title
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cyan)

                Text("VXDeck")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                if store.isEditMode {
                    Text("• Chế độ sửa")
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
                        newGroupTitle = ""
                        showAddGroupDialog = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Nhóm mới")
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
                    .help("Tạo nhóm bộ sưu tập mới")
                    .sheet(isPresented: $showAddGroupDialog) {
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
                                    showAddGroupDialog = false
                                }
                                .keyboardShortcut(.cancelAction)

                                Button("Tạo") {
                                    store.isModalOpen = false
                                    showAddGroupDialog = false
                                    store.createCollection(title: newGroupTitle)
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
                }

                // Edit Mode Toggle Button
                Button(action: {
                    store.toggleEditMode()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: store.isEditMode ? "checkmark" : "pencil")
                            .font(.system(size: 11, weight: .semibold))
                        Text(store.isEditMode ? "Hoàn tất" : "Chỉnh sửa")
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
                .help(store.isEditMode ? "Hoàn tất chỉnh sửa [⌘E]" : "Bật chế độ chỉnh sửa [⌘E]")
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.7))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
