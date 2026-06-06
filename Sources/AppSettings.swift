import SwiftUI
import AppKit

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
    @AppStorage("fluentEmojiFolderPath") private var fluentEmojiFolderPath = ""
    @AppStorage("fluentEmojiIndexVersion") private var fluentEmojiIndexVersion = ""
    @AppStorage("fluentEmojiIndexedFolderPath") private var fluentEmojiIndexedFolderPath = ""
    @AppStorage("fluentEmojiIndexedAssetCount") private var fluentEmojiIndexedAssetCount = 0
    @State private var indexingFailed = false
    @State private var settingsWindow: NSWindow?

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
