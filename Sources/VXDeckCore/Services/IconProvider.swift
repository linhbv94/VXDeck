import AppKit
import UniformTypeIdentifiers

public final class IconProvider: @unchecked Sendable {
    public static let shared = IconProvider()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 300
    }

    public func icon(forPath path: String, targetSize: NSSize = NSSize(width: 48, height: 48)) -> NSImage {
        let cacheKey = "\(path)_\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let image: NSImage
        if FileManager.default.fileExists(atPath: path) {
            image = NSWorkspace.shared.icon(forFile: path)
        } else {
            // Default generic application icon
            image = NSWorkspace.shared.icon(for: .application)
        }

        let finalImage = NSImage(size: targetSize)
        finalImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        finalImage.unlockFocus()

        cache.setObject(finalImage, forKey: cacheKey)
        return finalImage
    }

    public func clearCache() {
        cache.removeAllObjects()
    }
}
