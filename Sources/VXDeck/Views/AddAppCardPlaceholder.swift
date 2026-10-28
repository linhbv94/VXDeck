import SwiftUI
import AppKit
import UniformTypeIdentifiers
import VXDeckCore

public struct AddAppCardPlaceholder: View {
    @EnvironmentObject var store: DeckStore
    let collectionId: UUID

    @LocalState private var isHovered = false

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
            .frame(width: 96, height: 86)
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
        .onHover { hovering in
            isHovered = hovering
        }
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
            guard response == .OK else { return }

            for url in openPanel.urls {
                _ = store.addApp(toCollectionId: collectionId, path: url.path)
            }
        }
    }
}
