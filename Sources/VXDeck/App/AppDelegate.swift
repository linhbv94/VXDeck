import AppKit
import SwiftUI
import VXDeckCore

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public var panel: DeckPanel?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        Task { @MainActor in
            await DeckStore.shared.initialize()

            let mouseLoc = NSEvent.mouseLocation
            let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
                ?? NSScreen.main
                ?? NSScreen.screens.first

            let visibleFrame = targetScreen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            let savedWidth = CGFloat(DeckStore.shared.settings.windowWidth)
            let width = min(max(savedWidth, 440), visibleFrame.width - 40)
            let initialX = visibleFrame.origin.x + (visibleFrame.width - width) / 2
            let initialY = max(visibleFrame.origin.y + 40, visibleFrame.origin.y + (visibleFrame.height - 400) * 0.35)

            let initialFrame = NSRect(x: initialX, y: initialY, width: width, height: 400)
            let deckPanel = DeckPanel(contentRect: initialFrame)

            let rootView = DeckRootView(
                onCloseRequested: { [weak deckPanel] in
                    deckPanel?.hidePanel()
                },
                onContentSizeChange: { [weak deckPanel] in
                    deckPanel?.updateHeight()
                },
                onHeightMeasured: { [weak deckPanel] totalHeight in
                    deckPanel?.updateHeight(targetTotalHeight: totalHeight, animated: false)
                }
            )
            .environmentObject(DeckStore.shared)

            let hostingView = NSHostingView(rootView: rootView)
            deckPanel.contentView = hostingView
            self.panel = deckPanel

            deckPanel.showPanel()
            DeckStore.shared.checkUpdateInBackground()
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let panel = panel, panel.isVisible {
            if DeckStore.shared.isModalOpen {
                (panel.attachedSheet ?? panel).makeKeyAndOrderFront(nil)
                return true
            }
            panel.hidePanel()
        } else {
            panel?.showPanel()
        }
        return false
    }

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }
}
