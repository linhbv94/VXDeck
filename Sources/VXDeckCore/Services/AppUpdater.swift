import Foundation
import AppKit

public enum AppUpdaterError: LocalizedError, Equatable {
    case downloadFailed(String)
    case mountFailed(String)
    case appNotFoundInImage
    case targetNotWritable(String)
    case scriptGenerationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let reason):
            return "Tải bản cập nhật thất bại: \(reason)"
        case .mountFailed(let reason):
            return "Không thể mở file cập nhật DMG: \(reason)"
        case .appNotFoundInImage:
            return "Gói cập nhật không chứa file ứng dụng VXDeck.app hợp lệ."
        case .targetNotWritable(let path):
            return "Không có quyền ghi đè ứng dụng tại: \(path)"
        case .scriptGenerationFailed(let reason):
            return "Không thể khởi tạo tiến trình cập nhật: \(reason)"
        }
    }
}

public final class AppUpdater: @unchecked Sendable {
    public static let shared = AppUpdater()

    private init() {}

    public func applyUpdate(dmgURL: URL, targetAppURL: URL, currentPid: Int32 = getpid()) async throws {
        // 1. Download DMG to temporary location
        let tempDownloadURL: URL
        do {
            let (downloadedURL, response) = try await URLSession.shared.download(from: dmgURL)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw AppUpdaterError.downloadFailed("Máy chủ phản hồi mã lỗi HTTP \(http.statusCode)")
            }
            tempDownloadURL = downloadedURL
        } catch {
            throw AppUpdaterError.downloadFailed(error.localizedDescription)
        }

        let uniqueId = UUID().uuidString
        let tempDmgPath = "/tmp/vxdeck_update_\(uniqueId).dmg"
        let mountPoint = "/tmp/vxdeck_mount_\(uniqueId)"
        let updaterScriptPath = "/tmp/vxdeck_apply_update_\(uniqueId).sh"

        let fileManager = FileManager.default

        // Copy downloaded file to stable temp location
        try? fileManager.removeItem(atPath: tempDmgPath)
        do {
            try fileManager.copyItem(at: tempDownloadURL, to: URL(fileURLWithPath: tempDmgPath))
        } catch {
            throw AppUpdaterError.downloadFailed("Không thể lưu file tải về: \(error.localizedDescription)")
        }

        // 2. Mount DMG silently
        try? fileManager.removeItem(atPath: mountPoint)
        try fileManager.createDirectory(atPath: mountPoint, withIntermediateDirectories: true)

        let mountProc = Process()
        mountProc.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProc.arguments = ["attach", "-nobrowse", "-readonly", "-mountpoint", mountPoint, tempDmgPath]
        do {
            try mountProc.run()
            mountProc.waitUntilExit()
            if mountProc.terminationStatus != 0 {
                throw AppUpdaterError.mountFailed("Lệnh hdiutil thoát với mã \(mountProc.terminationStatus)")
            }
        } catch {
            try? fileManager.removeItem(atPath: mountPoint)
            try? fileManager.removeItem(atPath: tempDmgPath)
            throw AppUpdaterError.mountFailed(error.localizedDescription)
        }

        // 3. Verify VXDeck.app inside mount
        let sourceAppPath = "\(mountPoint)/VXDeck.app"
        guard fileManager.fileExists(atPath: sourceAppPath) else {
            let detachProc = Process()
            detachProc.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            detachProc.arguments = ["detach", mountPoint, "-force"]
            try? detachProc.run()
            try? fileManager.removeItem(atPath: mountPoint)
            try? fileManager.removeItem(atPath: tempDmgPath)
            throw AppUpdaterError.appNotFoundInImage
        }

        let targetPath = targetAppURL.path

        // 4. Generate detached helper script
        let script = """
        #!/bin/bash
        PID=$1
        MOUNT="$2"
        DMG="$3"
        TARGET="$4"

        # Wait for current app to fully terminate
        while kill -0 "$PID" 2>/dev/null; do
            sleep 0.1
        done

        # Replace app bundle
        if [ -d "$MOUNT/VXDeck.app" ] && [ -n "$TARGET" ]; then
            rm -rf "$TARGET"
            cp -R "$MOUNT/VXDeck.app" "$TARGET"
        fi

        # Detach DMG and cleanup
        /usr/bin/hdiutil detach "$MOUNT" -force >/dev/null 2>&1
        rm -rf "$MOUNT"
        rm -f "$DMG"

        # Relaunch updated app
        /usr/bin/open "$TARGET"

        # Remove self script
        rm -f "$0"
        """

        do {
            try script.write(toFile: updaterScriptPath, atomically: true, encoding: .utf8)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: updaterScriptPath)
        } catch {
            let detachProc = Process()
            detachProc.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            detachProc.arguments = ["detach", mountPoint, "-force"]
            try? detachProc.run()
            try? fileManager.removeItem(atPath: mountPoint)
            try? fileManager.removeItem(atPath: tempDmgPath)
            throw AppUpdaterError.scriptGenerationFailed(error.localizedDescription)
        }

        // 5. Spawn background updater process
        let updateProc = Process()
        updateProc.executableURL = URL(fileURLWithPath: "/bin/bash")
        updateProc.arguments = [updaterScriptPath, "\(currentPid)", mountPoint, tempDmgPath, targetPath]
        try updateProc.run()
    }
}
