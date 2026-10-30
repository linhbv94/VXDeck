import AppKit
import SwiftUI

final class FixtureModel: ObservableObject {
    @Published var settingsOpen = true
}

struct FixtureSettings: View {
    @ObservedObject var model: FixtureModel
    var body: some View {
        Text("VXDeck updater termination fixture")
            .frame(width: 620, height: 400)
            .sheet(isPresented: $model.settingsOpen) {
                Text("VXDeck Settings").frame(width: 660, height: 480)
            }
            .onReceive(NotificationCenter.default.publisher(for: UpdateApplicationTermination.willTerminate)) { _ in
                model.settingsOpen = false
            }
    }
}

@MainActor
final class FixtureDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var attempts = 0
    var terminateRequests = 0
    let model = FixtureModel()
    let mode = CommandLine.arguments.last!

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = NSPanel(contentRect: NSRect(x: 100, y: 100, width: 620, height: 400),
                        styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.contentView = NSHostingView(rootView: FixtureSettings(model: model))
        panel.makeKeyAndOrderFront(nil)
        pollSheet()
    }

    func pollSheet() {
        attempts += 1
        guard attempts < 100 else { print("FAIL: sheet_not_presented"); exit(3) }
        guard panel.attachedSheet != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.pollSheet() }
            return
        }
        print("sheet_presented mode=\(mode)")
        fflush(stdout)
        if mode == "notice" {
            // Same update action with Settings already closed, as in the user's working path.
            model.settingsOpen = false
            terminateAfterSheetCloses()
        } else if mode == "baseline" {
            NSApp.terminate(nil)
        } else {
            UpdateApplicationTermination.request()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("still_running mode=\(self.mode) delegate_requests=\(self.terminateRequests)")
            fflush(stdout)
            exit(42)
        }
    }

    func terminateAfterSheetCloses() {
        if panel.attachedSheet == nil {
            NSApp.terminate(nil)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.terminateAfterSheetCloses() }
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        terminateRequests += 1
        return .terminateNow
    }
    func applicationWillTerminate(_ notification: Notification) {
        print("terminated mode=\(mode) delegate_requests=\(terminateRequests)")
        fflush(stdout)
    }
}

@main
struct FixtureMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = FixtureDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
