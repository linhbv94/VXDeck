import AppKit
import SwiftUI
import VXDeckCore

public final class DeckPanel: NSPanel, NSWindowDelegate {
    private var eventMonitor: EventMonitor?
    private var isTerminating = false

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        self.delegate = self
        self.isFloatingPanel = true
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.animationBehavior = .utilityWindow
        self.minSize = NSSize(width: 440, height: 220)
        self.maxSize = NSSize(width: 1400, height: 960)

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
            if DeckStore.shared.isDraggingApp {
                DeckStore.shared.cancelDrag()
                return
            }
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

                // Check if click was outside the panel frame anywhere across all desktop monitors
                if !self.frame.contains(eventLocation) {
                    self.hidePanel()
                }
            }
        }
    }

    public func windowDidEndLiveResize(_ notification: Notification) {
        DeckStore.shared.updateWindowWidth(Double(self.frame.width))
        self.updateHeight(animated: true)
    }

    public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // Strictly lock height to current height; only allow width to resize freely
        return NSSize(width: frameSize.width, height: sender.frame.height)
    }

    public func calculateEstimatedHeight(width: CGFloat) -> CGFloat {
        let collections = DeckStore.shared.collections
        if collections.isEmpty {
            return 320
        }

        let availableWidth = width - 48
        let colCount = max(3, Int(floor((availableWidth + 12) / 100)))

        var totalSectionHeights: CGFloat = 0
        for col in collections {
            let itemCount = col.items.count + (DeckStore.shared.isEditMode ? 1 : 0)
            let rows = max(1, Int(ceil(Double(itemCount) / Double(colCount))))
            let gridHeight = CGFloat(rows) * 86 + CGFloat(max(0, rows - 1)) * 12
            let sectionHeight = 32 + gridHeight + 16
            totalSectionHeights += sectionHeight
        }

        let interSectionSpacing = CGFloat(max(0, collections.count - 1)) * 16
        let editBarHeight: CGFloat = DeckStore.shared.isEditMode ? 56 : 0
        let outerPadding: CGFloat = 32
        let chromeHeight: CGFloat = 44 + 28 // Header 44 + Footer 28

        return totalSectionHeights + interSectionSpacing + editBarHeight + outerPadding + chromeHeight
    }

    public func updateHeight(targetTotalHeight: CGFloat? = nil, animated: Bool = true) {
        guard !isTerminating, let screen = self.screen ?? NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame

        let savedWidth = CGFloat(DeckStore.shared.settings.windowWidth)
        let width = self.frame.width > 100 ? self.frame.width : min(max(savedWidth, 440), visibleFrame.width - 40)

        let maxScreenHeight = min(820, visibleFrame.height * 0.85)
        let minHeight: CGFloat = 200

        let chosenHeight: CGFloat
        if let target = targetTotalHeight, target > 50 {
            chosenHeight = target
        } else {
            chosenHeight = calculateEstimatedHeight(width: width)
        }

        let targetHeight = min(max(chosenHeight, minHeight), maxScreenHeight)

        let currentFrame = self.frame
        self.minSize = NSSize(width: 440, height: targetHeight)
        self.maxSize = NSSize(width: 1400, height: targetHeight)

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

        let savedWidth = CGFloat(DeckStore.shared.settings.windowWidth)
        let width: CGFloat = min(max(savedWidth, 440), visibleFrame.width - 40)
        let initialEstimated = calculateEstimatedHeight(width: width)
        let currentHeight = min(max(initialEstimated, 200), min(820, visibleFrame.height * 0.85))

        self.minSize = NSSize(width: 440, height: currentHeight)
        self.maxSize = NSSize(width: 1400, height: currentHeight)

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

    public func hidePanel(force: Bool = false) {
        if !force && DeckStore.shared.isModalOpen {
            return
        }
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
            if DeckStore.shared.isModalOpen { return }
            hidePanel()
        } else {
            showPanel()
        }
    }
}
