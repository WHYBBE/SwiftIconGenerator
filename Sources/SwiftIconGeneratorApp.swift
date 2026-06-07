import SwiftUI
import AppKit

@main
struct SFIconGeneratorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 860, minHeight: 640)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About SwiftIconGenerator") {
                    openWindow(id: "about")
                }
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appDelegate.showSettingsWindow(nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Window("About SwiftIconGenerator", id: "about") {
            AppAboutView()
        }
        .windowResizability(.contentSize)
    }
}

enum AppAbout {
    static var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        if let version, let build {
            return "\(version) (\(build))"
        }

        if let version {
            return version
        }

        return "Development"
    }

    static var repositoryURL: URL {
        URL(string: "https://github.com/WHYBBE/SwiftIconGenerator")!
    }

    static var licenseURL: URL {
        URL(string: "https://github.com/WHYBBE/SwiftIconGenerator/blob/main/LICENSE")!
    }

    static let licenseName = "MIT License"
    static let repositoryName = "WHYBBE/SwiftIconGenerator"
}

private struct AppAboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: appIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("SwiftIconGenerator")
                .font(.title2.weight(.semibold))

            Text("Version \(AppAbout.versionText)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Link(destination: AppAbout.repositoryURL) {
                    Label(AppAbout.repositoryName, systemImage: "link")
                }

                Link(destination: AppAbout.licenseURL) {
                    Label(AppAbout.licenseName, systemImage: "doc.text")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(24)
        .frame(width: 380)
    }

    private var appIconImage: NSImage {
        NSImage(named: "AppIcon") ?? NSApp.applicationIconImage ?? NSImage(size: NSSize(width: 64, height: 64))
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard isRunningFromSwiftPM else { return }

        // `swift run` starts as a terminal child process. Mark it as a regular GUI app
        // before the first window is created so macOS routes keyboard focus to it.
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyApplicationIcon()

        guard isRunningFromSwiftPM else { return }

        NSApp.activate(ignoringOtherApps: true)
    }

    private func applyApplicationIcon() {
        if let icon = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = icon
            return
        }

        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else {
            return
        }

        NSApp.applicationIconImage = icon
    }

    private var isRunningFromSwiftPM: Bool {
        Bundle.main.bundleURL.pathExtension != "app"
    }
}
