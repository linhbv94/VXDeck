import Foundation
import AppKit
import VXDeckCore

@main
struct DeckCoreTests {
    static func main() async throws {
        print("==> [VXDeckCoreTests] Starting suite execution...")

        try testModelSerializationRoundtrip()
        print("  ✓ testModelSerializationRoundtrip: PASS")

        testDefaultSeedGeneration()
        print("  ✓ testDefaultSeedGeneration: PASS")

        await testDeckStoreCollectionAndItemOperations()
        print("  ✓ testDeckStoreCollectionAndItemOperations (isolated sandbox & readback): PASS")

        await testConfigBackupRecovery()
        print("  ✓ testConfigBackupRecovery: PASS")

        testIconProvider()
        print("  ✓ testIconProvider: PASS")

        print("==> [VXDeckCoreTests] ALL 4 TEST SUITES PASSED SUCCESSFULLY (100% PASS)!")
    }

    static func testModelSerializationRoundtrip() throws {
        let app = AppItemModel(
            name: "Test App",
            customLabel: "Custom Label",
            bundleId: "com.example.test",
            path: "/Applications/Test.app",
            displayOrder: 0,
            addedAt: Date()
        )

        let collection = CollectionModel(
            title: "Testing Group",
            displayOrder: 0,
            isCollapsed: false,
            items: [app]
        )

        let settings = DeckSettings(
            autoHideOnLaunch: true,
            columnsCount: 5,
            iconSize: 48,
            themeMode: "dark",
            windowWidth: 700
        )

        let config = DeckConfig(
            version: "1.0.0",
            schemaVersion: 1,
            updatedAt: Date(),
            settings: settings,
            collections: [collection]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(config)
        assert(!data.isEmpty, "Encoded data should not be empty")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DeckConfig.self, from: data)

        assert(decoded.version == config.version, "Version mismatch")
        assert(decoded.schemaVersion == config.schemaVersion, "Schema version mismatch")
        assert(decoded.settings.columnsCount == 5, "Columns count mismatch")
        assert(decoded.settings.windowWidth == 700, "Window width mismatch")
        assert(decoded.collections.count == 1, "Collections count mismatch")
        assert(decoded.collections[0].title == "Testing Group", "Title mismatch")
        assert(decoded.collections[0].items.count == 1, "Items count mismatch")
        assert(decoded.collections[0].items[0].name == "Test App", "App name mismatch")
        assert(decoded.collections[0].items[0].displayName == "Custom Label", "Custom label mismatch")
    }

    static func testDefaultSeedGeneration() {
        let seed = DeckConfig.defaultSeed()
        assert(seed.version == "1.0.0", "Seed version mismatch")
        assert(seed.schemaVersion == 1, "Seed schema mismatch")
        assert(!seed.collections.isEmpty, "Seed collections should not be empty")
        assert(seed.collections[0].title == "Ứng dụng Hệ thống", "Seed title mismatch")
        assert(!seed.collections[0].items.isEmpty, "Seed items should not be empty")
    }

    @MainActor
    static func testDeckStoreCollectionAndItemOperations() async {
        // Enforce isolated temporary directory to ensure tests NEVER mutate user's real config
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vxdeck_test_\(UUID().uuidString)", isDirectory: true)
        let testConfigManager = ConfigManager(customDirectoryURL: tempDir)
        let store = DeckStore(configManager: testConfigManager)
        await store.initialize()

        // Create new collection
        let testColTitle = "Test Sandbox Group \(UUID().uuidString.prefix(6))"
        store.createCollection(title: testColTitle)
        guard let testCol = store.collections.first(where: { $0.title == testColTitle }) else {
            fatalError("Collection was not created")
        }

        // Add app to collection
        let added = store.addApp(toCollectionId: testCol.id, path: "/Applications/Safari.app")
        assert(added, "Failed to add Safari to collection")

        // Try adding duplicate app
        let duplicateAdded = store.addApp(toCollectionId: testCol.id, path: "/Applications/Safari.app")
        assert(!duplicateAdded, "Duplicate app should be rejected")

        // Add second app
        let addedSecond = store.addApp(toCollectionId: testCol.id, path: "/System/Applications/Utilities/Terminal.app")
        assert(addedSecond, "Failed to add Terminal to collection")

        let updatedCol = store.collections.first(where: { $0.id == testCol.id })!
        assert(updatedCol.items.count == 2, "Collection should have 2 items")
        let firstItemId = updatedCol.items[0].id
        let secondItemId = updatedCol.items[1].id
        assert(updatedCol.items[0].name == "Safari")
        assert(updatedCol.items[1].name == "Terminal")

        // Reorder items: move Safari from index 0 to after Terminal
        store.reorderItems(inCollectionId: testCol.id, from: 0, to: 2)
        let reorderedCol = store.collections.first(where: { $0.id == testCol.id })!
        assert(reorderedCol.items.count == 2, "Item count should remain 2")
        // Verify by actual Item ID that position swapped
        assert(reorderedCol.items[0].id == secondItemId, "Terminal should now be at index 0")
        assert(reorderedCol.items[1].id == firstItemId, "Safari should now be at index 1")
        assert(reorderedCol.items[0].displayOrder == 0)
        assert(reorderedCol.items[1].displayOrder == 1)

        // Remove item
        store.removeApp(itemId: firstItemId, fromCollectionId: testCol.id)
        let afterRemovalCol = store.collections.first(where: { $0.id == testCol.id })!
        assert(afterRemovalCol.items.count == 1, "Collection should have 1 item after removal")
        assert(afterRemovalCol.items[0].id == secondItemId, "Remaining item should be Terminal")

        // Delete collection
        store.deleteCollection(collectionId: testCol.id)
        assert(store.collections.first(where: { $0.id == testCol.id }) == nil, "Collection should be removed")

        // Window width update
        store.updateWindowWidth(780)
        assert(store.settings.windowWidth == 780, "Window width should be updated to 780")

        // Wait for asynchronous persistence to flush
        await store.flush()

        // Readback check from disk to ensure persistence integrity
        let readbackConfig = await testConfigManager.loadConfig()
        assert(readbackConfig.settings.windowWidth == 780, "Readback windowWidth should be 780")

        // Clean up sandbox
        try? FileManager.default.removeItem(at: tempDir)
    }

    static func testConfigBackupRecovery() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vxdeck_recovery_\(UUID().uuidString)", isDirectory: true)
        let configManager = ConfigManager(customDirectoryURL: tempDir)

        // 1. Save valid initial config
        var config = DeckConfig.defaultSeed()
        config.settings.windowWidth = 820
        try? await configManager.saveConfig(config, revision: 1)
        await configManager.flush()

        // 2. Perform second save to generate .bak file
        config.settings.windowWidth = 920
        try? await configManager.saveConfig(config, revision: 2)
        await configManager.flush()

        // Verify primary and backup files exist
        let mainFile = tempDir.appendingPathComponent("deck_config.json")
        let backupFile = tempDir.appendingPathComponent("deck_config.json.bak")
        assert(FileManager.default.fileExists(atPath: mainFile.path), "Primary config file must exist")
        assert(FileManager.default.fileExists(atPath: backupFile.path), "Backup config file must exist")

        // 3. Delete primary config file to simulate corruption / lost file
        try? FileManager.default.removeItem(at: mainFile)
        assert(!FileManager.default.fileExists(atPath: mainFile.path), "Primary file should be deleted")

        // 4. Load config: should recover from .bak (width 820)
        let recovered = await configManager.loadConfig()
        assert(recovered.settings.windowWidth == 820, "Should have recovered from .bak file with width 820")

        // Clean up sandbox
        try? FileManager.default.removeItem(at: tempDir)
    }

    static func testIconProvider() {
        let icon = IconProvider.shared.icon(forPath: "/Applications/Safari.app")
        assert(icon.size.width == 48, "Icon width should be 48")
        assert(icon.size.height == 48, "Icon height should be 48")
    }
}
