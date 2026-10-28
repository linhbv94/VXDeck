import AppKit
import SwiftUI
import VXDeckCore

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public var panel: DeckPanel?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let initialFrame = NSRect(x: 0, y: 0, width: 620, height: 460)
        let deckPanel = DeckPanel(contentRect: initialFrame)

        let rootView = DeckRootView(
            onCloseRequested: { [weak deckPanel] in
                deckPanel?.hidePanel()
            }
        )
        .environmentObject(DeckStore.shared)

        let hostingView = NSHostingView(rootView: rootView)
        deckPanel.contentView = hostingView
        self.panel = deckPanel

        Task { @MainActor in
            await DeckStore.shared.initialize()
            deckPanel.showPanel()
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Specification rule: Dock activation is ALWAYS Show / Bring to Front
        panel?.showPanel()
        return false
    }

    public func applicationWillTerminate(_ notification: Notification) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await ConfigManager.shared.flush()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 1.0)
    }
}
