import SwiftUI
import AppKit
import UniformTypeIdentifiers

fileprivate struct FluentEmojiAssetGroup {
    let initial: String
    let assets: [FluentEmojiAsset]
}

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
                return "Emoji"
            case .fluentEmoji:
                return "Fluent Emoji"
            }
        }
    }

    private enum VisualSizePreset: String, CaseIterable, Codable, Identifiable {
        case compact = "Compact"
        case balanced = "Balanced"
        case bold = "Bold"

        var id: String { rawValue }

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
        var foregroundGradientAngle: Double?
        var backgroundColor: ColorValue
        var useGradient: Bool
        var secondaryBackgroundColor: ColorValue
        var backgroundGradientAngle: Double?
        var cornerRadiusRatio: Double
        var visualSizePreset: VisualSizePreset
        var contentPaddingRatio: Double
        var symbolScaleRatio: Double
        var contentOffsetXRatio: Double?
        var contentOffsetYRatio: Double?
        var shadowStrength: Double
        var shadowAngle: Double?
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

    private struct PreviewRenderState: Equatable {
        var iconMode: IconMode
        var symbolName: String
        var emoji: String
        var foregroundColor: ColorValue
        var useForegroundGradient: Bool
        var secondaryForegroundColor: ColorValue
        var foregroundGradientAngle: Double
        var backgroundColor: ColorValue
        var useGradient: Bool
        var secondaryBackgroundColor: ColorValue
        var backgroundGradientAngle: Double
        var cornerRadiusRatio: Double
        var contentPaddingRatio: Double
        var symbolScaleRatio: Double
        var contentOffsetXRatio: Double
        var contentOffsetYRatio: Double
        var shadowStrength: Double
        var shadowAngle: Double
        var fluentEmojiAssetPath: String
        var fluentEmojiStyle: FluentEmojiStyle
    }

    @State private var symbolName = "sparkles"
    @State private var symbolQuery = ""
    @State private var iconMode: IconMode = .sfSymbol
    @State private var emoji = "🚀"
    @State private var foregroundColor = Color.white
    @State private var useForegroundGradient = false
    @State private var secondaryForegroundColor = Color(red: 1.0, green: 0.86, blue: 0.25)
    @State private var foregroundGradientAngle = 45.0
    @State private var backgroundColor = Color(red: 0.00, green: 0.78, blue: 0.62)
    @State private var useGradient = true
    @State private var secondaryBackgroundColor = Color(red: 1.00, green: 0.58, blue: 0.12)
    @State private var backgroundGradientAngle = -45.0
    @State private var cornerRadiusRatio = 0.24
    @State private var visualSizePreset: VisualSizePreset = .balanced
    @State private var contentPaddingRatio = 0.10
    @State private var symbolScaleRatio = 0.44
    @State private var contentOffsetXRatio = 0.0
    @State private var contentOffsetYRatio = 0.0
    @State private var shadowStrength = 0.25
    @State private var shadowAngle = 270.0
    @State private var iconSetName = "AppIcon"
    @State private var fluentEmojiQuery = ""
    @State private var fluentEmojiStyle: FluentEmojiStyle = .threeD
    @State private var fluentEmojiInitialFilter = ""
    @State private var selectedFluentEmojiAssetPath = ""
    @State private var fluentEmojiRandomScrollTarget = ""
    @State private var exportPlatforms: Set<IconRenderer.ExportPlatform> = Set(IconRenderer.ExportPlatform.allCases)
    @State private var exportMessage = ""
    @State private var exportSucceeded = false
    @State private var didActivateWindow = false
    @State private var emojiPickerSelectionToken = 0
    @State private var projectColumnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedProjectID: UUID?
    @State private var projectPendingDeletion: SavedProject?
    @State private var fluentEmojiFolderExists = false
    @State private var fluentEmojiIndexExists = false
    @State private var fluentEmojiIndex: FluentEmojiIndex?
    @State private var sfSymbolsMessage = ""
    @State private var sfSymbolsMessageIsError = false
    @State private var previewImage: NSImage?
    @State private var pendingPreviewRender: DispatchWorkItem?
    @State private var filteredSymbolNames = SFSymbolCatalog.all
    @State private var cachedFluentEmojiAssets: [FluentEmojiAsset] = []
    @State private var cachedFluentEmojiAssetByPath: [String: FluentEmojiAsset] = [:]
    @State private var cachedFilteredFluentEmojiAssets: [FluentEmojiAsset] = []
    @State private var cachedGroupedFluentEmojiAssets: [FluentEmojiAssetGroup] = []
    @AppStorage("appTheme") private var appTheme = AppTheme.system
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system
    @AppStorage("exportPlatforms") private var storedExportPlatforms = Self.defaultExportPlatformRawValues
    @AppStorage("savedProjects") private var savedProjectsData = "[]"
    @AppStorage("fluentEmojiFolderPath") private var fluentEmojiFolderPath = ""
    @AppStorage("fluentEmojiIndexVersion") private var fluentEmojiIndexVersion = ""
    @AppStorage("showPreviewBackdrop") private var showPreviewBackdrop = true
    @FocusState private var focusedField: Field?

    private let suggestedEmojis = [
        "🚀", "✨", "🔥", "🎯", "🧠", "🎨", "🪄", "💎",
        "🌈", "🌙", "☀️", "🍀", "🦄", "🐼", "🍎", "📦",
        "💬", "📷", "🎵", "🛠️", "🧩", "📚", "🧪", "🎮"
    ]
    private let panelPadding: CGFloat = 18
    private let panelTitleHeight: CGFloat = 30
    private let panelContentSpacing: CGFloat = 12

    private var filteredSymbols: [String] {
        filteredSymbolNames
    }

    private var availableIconModes: [IconMode] {
        isFluentEmojiFolderValid ? IconMode.allCases : [.sfSymbol, .emoji]
    }

    private var fluentEmojiAssets: [FluentEmojiAsset] {
        cachedFluentEmojiAssets
    }

    private var filteredFluentEmojiAssets: [FluentEmojiAsset] {
        cachedFilteredFluentEmojiAssets
    }

    private var groupedFilteredFluentEmojiAssets: [FluentEmojiAssetGroup] {
        cachedGroupedFluentEmojiAssets
    }

    private var activeFluentEmojiInitial: String {
        if fluentEmojiInitialFilter.isEmpty {
            return ""
        }

        if groupedFilteredFluentEmojiAssets.contains(where: { $0.initial == fluentEmojiInitialFilter }) {
            return fluentEmojiInitialFilter
        }

        return ""
    }

    private var activeFluentEmojiAssets: [FluentEmojiAsset] {
        if activeFluentEmojiInitial.isEmpty {
            return filteredFluentEmojiAssets
        }

        return groupedFilteredFluentEmojiAssets.first { $0.initial == activeFluentEmojiInitial }?.assets ?? []
    }

    private func fluentEmojiAssetSort(_ lhs: FluentEmojiAsset, _ rhs: FluentEmojiAsset) -> Bool {
        let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
        if nameComparison != .orderedSame {
            return nameComparison == .orderedAscending
        }

        return lhs.imageURL.path.localizedCaseInsensitiveCompare(rhs.imageURL.path) == .orderedAscending
    }

    private var selectedFluentEmojiAsset: FluentEmojiAsset? {
        cachedFluentEmojiAssetByPath[selectedFluentEmojiAssetPath] ?? fluentEmojiAssets.first
    }

    private var isFluentEmojiFolderValid: Bool {
        fluentEmojiFolderExists && fluentEmojiIndexExists
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $projectColumnVisibility) {
            projectSidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            mainWorkspace
                .navigationSplitViewColumnWidth(min: 880, ideal: 900)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(appTheme.colorScheme)
        .background(WindowAccessor { window in
            guard let window, !didActivateWindow, Self.isRunningFromSwiftPM else { return }

            didActivateWindow = true

            focusSwiftPMWindow(window)
        })
        .onAppear {
            DispatchQueue.main.async {
                applyVisualSizePreset(visualSizePreset)
                loadExportPlatforms()
                refreshFluentEmojiAvailability()
                refreshSymbolFilter()
                refreshFluentEmojiAssets()
                focusedField = .symbolName
                schedulePreviewImageRender()
            }
        }
        .onChange(of: previewRenderState) { _, _ in
            schedulePreviewImageRender()
        }
        .onChange(of: exportPlatforms) { _, newPlatforms in
            saveExportPlatforms(newPlatforms)
        }
        .onChange(of: symbolQuery) { _, _ in
            refreshSymbolFilter()
        }
        .onDisappear {
            pendingPreviewRender?.cancel()
            pendingPreviewRender = nil
        }
        .onChange(of: fluentEmojiFolderPath) { _, _ in
            fluentEmojiIndex = nil
            refreshFluentEmojiAvailability()
            if iconMode == .fluentEmoji {
                loadFluentEmojiIndexIfNeeded()
            }
            refreshFluentEmojiAssets()

            if !isFluentEmojiFolderValid, iconMode == .fluentEmoji {
                iconMode = .sfSymbol
            }

            if selectedFluentEmojiAsset == nil {
                selectedFluentEmojiAssetPath = fluentEmojiAssets.first?.imageURL.path ?? ""
            }
        }
        .onChange(of: fluentEmojiIndexVersion) { _, _ in
            fluentEmojiIndex = nil
            refreshFluentEmojiAvailability()
            if iconMode == .fluentEmoji {
                loadFluentEmojiIndexIfNeeded()
            }
            refreshFluentEmojiAssets()
            selectedFluentEmojiAssetPath = selectedFluentEmojiAsset?.imageURL.path ?? ""
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
            let availableWidth = max(proxy.size.width - 2, 0)
            let sourceWidth = availableWidth / 2.9
            let settingsWidth = availableWidth / 2.9
            let previewWidth = availableWidth - sourceWidth - settingsWidth

            HStack(spacing: 0) {
                symbolPanel
                    .frame(width: sourceWidth)
                    .clipped()
                Divider()
                settingsPanel
                    .frame(width: settingsWidth)
                Divider()
                previewPanel
                    .frame(width: previewWidth)
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
                                    export(project: project)
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .help(t(en: "Export project", zh: "导出项目"))

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
            .padding(panelPadding)
            .frame(maxHeight: .infinity)
            .background(sourcePanelBackground)
    }

    private var sourcePanelBackground: some View {
        Color(nsColor: .textBackgroundColor).opacity(0.35)
    }

    private var sourcePanelContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            panelTitle(t(en: "Icon", zh: "图标"))
                .frame(height: panelTitleHeight, alignment: .topLeading)
            iconModePicker
                .frame(maxWidth: .infinity)
            sourceControls
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
                loadFluentEmojiIndexIfNeeded()
                refreshFluentEmojiAssets()
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
            TextField(t(en: "SF Symbol name", zh: "SF Symbol 名称"), text: $symbolName)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .symbolName)

            TextField(t(en: "Search symbols", zh: "搜索符号"), text: $symbolQuery)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                Button(t(en: "Open SF Symbols", zh: "打开 SF Symbols"), action: openSFSymbolsApp)
                    .buttonStyle(.bordered)

                if !sfSymbolsMessage.isEmpty {
                    Label(sfSymbolsMessage, systemImage: sfSymbolsMessageIsError ? "xmark.circle" : "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(sfSymbolsMessageIsError ? .red : .secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

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
            Picker(t(en: "Style", zh: "风格"), selection: $fluentEmojiStyle) {
                ForEach(FluentEmojiStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: fluentEmojiStyle) { oldStyle, newStyle in
                let selectedName = fluentEmojiIndex?.assets(for: oldStyle).first {
                    $0.imageURL.path == selectedFluentEmojiAssetPath
                }?.name

                loadFluentEmojiIndexIfNeeded()

                let newStyleAssets = fluentEmojiIndex?.assets(for: newStyle) ?? []
                if let selectedName,
                   let matchingAsset = newStyleAssets.first(where: { $0.name == selectedName }) {
                    selectedFluentEmojiAssetPath = matchingAsset.imageURL.path
                } else {
                    selectedFluentEmojiAssetPath = newStyleAssets.first?.imageURL.path ?? ""
                }

                refreshFluentEmojiAssets()
            }

            HStack(spacing: 8) {
                TextField(t(en: "Search Fluent Emoji", zh: "搜索 Fluent Emoji"), text: $fluentEmojiQuery)
                    .textFieldStyle(.roundedBorder)

                Button(action: randomizeFluentEmojiSelection) {
                    Image(systemName: "dice")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .disabled(activeFluentEmojiAssets.isEmpty)
                .help(t(en: "Random Fluent Emoji", zh: "随机 Fluent Emoji"))
                .accessibilityLabel(t(en: "Random Fluent Emoji", zh: "随机 Fluent Emoji"))
            }

            FluentEmojiLetterFilter(
                initials: groupedFilteredFluentEmojiAssets.map(\.initial),
                allTitle: t(en: "All", zh: "全部"),
                selectedInitial: activeFluentEmojiInitial
            ) { initial in
                fluentEmojiInitialFilter = initial
            }

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activeFluentEmojiInitial.isEmpty ? t(en: "All", zh: "全部") : activeFluentEmojiInitial)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 10)], spacing: 10) {
                            ForEach(activeFluentEmojiAssets) { asset in
                                FluentEmojiPickerCell(
                                    asset: asset,
                                    isTemplate: fluentEmojiStyle.usesForegroundColor,
                                    isSelected: asset.imageURL.path == selectedFluentEmojiAssetPath
                                ) {
                                    withTransaction(Transaction(animation: nil)) {
                                        selectedFluentEmojiAssetPath = asset.imageURL.path
                                    }
                                }
                                .id(asset.id)
                            }
                        }
                    }
                    .padding(1)
                    .padding(.trailing, 8)
                }
                .background(FluentEmojiScrollerAccessor())
                .onChange(of: fluentEmojiRandomScrollTarget) { _, target in
                    guard !target.isEmpty else { return }
                    DispatchQueue.main.async {
                        withTransaction(Transaction(animation: nil)) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                        fluentEmojiRandomScrollTarget = ""
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(1)
        }
        .onChange(of: fluentEmojiQuery) { _, _ in
            refreshFluentEmojiFilter()
            if !groupedFilteredFluentEmojiAssets.contains(where: { $0.initial == fluentEmojiInitialFilter }) {
                fluentEmojiInitialFilter = ""
            }
        }
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: panelContentSpacing) {
            panelTitle(t(en: "Configuration", zh: "配置"))
                .frame(height: panelTitleHeight, alignment: .topLeading)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(t(en: "Layout", zh: "布局"))
                            .font(.headline)

                        SliderSettingRow(
                            title: t(en: "Corner radius", zh: "圆角"),
                            value: $cornerRadiusRatio,
                            range: 0.12...0.34,
                            valueText: cornerRadiusRatio.formatted(.percent.precision(.fractionLength(0))),
                            resetTitle: t(en: "Reset", zh: "重置")
                        ) {
                            cornerRadiusRatio = 0.24
                        }

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

                        SliderSettingRow(
                            title: t(en: "Content padding", zh: "内容边距"),
                            value: $contentPaddingRatio,
                            range: 0.04...0.2,
                            valueText: contentPaddingRatio.formatted(.percent.precision(.fractionLength(0))),
                            resetTitle: t(en: "Reset to preset", zh: "重置为预设")
                        ) {
                            contentPaddingRatio = visualSizePreset.contentPaddingRatio
                        }

                        SliderSettingRow(
                            title: t(en: "Symbol scale", zh: "符号缩放"),
                            value: $symbolScaleRatio,
                            range: 0.28...0.62,
                            valueText: symbolScaleRatio.formatted(.percent.precision(.fractionLength(0))),
                            resetTitle: t(en: "Reset to preset", zh: "重置为预设")
                        ) {
                            symbolScaleRatio = visualSizePreset.symbolScaleRatio
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(t(en: "Position presets", zh: "位置预设"))

                            HStack(spacing: 4) {
                                PositionPresetButton(symbolName: "arrow.up.left", title: t(en: "Top left", zh: "左上")) {
                                    applyContentPositionPreset(x: -safeContentPositionOffset, y: safeContentPositionOffset)
                                }

                                PositionPresetButton(symbolName: "arrow.up.right", title: t(en: "Top right", zh: "右上")) {
                                    applyContentPositionPreset(x: safeContentPositionOffset, y: safeContentPositionOffset)
                                }

                                PositionPresetButton(symbolName: "scope", title: t(en: "Center", zh: "中间")) {
                                    applyContentPositionPreset(x: 0, y: 0)
                                }

                                PositionPresetButton(symbolName: "arrow.down.left", title: t(en: "Bottom left", zh: "左下")) {
                                    applyContentPositionPreset(x: -safeContentPositionOffset, y: -safeContentPositionOffset)
                                }

                                PositionPresetButton(symbolName: "arrow.down.right", title: t(en: "Bottom right", zh: "右下")) {
                                    applyContentPositionPreset(x: safeContentPositionOffset, y: -safeContentPositionOffset)
                                }
                            }
                        }

                        SliderSettingRow(
                            title: t(en: "Horizontal position", zh: "水平位置"),
                            value: $contentOffsetXRatio,
                            range: -0.35...0.35,
                            valueText: positionOffsetText(contentOffsetXRatio),
                            resetTitle: t(en: "Reset position", zh: "重置位置")
                        ) {
                            contentOffsetXRatio = 0
                        }

                        SliderSettingRow(
                            title: t(en: "Vertical position", zh: "垂直位置"),
                            value: $contentOffsetYRatio,
                            range: -0.35...0.35,
                            valueText: positionOffsetText(contentOffsetYRatio),
                            resetTitle: t(en: "Reset position", zh: "重置位置")
                        ) {
                            contentOffsetYRatio = 0
                        }
                    }

                    if iconMode == .sfSymbol || (iconMode == .fluentEmoji && fluentEmojiStyle.usesForegroundColor) {
                        GradientColorSection(
                            title: t(en: "Foreground", zh: "前景"),
                            startTitle: t(en: "Start color", zh: "起始色"),
                            endTitle: t(en: "End color", zh: "结束色"),
                            gradientTitle: t(en: "Gradient", zh: "渐变"),
                            randomTitle: t(en: "Randomize colors", zh: "随机颜色"),
                            startColor: $foregroundColor,
                            endColor: $secondaryForegroundColor,
                            usesGradient: $useForegroundGradient
                        )

                        if useForegroundGradient {
                            angleSettingRow(
                                title: t(en: "Foreground angle", zh: "前景角度"),
                                value: $foregroundGradientAngle,
                                resetValue: 45
                            )
                        }
                    }

                    GradientColorSection(
                        title: t(en: "Background", zh: "背景"),
                        startTitle: t(en: "Start color", zh: "起始色"),
                        endTitle: t(en: "End color", zh: "结束色"),
                        gradientTitle: t(en: "Gradient", zh: "渐变"),
                        randomTitle: t(en: "Randomize colors", zh: "随机颜色"),
                        startColor: $backgroundColor,
                        endColor: $secondaryBackgroundColor,
                        usesGradient: $useGradient
                    )

                    if useGradient {
                        angleSettingRow(
                            title: t(en: "Background angle", zh: "背景角度"),
                            value: $backgroundGradientAngle,
                            resetValue: -45
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(t(en: "Shadow", zh: "阴影"))
                            .font(.headline)

                        SliderSettingRow(
                            title: t(en: "Strength", zh: "强度"),
                            value: $shadowStrength,
                            range: 0...0.5,
                            valueText: shadowStrength.formatted(.percent.precision(.fractionLength(0))),
                            resetTitle: t(en: "Reset", zh: "重置")
                        ) {
                            shadowStrength = 0.25
                        }

                        if shadowStrength > 0 {
                            angleSettingRow(
                                title: t(en: "Angle", zh: "角度"),
                                value: $shadowAngle,
                                resetValue: 270
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(panelPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var previewPanel: some View {
        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width - (panelPadding * 2), 120)

            VStack(spacing: panelContentSpacing) {
                panelTitle(t(en: "Preview", zh: "预览"))
                    .frame(height: panelTitleHeight, alignment: .topLeading)

                GeometryReader { contentProxy in
                    previewContent(
                        previewImage: previewImage,
                        contentWidth: contentWidth,
                        contentHeight: contentProxy.size.height
                    )
                    .frame(width: contentProxy.size.width, height: contentProxy.size.height, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                exportPanel
            }
            .padding(panelPadding)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }

    private func panelTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func angleSettingRow(title: String, value: Binding<Double>, resetValue: Double) -> some View {
        SliderSettingRow(
            title: title,
            value: value,
            range: -180...360,
            valueText: "\(Int(value.wrappedValue.rounded()))°",
            resetTitle: t(en: "Reset", zh: "重置")
        ) {
            value.wrappedValue = resetValue
        }
    }

    private var safeContentPositionOffset: Double {
        min(max(0.5 - contentPaddingRatio - (symbolScaleRatio / 2), 0), 0.35)
    }

    private func applyContentPositionPreset(x: Double, y: Double) {
        contentOffsetXRatio = x
        contentOffsetYRatio = y
    }

    private func previewContent(previewImage: NSImage?, contentWidth: CGFloat, contentHeight: CGFloat) -> some View {
        let maxCardHeight = max(120, contentHeight - 112)
        let cardSize = min(260, max(132, min(contentWidth, maxCardHeight)))
        let iconSize = min(196, cardSize * 0.74)
        let smallBaseSize = min(96, max(32, (contentWidth - 68) / 2.07))
        let smallSizes = [smallBaseSize * 0.4, smallBaseSize * 0.67, smallBaseSize]

        return VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(previewBackdropStyle)
                    .shadow(color: .black.opacity(0.08), radius: 24, y: 10)

                iconPreview(image: previewImage, size: iconSize)
                    .shadow(color: .black.opacity(0.14), radius: 22, y: 10)
            }
            .frame(width: cardSize, height: cardSize)

            Text(previewTitle)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: contentWidth)

            HStack(spacing: 10) {
                ForEach(smallSizes, id: \.self) { size in
                    iconPreview(image: previewImage, size: size)
                        .padding(8)
                        .background(previewBackdropStyle, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var previewBackdropStyle: AnyShapeStyle {
        if showPreviewBackdrop {
            return AnyShapeStyle(
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

        return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
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

                ViewThatFits(in: .horizontal) {
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

                    VStack(alignment: .leading, spacing: 8) {
                        Button(saveProjectTitle, action: saveCurrentProject)
                            .buttonStyle(.bordered)

                        if canSaveAsNewProject {
                            Button(t(en: "Save as New", zh: "另存为新项目"), action: saveCurrentProjectAsNew)
                                .buttonStyle(.bordered)
                        }

                        Button(t(en: "Export", zh: "导出"), action: exportIconSet)
                            .buttonStyle(.borderedProminent)
                    }
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
            foregroundGradientAngle: foregroundGradientAngle,
            backgroundColor: NSColor(backgroundColor),
            secondaryBackgroundColor: NSColor(secondaryBackgroundColor),
            useGradient: useGradient,
            backgroundGradientAngle: backgroundGradientAngle,
            cornerRadiusRatio: cornerRadiusRatio,
            contentPaddingRatio: contentPaddingRatio,
            symbolScaleRatio: symbolScaleRatio,
            contentOffsetXRatio: contentOffsetXRatio,
            contentOffsetYRatio: contentOffsetYRatio,
            shadowStrength: shadowStrength,
            shadowAngle: shadowAngle
        )
    }

    private func makePreviewImage(size: CGFloat) -> NSImage? {
        try? makeRenderer().render(size: size)
    }

    private var previewRenderState: PreviewRenderState {
        PreviewRenderState(
            iconMode: iconMode,
            symbolName: symbolName,
            emoji: emoji,
            foregroundColor: ColorValue(color: foregroundColor),
            useForegroundGradient: useForegroundGradient,
            secondaryForegroundColor: ColorValue(color: secondaryForegroundColor),
            foregroundGradientAngle: foregroundGradientAngle,
            backgroundColor: ColorValue(color: backgroundColor),
            useGradient: useGradient,
            secondaryBackgroundColor: ColorValue(color: secondaryBackgroundColor),
            backgroundGradientAngle: backgroundGradientAngle,
            cornerRadiusRatio: cornerRadiusRatio,
            contentPaddingRatio: contentPaddingRatio,
            symbolScaleRatio: symbolScaleRatio,
            contentOffsetXRatio: contentOffsetXRatio,
            contentOffsetYRatio: contentOffsetYRatio,
            shadowStrength: shadowStrength,
            shadowAngle: shadowAngle,
            fluentEmojiAssetPath: selectedFluentEmojiAssetPath,
            fluentEmojiStyle: fluentEmojiStyle
        )
    }

    private func schedulePreviewImageRender() {
        pendingPreviewRender?.cancel()

        let renderState = previewRenderState
        let workItem = DispatchWorkItem {
            guard renderState == previewRenderState else { return }
            previewImage = makePreviewImage(size: 196)
            pendingPreviewRender = nil
        }

        pendingPreviewRender = workItem
        DispatchQueue.main.async(execute: workItem)
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
        contentPaddingRatio = preset.contentPaddingRatio
        symbolScaleRatio = preset.symbolScaleRatio
    }

    private func positionOffsetText(_ value: Double) -> String {
        let percentage = Int((value * 100).rounded())
        return percentage > 0 ? "+\(percentage)%" : "\(percentage)%"
    }

    private func t(en: String, zh: String) -> String {
        appLanguage.text(en: en, zh: zh)
    }

    private static var isRunningFromSwiftPM: Bool {
        Bundle.main.bundleURL.pathExtension != "app"
    }

    private func focusSwiftPMWindow(_ window: NSWindow) {
        window.collectionBehavior.insert(.fullScreenPrimary)

        for delay in [0.0, 0.15, 0.45] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                focusedField = .symbolName
                window.makeFirstResponder(nil)
            }
        }
    }

    private func refreshFluentEmojiAvailability() {
        fluentEmojiFolderExists = FluentEmojiIndex.folderExists(at: fluentEmojiFolderPath)
        fluentEmojiIndexExists = FluentEmojiIndex.indexExists(for: fluentEmojiFolderPath)
    }

    private func loadFluentEmojiIndexIfNeeded() {
        guard fluentEmojiIndex == nil, isFluentEmojiFolderValid else { return }
        fluentEmojiIndex = FluentEmojiIndex.load(folderPath: fluentEmojiFolderPath)
        fluentEmojiIndexExists = fluentEmojiIndex != nil
    }

    private func refreshSymbolFilter() {
        let trimmedQuery = symbolQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            filteredSymbolNames = SFSymbolCatalog.all
            return
        }

        filteredSymbolNames = SFSymbolCatalog.all.filter {
            $0.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private func refreshFluentEmojiAssets() {
        cachedFluentEmojiAssets = fluentEmojiIndex?.assets(for: fluentEmojiStyle) ?? []
        cachedFluentEmojiAssetByPath = Dictionary(uniqueKeysWithValues: cachedFluentEmojiAssets.map { ($0.imageURL.path, $0) })
        refreshFluentEmojiFilter()
    }

    private func refreshFluentEmojiFilter() {
        let assets = fluentEmojiAssets
        let trimmedQuery = fluentEmojiQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredAssets = trimmedQuery.isEmpty
            ? assets
            : assets.filter { $0.name.localizedCaseInsensitiveContains(trimmedQuery) }
        let sortedAssets = filteredAssets.sorted(by: fluentEmojiAssetSort)
        let groups = Dictionary(grouping: sortedAssets) { asset in
            fluentEmojiInitial(for: asset.name)
        }

        cachedFilteredFluentEmojiAssets = sortedAssets
        cachedGroupedFluentEmojiAssets = groups
            .map { group in
                FluentEmojiAssetGroup(
                    initial: group.key,
                    assets: group.value
                )
            }
            .sorted { lhs, rhs in
                if lhs.initial == "#" { return false }
                if rhs.initial == "#" { return true }
                return lhs.initial.localizedCaseInsensitiveCompare(rhs.initial) == .orderedAscending
            }
    }

    private func randomizeFluentEmojiSelection() {
        guard let asset = activeFluentEmojiAssets.randomElement() else { return }
        withTransaction(Transaction(animation: nil)) {
            selectedFluentEmojiAssetPath = asset.imageURL.path
        }
        fluentEmojiRandomScrollTarget = asset.id
    }

    private func openSFSymbolsApp() {
        let workspace = NSWorkspace.shared
        let fileManager = FileManager.default
        let betaFallbackURLs = [
            URL(fileURLWithPath: "/Applications/SF Symbols beta.app", isDirectory: true),
            URL(fileURLWithPath: "/Applications/SF Symbols Beta.app", isDirectory: true)
        ]
        let releaseFallbackURL = URL(fileURLWithPath: "/Applications/SF Symbols.app", isDirectory: true)
        let betaFallbackURL = betaFallbackURLs.first { fileManager.fileExists(atPath: $0.path) }
        let releaseFallbackExists = fileManager.fileExists(atPath: releaseFallbackURL.path)
        let appURL = betaFallbackURL
            ?? workspace.urlForApplication(withBundleIdentifier: "com.apple.SFSymbols.beta")
            ?? workspace.urlForApplication(withBundleIdentifier: "com.apple.SFSymbols")
            ?? (releaseFallbackExists ? releaseFallbackURL : nil)

        guard let appURL else {
            sfSymbolsMessage = t(en: "SF Symbols app not found", zh: "未找到 SF Symbols 应用")
            sfSymbolsMessageIsError = true
            return
        }

        workspace.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            DispatchQueue.main.async {
                if let error {
                    sfSymbolsMessage = error.localizedDescription
                    sfSymbolsMessageIsError = true
                } else {
                    let openedMessage = t(en: "Opened", zh: "已打开")
                    sfSymbolsMessage = openedMessage
                    sfSymbolsMessageIsError = false

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if sfSymbolsMessage == openedMessage, !sfSymbolsMessageIsError {
                            sfSymbolsMessage = ""
                        }
                    }
                }
            }
        }
    }

    private func fluentEmojiInitial(for name: String) -> String {
        guard let firstCharacter = name.trimmingCharacters(in: .whitespacesAndNewlines).first else {
            return "#"
        }

        let initial = String(firstCharacter).uppercased()
        return initial.range(of: #"^[A-Z]$"#, options: .regularExpression) == nil ? "#" : initial
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
            foregroundGradientAngle: foregroundGradientAngle,
            backgroundColor: ColorValue(color: backgroundColor),
            useGradient: useGradient,
            secondaryBackgroundColor: ColorValue(color: secondaryBackgroundColor),
            backgroundGradientAngle: backgroundGradientAngle,
            cornerRadiusRatio: cornerRadiusRatio,
            visualSizePreset: visualSizePreset,
            contentPaddingRatio: contentPaddingRatio,
            symbolScaleRatio: symbolScaleRatio,
            contentOffsetXRatio: contentOffsetXRatio,
            contentOffsetYRatio: contentOffsetYRatio,
            shadowStrength: shadowStrength,
            shadowAngle: shadowAngle,
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
            (project.foregroundGradientAngle ?? 45) != foregroundGradientAngle ||
            project.backgroundColor != ColorValue(color: backgroundColor) ||
            project.useGradient != useGradient ||
            project.secondaryBackgroundColor != ColorValue(color: secondaryBackgroundColor) ||
            (project.backgroundGradientAngle ?? -45) != backgroundGradientAngle ||
            project.cornerRadiusRatio != cornerRadiusRatio ||
            project.visualSizePreset != visualSizePreset ||
            project.contentPaddingRatio != contentPaddingRatio ||
            project.symbolScaleRatio != symbolScaleRatio ||
            (project.contentOffsetXRatio ?? 0) != contentOffsetXRatio ||
            (project.contentOffsetYRatio ?? 0) != contentOffsetYRatio ||
            project.shadowStrength != shadowStrength ||
            (project.shadowAngle ?? 270) != shadowAngle ||
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
        foregroundGradientAngle = project.foregroundGradientAngle ?? 45
        backgroundColor = project.backgroundColor.color
        useGradient = project.useGradient
        secondaryBackgroundColor = project.secondaryBackgroundColor.color
        backgroundGradientAngle = project.backgroundGradientAngle ?? -45
        cornerRadiusRatio = project.cornerRadiusRatio
        visualSizePreset = project.visualSizePreset
        contentPaddingRatio = project.contentPaddingRatio
        symbolScaleRatio = project.symbolScaleRatio
        contentOffsetXRatio = project.contentOffsetXRatio ?? 0
        contentOffsetYRatio = project.contentOffsetYRatio ?? 0
        shadowStrength = project.shadowStrength
        shadowAngle = project.shadowAngle ?? 270
        iconSetName = project.iconSetName
        exportPlatforms = Set(project.exportPlatforms.compactMap(IconRenderer.ExportPlatform.init(rawValue:)))
        fluentEmojiStyle = project.fluentEmojiStyle ?? .threeD
        if iconMode == .fluentEmoji {
            loadFluentEmojiIndexIfNeeded()
        }
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

    private func export(project: SavedProject) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(project.name).json"
        panel.prompt = t(en: "Export", zh: "导出")

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try JSONEncoder().encode(project)
            try data.write(to: url, options: .atomic)
        } catch {
            exportSucceeded = false
            exportMessage = error.localizedDescription
        }
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
        foregroundGradientAngle = 45
        backgroundColor = Color(red: 0.00, green: 0.78, blue: 0.62)
        useGradient = true
        secondaryBackgroundColor = Color(red: 1.00, green: 0.58, blue: 0.12)
        backgroundGradientAngle = -45
        cornerRadiusRatio = 0.24
        visualSizePreset = .balanced
        contentPaddingRatio = 0.10
        symbolScaleRatio = 0.44
        contentOffsetXRatio = 0
        contentOffsetYRatio = 0
        shadowStrength = 0.25
        shadowAngle = 270
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
    let randomTitle: String
    @Binding var color: Color

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button {
                color = .randomIconColor()
            } label: {
                Image(systemName: "dice")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help(randomTitle)
            .accessibilityLabel(randomTitle)

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
    let randomTitle: String
    @Binding var startColor: Color
    @Binding var endColor: Color
    @Binding var usesGradient: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if usesGradient {
                    Button {
                        startColor = .randomIconColor()
                        endColor = .randomIconColor()
                    } label: {
                        Image(systemName: "dice.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help(randomTitle)
                    .accessibilityLabel(randomTitle)
                }

                Toggle(gradientTitle, isOn: $usesGradient)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help(gradientTitle)
            }

            ColorSettingRow(title: startTitle, randomTitle: randomTitle, color: $startColor)

            if usesGradient {
                ColorSettingRow(title: endTitle, randomTitle: randomTitle, color: $endColor)
            }
        }
    }
}

private extension Color {
    static func randomIconColor() -> Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
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

private struct PositionPresetButton: View {
    let symbolName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.8), lineWidth: 1)
        }
        .help(title)
        .accessibilityLabel(title)
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

private struct FluentEmojiLetterFilter: View {
    let initials: [String]
    let allTitle: String
    let selectedInitial: String
    let action: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 34), spacing: 6)], spacing: 6) {
            FluentEmojiLetterFilterButton(
                title: allTitle,
                isSelected: selectedInitial.isEmpty,
                action: { action("") }
            )

            ForEach(initials, id: \.self) { initial in
                FluentEmojiLetterFilterButton(
                    title: initial,
                    isSelected: initial == selectedInitial,
                    action: { action(initial) }
                )
            }
        }
    }
}

private struct FluentEmojiLetterFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .background {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

private struct FluentEmojiPickerCell: View {
    let asset: FluentEmojiAsset
    let isTemplate: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(nsImage: ImageFileCache.shared.image(for: asset.imageURL) ?? NSImage())
                    .resizable()
                    .renderingMode(isTemplate ? .template : .original)
                    .interpolation(.high)
                    .scaledToFit()
                    .foregroundStyle(isTemplate ? (isSelected ? Color.white : Color.primary) : Color.primary)
                    .frame(width: 44, height: 44)

                Text(asset.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

private struct FluentEmojiScrollerAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configureScrollView(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureScrollView(for: nsView)
        }
    }

    private func configureScrollView(for view: NSView) {
        guard let scrollView = view.enclosingScrollView else { return }
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy
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
