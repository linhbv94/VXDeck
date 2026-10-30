import AppKit

/// Used only after the update helper has acknowledged the verified staged app.
@MainActor
public enum UpdateApplicationTermination {
    public static let willTerminate = Notification.Name("vxdeck_update_will_terminate")

    public static func request() {
        NotificationCenter.default.post(name: willTerminate, object: nil)
        // AppKit can cancel terminate while a sheet (including SwiftUI Settings) is open.
        // End sheets before requesting termination; never force-exit or skip the app delegate.
        for window in NSApp.windows {
            if let sheet = window.attachedSheet {
                window.endSheet(sheet, returnCode: .abort)
                sheet.orderOut(nil)
            }
        }
        if NSApp.modalWindow != nil {
            NSApp.abortModal()
        }
        // SwiftUI sheet dismissal is asynchronous. Do not ask AppKit to quit until
        // it has finished, or terminate can be silently cancelled again.
        DispatchQueue.main.async { finishWhenSheetsEnd(remainingAttempts: 100) }
    }

    private static func finishWhenSheetsEnd(remainingAttempts: Int) {
        if NSApp.modalWindow == nil && !NSApp.windows.contains(where: { $0.attachedSheet != nil }) {
            NSApp.terminate(nil)
        } else if remainingAttempts > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                finishWhenSheetsEnd(remainingAttempts: remainingAttempts - 1)
            }
        }
    }
}
