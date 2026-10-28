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
        print("  ✓ testDeckStoreCollectionAndItemOperations: PASS")

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
            themeMode: "dark"
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
        let store = DeckStore()
        await store.initialize()

        // Create new collection
        store.createCollection(title: "Nhóm Kiểm Thử")
        guard let testCol = store.collections.first(where: { $0.title == "Nhóm Kiểm Thử" }) else {
            fatalError("Collection was not created")
        }

        // Add app to collection
        let added = store.addApp(toCollectionId: testCol.id, path: "/Applications/Safari.app")
        assert(added, "Failed to add Safari to collection")

        // Try adding duplicate app
        let duplicateAdded = store.addApp(toCollectionId: testCol.id, path: "/Applications/Safari.app")
        assert(!duplicateAdded, "Duplicate app should be rejected")

        // Add another app
        _ = store.addApp(toCollectionId: testCol.id, path: "/System/Applications/Utilities/Terminal.app")

        let updatedCol = store.collections.first(where: { $0.id == testCol.id })!
        assert(updatedCol.items.count == 2, "Collection should have 2 items")
        assert(updatedCol.items[0].displayOrder == 0, "Item 0 order should be 0")
        assert(updatedCol.items[1].displayOrder == 1, "Item 1 order should be 1")

        // Reorder items
        store.reorderItems(inCollectionId: testCol.id, from: 0, to: 2)
        let reorderedCol = store.collections.first(where: { $0.id == testCol.id })!
        assert(reorderedCol.items[0].displayOrder == 0, "Reordered item 0 should be 0")
        assert(reorderedCol.items[1].displayOrder == 1, "Reordered item 1 should be 1")

        // Remove item
        let firstItemId = reorderedCol.items[0].id
        store.removeApp(itemId: firstItemId, fromCollectionId: testCol.id)
        let afterRemovalCol = store.collections.first(where: { $0.id == testCol.id })!
        assert(afterRemovalCol.items.count == 1, "Collection should have 1 item after removal")

        // Delete collection
        store.deleteCollection(collectionId: testCol.id)
        assert(store.collections.first(where: { $0.id == testCol.id }) == nil, "Collection should be removed")
    }

    static func testIconProvider() {
        let icon = IconProvider.shared.icon(forPath: "/Applications/Safari.app")
        assert(icon.size.width == 48, "Icon width should be 48")
        assert(icon.size.height == 48, "Icon height should be 48")
    }
}
