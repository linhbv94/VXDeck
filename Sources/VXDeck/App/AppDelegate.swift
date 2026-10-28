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
            },
            onContentSizeChange: { [weak deckPanel] in
                deckPanel?.updateHeight()
            },
            onHeightMeasured: { [weak deckPanel] totalHeight in
                deckPanel?.updateHeight(targetTotalHeight: totalHeight, animated: true)
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
        if let panel = panel, panel.isVisible {
            if DeckStore.shared.isModalOpen {
                panel.makeKeyAndOrderFront(nil)
                return true
            }
            panel.hidePanel()
        } else {
            panel?.showPanel()
        }
        return false
    }

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task { @MainActor in
            _ = await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await DeckStore.shared.flush()
                }
                group.addTask {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
                await group.next()
            }
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
