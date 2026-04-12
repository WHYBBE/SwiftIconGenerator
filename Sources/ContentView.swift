import SwiftUI
import AppKit

struct ContentView: View {
    private enum Field: Hashable {
        case symbolName
    }

    @State private var symbolName = "sparkles"
    @State private var symbolQuery = ""
    @State private var foregroundColor = Color.white
    @State private var backgroundColor = Color(red: 0.17, green: 0.51, blue: 0.98)
    @State private var useGradient = true
    @State private var secondaryBackgroundColor = Color(red: 0.39, green: 0.20, blue: 0.98)
    @State private var cornerRadiusRatio = 0.24
    @State private var symbolScaleRatio = 0.54
    @State private var shadowStrength = 0.25
    @State private var exportMessage = ""
    @State private var exportSucceeded = false
    @State private var didActivateWindow = false
    @FocusState private var focusedField: Field?

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
            inspector
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
                focusedField = .symbolName
            }
        }
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("SF Symbols Icon Generator")
                    .font(.largeTitle.weight(.semibold))

                VStack(alignment: .leading, spacing: 10) {
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
                    .frame(height: 220)
                    .padding(1)
                }

                GroupBox("Appearance") {
                    VStack(alignment: .leading, spacing: 16) {
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
                            title: "Symbol scale",
                            value: $symbolScaleRatio,
                            range: 0.38...0.72,
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
                    Button("Export AppIcon.appiconset", action: exportIconSet)
                        .buttonStyle(.borderedProminent)

                    if !exportMessage.isEmpty {
                        Label(exportMessage, systemImage: exportSucceeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundStyle(exportSucceeded ? .green : .red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("Exports all macOS app icon sizes plus a ready-to-use Contents.json.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 360)
    }

    private var previewPanel: some View {
        VStack(spacing: 24) {
            Spacer()

            iconPreview(size: 256)
                .shadow(color: .black.opacity(0.12), radius: 24, y: 10)

            VStack(spacing: 12) {
                Text(symbolName)
                    .font(.title3.weight(.semibold))

                Text("Live preview of the generated macOS app icon style.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 18) {
                ForEach([32.0, 64.0, 128.0], id: \.self) { size in
                    iconPreview(size: size)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
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
            symbolName: symbolName,
            foregroundColor: NSColor(foregroundColor),
            backgroundColor: NSColor(backgroundColor),
            secondaryBackgroundColor: NSColor(secondaryBackgroundColor),
            useGradient: useGradient,
            cornerRadiusRatio: cornerRadiusRatio,
            symbolScaleRatio: symbolScaleRatio,
            shadowStrength: shadowStrength
        )
    }

    private func makePreviewImage(size: CGFloat) -> NSImage? {
        try? makeRenderer().render(size: size)
    }

    private func exportIconSet() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Export"
        panel.message = "Choose a folder to export AppIcon.appiconset"

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            return
        }

        do {
            let exportURL = try makeRenderer().exportAppIconSet(to: folderURL)
            exportSucceeded = true
            exportMessage = "Exported to \(exportURL.path)"
        } catch {
            exportSucceeded = false
            exportMessage = error.localizedDescription
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
