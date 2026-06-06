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
                return language.text(en: "Detected \(count) Fluent Emoji assets", zh: "检测通过，找到 \(count) 个 Fluent Emoji 资源")
            case .invalid:
                return language.text(en: "No valid Fluent Emoji assets found", zh: "检测未通过，未找到有效 Fluent Emoji 资源")
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
    @State private var detectionState: DetectionState = .idle

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

                        Button(t(en: "Detect", zh: "检测"), action: detectFluentEmojiFolder)

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

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            return
        }

        fluentEmojiFolderPath = folderURL.path
        detectionState = .idle
    }

    private func detectFluentEmojiFolder() {
        let count = fluentEmojiAssetCount(folderPath: fluentEmojiFolderPath)
        detectionState = count > 0 ? .valid(count) : .invalid
    }

    private func fluentEmojiAssetCount(folderPath: String) -> Int {
        let trimmedPath = folderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return 0 }

        let fileManager = FileManager.default
        let assetsURL = URL(fileURLWithPath: trimmedPath, isDirectory: true)
            .appendingPathComponent("assets", isDirectory: true)
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: assetsURL.path, isDirectory: &isDirectory), isDirectory.boolValue,
              let emojiFolders = try? fileManager.contentsOfDirectory(
                at: assetsURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              ) else {
            return 0
        }

        return emojiFolders.reduce(0) { count, emojiFolder in
            guard (try? emojiFolder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                  hasFluentEmojiPNG(in: emojiFolder) else {
                return count
            }

            return count + 1
        }
    }

    private func hasFluentEmojiPNG(in emojiFolder: URL) -> Bool {
        guard let enumerator = FileManager.default.enumerator(
            at: emojiFolder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        return enumerator.contains { item in
            guard let url = item as? URL,
                  url.pathExtension.localizedCaseInsensitiveCompare("png") == .orderedSame,
                  url.path.lowercased().contains("/3d/"),
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                return false
            }

            return true
        }
    }
}
