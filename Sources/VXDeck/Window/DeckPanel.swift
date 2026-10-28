import AppKit
import SwiftUI
import VXDeckCore

public final class DeckPanel: NSPanel {
    private var eventMonitor: EventMonitor?
    private var isTerminating = false

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
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
        // Intercept Escape, Cmd+E, and Cmd+,
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

        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
            DeckStore.shared.isModalOpen = true
            DeckStore.shared.showSettingsModal.toggle()
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

        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
            DeckStore.shared.isModalOpen = true
            DeckStore.shared.showSettingsModal.toggle()
            return
        }

        super.keyDown(with: event)
    }

    private func setupOutsideClickMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            let eventLocation = NSEvent.mouseLocation
            let capturedSessionId = DeckStore.shared.windowSessionId

            Task { @MainActor in
                guard let self = self, !self.isTerminating else { return }
                guard DeckStore.shared.windowSessionId == capturedSessionId else { return }
                if DeckStore.shared.isModalOpen || DeckStore.shared.isEditMode { return }

                // Check if click was on the same screen as the panel, but outside the panel frame
                if let panelScreen = self.screen {
                    if panelScreen.frame.contains(eventLocation) && !self.frame.contains(eventLocation) {
                        self.hidePanel()
                    }
                } else if !self.frame.contains(eventLocation) {
                    self.hidePanel()
                }
            }
        }
    }

    public func updateHeight(animated: Bool = true) {
        guard !isTerminating, let screen = self.screen ?? NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame

        let width = self.frame.width > 100 ? self.frame.width : min(620, visibleFrame.width - 40)
        let fittingHeight = self.contentView?.fittingSize.height ?? 460
        let targetHeight = min(max(fittingHeight > 100 ? fittingHeight : 460, 250), min(760, visibleFrame.height * 0.85))

        let currentFrame = self.frame
        let diff = targetHeight - currentFrame.height
        if abs(diff) < 2 { return }

        let newY = max(visibleFrame.origin.y + 20, currentFrame.origin.y - diff)
        let newFrame = NSRect(x: currentFrame.origin.x, y: newY, width: width, height: targetHeight)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().setFrame(newFrame, display: true)
            }
        } else {
            self.setFrame(newFrame, display: true)
        }
        self.invalidateShadow()
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
        let fittingHeight = self.contentView?.fittingSize.height ?? 460
        let currentHeight = min(max(fittingHeight > 100 ? fittingHeight : 460, 250), min(760, visibleFrame.height * 0.85))

        // Position horizontally centered, vertically in the lower half above the Dock
        let x = visibleFrame.origin.x + (visibleFrame.width - width) / 2
        let y = max(visibleFrame.origin.y + 40, visibleFrame.origin.y + (visibleFrame.height - currentHeight) * 0.35)

        self.setFrame(NSRect(x: x, y: y, width: width, height: currentHeight), display: true)
        self.invalidateShadow()

        DeckStore.shared.resetWindowSession()
        DeckStore.shared.refreshAvailability()

        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        eventMonitor?.start()
    }

    public func hidePanel() {
        guard !isTerminating else { return }
        isTerminating = true

        eventMonitor?.stop()
        self.orderOut(nil)
        if DeckStore.shared.isEditMode {
            DeckStore.shared.setEditMode(false)
        }

        Task { @MainActor in
            await DeckStore.shared.flush()
            NSApp.terminate(nil)
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
