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

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Intercept Escape and Cmd+E even if a child responder / textfield is focused
        if event.keyCode == 53 { // Escape
            if DeckStore.shared.isModalOpen {
                return false
            }
            if DeckStore.shared.isEditMode {
                DeckStore.shared.setEditMode(false)
                return true
            }
            hidePanel()
            return true
        }

        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "e" {
            DeckStore.shared.toggleEditMode()
            return true
        }

        return super.performKeyEquivalent(with: event)
    }

    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            if DeckStore.shared.isModalOpen { return }
            if DeckStore.shared.isEditMode {
                DeckStore.shared.setEditMode(false)
                return
            }
            hidePanel()
            return
        }

        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "e" {
            DeckStore.shared.toggleEditMode()
            return
        }

        super.keyDown(with: event)
    }

    private func setupOutsideClickMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            let eventLocation = NSEvent.mouseLocation
            let capturedSessionId = DeckStore.shared.windowSessionId

            Task { @MainActor in
                guard let self = self, self.isVisible else { return }
                guard DeckStore.shared.windowSessionId == capturedSessionId else { return }
                if DeckStore.shared.isModalOpen || DeckStore.shared.isEditMode { return }

                if !self.frame.contains(eventLocation) {
                    self.hidePanel()
                }
            }
        }
    }

    public func showPanel() {
        // Multi-monitor support: prioritize screen currently containing the mouse cursor
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let screen = targetScreen else { return }
        let visibleFrame = screen.visibleFrame

        let width: CGFloat = min(620, visibleFrame.width - 40)
        let currentHeight = min(max(self.frame.height > 100 ? self.frame.height : 460, 260), min(760, visibleFrame.height * 0.85))

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
