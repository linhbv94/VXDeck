import Foundation

public struct DeckConfig: Codable, Equatable, Sendable {
    public var version: String
    public var schemaVersion: Int
    public var updatedAt: Date
    public var settings: DeckSettings
    public var collections: [CollectionModel]

    public init(
        version: String = "1.0.0",
        schemaVersion: Int = 1,
        updatedAt: Date = Date(),
        settings: DeckSettings = DeckSettings(),
        collections: [CollectionModel] = []
    ) {
        self.version = version
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.settings = settings
        self.collections = collections
    }

    enum CodingKeys: String, CodingKey {
        case version
        case schemaVersion = "schema_version"
        case updatedAt = "updated_at"
        case settings
        case collections
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0.0"
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        self.settings = try container.decodeIfPresent(DeckSettings.self, forKey: .settings) ?? DeckSettings()
        self.collections = try container.decodeIfPresent([CollectionModel].self, forKey: .collections) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(settings, forKey: .settings)
        try container.encode(collections, forKey: .collections)
    }

    public static func defaultSeed() -> DeckConfig {
        let defaultApps: [(name: String, path: String, bundleId: String)] = [
            ("Safari", "/Applications/Safari.app", "com.apple.Safari"),
            ("Terminal", "/System/Applications/Utilities/Terminal.app", "com.apple.Terminal"),
            ("Cài đặt", "/System/Applications/System Settings.app", "com.apple.systempreferences"),
            ("Ghi chú", "/System/Applications/Notes.app", "com.apple.Notes"),
            ("Máy tính", "/System/Applications/Calculator.app", "com.apple.calculator")
        ]

        var items: [AppItemModel] = []
        for (index, item) in defaultApps.enumerated() {
            var actualPath = item.path
            if !FileManager.default.fileExists(atPath: actualPath) {
                // Try fallback for Safari on macOS modern cryptex/system paths
                if item.name == "Safari" && FileManager.default.fileExists(atPath: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app") {
                    actualPath = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
                }
            }
            items.append(
                AppItemModel(
                    name: item.name,
                    bundleId: item.bundleId,
                    path: actualPath,
                    displayOrder: index
                )
            )
        }

        let defaultCollection = CollectionModel(
            title: "Ứng dụng Hệ thống",
            displayOrder: 0,
            items: items
        )

        return DeckConfig(
            version: "1.0.0",
            schemaVersion: 1,
            updatedAt: Date(),
            settings: DeckSettings(),
            collections: [defaultCollection]
        )
    }
}
