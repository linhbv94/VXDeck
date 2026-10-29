import Foundation
import CryptoKit
import Darwin

public enum AppUpdaterError: LocalizedError, Equatable {
    case downloadFailed(String)
    case mountFailed(String)
    case appNotFoundInImage
    case targetNotWritable(String)
    case scriptGenerationFailed(String)
    case invalidManifest(String)
    case operationBusy

    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let reason): return "update_download_failed: \(reason)"
        case .mountFailed(let reason): return "update_mount_failed: \(reason)"
        case .appNotFoundInImage: return "update_bundle_invalid"
        case .targetNotWritable(let path): return "update_target_not_writable: \(path)"
        case .scriptGenerationFailed(let reason): return "update_helper_failed: \(reason)"
        case .invalidManifest(let reason): return "update_manifest_invalid: \(reason)"
        case .operationBusy: return "update_operation_busy"
        }
    }
}

public struct DeckUpdateAsset: Codable, Sendable {
    public let url: URL
    public let sha256: String
    public let size: Int64
}
public struct DeckUpdateRelease: Codable, Sendable {
    public let app_id: String
    public let version: String
    public let platforms: [String: DeckUpdateAsset]
}
private struct SignedDeckRelease: Decodable {
    let signed_payload: String
    let signature: String
}

// Signature is over exact payload bytes, not a second JSON serializer's output.
public enum DeckUpdateValidation {
    public static func version(_ value: String) throws -> [Int] {
        guard value.range(of: #"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$"#, options: .regularExpression) != nil else {
            throw AppUpdaterError.invalidManifest("stable_version")
        }
        let numbers = value.split(separator: ".").compactMap { Int($0) }
        guard numbers.count == 3 else { throw AppUpdaterError.invalidManifest("version_overflow") }
        return numbers
    }
    public static func newer(_ remote: String, than current: String) throws -> Bool {
        let a = try version(remote), b = try version(current)
        return a.lexicographicallyPrecedes(b) == false && a != b
    }
    public static func verify(_ data: Data, publicKey: String, platform: String) throws -> DeckUpdateRelease {
        guard data.count <= 1_048_576,
              let envelope = try? JSONDecoder().decode(SignedDeckRelease.self, from: data),
              let bytes = Data(base64Encoded: envelope.signed_payload),
              let signature = Data(base64Encoded: envelope.signature),
              let keyBytes = Data(base64Encoded: publicKey),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: keyBytes),
              key.isValidSignature(signature, for: bytes) else {
            throw AppUpdaterError.invalidManifest("signature")
        }
        let release = try JSONDecoder().decode(DeckUpdateRelease.self, from: bytes)
        guard release.app_id == "com.ztools.vxdeck", !release.platforms.isEmpty else {
            throw AppUpdaterError.invalidManifest("app_identity")
        }
        _ = try version(release.version)
        for (target, asset) in release.platforms {
            guard ["macos_silicon", "macos_intel"].contains(target),
                  asset.size > 0, asset.size <= 512 * 1024 * 1024,
                  asset.sha256.range(of: #"^[a-f0-9]{64}$"#, options: .regularExpression) != nil,
                  asset.url.absoluteString == "https://github.com/linhbv94/VXDeck/releases/download/v\(release.version)/vxdeck_\(release.version)_\(target).dmg" else {
                throw AppUpdaterError.invalidManifest("asset_target")
            }
        }
        guard release.platforms[platform] != nil else { throw AppUpdaterError.invalidManifest("missing_architecture") }
        return release
    }
    public static func hash(_ url: URL) throws -> String {
        let stream = try FileHandle(forReadingFrom: url)
        defer { try? stream.close() }
        var digest = SHA256()
        while let block = try stream.read(upToCount: 65_536), !block.isEmpty { digest.update(data: block) }
        return digest.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

private final class DeckDownloadProgress: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let expectedSize: Int64
    let callback: @Sendable (Double) -> Void
    init(expectedSize: Int64, callback: @escaping @Sendable (Double) -> Void) {
        self.expectedSize = expectedSize; self.callback = callback
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > expectedSize { downloadTask.cancel(); return }
        callback(min(100, Double(totalBytesWritten) / Double(expectedSize) * 100))
    }
}

public actor AppUpdater {
    public static let shared = AppUpdater()
    private var applying = false
    private var dispatched = false
    private init() {}
    public static var platform: String {
        #if arch(arm64)
        return "macos_silicon"
        #else
        return "macos_intel"
        #endif
    }
    public func checkUpdate() async throws -> DeckUpdateRelease? {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let endpoint = URL(string: "https://github.com/linhbv94/VXDeck/releases/latest/download/latest.json")!
        let (data, response) = try await session.data(from: endpoint)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppUpdaterError.invalidManifest("http_response")
        }
        let release = try DeckUpdateValidation.verify(data, publicKey: UpdaterTrust.publicKey, platform: Self.platform)
        guard let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            throw AppUpdaterError.invalidManifest("packaged_app_required")
        }
        return try DeckUpdateValidation.newer(release.version, than: current) ? release : nil
    }

    // Existing API retained: arbitrary download URLs and non-running install targets are rejected.
    public func applyUpdate(dmgURL: URL, targetAppURL: URL, currentPid: Int32 = getpid(),
                            progress: @escaping @Sendable (Double) -> Void = { _ in },
                            phase: @escaping @Sendable (String) -> Void = { _ in }) async throws {
        guard !applying, !dispatched else { throw AppUpdaterError.operationBusy }
        applying = true
        defer { applying = false }
        let target = targetAppURL.standardizedFileURL
        guard target.pathExtension == "app", target.lastPathComponent == "VXDeck.app",
              target == Bundle.main.bundleURL.standardizedFileURL,
              !target.path.hasPrefix("/Volumes/"),
              currentPid == getpid(), FileManager.default.isWritableFile(atPath: target.deletingLastPathComponent().path),
              (try? target.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == false else {
            throw AppUpdaterError.targetNotWritable(target.path)
        }
        guard let release = try await checkUpdate(), let asset = release.platforms[Self.platform], asset.url == dmgURL else {
            throw AppUpdaterError.invalidManifest("offer_changed_or_unsigned")
        }
        let manager = FileManager.default
        let job = UUID().uuidString.lowercased()
        let downloads = manager.temporaryDirectory.appendingPathComponent("vxdeck_download_\(job)", isDirectory: true)
        let stage = target.deletingLastPathComponent().appendingPathComponent(".vxdeck_update_\(job)", isDirectory: true)
        try manager.createDirectory(at: downloads, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        var mounted = false
        var helper: Process?
        let mount = downloads.appendingPathComponent("mount", isDirectory: true)
        defer {
            if mounted { try? Self.tool("/usr/bin/hdiutil", ["detach", mount.path, "-force"], timeout: 15) }
            try? manager.removeItem(at: downloads)
            if !dispatched { try? manager.removeItem(at: stage) }
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let observer = DeckDownloadProgress(expectedSize: asset.size, callback: progress)
        let (downloaded, response) = try await session.download(for: URLRequest(url: asset.url), delegate: observer)
        phase("verifying")
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              (try downloaded.resourceValues(forKeys: [.fileSizeKey]).fileSize) == Int(asset.size),
              try DeckUpdateValidation.hash(downloaded) == asset.sha256 else {
            throw AppUpdaterError.downloadFailed("signed_size_or_hash_mismatch")
        }
        let dmg = downloads.appendingPathComponent("package.dmg")
        try manager.moveItem(at: downloaded, to: dmg)
        try manager.createDirectory(at: mount, withIntermediateDirectories: false)
        try Self.tool("/usr/bin/hdiutil", ["attach", "-nobrowse", "-readonly", "-mountpoint", mount.path, dmg.path], timeout: 30)
        mounted = true
        let candidate = mount.appendingPathComponent("VXDeck.app", isDirectory: true)
        try Self.validateBundle(candidate, version: release.version)
        phase("installing")
        try manager.createDirectory(at: stage, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let stagedApp = stage.appendingPathComponent("VXDeck.app", isDirectory: true)
        try Self.tool("/usr/bin/ditto", [candidate.path, stagedApp.path], timeout: 300)
        try Self.validateBundle(stagedApp, version: release.version)
        try Self.tool("/usr/bin/hdiutil", ["detach", mount.path, "-force"], timeout: 15)
        mounted = false
        let hash = try DeckUpdateValidation.hash(stagedApp.appendingPathComponent("Contents/MacOS/VXDeck"))
        let identity = try Self.output("/usr/bin/stat", ["-f", "%d:%i", target.path])
        let helperURL = stage.appendingPathComponent("apply_update.sh")
        let ready = stage.appendingPathComponent("ready")
        let receipt = target.deletingLastPathComponent().appendingPathComponent(".vxdeck_update_receipt.plist")
        let backup = target.deletingLastPathComponent().appendingPathComponent(".vxdeck_backup_\(job).app")
        try Self.helperScript.write(to: helperURL, atomically: true, encoding: .utf8)
        try manager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: helperURL.path)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [helperURL.path, String(currentPid), target.path, stagedApp.path, backup.path,
                             ready.path, receipt.path, hash, release.version, identity]
        try process.run(); helper = process
        for _ in 0..<100 {
            if manager.fileExists(atPath: ready.path) { dispatched = true; phase("handed_off"); return }
            if !process.isRunning { throw AppUpdaterError.scriptGenerationFailed("helper_exited_before_ready") }
            try await Task.sleep(for: .milliseconds(100))
        }
        if let helper, helper.isRunning { helper.terminate() }
        throw AppUpdaterError.scriptGenerationFailed("helper_ready_timeout")
    }

    public func recoverExpiredHandoff() -> Bool {
        let target = Bundle.main.bundleURL.standardizedFileURL
        let receipt = target.deletingLastPathComponent().appendingPathComponent(".vxdeck_update_receipt.plist")
        guard let data = try? Data(contentsOf: receipt),
              let document = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              document["target"] == target.path,
              ["parent_exit_timeout", "revalidation_failed"].contains(document["state"] ?? "") else { return false }
        dispatched = false
        return true
    }
    public nonisolated static func acknowledgeLaunch(bundleURL: URL = Bundle.main.bundleURL) throws -> Bool {
        let target = bundleURL.standardizedFileURL
        let receipt = target.deletingLastPathComponent().appendingPathComponent(".vxdeck_update_receipt.plist")
        guard let data = try? Data(contentsOf: receipt),
              var document = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              document["target"] == target.path,
              ["awaiting_launch_confirmation", "restarting"].contains(document["state"] ?? ""),
              let bundle = Bundle(url: target),
              document["version"] == bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
              document["binary_sha256"] == (try hashInstalledBinary(target)) else { return false }
        document["state"] = "completed"
        let output = try PropertyListSerialization.data(fromPropertyList: document, format: .xml, options: 0)
        try output.write(to: receipt, options: .atomic)
        return true
    }
    private nonisolated static func hashInstalledBinary(_ target: URL) throws -> String {
        try DeckUpdateValidation.hash(target.appendingPathComponent("Contents/MacOS/VXDeck"))
    }

    private static func validateBundle(_ url: URL, version: String) throws {
        guard (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == false,
              let bundle = Bundle(url: url), bundle.bundleIdentifier == "com.ztools.vxdeck",
              bundle.infoDictionary?["CFBundleShortVersionString"] as? String == version,
              bundle.infoDictionary?["CFBundleExecutable"] as? String == "VXDeck" else {
            throw AppUpdaterError.appNotFoundInImage
        }
        try tool("/usr/bin/codesign", ["--verify", "--deep", "--strict", url.path], timeout: 30)
    }
    private static func tool(_ executable: String, _ arguments: [String], timeout: TimeInterval) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable); process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice; process.standardError = FileHandle.nullDevice
        try process.run()
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.02) }
        if process.isRunning {
            process.terminate(); Thread.sleep(forTimeInterval: 0.1)
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            process.waitUntilExit()
            throw AppUpdaterError.scriptGenerationFailed("tool_timeout")
        }
        guard process.terminationStatus == 0 else { throw AppUpdaterError.scriptGenerationFailed("tool_failed: \(executable)") }
    }
    private static func output(_ executable: String, _ arguments: [String]) throws -> String {
        // Fixed /usr/bin/stat invocation; output is a single bounded identity line.
        let process = Process(), pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable); process.arguments = arguments
        process.standardOutput = pipe
        try process.run(); process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw AppUpdaterError.appNotFoundInImage }
        return String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public nonisolated static let helperScript = #"""
    #!/bin/bash
    set -eu
    umask 077
    pid="$1"; target="$2"; stage="$3"; backup="$4"; ready="$5"; receipt="$6"; digest="$7"; version="$8"; identity="$9"
    write_state() {
        tmp="${receipt}.tmp.$$"
        /usr/bin/plutil -create xml1 "$tmp"
        /usr/bin/plutil -insert state -string "$1" "$tmp"
        /usr/bin/plutil -insert target -string "$target" "$tmp"
        /usr/bin/plutil -insert version -string "$version" "$tmp"
        /usr/bin/plutil -insert binary_sha256 -string "$digest" "$tmp"
        /usr/bin/plutil -insert backup -string "$backup" "$tmp"
        /bin/mv "$tmp" "$receipt"
    }
    valid_stage() {
        [ -d "$stage" ] && [ ! -L "$stage" ] &&
        [ "$(/usr/bin/shasum -a 256 "$stage/Contents/MacOS/VXDeck" | /usr/bin/awk '{print $1}')" = "$digest" ] &&
        [ "$(/usr/bin/defaults read "$stage/Contents/Info" CFBundleIdentifier)" = 'com.ztools.vxdeck' ] &&
        [ "$(/usr/bin/defaults read "$stage/Contents/Info" CFBundleShortVersionString)" = "$version" ] &&
        /usr/bin/codesign --verify --deep --strict "$stage"
    }
    case "$pid" in ''|*[!0-9]*|0|1) exit 11;; esac
    [ -d "$target" ] && [ ! -L "$target" ] && [ ! -e "$backup" ] && valid_stage || exit 12
    [ "$(/usr/bin/stat -f '%d:%i' "$target")" = "$identity" ] || exit 13
    write_state helper_ready
    : > "$ready"
    count=0
    while kill -0 "$pid" 2>/dev/null; do
        count=$((count+1))
        if [ "$count" -gt 300 ]; then write_state parent_exit_timeout; exit 14; fi
        /bin/sleep 0.1
    done
    valid_stage && [ ! -L "$target" ] && [ "$(/usr/bin/stat -f '%d:%i' "$target")" = "$identity" ] || { write_state revalidation_failed; exit 15; }
    write_state installing
    /bin/mv "$target" "$backup"
    if ! /bin/mv "$stage" "$target"; then
        /bin/mv "$backup" "$target"
        write_state install_failed_rolled_back
        exit 16
    fi
    write_state awaiting_launch_confirmation
    if ! /usr/bin/open -n "$target"; then
        /bin/mv "$target" "$stage"
        /bin/mv "$backup" "$target"
        write_state relaunch_failed_rolled_back
        exit 17
    fi
    """#
}
