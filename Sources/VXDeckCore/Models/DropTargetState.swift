import Foundation

public struct DropTargetState: Equatable, Sendable {
    public enum Edge: String, Codable, Sendable {
        case leading
        case trailing
    }

    public let collectionId: UUID
    public let itemId: UUID
    public let edge: Edge

    public init(collectionId: UUID, itemId: UUID, edge: Edge) {
        self.collectionId = collectionId
        self.itemId = itemId
        self.edge = edge
    }
}
