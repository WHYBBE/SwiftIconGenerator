import SwiftUI
import AppKit

struct ContentView: View {
    private enum Field: Hashable {
        case symbolName
        case emoji
    }

    private enum IconMode: String, CaseIterable, Identifiable {
        case sfSymbol = "SF Symbols"
        case emoji = "Emoji"

        var id: String { rawValue }
    }

    private enum VisualSizePreset: String, CaseIterable, Identifiable {
        case compact = "Compact"
        case balanced = "Balanced"
        case bold = "Bold"

        var id: String { rawValue }

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

    @State private var symbolName = "sparkles"
    @State private var symbolQuery = ""
    @State private var iconMode: IconMode = .sfSymbol
    @State private var emoji = "🚀"
    @State private var foregroundColor = Color.white
    @State private var backgroundColor = Color(red: 0.17, green: 0.51, blue: 0.98)
    @State private var useGradient = true
    @State private var secondaryBackgroundColor = Color(red: 0.39, green: 0.20, blue: 0.98)
    @State private var cornerRadiusRatio = 0.24
    @State private var visualSizePreset: VisualSizePreset = .balanced
    @State private var contentPaddingRatio = 0.10
    @State private var symbolScaleRatio = 0.44
    @State private var shadowStrength = 0.25
    @State private var iconSetName = "AppIcon"
    @State private var exportPlatforms: Set<IconRenderer.ExportPlatform> = Set(IconRenderer.ExportPlatform.allCases)
    @State private var exportMessage = ""
    @State private var exportSucceeded = false
    @State private var didActivateWindow = false
    @State private var emojiPickerSelectionToken = 0
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

    var body: some View {
        HStack(spacing: 0) {
            symbolPanel
            Divider()
            settingsPanel
            Divider()
            previewPanel
        }
        .background(Color(nsColor: .windowBackgroundColor))
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
                focusedField = .symbolName
            }
        }
    }

    private var symbolPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Icon Source")
                .font(.title2.weight(.semibold))

            Picker("Icon source", selection: $iconMode) {
                ForEach(IconMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: iconMode) { _, newMode in
                focusedField = newMode == .sfSymbol ? .symbolName : .emoji
            }

            if iconMode == .sfSymbol {
                Text("Symbol")
                    .font(.headline)

                TextField("SF Symbol name", text: $symbolName)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .symbolName)

                TextField("Search symbols", text: $symbolQuery)
                    .textFieldStyle(.roundedBorder)

                Text("Choose a symbol directly from the list below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ScrollView {
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
            } else {
                Text("Emoji")
                    .font(.headline)

                TextField("Emoji", text: $emoji)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .emoji)
                    .background(SelectAllTextFieldContent(selectionToken: emojiPickerSelectionToken))

                Button("Open System Emoji Picker", action: openEmojiPicker)
                    .buttonStyle(.bordered)

                Text("Choose one emoji or paste a custom emoji sequence.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ScrollView {
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
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var settingsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Configuration")
                    .font(.title2.weight(.semibold))

                GroupBox("Appearance") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Visual size")

                            Picker("Visual size", selection: $visualSizePreset) {
                                ForEach(VisualSizePreset.allCases) { preset in
                                    Text(preset.rawValue).tag(preset)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .onChange(of: visualSizePreset) { _, newPreset in
                                applyVisualSizePreset(newPreset)
                            }
                        }

                        ColorSettingRow(title: "Foreground", color: $foregroundColor)
                        ColorSettingRow(title: "Background", color: $backgroundColor)

                        Toggle("Use gradient", isOn: $useGradient)

                        if useGradient {
                            ColorSettingRow(title: "Gradient end", color: $secondaryBackgroundColor)
                        }

                        SliderSettingRow(
                            title: "Corner radius",
                            value: $cornerRadiusRatio,
                            range: 0.12...0.34,
                            valueText: cornerRadiusRatio.formatted(.percent.precision(.fractionLength(0)))
                        )

                        SliderSettingRow(
                            title: "Content padding",
                            value: $contentPaddingRatio,
                            range: 0.04...0.2,
                            valueText: contentPaddingRatio.formatted(.percent.precision(.fractionLength(0)))
                        )

                        SliderSettingRow(
                            title: "Symbol scale",
                            value: $symbolScaleRatio,
                            range: 0.28...0.62,
                            valueText: symbolScaleRatio.formatted(.percent.precision(.fractionLength(0)))
                        )

                        SliderSettingRow(
                            title: "Shadow",
                            value: $shadowStrength,
                            range: 0...0.5,
                            valueText: shadowStrength.formatted(.percent.precision(.fractionLength(0)))
                        )
                    }
                    .padding(.top, 6)
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Icon set name", text: $iconSetName)
                        .textFieldStyle(.roundedBorder)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export channels")
                            .font(.headline)

                        ForEach(IconRenderer.ExportPlatform.allCases, id: \.self) { platform in
                            Toggle(platform.title, isOn: binding(for: platform))
                        }
                    }

                    Button("Export Xcode AppIcon.appiconset", action: exportIconSet)
                        .buttonStyle(.borderedProminent)

                    if !exportMessage.isEmpty {
                        Label(exportMessage, systemImage: exportSucceeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundStyle(exportSucceeded ? .green : .red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("Exports an Xcode-ready .appiconset for iPhone, iPad, App Store, and macOS.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var previewPanel: some View {
        VStack(spacing: 20) {
            Text("Preview")
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            iconPreview(size: 196)
                .shadow(color: .black.opacity(0.12), radius: 20, y: 8)

            VStack(spacing: 10) {
                Text(previewTitle)
                    .font(.title3.weight(.semibold))

                Text("Live preview of the generated macOS app icon style.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 14) {
                ForEach([32.0, 64.0, 96.0], id: \.self) { size in
                    iconPreview(size: size)
                }
            }

            Spacer(minLength: 0)
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

    @ViewBuilder
    private func iconPreview(size: CGFloat) -> some View {
        if let image = makePreviewImage(size: size) {
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
        }
    }

    private var previewTitle: String {
        switch iconMode {
        case .sfSymbol:
            return symbolName
        case .emoji:
            return emoji
        }
    }

    private func applyVisualSizePreset(_ preset: VisualSizePreset) {
        contentPaddingRatio = preset.contentPaddingRatio
        symbolScaleRatio = preset.symbolScaleRatio
    }

    private func exportIconSet() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Export"
        panel.message = "Choose a folder to export the icon set"

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
            exportMessage = "Exported to \(exportURL.path)"
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

private struct SliderSettingRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
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
