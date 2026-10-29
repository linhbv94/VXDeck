import Foundation
import AppKit
import VXDeckCore

@main
struct DeckCoreTests {
    static func main() async throws {
        if CommandLine.arguments.contains("--qa-update-flush") {
            try await testUpdateFlushFailureFixture()
            return
        }
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

        testSemVerComparison()
        print("  ✓ testSemVerComparison: PASS")

        await testAddAppAndImmediateReorderPersistence()
        print("  ✓ testAddAppAndImmediateReorderPersistence: PASS")

        await testCollectionReordering()
        print("  ✓ testCollectionReordering: PASS")

        await testAppUpdaterErrors()
        print("  ✓ testAppUpdaterErrors: PASS")

        try UpdateSecurityTests.run()
        print("==> [VXDeckCoreTests] ALL TEST SUITES PASSED")
    }

    static func testSemVerComparison() {
        assert(DeckStore.isNewerVersion("1.0.1", than: "1.0.0"), "1.0.1 should be newer than 1.0.0")
        assert(DeckStore.isNewerVersion("1.0.10", than: "1.0.2"), "1.0.10 should be newer than 1.0.2")
        assert(DeckStore.isNewerVersion("v1.2.0", than: "1.1.9"), "v1.2.0 should be newer than 1.1.9")
        assert(DeckStore.isNewerVersion("2.0.0", than: "1.99.99"), "2.0.0 should be newer than 1.99.99")
        assert(!DeckStore.isNewerVersion("1.0.0", than: "1.0.0"), "1.0.0 should not be newer than 1.0.0")
        assert(!DeckStore.isNewerVersion("1.0.0", than: "1.0.1"), "1.0.0 should not be newer than 1.0.1")
        assert(!DeckStore.isNewerVersion("1.0.2", than: "1.0.10"), "1.0.2 should not be newer than 1.0.10")
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
            language: "en",
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
        assert(decoded.settings.language == "en", "Language readback mismatch")
        let legacy = try decoder.decode(DeckSettings.self, from: Data("{}".utf8))
        assert(legacy.language == "vi", "Legacy config must remain readable")
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

    @MainActor
    static func testAddAppAndImmediateReorderPersistence() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vxdeck_reorder_test_\(UUID().uuidString)", isDirectory: true)
        let configManager = ConfigManager(customDirectoryURL: tempDir)
        let store = DeckStore(configManager: configManager)
        await store.initialize()

        // 1. Create a fresh collection
        store.createCollection(title: "Development")
        guard let col = store.collections.first(where: { $0.title == "Development" }) else {
            fatalError("Collection creation failed")
        }

        // 2. Add multiple apps sequentially (mimicking openAppPicker loop)
        let added1 = store.addApp(toCollectionId: col.id, path: "/Applications/Safari.app")
        let added2 = store.addApp(toCollectionId: col.id, path: "/System/Applications/Utilities/Terminal.app")
        let added3 = store.addApp(toCollectionId: col.id, path: "/System/Applications/Calculator.app")
        assert(added1 && added2 && added3, "All apps should be added successfully")

        var currentItems = store.collections.first(where: { $0.id == col.id })!.items
        assert(currentItems.count == 3, "Collection should have 3 items")
        let idSafari = currentItems[0].id
        let idTerminal = currentItems[1].id
        let idCalc = currentItems[2].id

        // 3. Immediately test reorderItem: Move Calculator before Terminal (.leading of Terminal)
        store.reorderItem(itemId: idCalc, inCollectionId: col.id, relativeTo: idTerminal, edge: .leading)
        currentItems = store.collections.first(where: { $0.id == col.id })!.items
        // Expected order: Safari (0), Calculator (1), Terminal (2)
        assert(currentItems[0].id == idSafari, "Item 0 should be Safari")
        assert(currentItems[1].id == idCalc, "Item 1 should be Calculator")
        assert(currentItems[2].id == idTerminal, "Item 2 should be Terminal")
        assert(currentItems[0].displayOrder == 0)
        assert(currentItems[1].displayOrder == 1)
        assert(currentItems[2].displayOrder == 2)

        // 4. Test reorderItem: Move Safari after Terminal (.trailing of Terminal)
        store.reorderItem(itemId: idSafari, inCollectionId: col.id, relativeTo: idTerminal, edge: .trailing)
        currentItems = store.collections.first(where: { $0.id == col.id })!.items
        // Expected order: Calculator (0), Terminal (1), Safari (2)
        assert(currentItems[0].id == idCalc, "Item 0 should be Calculator")
        assert(currentItems[1].id == idTerminal, "Item 1 should be Terminal")
        assert(currentItems[2].id == idSafari, "Item 2 should be Safari")

        // 5. Test moveItemToEnd: Move Calculator to end
        store.moveItemToEnd(itemId: idCalc, inCollectionId: col.id)
        currentItems = store.collections.first(where: { $0.id == col.id })!.items
        // Expected order: Terminal (0), Safari (1), Calculator (2)
        assert(currentItems[0].id == idTerminal, "Item 0 should be Terminal")
        assert(currentItems[1].id == idSafari, "Item 1 should be Safari")
        assert(currentItems[2].id == idCalc, "Item 2 should be Calculator")

        // 6. Flush persistence to disk
        await store.flush()

        // 7. Simulate restart / crash recovery: Create fresh ConfigManager and reload from disk
        let reloadConfigManager = ConfigManager(customDirectoryURL: tempDir)
        let reloadedConfig = await reloadConfigManager.loadConfig()
        guard let reloadedCol = reloadedConfig.collections.first(where: { $0.id == col.id }) else {
            fatalError("Reloaded collection missing")
        }

        let reloadedItems = reloadedCol.items.sorted(by: { $0.displayOrder < $1.displayOrder })
        assert(reloadedItems.count == 3, "Reloaded collection must retain all 3 items (none lost on restart)")
        assert(reloadedItems[0].id == idTerminal, "Persisted item 0 must be Terminal")
        assert(reloadedItems[1].id == idSafari, "Persisted item 1 must be Safari")
        assert(reloadedItems[2].id == idCalc, "Persisted item 2 must be Calculator")

        // Clean up sandbox
        try? FileManager.default.removeItem(at: tempDir)
    }

    @MainActor
    static func testCollectionReordering() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vxdeck_col_reorder_\(UUID().uuidString)", isDirectory: true)
        let configManager = ConfigManager(customDirectoryURL: tempDir)
        let store = DeckStore(configManager: configManager)
        await store.initialize()

        // Create 3 collections
        store.createCollection(title: "Group Alpha")
        store.createCollection(title: "Group Beta")
        store.createCollection(title: "Group Gamma")

        var cols = store.collections
        assert(cols.count >= 3, "Must have at least 3 collections")
        guard let idAlpha = cols.first(where: { $0.title == "Group Alpha" })?.id,
              let idBeta = cols.first(where: { $0.title == "Group Beta" })?.id,
              let idGamma = cols.first(where: { $0.title == "Group Gamma" })?.id else {
            fatalError("Collections not found")
        }

        // Test moveCollectionDown on Alpha
        store.moveCollectionDown(collectionId: idAlpha)
        cols = store.collections
        let idxAlpha = cols.firstIndex(where: { $0.id == idAlpha })!
        let idxBeta = cols.firstIndex(where: { $0.id == idBeta })!
        assert(idxAlpha > idxBeta, "Alpha should now be below Beta")

        // Test moveCollectionUp on Gamma
        store.moveCollectionUp(collectionId: idGamma)
        cols = store.collections
        let idxGamma = cols.firstIndex(where: { $0.id == idGamma })!
        assert(idxGamma < cols.count - 1, "Gamma should have moved up")

        // Test persistence of collection orders
        let finalCols = store.collections
        let expectedAlphaIndex = finalCols.firstIndex(where: { $0.id == idAlpha })!
        let expectedGammaIndex = finalCols.firstIndex(where: { $0.id == idGamma })!
        await store.flush()

        let reloadManager = ConfigManager(customDirectoryURL: tempDir)
        let reloadedConfig = await reloadManager.loadConfig()
        let reloadedCols = reloadedConfig.collections.sorted(by: { $0.displayOrder < $1.displayOrder })
        assert(reloadedCols.firstIndex(where: { $0.id == idAlpha }) == expectedAlphaIndex, "Alpha position must be persisted")
        assert(reloadedCols.firstIndex(where: { $0.id == idGamma }) == expectedGammaIndex, "Gamma position must be persisted")

        // Clean up sandbox
        try? FileManager.default.removeItem(at: tempDir)
    }

    static func testAppUpdaterErrors() async {
        let updater = AppUpdater.shared
        let invalidURL = URL(string: "https://127.0.0.1:9/non_existent.dmg")!
        let target = URL(fileURLWithPath: "/tmp/non_existent.app")
        do {
            try await updater.applyUpdate(dmgURL: invalidURL, targetAppURL: target)
            fatalError("Should fail on invalid URL")
        } catch let err as AppUpdaterError {
            switch err {
            case .targetNotWritable:
                break
            default:
                fatalError("Unexpected error type: \(err)")
            }
        } catch {
            // Network connection rejected
        }

        let errDesc = AppUpdaterError.appNotFoundInImage.localizedDescription
        assert(!errDesc.isEmpty, "Error description should not be empty")
    }
    @MainActor
    static func testUpdateFlushFailureFixture() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("vxdeck_update_flush_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let blocked = root.appendingPathComponent("config_directory")
        try Data("fixture blocker".utf8).write(to: blocked)
        let manager = ConfigManager(customDirectoryURL: blocked)
        let store = DeckStore(configManager: manager)
        store.config.settings.language = "en"
        store.save()
        await store.flush()
        assert(!FileManager.default.fileExists(atPath: blocked.appendingPathComponent("deck_config.json").path))
        print("REPRO: legacy flush returned normally although config save failed; update prepare would proceed")
        var rejected = false
        do { try await store.flushForUpdate() } catch { rejected = true }
        assert(rejected, "Update must stop when configuration cannot be persisted")
        try FileManager.default.removeItem(at: blocked)
        try FileManager.default.createDirectory(at: blocked, withIntermediateDirectories: true)
        try await store.flushForUpdate()
        let disk = await ConfigManager(customDirectoryURL: blocked).loadConfig()
        assert(disk.settings.language == "en", "Retry must persist the live preference")
        assert(store.config.settings.language == "en", "Failed flush must not clear draft")
        print("PASS: update flush rejects save failure, preserves draft and retries with readback")
    }

}
