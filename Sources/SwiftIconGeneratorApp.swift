import SwiftUI
import AppKit

@main
struct SFIconGeneratorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 860, minHeight: 640)
        }
        .windowResizability(.contentMinSize)

        Settings {
            AppSettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard isRunningFromSwiftPM else { return }

        // `swift run` starts as a terminal child process. Mark it as a regular GUI app
        // before the first window is created so macOS routes keyboard focus to it.
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard isRunningFromSwiftPM else { return }

        NSApp.activate(ignoringOtherApps: true)
    }

    private var isRunningFromSwiftPM: Bool {
        Bundle.main.bundleURL.pathExtension != "app"
    }
}
