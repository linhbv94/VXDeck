import Foundation

public struct AppItemModel: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var customLabel: String?
    public var bundleId: String?
    public var path: String
    public var displayOrder: Int
    public var addedAt: Date
    public var isAvailable: Bool

    public var displayName: String {
        if let custom = customLabel, !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return custom
        }
        return name
    }

    public init(
        id: UUID = UUID(),
        name: String,
        customLabel: String? = nil,
        bundleId: String? = nil,
        path: String,
        displayOrder: Int = 0,
        addedAt: Date = Date(),
        isAvailable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.customLabel = customLabel
        self.bundleId = bundleId
        self.path = path
        self.displayOrder = displayOrder
        self.addedAt = addedAt
        self.isAvailable = isAvailable
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case customLabel = "custom_label"
        case bundleId = "bundle_id"
        case path
        case displayOrder = "display_order"
        case addedAt = "added_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "App"
        self.customLabel = try container.decodeIfPresent(String.self, forKey: .customLabel)
        self.bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId)
        self.path = try container.decodeIfPresent(String.self, forKey: .path) ?? ""
        self.displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 0
        self.addedAt = try container.decodeIfPresent(Date.self, forKey: .addedAt) ?? Date()
        self.isAvailable = true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(customLabel, forKey: .customLabel)
        try container.encodeIfPresent(bundleId, forKey: .bundleId)
        try container.encode(path, forKey: .path)
        try container.encode(displayOrder, forKey: .displayOrder)
        try container.encode(addedAt, forKey: .addedAt)
    }
}
