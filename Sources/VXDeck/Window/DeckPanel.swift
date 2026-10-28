import AppKit
import SwiftUI
import VXDeckCore

public final class DeckPanel: NSPanel {
    private var eventMonitor: EventMonitor?

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.animationBehavior = .utilityWindow

        setupOutsideClickMonitor()
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return true
    }

    public override func keyDown(with event: NSEvent) {
        // Keycode 53 is Escape
        if event.keyCode == 53 {
            if DeckStore.shared.isModalOpen {
                return
            }
            if DeckStore.shared.isEditMode {
                DeckStore.shared.setEditMode(false)
                return
            }
            hidePanel()
            return
        }

        // Cmd + E for Edit Mode toggle
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "e" {
            DeckStore.shared.toggleEditMode()
            return
        }

        super.keyDown(with: event)
    }

    private func setupOutsideClickMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isVisible else { return }

                // If a modal (such as NSOpenPanel) is currently active, ignore outside clicks
                if DeckStore.shared.isModalOpen {
                    return
                }

                // In Edit Mode, outside clicks do not close the window to prevent accidental loss
                if DeckStore.shared.isEditMode {
                    return
                }

                let mouseLocation = NSEvent.mouseLocation
                if !self.frame.contains(mouseLocation) {
                    self.hidePanel()
                }
            }
        }
    }

    public func showPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visibleFrame = screen.visibleFrame

        let width: CGFloat = 620
        let currentHeight = self.frame.height > 100 ? self.frame.height : 460

        // Position horizontally centered, vertically in the lower half above the Dock
        let x = visibleFrame.origin.x + (visibleFrame.width - width) / 2
        let y = max(visibleFrame.origin.y + 40, visibleFrame.origin.y + (visibleFrame.height - currentHeight) * 0.35)

        self.setFrame(NSRect(x: x, y: y, width: width, height: currentHeight), display: true)

        DeckStore.shared.resetWindowSession()
        DeckStore.shared.refreshAvailability()

        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        eventMonitor?.start()
    }

    public func hidePanel() {
        eventMonitor?.stop()
        self.orderOut(nil)
        if DeckStore.shared.isEditMode {
            DeckStore.shared.setEditMode(false)
        }
    }

    public func togglePanel() {
        if self.isVisible && self.isKeyWindow {
            hidePanel()
        } else {
            showPanel()
        }
    }
}
