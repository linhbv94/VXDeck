import Foundation

public struct DeckSettings: Codable, Equatable, Sendable {
    public var autoHideOnLaunch: Bool
    public var columnsCount: Int
    public var iconSize: Int
    public var themeMode: String

    public init(
        autoHideOnLaunch: Bool = true,
        columnsCount: Int = 5,
        iconSize: Int = 48,
        themeMode: String = "dark"
    ) {
        self.autoHideOnLaunch = autoHideOnLaunch
        self.columnsCount = columnsCount
        self.iconSize = iconSize
        self.themeMode = themeMode
    }

    enum CodingKeys: String, CodingKey {
        case autoHideOnLaunch = "auto_hide_on_launch"
        case columnsCount = "columns_count"
        case iconSize = "icon_size"
        case themeMode = "theme_mode"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.autoHideOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .autoHideOnLaunch) ?? true
        self.columnsCount = try container.decodeIfPresent(Int.self, forKey: .columnsCount) ?? 5
        self.iconSize = try container.decodeIfPresent(Int.self, forKey: .iconSize) ?? 48
        self.themeMode = try container.decodeIfPresent(String.self, forKey: .themeMode) ?? "dark"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(autoHideOnLaunch, forKey: .autoHideOnLaunch)
        try container.encode(columnsCount, forKey: .columnsCount)
        try container.encode(iconSize, forKey: .iconSize)
        try container.encode(themeMode, forKey: .themeMode)
    }
}
