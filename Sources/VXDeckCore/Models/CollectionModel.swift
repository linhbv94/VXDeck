import Foundation

public struct CollectionModel: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var displayOrder: Int
    public var isCollapsed: Bool
    public var items: [AppItemModel]

    public init(
        id: UUID = UUID(),
        title: String,
        displayOrder: Int = 0,
        isCollapsed: Bool = false,
        items: [AppItemModel] = []
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
        self.isCollapsed = isCollapsed
        self.items = items
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case displayOrder = "display_order"
        case isCollapsed = "is_collapsed"
        case items
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Bộ sưu tập"
        self.displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 0
        self.isCollapsed = try container.decodeIfPresent(Bool.self, forKey: .isCollapsed) ?? false
        self.items = try container.decodeIfPresent([AppItemModel].self, forKey: .items) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(displayOrder, forKey: .displayOrder)
        try container.encode(isCollapsed, forKey: .isCollapsed)
        try container.encode(items, forKey: .items)
    }
}
