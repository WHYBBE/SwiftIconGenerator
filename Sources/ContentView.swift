import SwiftUI
import AppKit

struct ContentView: View {
    private enum Field: Hashable {
        case symbolName
        case emoji
    }

    private enum IconMode: String, CaseIterable, Codable, Identifiable {
        case sfSymbol = "SF Symbols"
        case emoji = "Emoji"
        case fluentEmoji = "Fluent Emoji"

        var id: String { rawValue }

        func title(language: AppLanguage) -> String {
            switch self {
            case .sfSymbol:
                return "SF Symbols"
            case .emoji:
                return language.text(en: "Emoji", zh: "表情符号")
            case .fluentEmoji:
                return "Fluent Emoji"
            }
        }
    }

    fileprivate struct FluentEmojiAsset: Identifiable, Hashable {
        var id: String { imageURL.path }
        let name: String
        let imageURL: URL
    }

    private enum VisualSizePreset: String, CaseIterable, Codable, Identifiable {
        case compact = "Compact"
        case balanced = "Balanced"
        case bold = "Bold"

        var id: String { rawValue }

        var cornerRadiusRatio: Double { 0.24 }

        func title(language: AppLanguage) -> String {
            switch self {
            case .compact:
                return language.text(en: "Compact", zh: "紧凑")
            case .balanced:
                return language.text(en: "Balanced", zh: "均衡")
            case .bold:
                return language.text(en: "Bold", zh: "醒目")
            }
        }

        var contentPaddingRatio: Double {
            switch self {
            case .compact:
                return 0.14
            case .balanced:
                return 0.10
            case .bold:
                return 0.06
            }
        }

        var symbolScaleRatio: Double {
            switch self {
            case .compact:
                return 0.38
            case .balanced:
                return 0.44
            case .bold:
                return 0.50
            }
        }

        var shadowStrength: Double { 0.25 }
    }

    private static let defaultExportPlatformRawValues = IconRenderer.ExportPlatform.allCases
        .map(\.rawValue)
        .joined(separator: ",")

    private struct SavedProject: Codable, Identifiable {
        let id: UUID
        var name: String
        var updatedAt: Date
        var symbolName: String
        var iconMode: IconMode
        var emoji: String
        var foregroundColor: ColorValue
        var useForegroundGradient: Bool
        var secondaryForegroundColor: ColorValue
        var backgroundColor: ColorValue
        var useGradient: Bool
        var secondaryBackgroundColor: ColorValue
        var cornerRadiusRatio: Double
        var visualSizePreset: VisualSizePreset
        var contentPaddingRatio: Double
        var symbolScaleRatio: Double
        var shadowStrength: Double
        var iconSetName: String
        var exportPlatforms: [IconRenderer.ExportPlatform.RawValue]
        var fluentEmojiAssetPath: String?
        var fluentEmojiStyle: FluentEmojiStyle?
    }

    private struct ColorValue: Codable, Equatable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double

        var color: Color {
            Color(red: red, green: green, blue: blue, opacity: alpha)
        }

        init(color: Color) {
            let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .white
            red = Double(nsColor.redComponent)
            green = Double(nsColor.greenComponent)
            blue = Double(nsColor.blueComponent)
            alpha = Double(nsColor.alphaComponent)
        }
    }

    private enum FluentEmojiStyle: String, CaseIterable, Codable, Identifiable {
        case threeD
        case color
        case flat
        case highContrast

        var id: String { rawValue }

        var folderName: String {
            switch self {
            case .threeD:
                return "3D"
            case .color:
                return "Color"
            case .flat:
                return "Flat"
            case .highContrast:
                return "High Contrast"
            }
        }

        var fileExtension: String {
            switch self {
            case .threeD:
                return "png"
            case .color, .flat, .highContrast:
                return "svg"
            }
        }

        var title: String {
            switch self {
            case .threeD:
                return "3D"
            case .color:
                return "Color"
            case .flat:
                return "Flat"
            case .highContrast:
                return "High Contrast"
            }
        }

        var usesForegroundColor: Bool {
            self == .highContrast
        }
    }

    @State private var symbolName = "sparkles"
    @State private var symbolQuery = ""
    @State private var iconMode: IconMode = .sfSymbol
    @State private var emoji = "🚀"
    @State private var foregroundColor = Color.white
    @State private var useForegroundGradient = false
    @State private var secondaryForegroundColor = Color(red: 1.0, green: 0.86, blue: 0.25)
    @State private var backgroundColor = Color(red: 0.17, green: 0.51, blue: 0.98)
    @State private var useGradient = true
    @State private var secondaryBackgroundColor = Color(red: 0.39, green: 0.20, blue: 0.98)
    @State private var cornerRadiusRatio = 0.24
    @State private var visualSizePreset: VisualSizePreset = .balanced
    @State private var contentPaddingRatio = 0.10
    @State private var symbolScaleRatio = 0.44
    @State private var shadowStrength = 0.25
    @State private var iconSetName = "AppIcon"
    @State private var fluentEmojiQuery = ""
    @State private var fluentEmojiStyle: FluentEmojiStyle = .threeD
    @State private var selectedFluentEmojiAssetPath = ""
    @State private var exportPlatforms: Set<IconRenderer.ExportPlatform> = Set(IconRenderer.ExportPlatform.allCases)
    @State private var exportMessage = ""
    @State private var exportSucceeded = false
    @State private var didActivateWindow = false
    @State private var emojiPickerSelectionToken = 0
    @State private var projectColumnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedProjectID: UUID?
    @State private var projectPendingDeletion: SavedProject?
    @AppStorage("appTheme") private var appTheme = AppTheme.system
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system
    @AppStorage("exportPlatforms") private var storedExportPlatforms = Self.defaultExportPlatformRawValues
    @AppStorage("savedProjects") private var savedProjectsData = "[]"
    @AppStorage("fluentEmojiFolderPath") private var fluentEmojiFolderPath = ""
    @FocusState private var focusedField: Field?

    private let suggestedEmojis = [
        "🚀", "✨", "🔥", "🎯", "🧠", "🎨", "🪄", "💎",
        "🌈", "🌙", "☀️", "🍀", "🦄", "🐼", "🍎", "📦",
        "💬", "📷", "🎵", "🛠️", "🧩", "📚", "🧪", "🎮"
    ]

    private var filteredSymbols: [String] {
        let trimmedQuery = symbolQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return SFSymbolCatalog.all
        }

        return SFSymbolCatalog.all.filter {
            $0.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private var availableIconModes: [IconMode] {
        isFluentEmojiFolderValid ? IconMode.allCases : [.sfSymbol, .emoji]
    }

    private var fluentEmojiAssets: [FluentEmojiAsset] {
        scanFluentEmojiAssets(folderPath: fluentEmojiFolderPath, style: fluentEmojiStyle)
    }

    private var filteredFluentEmojiAssets: [FluentEmojiAsset] {
        let trimmedQuery = fluentEmojiQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return fluentEmojiAssets
        }

        return fluentEmojiAssets.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private var selectedFluentEmojiAsset: FluentEmojiAsset? {
        fluentEmojiAssets.first { $0.imageURL.path == selectedFluentEmojiAssetPath }
            ?? fluentEmojiAssets.first
    }

    private var isFluentEmojiFolderValid: Bool {
        FluentEmojiStyle.allCases.contains { style in
            !scanFluentEmojiAssets(folderPath: fluentEmojiFolderPath, style: style).isEmpty
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $projectColumnVisibility) {
            projectSidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            mainWorkspace
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(appTheme.colorScheme)
        .background(WindowAccessor { window in
            guard let window, !didActivateWindow else { return }

            didActivateWindow = true

            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                window.collectionBehavior.insert(.fullScreenPrimary)
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                focusedField = .symbolName
                window.makeFirstResponder(nil)
            }
        })
        .onAppear {
            DispatchQueue.main.async {
                applyVisualSizePreset(visualSizePreset)
                loadExportPlatforms()
                focusedField = .symbolName
            }
        }
        .onChange(of: exportPlatforms) { _, newPlatforms in
            saveExportPlatforms(newPlatforms)
        }
        .onChange(of: fluentEmojiFolderPath) { _, _ in
            if !isFluentEmojiFolderValid, iconMode == .fluentEmoji {
                iconMode = .sfSymbol
            }

            if selectedFluentEmojiAsset == nil {
                selectedFluentEmojiAssetPath = fluentEmojiAssets.first?.imageURL.path ?? ""
            }
        }
        .alert(
            t(en: "Delete Project", zh: "删除项目"),
            isPresented: deleteConfirmationPresented,
            presenting: projectPendingDeletion
        ) { project in
            Button(t(en: "Cancel", zh: "取消"), role: .cancel) {
                projectPendingDeletion = nil
            }

            Button(t(en: "Delete", zh: "删除"), role: .destructive) {
                deleteConfirmed(project: project)
            }
        } message: { project in
            Text(t(en: "Delete", zh: "删除") + " \(project.name)?")
        }
    }

    private var deleteConfirmationPresented: Binding<Bool> {
        Binding(
            get: { projectPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    projectPendingDeletion = nil
                }
            }
        )
    }

    private var mainWorkspace: some View {
        GeometryReader { proxy in
            let unitWidth = max((proxy.size.width - 2) / 3.2, 260)

            HStack(spacing: 0) {
                symbolPanel
                    .frame(width: unitWidth)
                Divider()
                settingsPanel
                    .frame(width: unitWidth * 1.2)
                Divider()
                previewPanel
                    .frame(width: unitWidth)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
        }
    }

    private var projectSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            projectSidebarHeader

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(savedProjects) { project in
                        Button {
                            apply(project: project)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: project.iconMode == .sfSymbol ? project.symbolName : "face.smiling")
                                    .frame(width: 18)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.name)
                                        .lineLimit(1)

                                    Text(project.iconMode.title(language: appLanguage))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 0)

                                Button {
                                    projectPendingDeletion = project
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .help(t(en: "Delete project", zh: "删除项目"))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                            .contentShape(Rectangle())
                            .background {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(project.id == selectedProjectID ? Color.accentColor.opacity(0.16) : Color.clear)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 240)
        .frame(maxHeight: .infinity)
    }

    private var projectSidebarHeader: some View {
        HStack {
            Text(t(en: "Projects", zh: "项目"))
                .font(.title3.weight(.semibold))

            Spacer()

            Button {
                resetEditor()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help(t(en: "New project", zh: "新建项目"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var symbolPanel: some View {
        sourcePanelContent
            .padding(24)
            .frame(maxHeight: .infinity)
            .background(sourcePanelBackground)
    }

    private var sourcePanelBackground: some View {
        Color(nsColor: .textBackgroundColor).opacity(0.35)
    }

    private var sourcePanelContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            sourcePanelHeader
            sourceControls
        }
    }

    private var sourcePanelHeader: some View {
        HStack(spacing: 12) {
            Text(t(en: "Icon Source", zh: "图标来源"))
                .font(.title2.weight(.semibold))

            iconModePicker
        }
    }

    private var iconModePicker: some View {
        Picker(t(en: "Icon source", zh: "图标来源"), selection: $iconMode) {
            ForEach(availableIconModes) { mode in
                Text(mode.title(language: appLanguage)).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: iconMode) { _, newMode in
            switch newMode {
            case .sfSymbol:
                focusedField = .symbolName
            case .emoji:
                focusedField = .emoji
            case .fluentEmoji:
                focusedField = nil
                selectedFluentEmojiAssetPath = selectedFluentEmojiAsset?.imageURL.path ?? ""
            }
        }
    }

    @ViewBuilder
    private var sourceControls: some View {
        if iconMode == .sfSymbol {
            symbolControls
        } else if iconMode == .emoji {
            emojiControls
        } else {
            fluentEmojiControls
        }
    }

    private var symbolControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t(en: "Symbol", zh: "符号"))
                .font(.headline)

            TextField(t(en: "SF Symbol name", zh: "SF Symbol 名称"), text: $symbolName)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .symbolName)

            TextField(t(en: "Search symbols", zh: "搜索符号"), text: $symbolQuery)
                .textFieldStyle(.roundedBorder)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        SymbolPickerCell(
                            symbol: symbol,
                            isSelected: symbol == symbolName
                        ) {
                            symbolName = symbol
                        }
                    }
                }
                .padding(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(1)
        }
    }

    private var emojiControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t(en: "Emoji", zh: "表情符号"))
                .font(.headline)

            TextField(t(en: "Emoji", zh: "表情符号"), text: $emoji)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .emoji)
                .background(SelectAllTextFieldContent(selectionToken: emojiPickerSelectionToken))

            Button(t(en: "Open System Emoji Picker", zh: "打开系统表情符号选择器"), action: openEmojiPicker)
                .buttonStyle(.bordered)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 10)], spacing: 10) {
                    ForEach(suggestedEmojis, id: \.self) { item in
                        EmojiPickerCell(
                            emoji: item,
                            isSelected: item == emoji
                        ) {
                            emoji = item
                        }
                    }
                }
                .padding(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(1)
        }
    }

    private var fluentEmojiControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fluent Emoji")
                .font(.headline)

            Picker(t(en: "Style", zh: "风格"), selection: $fluentEmojiStyle) {
                ForEach(FluentEmojiStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: fluentEmojiStyle) { _, _ in
                selectedFluentEmojiAssetPath = fluentEmojiAssets.first?.imageURL.path ?? ""
            }

            TextField(t(en: "Search Fluent Emoji", zh: "搜索 Fluent Emoji"), text: $fluentEmojiQuery)
                .textFieldStyle(.roundedBorder)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 10)], spacing: 10) {
                    ForEach(filteredFluentEmojiAssets) { asset in
                        FluentEmojiPickerCell(
                            asset: asset,
                            isTemplate: fluentEmojiStyle.usesForegroundColor,
                            isSelected: asset.imageURL.path == selectedFluentEmojiAssetPath
                        ) {
                            selectedFluentEmojiAssetPath = asset.imageURL.path
                        }
                    }
                }
                .padding(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(1)
        }
    }

    private var settingsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(t(en: "Configuration", zh: "配置"))
                    .font(.title2.weight(.semibold))

                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(t(en: "Visual size", zh: "视觉大小"))

                            Picker(t(en: "Visual size", zh: "视觉大小"), selection: $visualSizePreset) {
                                ForEach(VisualSizePreset.allCases) { preset in
                                    Text(preset.title(language: appLanguage)).tag(preset)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .onChange(of: visualSizePreset) { _, newPreset in
                                applyVisualSizePreset(newPreset)
                            }
                        }

                        if iconMode == .sfSymbol || (iconMode == .fluentEmoji && fluentEmojiStyle.usesForegroundColor) {
                            GradientColorSection(
                                title: t(en: "Foreground", zh: "前景"),
                                startTitle: t(en: "Start color", zh: "起始色"),
                                endTitle: t(en: "End color", zh: "结束色"),
                                gradientTitle: t(en: "Gradient", zh: "渐变"),
                                startColor: $foregroundColor,
                                endColor: $secondaryForegroundColor,
                                usesGradient: $useForegroundGradient
                            )
                        }

                        GradientColorSection(
                            title: t(en: "Background", zh: "背景"),
                            startTitle: t(en: "Start color", zh: "起始色"),
                            endTitle: t(en: "End color", zh: "结束色"),
                            gradientTitle: t(en: "Gradient", zh: "渐变"),
                            startColor: $backgroundColor,
                            endColor: $secondaryBackgroundColor,
                            usesGradient: $useGradient
                        )

                        SliderSettingRow(
                            title: t(en: "Corner radius", zh: "圆角"),
                            value: $cornerRadiusRatio,
                            range: 0.12...0.34,
                            valueText: cornerRadiusRatio.formatted(.percent.precision(.fractionLength(0))),
                            resetTitle: t(en: "Reset", zh: "重置")
                        ) {
                            cornerRadiusRatio = visualSizePreset.cornerRadiusRatio
                        }

                        SliderSettingRow(
                            title: t(en: "Content padding", zh: "内容边距"),
                            value: $contentPaddingRatio,
                            range: 0.04...0.2,
                            valueText: contentPaddingRatio.formatted(.percent.precision(.fractionLength(0))),
                            resetTitle: t(en: "Reset", zh: "重置")
                        ) {
                            contentPaddingRatio = visualSizePreset.contentPaddingRatio
                        }

                        SliderSettingRow(
                            title: t(en: "Symbol scale", zh: "符号缩放"),
                            value: $symbolScaleRatio,
                            range: 0.28...0.62,
                            valueText: symbolScaleRatio.formatted(.percent.precision(.fractionLength(0))),
                            resetTitle: t(en: "Reset", zh: "重置")
                        ) {
                            symbolScaleRatio = visualSizePreset.symbolScaleRatio
                        }

                        SliderSettingRow(
                            title: t(en: "Shadow", zh: "阴影"),
                            value: $shadowStrength,
                            range: 0...0.5,
                            valueText: shadowStrength.formatted(.percent.precision(.fractionLength(0))),
                            resetTitle: t(en: "Reset", zh: "重置")
                        ) {
                            shadowStrength = visualSizePreset.shadowStrength
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var previewPanel: some View {
        let previewImage = makePreviewImage(size: 196)

        return VStack(spacing: 16) {
            Text(t(en: "Preview", zh: "预览"))
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            previewContent(previewImage: previewImage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            exportPanel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .underPageBackgroundColor),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func previewContent(previewImage: NSImage?) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.08), radius: 24, y: 10)

                iconPreview(image: previewImage, size: 196)
                    .shadow(color: .black.opacity(0.14), radius: 22, y: 10)
            }
            .frame(width: 260, height: 260)

            Text(previewTitle)
                .font(.title3.weight(.semibold))

            HStack(spacing: 10) {
                ForEach([32.0, 64.0, 96.0], id: \.self) { size in
                    iconPreview(image: previewImage, size: size)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var exportPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                TextField(t(en: "Icon set name", zh: "图标集名称"), text: $iconSetName)
                    .textFieldStyle(.roundedBorder)

                Label(normalizedIconSetName, systemImage: "folder")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(t(en: "Export channels", zh: "导出渠道"))
                        .font(.headline)

                    Grid(horizontalSpacing: 14, verticalSpacing: 8) {
                        GridRow {
                            ForEach([IconRenderer.ExportPlatform.iphone, .ipad], id: \.self) { platform in
                                Toggle(platform.title, isOn: binding(for: platform))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        GridRow {
                            ForEach([IconRenderer.ExportPlatform.appStore, .mac], id: \.self) { platform in
                                Toggle(platform.title, isOn: binding(for: platform))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button(saveProjectTitle, action: saveCurrentProject)
                        .buttonStyle(.bordered)

                    if canSaveAsNewProject {
                        Button(t(en: "Save as New", zh: "另存为新项目"), action: saveCurrentProjectAsNew)
                            .buttonStyle(.bordered)
                    }

                    Button(t(en: "Export", zh: "导出"), action: exportIconSet)
                        .buttonStyle(.borderedProminent)
                }

                if !exportMessage.isEmpty {
                    Label(exportMessage, systemImage: exportSucceeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .foregroundStyle(exportSucceeded ? .green : .red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 6)
        } label: {
            Text(t(en: "Export", zh: "导出"))
        }
    }

    @ViewBuilder
    private func iconPreview(image: NSImage?, size: CGFloat) -> some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
        } else {
            RoundedRectangle(cornerRadius: size * cornerRadiusRatio)
                .fill(.quaternary)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: size * 0.25, weight: .bold))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func makeRenderer() -> IconRenderer {
        IconRenderer(
            content: iconContent,
            foregroundColor: NSColor(foregroundColor),
            secondaryForegroundColor: NSColor(secondaryForegroundColor),
            useForegroundGradient: useForegroundGradient,
            backgroundColor: NSColor(backgroundColor),
            secondaryBackgroundColor: NSColor(secondaryBackgroundColor),
            useGradient: useGradient,
            cornerRadiusRatio: cornerRadiusRatio,
            contentPaddingRatio: contentPaddingRatio,
            symbolScaleRatio: symbolScaleRatio,
            shadowStrength: shadowStrength
        )
    }

    private func makePreviewImage(size: CGFloat) -> NSImage? {
        try? makeRenderer().render(size: size)
    }

    private var iconContent: IconRenderer.IconContent {
        switch iconMode {
        case .sfSymbol:
            return .symbol(symbolName)
        case .emoji:
            return .emoji(emoji)
        case .fluentEmoji:
            guard let asset = selectedFluentEmojiAsset else {
                return .symbol("questionmark")
            }

            return .image(asset.imageURL, isTemplate: fluentEmojiStyle.usesForegroundColor)
        }
    }

    private var previewTitle: String {
        switch iconMode {
        case .sfSymbol:
            return symbolName
        case .emoji:
            return emoji
        case .fluentEmoji:
            return selectedFluentEmojiAsset?.name ?? "Fluent Emoji"
        }
    }

    private func applyVisualSizePreset(_ preset: VisualSizePreset) {
        cornerRadiusRatio = preset.cornerRadiusRatio
        contentPaddingRatio = preset.contentPaddingRatio
        symbolScaleRatio = preset.symbolScaleRatio
        shadowStrength = preset.shadowStrength
    }

    private func t(en: String, zh: String) -> String {
        appLanguage.text(en: en, zh: zh)
    }

    private var savedProjects: [SavedProject] {
        guard let data = savedProjectsData.data(using: .utf8),
              let projects = try? JSONDecoder().decode([SavedProject].self, from: data) else {
            return []
        }

        return projects.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var saveProjectTitle: String {
        selectedProjectID == nil
            ? t(en: "Save as Project", zh: "保存为项目")
            : t(en: "Update Project", zh: "更新项目")
    }

    private var canSaveAsNewProject: Bool {
        guard let selectedProjectID,
              let selectedProject = savedProjects.first(where: { $0.id == selectedProjectID }) else {
            return false
        }

        return hasChanges(from: selectedProject)
    }

    private func saveCurrentProject() {
        var projects = savedProjects
        let project = makeCurrentProject()

        if let selectedProjectID,
           let index = projects.firstIndex(where: { $0.id == selectedProjectID }) {
            projects[index] = project
        } else {
            projects.insert(project, at: 0)
            selectedProjectID = project.id
        }

        persist(projects: projects)
    }

    private func saveCurrentProjectAsNew() {
        var projects = savedProjects
        let project = makeCurrentProject(id: UUID())
        projects.insert(project, at: 0)
        selectedProjectID = project.id
        persist(projects: projects)
    }

    private func makeCurrentProject(id: UUID? = nil) -> SavedProject {
        SavedProject(
            id: id ?? selectedProjectID ?? UUID(),
            name: projectName,
            updatedAt: Date(),
            symbolName: symbolName,
            iconMode: iconMode,
            emoji: emoji,
            foregroundColor: ColorValue(color: foregroundColor),
            useForegroundGradient: useForegroundGradient,
            secondaryForegroundColor: ColorValue(color: secondaryForegroundColor),
            backgroundColor: ColorValue(color: backgroundColor),
            useGradient: useGradient,
            secondaryBackgroundColor: ColorValue(color: secondaryBackgroundColor),
            cornerRadiusRatio: cornerRadiusRatio,
            visualSizePreset: visualSizePreset,
            contentPaddingRatio: contentPaddingRatio,
            symbolScaleRatio: symbolScaleRatio,
            shadowStrength: shadowStrength,
            iconSetName: iconSetName,
            exportPlatforms: exportPlatforms.map(\.rawValue),
            fluentEmojiAssetPath: selectedFluentEmojiAssetPath.isEmpty ? nil : selectedFluentEmojiAssetPath,
            fluentEmojiStyle: fluentEmojiStyle
        )
    }

    private func hasChanges(from project: SavedProject) -> Bool {
        project.symbolName != symbolName ||
            project.iconMode != iconMode ||
            project.emoji != emoji ||
            project.foregroundColor != ColorValue(color: foregroundColor) ||
            project.useForegroundGradient != useForegroundGradient ||
            project.secondaryForegroundColor != ColorValue(color: secondaryForegroundColor) ||
            project.backgroundColor != ColorValue(color: backgroundColor) ||
            project.useGradient != useGradient ||
            project.secondaryBackgroundColor != ColorValue(color: secondaryBackgroundColor) ||
            project.cornerRadiusRatio != cornerRadiusRatio ||
            project.visualSizePreset != visualSizePreset ||
            project.contentPaddingRatio != contentPaddingRatio ||
            project.symbolScaleRatio != symbolScaleRatio ||
            project.shadowStrength != shadowStrength ||
            project.iconSetName != iconSetName ||
            Set(project.exportPlatforms) != Set(exportPlatforms.map(\.rawValue)) ||
            (project.fluentEmojiAssetPath ?? "") != selectedFluentEmojiAssetPath ||
            (project.fluentEmojiStyle ?? .threeD) != fluentEmojiStyle
    }

    private var projectName: String {
        let trimmedIconSetName = iconSetName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedIconSetName.isEmpty {
            return trimmedIconSetName.replacingOccurrences(of: ".appiconset", with: "")
        }

        return previewTitle
    }

    private func apply(project: SavedProject) {
        selectedProjectID = project.id
        symbolName = project.symbolName
        iconMode = project.iconMode
        emoji = project.emoji
        foregroundColor = project.foregroundColor.color
        useForegroundGradient = project.useForegroundGradient
        secondaryForegroundColor = project.secondaryForegroundColor.color
        backgroundColor = project.backgroundColor.color
        useGradient = project.useGradient
        secondaryBackgroundColor = project.secondaryBackgroundColor.color
        cornerRadiusRatio = project.cornerRadiusRatio
        visualSizePreset = project.visualSizePreset
        contentPaddingRatio = project.contentPaddingRatio
        symbolScaleRatio = project.symbolScaleRatio
        shadowStrength = project.shadowStrength
        iconSetName = project.iconSetName
        exportPlatforms = Set(project.exportPlatforms.compactMap(IconRenderer.ExportPlatform.init(rawValue:)))
        fluentEmojiStyle = project.fluentEmojiStyle ?? .threeD
        selectedFluentEmojiAssetPath = project.fluentEmojiAssetPath ?? ""
    }

    private func delete(project: SavedProject) {
        projectPendingDeletion = project
    }

    private func deleteConfirmed(project: SavedProject) {
        let projects = savedProjects.filter { $0.id != project.id }
        persist(projects: projects)
        projectPendingDeletion = nil
        resetEditor()
    }

    private func resetEditor() {
        selectedProjectID = nil
        symbolName = "sparkles"
        symbolQuery = ""
        iconMode = .sfSymbol
        emoji = "🚀"
        foregroundColor = .white
        useForegroundGradient = false
        secondaryForegroundColor = Color(red: 1.0, green: 0.86, blue: 0.25)
        backgroundColor = Color(red: 0.17, green: 0.51, blue: 0.98)
        useGradient = true
        secondaryBackgroundColor = Color(red: 0.39, green: 0.20, blue: 0.98)
        cornerRadiusRatio = 0.24
        visualSizePreset = .balanced
        contentPaddingRatio = 0.10
        symbolScaleRatio = 0.44
        shadowStrength = 0.25
        iconSetName = "AppIcon"
        fluentEmojiQuery = ""
        fluentEmojiStyle = .threeD
        selectedFluentEmojiAssetPath = ""
        exportMessage = ""
        exportSucceeded = false
        exportPlatforms = Set(IconRenderer.ExportPlatform.allCases)
    }

    private func persist(projects: [SavedProject]) {
        guard let data = try? JSONEncoder().encode(projects),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedProjectsData = json
    }

    private func scanFluentEmojiAssets(folderPath: String, style: FluentEmojiStyle) -> [FluentEmojiAsset] {
        let trimmedPath = folderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return [] }

        let fileManager = FileManager.default
        let rootURL = URL(fileURLWithPath: trimmedPath, isDirectory: true)
        let assetsURL = rootURL.appendingPathComponent("assets", isDirectory: true)
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: assetsURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return []
        }

        guard let emojiFolders = try? fileManager.contentsOfDirectory(
            at: assetsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return emojiFolders.compactMap { emojiFolder in
            guard (try? emojiFolder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                  let imageURL = bestFluentEmojiImageURL(in: emojiFolder, style: style) else {
                return nil
            }

            return FluentEmojiAsset(name: emojiFolder.lastPathComponent, imageURL: imageURL)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func bestFluentEmojiImageURL(in emojiFolder: URL, style: FluentEmojiStyle) -> URL? {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
        guard let enumerator = fileManager.enumerator(
            at: emojiFolder,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let pngURLs = enumerator.compactMap { item -> URL? in
            guard let url = item as? URL,
                  url.pathExtension.localizedCaseInsensitiveCompare(style.fileExtension) == .orderedSame,
                  url.path.lowercased().contains("/\(style.folderName.lowercased())/"),
                  (try? url.resourceValues(forKeys: Set(resourceKeys)).isRegularFile) == true else {
                return nil
            }

            return url
        }

        return pngURLs.sorted { lhs, rhs in
            fluentEmojiImageRank(lhs, style: style) < fluentEmojiImageRank(rhs, style: style)
        }.first
    }

    private func fluentEmojiImageRank(_ url: URL, style: FluentEmojiStyle) -> Int {
        let path = url.path.lowercased()
        let stylePath = "/\(style.folderName.lowercased())/"

        if path.contains(stylePath) && !path.contains("/default/") && !path.contains("/light/") && !path.contains("/dark/") {
            return 0
        }

        if path.contains("/default") && path.contains(stylePath) {
            return 1
        }

        if path.contains(stylePath) {
            return 2
        }

        return 3
    }

    private func exportIconSet() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = t(en: "Export", zh: "导出")
        panel.message = t(en: "Choose a folder to export the icon set", zh: "选择要导出图标集的文件夹")

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            return
        }

        do {
            let exportURL = try makeRenderer().exportAppIconSet(
                named: normalizedIconSetName,
                platforms: normalizedExportPlatforms,
                to: folderURL
            )
            exportSucceeded = true
            exportMessage = t(en: "Exported to", zh: "已导出到") + " \(exportURL.path)"
        } catch {
            exportSucceeded = false
            exportMessage = error.localizedDescription
        }
    }

    private var normalizedIconSetName: String {
        let trimmed = iconSetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = trimmed.isEmpty ? "AppIcon" : trimmed
        return baseName.hasSuffix(".appiconset") ? baseName : "\(baseName).appiconset"
    }

    private var normalizedExportPlatforms: Set<IconRenderer.ExportPlatform> {
        exportPlatforms.isEmpty ? Set(IconRenderer.ExportPlatform.allCases) : exportPlatforms
    }

    private func loadExportPlatforms() {
        let platforms = Set(
            storedExportPlatforms
                .split(separator: ",")
                .compactMap { IconRenderer.ExportPlatform(rawValue: String($0)) }
        )

        exportPlatforms = platforms
    }

    private func saveExportPlatforms(_ platforms: Set<IconRenderer.ExportPlatform>) {
        storedExportPlatforms = platforms
            .sorted { $0.rawValue < $1.rawValue }
            .map(\.rawValue)
            .joined(separator: ",")
    }

    private func binding(for platform: IconRenderer.ExportPlatform) -> Binding<Bool> {
        Binding(
            get: { exportPlatforms.contains(platform) },
            set: { isEnabled in
                if isEnabled {
                    exportPlatforms.insert(platform)
                } else {
                    exportPlatforms.remove(platform)
                }
            }
        )
    }

    private func openEmojiPicker() {
        emojiPickerSelectionToken += 1
        focusedField = .emoji
        DispatchQueue.main.async {
            NSApp.orderFrontCharacterPalette(nil)
        }
    }
}

private struct ColorSettingRow: View {
    let title: String
    @Binding var color: Color

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            ColorPicker(title, selection: $color, supportsOpacity: true)
                .labelsHidden()
        }
    }
}

private struct GradientColorSection: View {
    let title: String
    let startTitle: String
    let endTitle: String
    let gradientTitle: String
    @Binding var startColor: Color
    @Binding var endColor: Color
    @Binding var usesGradient: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Toggle(gradientTitle, isOn: $usesGradient)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help(gradientTitle)
            }

            ColorSettingRow(title: startTitle, color: $startColor)

            if usesGradient {
                ColorSettingRow(title: endTitle, color: $endColor)
            }
        }
    }
}

private struct SliderSettingRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueText: String
    let resetTitle: String
    let resetAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Button(action: resetAction) {
                    Image(systemName: "arrow.counterclockwise")
                }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help(resetTitle)
                    .accessibilityLabel(resetTitle)
            }

            Slider(value: $value, in: range)
        }
    }
}

private struct SymbolPickerCell: View {
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18, height: 18)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)

                Text(symbol)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct EmojiPickerCell: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(maxWidth: .infinity, minHeight: 58)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct FluentEmojiPickerCell: View {
    let asset: ContentView.FluentEmojiAsset
    let isTemplate: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(nsImage: NSImage(contentsOf: asset.imageURL) ?? NSImage())
                    .resizable()
                    .renderingMode(isTemplate ? .template : .original)
                    .interpolation(.high)
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)

                Text(asset.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct WindowAccessor: NSViewRepresentable {
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

private struct SelectAllTextFieldContent: NSViewRepresentable {
    let selectionToken: Int

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let editor = nsView.window?.firstResponder as? NSTextView else { return }
            editor.selectAll(nil)
        }
    }
}
