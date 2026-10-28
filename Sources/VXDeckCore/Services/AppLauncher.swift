import AppKit

public enum AppLauncherError: LocalizedError, Equatable {
    case appNotFound(path: String, bundleId: String?)
    case launchFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .appNotFound(let path, let bundleId):
            return "Không tìm thấy ứng dụng tại đường dẫn: \(path) (bundle: \(bundleId ?? "none"))"
        case .launchFailed(let reason):
            return "Khởi chạy ứng dụng thất bại: \(reason)"
        }
    }
}

public final class AppLauncher: @unchecked Sendable {
    public static let shared = AppLauncher()

    private init() {}

    /// Resolve the actual executable URL for the given AppItemModel.
    /// Strictly verifies identity: if expected bundleId is provided, path MUST match that bundleId.
    /// If path is missing, moved, or mismatched, fall back to LaunchServices lookup by bundle identifier.
    public func resolveTargetURL(for item: AppItemModel) -> URL? {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: item.path)

        if fileManager.fileExists(atPath: item.path) && url.pathExtension.lowercased() == "app" {
            if let expectedBundleId = item.bundleId, !expectedBundleId.isEmpty {
                if let bundle = Bundle(url: url), let actualBundleId = bundle.bundleIdentifier {
                    if actualBundleId == expectedBundleId {
                        return url
                    }
                    // Mismatched bundle ID at path! Do not launch wrong app.
                }
            } else {
                // No expected bundle ID saved; verify it's a readable bundle
                if Bundle(url: url) != nil {
                    return url
                }
            }
        }

        // Fallback: look up by Bundle Identifier via NSWorkspace
        if let bundleId = item.bundleId, !bundleId.isEmpty {
            if let resolvedURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                // Verify resolved bundle
                if let resolvedBundle = Bundle(url: resolvedURL),
                   resolvedBundle.bundleIdentifier == bundleId {
                    return resolvedURL
                }
            }
        }

        return nil
    }

    /// Check if the application exists and is available.
    public func isAvailable(item: AppItemModel) -> Bool {
        return resolveTargetURL(for: item) != nil
    }

    /// Launch application asynchronously.
    @MainActor
    public func launch(item: AppItemModel) async throws {
        guard let appURL = resolveTargetURL(for: item) else {
            throw AppLauncherError.appNotFound(path: item.path, bundleId: item.bundleId)
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.addsToRecentItems = true

        do {
            _ = try await NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
        } catch {
            throw AppLauncherError.launchFailed(reason: error.localizedDescription)
        }
    }
}
