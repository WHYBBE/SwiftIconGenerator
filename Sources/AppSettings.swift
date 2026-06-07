import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .system:
            return language.text(en: "System", zh: "跟随系统")
        case .light:
            return language.text(en: "Light", zh: "浅色")
        case .dark:
            return language.text(en: "Dark", zh: "深色")
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case chineseSimplified

    var id: String { rawValue }

    var usesChinese: Bool {
        switch self {
        case .chineseSimplified:
            return true
        case .english:
            return false
        case .system:
            return Locale.preferredLanguages.first?.localizedCaseInsensitiveContains("zh") == true
        }
    }

    func text(en: String, zh: String) -> String {
        usesChinese ? zh : en
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .system:
            return language.text(en: "System", zh: "跟随系统")
        case .english:
            return language.text(en: "English", zh: "英语")
        case .chineseSimplified:
            return language.text(en: "Simplified Chinese", zh: "简体中文")
        }
    }
}

struct AppSettingsView: View {
    private struct AppDataExport: Codable {
        let version: Int
        let appTheme: String
        let appLanguage: String
        let exportPlatforms: String
        let savedProjects: String
        let fluentEmojiFolderPath: String
        let fluentEmojiIndexVersion: String
        let fluentEmojiIndexedFolderPath: String
        let fluentEmojiIndexedAssetCount: Int
    }

    private enum DetectionState {
        case idle
        case valid(Int)
        case invalid

        func title(language: AppLanguage) -> String {
            switch self {
            case .idle:
                return language.text(en: "Not checked", zh: "未检测")
            case .valid(let count):
                return language.text(en: "Indexed \(count) Fluent Emoji assets", zh: "已索引 \(count) 个 Fluent Emoji 资源")
            case .invalid:
                return language.text(en: "No valid Fluent Emoji assets found", zh: "检测并索引失败，未找到有效 Fluent Emoji 资源")
            }
        }

        var systemImage: String {
            switch self {
            case .idle:
                return "circle"
            case .valid:
                return "checkmark.circle"
            case .invalid:
                return "xmark.circle"
            }
        }

        var color: Color {
            switch self {
            case .idle:
                return .secondary
            case .valid:
                return .green
            case .invalid:
                return .red
            }
        }
    }

    @AppStorage("appTheme") private var appTheme = AppTheme.system
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system
    @AppStorage("exportPlatforms") private var storedExportPlatforms = ""
    @AppStorage("savedProjects") private var savedProjectsData = "[]"
    @AppStorage("fluentEmojiFolderPath") private var fluentEmojiFolderPath = ""
    @AppStorage("fluentEmojiIndexVersion") private var fluentEmojiIndexVersion = ""
    @AppStorage("fluentEmojiIndexedFolderPath") private var fluentEmojiIndexedFolderPath = ""
    @AppStorage("fluentEmojiIndexedAssetCount") private var fluentEmojiIndexedAssetCount = 0
    @AppStorage("showPreviewBackdrop") private var showPreviewBackdrop = true
    @State private var indexingFailed = false
    @State private var settingsWindow: NSWindow?
    @State private var dataMessage = ""
    @State private var dataMessageIsError = false
    @State private var clearAllConfirmationPresented = false

    private var detectionState: DetectionState {
        let trimmedPath = fluentEmojiFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)

        if indexingFailed {
            return .invalid
        }

        if !trimmedPath.isEmpty,
           trimmedPath == fluentEmojiIndexedFolderPath,
           fluentEmojiIndexedAssetCount > 0,
           FluentEmojiIndex.indexExists(for: trimmedPath) {
            return .valid(fluentEmojiIndexedAssetCount)
        }

        return .idle
    }

    var body: some View {
        Form {
            Picker(t(en: "Theme", zh: "主题"), selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.title(language: appLanguage)).tag(theme)
                }
            }

            Picker(t(en: "Language", zh: "语言"), selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title(language: appLanguage)).tag(language)
                }
            }

            Section(t(en: "Preview", zh: "预览")) {
                Toggle(t(en: "Show contrast background", zh: "显示对比背景"), isOn: $showPreviewBackdrop)
            }

            Section(t(en: "Icon Sources", zh: "图标来源")) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(t(en: "Fluent Emoji folder", zh: "Fluent Emoji 文件夹"), text: $fluentEmojiFolderPath)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        Button(t(en: "Choose", zh: "选择"), action: chooseFluentEmojiFolder)

                        Button(t(en: "Detect and Index", zh: "检测并索引"), action: detectAndIndexFluentEmojiFolder)

                        Button(t(en: "Clear", zh: "清除"), action: clearFluentEmojiFolder)

                        Spacer()
                    }

                    Label(detectionState.title(language: appLanguage), systemImage: detectionState.systemImage)
                        .font(.footnote)
                        .foregroundStyle(detectionState.color)
                }
            }

            Section(t(en: "Data", zh: "数据")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Button(t(en: "Import Data", zh: "导入数据"), action: importData)

                        Button(t(en: "Export Data", zh: "导出数据"), action: exportData)

                        Button(t(en: "Clear All Data", zh: "清除所有数据"), role: .destructive) {
                            clearAllConfirmationPresented = true
                        }

                        Spacer()
                    }

                    if !dataMessage.isEmpty {
                        Label(dataMessage, systemImage: dataMessageIsError ? "xmark.circle" : "checkmark.circle")
                            .font(.footnote)
                            .foregroundStyle(dataMessageIsError ? .red : .secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Section(t(en: "About", zh: "关于")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(t(en: "Version", zh: "版本"))
                        Spacer()
                        Text(AppAbout.versionText)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: AppAbout.repositoryURL) {
                        Label(AppAbout.repositoryName, systemImage: "link")
                    }

                    Link(destination: AppAbout.licenseURL) {
                        Label(AppAbout.licenseName, systemImage: "doc.text")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding(20)
        .preferredColorScheme(appTheme.colorScheme)
        .background(SettingsWindowAccessor { window in
            settingsWindow = window
        })
        .onChange(of: fluentEmojiFolderPath) { _, _ in
            fluentEmojiIndexVersion = ""
            indexingFailed = false
        }
        .alert(t(en: "Clear All Data", zh: "清除所有数据"), isPresented: $clearAllConfirmationPresented) {
            Button(t(en: "Cancel", zh: "取消"), role: .cancel) {}
            Button(t(en: "Clear", zh: "清除"), role: .destructive, action: clearAllData)
        } message: {
            Text(t(en: "This will remove all projects, settings, Fluent Emoji paths, and index state. This cannot be undone.", zh: "这会删除所有项目、设置、Fluent Emoji 路径和索引状态。此操作无法撤销。"))
        }
    }

    private func t(en: String, zh: String) -> String {
        appLanguage.text(en: en, zh: zh)
    }

    private func chooseFluentEmojiFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = t(en: "Choose", zh: "选择")
        panel.message = t(en: "Choose a Fluent Emoji repository folder", zh: "选择 Fluent Emoji 仓库文件夹")

        guard let settingsWindow else {
            chooseFluentEmojiFolder(from: panel.runModal(), url: panel.url)
            return
        }

        panel.beginSheetModal(for: settingsWindow) { response in
            chooseFluentEmojiFolder(from: response, url: panel.url)
        }
    }

    private func chooseFluentEmojiFolder(from response: NSApplication.ModalResponse, url: URL?) {
        guard response == .OK, let url else { return }

        fluentEmojiFolderPath = url.path
        fluentEmojiIndexVersion = ""
        indexingFailed = false
    }

    private func detectAndIndexFluentEmojiFolder() {
        let trimmedPath = fluentEmojiFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let index = FluentEmojiIndex.build(folderPath: fluentEmojiFolderPath),
              (try? index.save()) != nil else {
            fluentEmojiIndexVersion = ""
            fluentEmojiIndexedFolderPath = ""
            fluentEmojiIndexedAssetCount = 0
            indexingFailed = true
            return
        }

        fluentEmojiIndexedFolderPath = trimmedPath
        fluentEmojiIndexedAssetCount = index.assetCount
        fluentEmojiIndexVersion = UUID().uuidString
        indexingFailed = false
    }

    private func clearFluentEmojiFolder() {
        FluentEmojiIndex.removeIndex(for: fluentEmojiFolderPath)
        FluentEmojiIndex.removeIndex(for: fluentEmojiIndexedFolderPath)
        fluentEmojiFolderPath = ""
        fluentEmojiIndexVersion = ""
        fluentEmojiIndexedFolderPath = ""
        fluentEmojiIndexedAssetCount = 0
        indexingFailed = false
    }

    private func exportData() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "SwiftIconGeneratorData.json"
        panel.prompt = t(en: "Export", zh: "导出")

        beginSavePanel(panel) { response, url in
            guard response == .OK, let url else { return }

            let dataExport = AppDataExport(
                version: 1,
                appTheme: appTheme.rawValue,
                appLanguage: appLanguage.rawValue,
                exportPlatforms: storedExportPlatforms,
                savedProjects: savedProjectsData,
                fluentEmojiFolderPath: fluentEmojiFolderPath,
                fluentEmojiIndexVersion: fluentEmojiIndexVersion,
                fluentEmojiIndexedFolderPath: fluentEmojiIndexedFolderPath,
                fluentEmojiIndexedAssetCount: fluentEmojiIndexedAssetCount
            )

            do {
                let data = try JSONEncoder().encode(dataExport)
                try data.write(to: url, options: .atomic)
                showDataMessage(t(en: "Exported data", zh: "已导出数据"), isError: false)
            } catch {
                showDataMessage(error.localizedDescription, isError: true)
            }
        }
    }

    private func importData() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.prompt = t(en: "Import", zh: "导入")

        beginOpenPanel(panel) { response, url in
            guard response == .OK, let url else { return }

            do {
                let data = try Data(contentsOf: url)
                if let dataExport = try? JSONDecoder().decode(AppDataExport.self, from: data) {
                    apply(dataExport: dataExport)
                    showDataMessage(t(en: "Imported data", zh: "已导入数据"), isError: false)
                    return
                }

                try importSingleProject(data: data)
                showDataMessage(t(en: "Imported project", zh: "已导入项目"), isError: false)
            } catch {
                showDataMessage(error.localizedDescription, isError: true)
            }
        }
    }

    private func apply(dataExport: AppDataExport) {
        appTheme = AppTheme(rawValue: dataExport.appTheme) ?? .system
        appLanguage = AppLanguage(rawValue: dataExport.appLanguage) ?? .system
        storedExportPlatforms = dataExport.exportPlatforms
        savedProjectsData = dataExport.savedProjects
        fluentEmojiFolderPath = dataExport.fluentEmojiFolderPath
        fluentEmojiIndexVersion = dataExport.fluentEmojiIndexVersion
        fluentEmojiIndexedFolderPath = dataExport.fluentEmojiIndexedFolderPath
        fluentEmojiIndexedAssetCount = dataExport.fluentEmojiIndexedAssetCount
        indexingFailed = false
    }

    private func importSingleProject(data: Data) throws {
        let object = try JSONSerialization.jsonObject(with: data)
        guard var project = object as? [String: Any],
              let id = project["id"] as? String,
              project["name"] is String else {
            throw NSError(domain: "SwiftIconGenerator", code: 1, userInfo: [
                NSLocalizedDescriptionKey: t(en: "The file is not a supported data or project export.", zh: "文件不是支持的数据或项目导出。")
            ])
        }

        var projects = (try? JSONSerialization.jsonObject(with: Data(savedProjectsData.utf8))) as? [[String: Any]] ?? []
        project["updatedAt"] = project["updatedAt"] ?? ISO8601DateFormatter().string(from: Date())

        if let index = projects.firstIndex(where: { $0["id"] as? String == id }) {
            projects[index] = project
        } else {
            projects.insert(project, at: 0)
        }

        let data = try JSONSerialization.data(withJSONObject: projects, options: [])
        savedProjectsData = String(data: data, encoding: .utf8) ?? "[]"
    }

    private func clearAllData() {
        FluentEmojiIndex.removeAllIndexes()
        appTheme = .system
        appLanguage = .system
        storedExportPlatforms = IconRenderer.ExportPlatform.allCases.map(\.rawValue).joined(separator: ",")
        savedProjectsData = "[]"
        fluentEmojiFolderPath = ""
        fluentEmojiIndexVersion = ""
        fluentEmojiIndexedFolderPath = ""
        fluentEmojiIndexedAssetCount = 0
        indexingFailed = false
        showDataMessage(t(en: "Cleared all data", zh: "已清除所有数据"), isError: false)
    }

    private func beginSavePanel(_ panel: NSSavePanel, completion: @escaping (NSApplication.ModalResponse, URL?) -> Void) {
        guard let settingsWindow else {
            completion(panel.runModal(), panel.url)
            return
        }

        panel.beginSheetModal(for: settingsWindow) { response in
            completion(response, panel.url)
        }
    }

    private func beginOpenPanel(_ panel: NSOpenPanel, completion: @escaping (NSApplication.ModalResponse, URL?) -> Void) {
        guard let settingsWindow else {
            completion(panel.runModal(), panel.url)
            return
        }

        panel.beginSheetModal(for: settingsWindow) { response in
            completion(response, panel.url)
        }
    }

    private func showDataMessage(_ message: String, isError: Bool) {
        dataMessage = message
        dataMessageIsError = isError
    }
}

@MainActor
private final class AppSettingsWindowController {
    static let shared = AppSettingsWindowController()

    private var window: NSWindow?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentView = NSHostingView(rootView: AppSettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}

extension AppDelegate {
    @objc func showSettingsWindow(_ sender: Any?) {
        Task { @MainActor in
            AppSettingsWindowController.shared.show()
        }
    }
}

private struct SettingsWindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onResolve(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onResolve(nsView.window)
        }
    }
}
