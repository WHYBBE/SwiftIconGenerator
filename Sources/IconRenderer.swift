import AppKit
import Foundation

struct IconRenderer {
    struct IconSpec {
        let filename: String
        let pointSize: Int
        let pixelSize: Int
        let scale: String
    }

    enum IconRendererError: LocalizedError {
        case missingSymbol(String)
        case failedBitmapCreation(Int)
        case failedPNGEncoding(String)

        var errorDescription: String? {
            switch self {
            case .missingSymbol(let symbol):
                return "SF Symbol '\(symbol)' was not found."
            case .failedBitmapCreation(let size):
                return "Failed to create bitmap for size \(size)x\(size)."
            case .failedPNGEncoding(let filename):
                return "Failed to encode PNG for \(filename)."
            }
        }
    }

    let symbolName: String
    let foregroundColor: NSColor
    let backgroundColor: NSColor
    let secondaryBackgroundColor: NSColor
    let useGradient: Bool
    let cornerRadiusRatio: Double
    let symbolScaleRatio: Double
    let shadowStrength: Double

    private let specs: [IconSpec] = [
        .init(filename: "icon_16x16.png", pointSize: 16, pixelSize: 16, scale: "1x"),
        .init(filename: "icon_16x16@2x.png", pointSize: 16, pixelSize: 32, scale: "2x"),
        .init(filename: "icon_32x32.png", pointSize: 32, pixelSize: 32, scale: "1x"),
        .init(filename: "icon_32x32@2x.png", pointSize: 32, pixelSize: 64, scale: "2x"),
        .init(filename: "icon_128x128.png", pointSize: 128, pixelSize: 128, scale: "1x"),
        .init(filename: "icon_128x128@2x.png", pointSize: 128, pixelSize: 256, scale: "2x"),
        .init(filename: "icon_256x256.png", pointSize: 256, pixelSize: 256, scale: "1x"),
        .init(filename: "icon_256x256@2x.png", pointSize: 256, pixelSize: 512, scale: "2x"),
        .init(filename: "icon_512x512.png", pointSize: 512, pixelSize: 512, scale: "1x"),
        .init(filename: "icon_512x512@2x.png", pointSize: 512, pixelSize: 1024, scale: "2x")
    ]

    func render(size: CGFloat) throws -> NSImage {
        guard let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            throw IconRendererError.missingSymbol(symbolName)
        }

        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let cornerRadius = size * cornerRadiusRatio
        let bezierPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSGraphicsContext.current?.imageInterpolation = .high

        if useGradient {
            let gradient = NSGradient(colors: [backgroundColor, secondaryBackgroundColor])
            gradient?.draw(in: bezierPath, angle: -45)
        } else {
            backgroundColor.setFill()
            bezierPath.fill()
        }

        if shadowStrength > 0 {
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(shadowStrength * 0.7)
            shadow.shadowOffset = NSSize(width: 0, height: -(size * 0.025))
            shadow.shadowBlurRadius = size * 0.06
            shadow.set()
        }

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: size * symbolScaleRatio, weight: .bold)
        let configuredSymbol = symbolImage.withSymbolConfiguration(symbolConfig) ?? symbolImage
        let tintedSymbol = configuredSymbol.withSymbolConfiguration(.init(paletteColors: [foregroundColor])) ?? configuredSymbol

        let symbolRect = centeredRect(for: tintedSymbol.size, canvasSize: size, scale: 1)
        tintedSymbol.draw(in: symbolRect)

        image.unlockFocus()
        return image
    }

    func exportAppIconSet(to folderURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let appIconSetURL = folderURL.appendingPathComponent("AppIcon.appiconset", isDirectory: true)

        if fileManager.fileExists(atPath: appIconSetURL.path) {
            try fileManager.removeItem(at: appIconSetURL)
        }

        try fileManager.createDirectory(at: appIconSetURL, withIntermediateDirectories: true)

        for spec in specs {
            let image = try render(size: CGFloat(spec.pixelSize))
            let fileURL = appIconSetURL.appendingPathComponent(spec.filename)
            try writePNG(image: image, to: fileURL, pixelSize: spec.pixelSize)
        }

        let contents = makeContentsJSON()
        let contentsURL = appIconSetURL.appendingPathComponent("Contents.json")
        try contents.write(to: contentsURL, atomically: true, encoding: .utf8)

        return appIconSetURL
    }

    private func writePNG(image: NSImage, to fileURL: URL, pixelSize: Int) throws {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            throw IconRendererError.failedBitmapCreation(pixelSize)
        }

        bitmap.size = NSSize(width: pixelSize, height: pixelSize)

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw IconRendererError.failedPNGEncoding(fileURL.lastPathComponent)
        }

        try pngData.write(to: fileURL)
    }

    private func centeredRect(for symbolSize: NSSize, canvasSize: CGFloat, scale: CGFloat) -> NSRect {
        let width = canvasSize * symbolScaleRatio * scale
        let aspectRatio = symbolSize.height == 0 ? 1 : symbolSize.width / symbolSize.height
        let height = width / max(aspectRatio, 0.01)
        let originX = (canvasSize - width) / 2
        let originY = (canvasSize - height) / 2
        return NSRect(x: originX, y: originY, width: width, height: height)
    }

    private func makeContentsJSON() -> String {
        let images = specs.map { spec in
            """
                {
                  \"filename\" : \"\(spec.filename)\",
                  \"idiom\" : \"mac\",
                  \"scale\" : \"\(spec.scale)\",
                  \"size\" : \"\(spec.pointSize)x\(spec.pointSize)\"
                }
            """
        }.joined(separator: ",\n")

        return """
        {
          \"images\" : [
        \(images)
          ],
          \"info\" : {
            \"author\" : \"xcode\",
            \"version\" : 1
          }
        }
        """
    }
}
