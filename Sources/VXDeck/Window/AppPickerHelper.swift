import AppKit
import UniformTypeIdentifiers

@MainActor
public final class AppPickerDelegate: NSObject, NSOpenSavePanelDelegate {
    public static let shared = AppPickerDelegate()

    /// A sheet stays above its floating owner and blocks interaction with that owner.
    public static func present(_ picker: NSOpenPanel, on parent: NSWindow,
                               completion: @escaping @MainActor (NSApplication.ModalResponse) -> Void) {
        picker.beginSheetModal(for: parent) { response in
            completion(response)
            if parent.isVisible {
                NSApp.activate(ignoringOtherApps: true)
                parent.makeKeyAndOrderFront(nil)
            }
        }
    }

    public func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        if url.pathExtension.lowercased() == "app" {
            return true
        }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            // Allow navigating inside folders (e.g. /Applications/Utilities) but not into .app packages
            return url.pathExtension.lowercased() != "app"
        }
        return false
    }
}
