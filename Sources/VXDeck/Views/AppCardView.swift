import SwiftUI
import AppKit
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

    public var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // App Icon
                Image(nsImage: iconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .opacity(item.isAvailable ? 1.0 : 0.45)
                    .grayscale(item.isAvailable ? 0.0 : 1.0)
                    .scaleEffect(isPressed ? 0.92 : (isHovered && !store.isEditMode ? 1.05 : 1.0))
                    .animation(.easeOut(duration: 0.15), value: isPressed)
                    .animation(.easeOut(duration: 0.18), value: isHovered)

                // Unavailable Badge
                if !item.isAvailable {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.98, green: 0.75, blue: 0.14))
                        .offset(x: 4, y: -4)
                }

                // Delete Badge in Edit Mode
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

            // App Label
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
                .frame(width: 90)
            } else {
                Text(item.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(item.isAvailable ? (isHovered ? .white : Color(red: 0.94, green: 0.96, blue: 0.98)) : Color(red: 0.6, green: 0.6, blue: 0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 90, height: 26, alignment: .top)
            }
        }
        .frame(width: 96, height: 86)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color.white.opacity(store.isEditMode ? 0.05 : 0.08) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(store.isEditMode ? Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if store.isEditMode {
                // In edit mode, tap allows renaming label
                labelText = item.customLabel ?? item.name
                isEditingLabel = true
            } else {
                launchApp()
            }
        }
        .contextMenu {
            Button("Khởi chạy") {
                launchApp()
            }
            Button("Đổi tên hiển thị...") {
                labelText = item.customLabel ?? item.name
                isEditingLabel = true
            }
            Divider()
            Button("Hiện trong Finder") {
                let url = URL(fileURLWithPath: item.path)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            Divider()
            Button(role: .destructive, action: {
                store.removeApp(itemId: item.id, fromCollectionId: collectionId)
            }) {
                Text("Xóa khỏi nhóm")
            }
        }
    }

    private func launchApp() {
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
                if store.settings.autoHideOnLaunch && store.windowSessionId == sessionId {
                    onLaunchRequested()
                }
            } catch {
                store.showToast("Không thể mở: \(error.localizedDescription)")
            }
        }
    }
}
