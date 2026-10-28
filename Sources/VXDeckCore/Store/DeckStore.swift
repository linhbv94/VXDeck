import Foundation
import AppKit

@MainActor
public final class DeckStore: ObservableObject {
    public static let shared = DeckStore()

    @Published public var config: DeckConfig
    @Published public var isEditMode: Bool = false
    @Published public var isModalOpen: Bool = false
    @Published public var windowSessionId: UUID = UUID()
    @Published public var toastMessage: String? = nil

    private let configManager: ConfigManager
    private let appLauncher: AppLauncher
    private var toastTask: Task<Void, Never>?

    public var collections: [CollectionModel] {
        get { config.collections.sorted(by: { $0.displayOrder < $1.displayOrder }) }
        set { config.collections = newValue }
    }

    public var settings: DeckSettings {
        get { config.settings }
        set { config.settings = newValue }
    }

    public init(configManager: ConfigManager = .shared, appLauncher: AppLauncher = .shared) {
        self.configManager = configManager
        self.appLauncher = appLauncher
        self.config = DeckConfig.defaultSeed()
    }

    public func initialize() async {
        let loaded = await configManager.loadConfig()
        self.config = loaded
        self.refreshAvailability()
    }

    public func refreshAvailability() {
        for cIndex in 0..<config.collections.count {
            for iIndex in 0..<config.collections[cIndex].items.count {
                let item = config.collections[cIndex].items[iIndex]
                let available = appLauncher.isAvailable(item: item)
                config.collections[cIndex].items[iIndex].isAvailable = available
            }
        }
    }

    public func save() {
        let current = self.config
        Task {
            do {
                try await configManager.saveConfig(current)
            } catch {
                print("[DeckStore] Failed to save config: \(error)")
            }
        }
    }

    public func toggleEditMode() {
        isEditMode.toggle()
        if !isEditMode {
            save()
            Task {
                await configManager.flush()
            }
        }
    }

    public func setEditMode(_ active: Bool) {
        guard isEditMode != active else { return }
        isEditMode = active
        if !isEditMode {
            save()
            Task {
                await configManager.flush()
            }
        }
    }

    public func resetWindowSession() {
        windowSessionId = UUID()
    }

    public func showToast(_ message: String, duration: TimeInterval = 2.5) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                self.toastMessage = nil
            }
        }
    }

    // MARK: - App Operations

    public func addApp(toCollectionId collectionId: UUID, path: String) -> Bool {
        guard let colIndex = config.collections.firstIndex(where: { $0.id == collectionId }) else {
            return false
        }

        let url = URL(fileURLWithPath: path)
        guard url.pathExtension == "app" || FileManager.default.fileExists(atPath: path) else {
            showToast("Chỉ chấp nhận các tệp ứng dụng .app")
            return false
        }

        let bundle = Bundle(url: url)
        let bundleId = bundle?.bundleIdentifier
        let displayName = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle?.infoDictionary?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent

        // Check for duplicates in collection
        let isDuplicate = config.collections[colIndex].items.contains { item in
            if let bundleId = bundleId, let itemBundleId = item.bundleId, bundleId == itemBundleId {
                return true
            }
            return item.path == path
        }

        if isDuplicate {
            showToast("Ứng dụng '\(displayName)' đã có trong nhóm")
            return false
        }

        let newItem = AppItemModel(
            name: displayName,
            bundleId: bundleId,
            path: path,
            displayOrder: config.collections[colIndex].items.count,
            isAvailable: true
        )

        config.collections[colIndex].items.append(newItem)
        recalculateItemOrders(inCollectionIndex: colIndex)
        save()
        showToast("Đã thêm \(displayName)")
        return true
    }

    public func removeApp(itemId: UUID, fromCollectionId collectionId: UUID) {
        guard let colIndex = config.collections.firstIndex(where: { $0.id == collectionId }) else { return }
        guard let itemIndex = config.collections[colIndex].items.firstIndex(where: { $0.id == itemId }) else { return }

        let name = config.collections[colIndex].items[itemIndex].displayName
        config.collections[colIndex].items.remove(at: itemIndex)
        recalculateItemOrders(inCollectionIndex: colIndex)
        save()
        showToast("Đã xóa \(name)")
    }

    public func updateAppLabel(itemId: UUID, inCollectionId collectionId: UUID, customLabel: String?) {
        guard let colIndex = config.collections.firstIndex(where: { $0.id == collectionId }) else { return }
        guard let itemIndex = config.collections[colIndex].items.firstIndex(where: { $0.id == itemId }) else { return }

        config.collections[colIndex].items[itemIndex].customLabel = customLabel
        save()
    }

    // MARK: - Reordering

    public func reorderItems(inCollectionId collectionId: UUID, from sourceIndex: Int, to destinationIndex: Int) {
        guard let colIndex = config.collections.firstIndex(where: { $0.id == collectionId }) else { return }
        var items = config.collections[colIndex].items
        guard sourceIndex >= 0, sourceIndex < items.count else { return }
        guard destinationIndex >= 0, destinationIndex <= items.count else { return }

        let item = items.remove(at: sourceIndex)
        let insertIndex = (destinationIndex > sourceIndex) ? destinationIndex - 1 : destinationIndex
        items.insert(item, at: min(insertIndex, items.count))

        for i in 0..<items.count {
            items[i].displayOrder = i
        }

        config.collections[colIndex].items = items
        save()
    }

    public func moveItem(
        itemId: UUID,
        fromCollectionId: UUID,
        toCollectionId: UUID,
        targetIndex: Int? = nil
    ) {
        guard let sourceColIndex = config.collections.firstIndex(where: { $0.id == fromCollectionId }),
              let targetColIndex = config.collections.firstIndex(where: { $0.id == toCollectionId }) else {
            return
        }

        guard let sourceItemIndex = config.collections[sourceColIndex].items.firstIndex(where: { $0.id == itemId }) else {
            return
        }

        let item = config.collections[sourceColIndex].items.remove(at: sourceItemIndex)
        recalculateItemOrders(inCollectionIndex: sourceColIndex)

        // Check duplicate in target
        let duplicate = config.collections[targetColIndex].items.contains {
            if let bid = item.bundleId, let tbid = $0.bundleId, bid == tbid { return true }
            return $0.path == item.path
        }

        if duplicate {
            // Re-insert into source if duplicate
            config.collections[sourceColIndex].items.insert(item, at: sourceItemIndex)
            recalculateItemOrders(inCollectionIndex: sourceColIndex)
            showToast("Ứng dụng đã tồn tại ở nhóm đích")
            return
        }

        let insertAt = min(targetIndex ?? config.collections[targetColIndex].items.count, config.collections[targetColIndex].items.count)
        config.collections[targetColIndex].items.insert(item, at: insertAt)
        recalculateItemOrders(inCollectionIndex: targetColIndex)
        save()
    }

    private func recalculateItemOrders(inCollectionIndex colIndex: Int) {
        for i in 0..<config.collections[colIndex].items.count {
            config.collections[colIndex].items[i].displayOrder = i
        }
    }

    // MARK: - Collection Operations

    public func createCollection(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmed.isEmpty ? "Bộ sưu tập mới" : trimmed
        let newCol = CollectionModel(
            title: finalTitle,
            displayOrder: config.collections.count,
            items: []
        )
        config.collections.append(newCol)
        recalculateCollectionOrders()
        save()
        showToast("Đã thêm nhóm '\(finalTitle)'")
    }

    public func updateCollectionTitle(collectionId: UUID, title: String) {
        guard let index = config.collections.firstIndex(where: { $0.id == collectionId }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        config.collections[index].title = trimmed.isEmpty ? "Bộ sưu tập" : trimmed
        save()
    }

    public func deleteCollection(collectionId: UUID) {
        guard let index = config.collections.firstIndex(where: { $0.id == collectionId }) else { return }
        let title = config.collections[index].title
        config.collections.remove(at: index)
        recalculateCollectionOrders()
        save()
        showToast("Đã xóa nhóm '\(title)'")
    }

    private func recalculateCollectionOrders() {
        for i in 0..<config.collections.count {
            config.collections[i].displayOrder = i
        }
    }
}
