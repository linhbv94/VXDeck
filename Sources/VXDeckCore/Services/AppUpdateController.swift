import Foundation
import AppKit

// Process-owned UI adapter: popup dismissal never cancels an authorized job.
@MainActor
public final class AppUpdateController: ObservableObject {
    public static let shared = AppUpdateController()
    @Published public private(set) var status = "idle"
    @Published public private(set) var version: String?
    @Published public private(set) var progress: Double?
    @Published public private(set) var error: String?
    @Published public private(set) var noticeVisible = false
    @Published public private(set) var release: DeckUpdateRelease?
    private var busy = false
    private var started = false
    private var dismissed = Set<String>()
    private init() {}
    public func start() {
        guard !started else { return }; started = true
        guard Bundle.main.bundleURL.pathExtension == "app" else { status = "disabled"; return }
        Task {
            // Retry receipt read briefly to cover the helper/open startup race.
            for _ in 0..<5 {
                if (try? AppUpdater.acknowledgeLaunch()) == true { break }
                try? await Task.sleep(for: .seconds(1))
            }
            await check(manual: false)
        }
    }
    public func check(manual: Bool = true) async {
        guard !busy, status != "handed_off" else { return }
        busy = true; defer { busy = false }
        status = "checking"; error = nil
        do {
            release = try await AppUpdater.shared.checkUpdate()
            version = release?.version
            status = release == nil ? "current" : "available"
            noticeVisible = release.map { !dismissed.contains($0.version) } ?? false
        } catch {
            release = nil; status = "error"; self.error = String(describing: error); noticeVisible = manual
        }
    }
    public func dismiss() {
        guard !busy else { return }
        if let version, status == "available" { dismissed.insert(version) }
        noticeVisible = false
    }
    public func install(prepare: @MainActor () async throws -> Void = {}) async {
        guard !busy, status == "available", let asset = release?.platforms[AppUpdater.platform] else { return }
        busy = true; status = "downloading"; progress = nil; error = nil; noticeVisible = true
        defer { busy = false }
        do {
            try await prepare()
            try await AppUpdater.shared.applyUpdate(dmgURL: asset.url, targetAppURL: Bundle.main.bundleURL,
                progress: { value in Task { @MainActor in self.progress = value } },
                phase: { phase in Task { @MainActor in self.status = phase } })
            status = "handed_off"
            // Helper has durably acknowledged and verified the staged bundle before quit.
            NSApp.terminate(nil)
            try? await Task.sleep(for: .seconds(35))
            if await AppUpdater.shared.recoverExpiredHandoff() {
                status = "error"; error = "update_parent_exit_timeout"; noticeVisible = true
            }
        } catch {
            status = "error"; self.error = String(describing: error); noticeVisible = true
        }
    }
}
