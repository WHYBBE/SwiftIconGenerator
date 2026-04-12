import AppKit
import Foundation

struct IconRenderer {
    struct IconSpec {
        let filename: String
        let idiom: String
        let pointSize: Double
        let pixelSize: Int
        let scale: String
        let role: String?
        let subtype: String?
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
    let contentPaddingRatio: Double
    let symbolScaleRatio: Double
    let shadowStrength: Double

    private let specs: [IconSpec] = [
        .init(filename: "appicon-iphone-20@2x.png", idiom: "iphone", pointSize: 20, pixelSize: 40, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-iphone-20@3x.png", idiom: "iphone", pointSize: 20, pixelSize: 60, scale: "3x", role: nil, subtype: nil),
        .init(filename: "appicon-iphone-29@2x.png", idiom: "iphone", pointSize: 29, pixelSize: 58, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-iphone-29@3x.png", idiom: "iphone", pointSize: 29, pixelSize: 87, scale: "3x", role: nil, subtype: nil),
        .init(filename: "appicon-iphone-40@2x.png", idiom: "iphone", pointSize: 40, pixelSize: 80, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-iphone-40@3x.png", idiom: "iphone", pointSize: 40, pixelSize: 120, scale: "3x", role: nil, subtype: nil),
        .init(filename: "appicon-iphone-60@2x.png", idiom: "iphone", pointSize: 60, pixelSize: 120, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-iphone-60@3x.png", idiom: "iphone", pointSize: 60, pixelSize: 180, scale: "3x", role: nil, subtype: nil),

        .init(filename: "appicon-ipad-20@1x.png", idiom: "ipad", pointSize: 20, pixelSize: 20, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-ipad-20@2x.png", idiom: "ipad", pointSize: 20, pixelSize: 40, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-ipad-29@1x.png", idiom: "ipad", pointSize: 29, pixelSize: 29, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-ipad-29@2x.png", idiom: "ipad", pointSize: 29, pixelSize: 58, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-ipad-40@1x.png", idiom: "ipad", pointSize: 40, pixelSize: 40, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-ipad-40@2x.png", idiom: "ipad", pointSize: 40, pixelSize: 80, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-ipad-76@1x.png", idiom: "ipad", pointSize: 76, pixelSize: 76, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-ipad-76@2x.png", idiom: "ipad", pointSize: 76, pixelSize: 152, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-ipad-83.5@2x.png", idiom: "ipad", pointSize: 83.5, pixelSize: 167, scale: "2x", role: nil, subtype: nil),

        .init(filename: "appicon-appstore-1024.png", idiom: "ios-marketing", pointSize: 1024, pixelSize: 1024, scale: "1x", role: nil, subtype: nil),

        .init(filename: "appicon-mac-16@1x.png", idiom: "mac", pointSize: 16, pixelSize: 16, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-16@2x.png", idiom: "mac", pointSize: 16, pixelSize: 32, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-32@1x.png", idiom: "mac", pointSize: 32, pixelSize: 32, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-32@2x.png", idiom: "mac", pointSize: 32, pixelSize: 64, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-128@1x.png", idiom: "mac", pointSize: 128, pixelSize: 128, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-128@2x.png", idiom: "mac", pointSize: 128, pixelSize: 256, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-256@1x.png", idiom: "mac", pointSize: 256, pixelSize: 256, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-256@2x.png", idiom: "mac", pointSize: 256, pixelSize: 512, scale: "2x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-512@1x.png", idiom: "mac", pointSize: 512, pixelSize: 512, scale: "1x", role: nil, subtype: nil),
        .init(filename: "appicon-mac-512@2x.png", idiom: "mac", pointSize: 512, pixelSize: 1024, scale: "2x", role: nil, subtype: nil)
    ]

    func render(size: CGFloat) throws -> NSImage {
        guard let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            throw IconRendererError.missingSymbol(symbolName)
        }

        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let padding = size * contentPaddingRatio
        let iconRect = NSRect(x: padding, y: padding, width: size - (padding * 2), height: size - (padding * 2))
        let cornerRadius = iconRect.width * cornerRadiusRatio
        let bezierPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)

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

        let symbolRect = centeredRect(for: tintedSymbol.size, canvasRect: iconRect)
        tintedSymbol.draw(in: symbolRect)

        image.unlockFocus()
        return image
    }

    func exportAppIconSet(named iconSetName: String, to folderURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let appIconSetURL = folderURL.appendingPathComponent(iconSetName, isDirectory: true)

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
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw IconRendererError.failedBitmapCreation(pixelSize)
        }

        bitmap.size = NSSize(width: pixelSize, height: pixelSize)

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current = context
        context?.imageInterpolation = .high
        image.draw(
            in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        context?.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw IconRendererError.failedPNGEncoding(fileURL.lastPathComponent)
        }

        try pngData.write(to: fileURL)
    }

    private func centeredRect(for symbolSize: NSSize, canvasRect: NSRect) -> NSRect {
        let width = canvasRect.width * symbolScaleRatio
        let aspectRatio = symbolSize.height == 0 ? 1 : symbolSize.width / symbolSize.height
        let height = width / max(aspectRatio, 0.01)
        let originX = canvasRect.midX - (width / 2)
        let originY = canvasRect.midY - (height / 2)
        return NSRect(x: originX, y: originY, width: width, height: height)
    }

    private func makeContentsJSON() -> String {
        let images = specs.map { spec in
            var fields = [
                "\"filename\" : \"\(spec.filename)\"",
                "\"idiom\" : \"\(spec.idiom)\"",
                "\"scale\" : \"\(spec.scale)\"",
                "\"size\" : \"\(formattedPointSize(spec.pointSize))x\(formattedPointSize(spec.pointSize))\""
            ]

            if let role = spec.role {
                fields.append("\"role\" : \"\(role)\"")
            }

            if let subtype = spec.subtype {
                fields.append("\"subtype\" : \"\(subtype)\"")
            }

            let body = fields.map { "        \($0)" }.joined(separator: ",\n")
            return """
                  {
            \(body)
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

    private func formattedPointSize(_ size: Double) -> String {
        if size.rounded() == size {
            return String(Int(size))
        }

        return String(size)
    }
}
