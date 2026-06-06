import SwiftUI

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
    @AppStorage("appTheme") private var appTheme = AppTheme.system
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system

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
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding(20)
        .preferredColorScheme(appTheme.colorScheme)
    }

    private func t(en: String, zh: String) -> String {
        appLanguage.text(en: en, zh: zh)
    }
}
