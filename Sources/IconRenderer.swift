import AppKit
import Foundation

struct IconRenderer {
    enum IconContent {
        case symbol(String)
        case emoji(String)
        case image(URL, isTemplate: Bool)
    }

    enum ExportPlatform: String, CaseIterable, Hashable {
        case iphone
        case ipad
        case appStore
        case mac

        var title: String {
            switch self {
            case .iphone:
                return "iPhone"
            case .ipad:
                return "iPad"
            case .appStore:
                return "App Store"
            case .mac:
                return "macOS"
            }
        }
    }

    struct IconSpec {
        let filename: String
        let idiom: String
        let pointSize: Double
        let pixelSize: Int
        let scale: String
        let platform: ExportPlatform
        let role: String?
        let subtype: String?
    }

    enum IconRendererError: LocalizedError {
        case missingSymbol(String)
        case missingEmoji
        case failedBitmapCreation(Int)
        case failedPNGEncoding(String)

        var errorDescription: String? {
            switch self {
            case .missingSymbol(let symbol):
                return "SF Symbol '\(symbol)' was not found."
            case .missingEmoji:
                return "Emoji content is empty."
            case .failedBitmapCreation(let size):
                return "Failed to create bitmap for size \(size)x\(size)."
            case .failedPNGEncoding(let filename):
                return "Failed to encode PNG for \(filename)."
            }
        }
    }

    let content: IconContent
    let foregroundColor: NSColor
    let secondaryForegroundColor: NSColor
    let useForegroundGradient: Bool
    let foregroundGradientAngle: Double
    let backgroundColor: NSColor
    let secondaryBackgroundColor: NSColor
    let useGradient: Bool
    let backgroundGradientAngle: Double
    let cornerRadiusRatio: Double
    let contentPaddingRatio: Double
    let symbolScaleRatio: Double
    let contentOffsetXRatio: Double
    let contentOffsetYRatio: Double
    let shadowStrength: Double
    let shadowAngle: Double

    private let specs: [IconSpec] = [
        .init(filename: "appicon-iphone-20@2x.png", idiom: "iphone", pointSize: 20, pixelSize: 40, scale: "2x", platform: .iphone, role: nil, subtype: nil),
        .init(filename: "appicon-iphone-20@3x.png", idiom: "iphone", pointSize: 20, pixelSize: 60, scale: "3x", platform: .iphone, role: nil, subtype: nil),
        .init(filename: "appicon-iphone-29@2x.png", idiom: "iphone", pointSize: 29, pixelSize: 58, scale: "2x", platform: .iphone, role: nil, subtype: nil),
        .init(filename: "appicon-iphone-29@3x.png", idiom: "iphone", pointSize: 29, pixelSize: 87, scale: "3x", platform: .iphone, role: nil, subtype: nil),
        .init(filename: "appicon-iphone-40@2x.png", idiom: "iphone", pointSize: 40, pixelSize: 80, scale: "2x", platform: .iphone, role: nil, subtype: nil),
        .init(filename: "appicon-iphone-40@3x.png", idiom: "iphone", pointSize: 40, pixelSize: 120, scale: "3x", platform: .iphone, role: nil, subtype: nil),
        .init(filename: "appicon-iphone-60@2x.png", idiom: "iphone", pointSize: 60, pixelSize: 120, scale: "2x", platform: .iphone, role: nil, subtype: nil),
        .init(filename: "appicon-iphone-60@3x.png", idiom: "iphone", pointSize: 60, pixelSize: 180, scale: "3x", platform: .iphone, role: nil, subtype: nil),

        .init(filename: "appicon-ipad-20@1x.png", idiom: "ipad", pointSize: 20, pixelSize: 20, scale: "1x", platform: .ipad, role: nil, subtype: nil),
        .init(filename: "appicon-ipad-20@2x.png", idiom: "ipad", pointSize: 20, pixelSize: 40, scale: "2x", platform: .ipad, role: nil, subtype: nil),
        .init(filename: "appicon-ipad-29@1x.png", idiom: "ipad", pointSize: 29, pixelSize: 29, scale: "1x", platform: .ipad, role: nil, subtype: nil),
        .init(filename: "appicon-ipad-29@2x.png", idiom: "ipad", pointSize: 29, pixelSize: 58, scale: "2x", platform: .ipad, role: nil, subtype: nil),
        .init(filename: "appicon-ipad-40@1x.png", idiom: "ipad", pointSize: 40, pixelSize: 40, scale: "1x", platform: .ipad, role: nil, subtype: nil),
        .init(filename: "appicon-ipad-40@2x.png", idiom: "ipad", pointSize: 40, pixelSize: 80, scale: "2x", platform: .ipad, role: nil, subtype: nil),
        .init(filename: "appicon-ipad-76@1x.png", idiom: "ipad", pointSize: 76, pixelSize: 76, scale: "1x", platform: .ipad, role: nil, subtype: nil),
        .init(filename: "appicon-ipad-76@2x.png", idiom: "ipad", pointSize: 76, pixelSize: 152, scale: "2x", platform: .ipad, role: nil, subtype: nil),
        .init(filename: "appicon-ipad-83.5@2x.png", idiom: "ipad", pointSize: 83.5, pixelSize: 167, scale: "2x", platform: .ipad, role: nil, subtype: nil),

        .init(filename: "appicon-appstore-1024.png", idiom: "ios-marketing", pointSize: 1024, pixelSize: 1024, scale: "1x", platform: .appStore, role: nil, subtype: nil),

        .init(filename: "appicon-mac-16@1x.png", idiom: "mac", pointSize: 16, pixelSize: 16, scale: "1x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-16@2x.png", idiom: "mac", pointSize: 16, pixelSize: 32, scale: "2x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-32@1x.png", idiom: "mac", pointSize: 32, pixelSize: 32, scale: "1x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-32@2x.png", idiom: "mac", pointSize: 32, pixelSize: 64, scale: "2x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-128@1x.png", idiom: "mac", pointSize: 128, pixelSize: 128, scale: "1x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-128@2x.png", idiom: "mac", pointSize: 128, pixelSize: 256, scale: "2x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-256@1x.png", idiom: "mac", pointSize: 256, pixelSize: 256, scale: "1x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-256@2x.png", idiom: "mac", pointSize: 256, pixelSize: 512, scale: "2x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-512@1x.png", idiom: "mac", pointSize: 512, pixelSize: 512, scale: "1x", platform: .mac, role: nil, subtype: nil),
        .init(filename: "appicon-mac-512@2x.png", idiom: "mac", pointSize: 512, pixelSize: 1024, scale: "2x", platform: .mac, role: nil, subtype: nil)
    ]

    func render(size: CGFloat) throws -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let padding = size * contentPaddingRatio
        let iconRect = NSRect(x: padding, y: padding, width: size - (padding * 2), height: size - (padding * 2))
        let cornerRadius = iconRect.width * cornerRadiusRatio
        let bezierPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSGraphicsContext.current?.imageInterpolation = .high

        if useGradient {
            let gradient = NSGradient(colors: [backgroundColor, secondaryBackgroundColor])
            gradient?.draw(in: bezierPath, angle: backgroundGradientAngle)
        } else {
            backgroundColor.setFill()
            bezierPath.fill()
        }

        switch content {
        case .symbol(let symbolName):
            guard let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
                throw IconRendererError.missingSymbol(symbolName)
            }

            let symbolConfig = NSImage.SymbolConfiguration(pointSize: size * symbolScaleRatio, weight: .bold)
            let configuredSymbol = symbolImage.withSymbolConfiguration(symbolConfig) ?? symbolImage
            let tintedSymbol = configuredSymbol.withSymbolConfiguration(.init(paletteColors: [foregroundColor])) ?? configuredSymbol
            let symbolRect = offsetRect(centeredRect(for: tintedSymbol.size, canvasRect: iconRect), in: iconRect)

            if !useForegroundGradient {
                setContentShadow(size: size)
                tintedSymbol.draw(in: symbolRect)
                return finish(image: image)
            }

            let foregroundSymbol = makeGradientSymbolImage(
                size: size,
                symbol: tintedSymbol,
                symbolRect: symbolRect
            )

            setContentShadow(size: size)
            foregroundSymbol.draw(in: NSRect(x: 0, y: 0, width: size, height: size))

        case .emoji(let emoji):
            let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedEmoji.isEmpty else {
                throw IconRendererError.missingEmoji
            }

            let emojiRect = offsetRect(centeredSquareRect(in: iconRect, ratio: symbolScaleRatio), in: iconRect)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: emojiRect.height * 0.84),
                .paragraphStyle: paragraphStyle
            ]

            let attributedEmoji = NSAttributedString(string: trimmedEmoji, attributes: attributes)
            let textBounds = attributedEmoji.boundingRect(
                with: emojiRect.size,
                options: [.usesLineFragmentOrigin, .usesFontLeading]
            )

            let drawRect = NSRect(
                x: emojiRect.minX,
                y: emojiRect.midY - (textBounds.height / 2),
                width: emojiRect.width,
                height: textBounds.height
            )

            setContentShadow(size: size)
            attributedEmoji.draw(in: drawRect)

        case .image(let imageURL, let isTemplate):
            guard let sourceImage = NSImage(contentsOf: imageURL), sourceImage.isValid else {
                throw IconRendererError.missingEmoji
            }

            let imageRect = offsetRect(centeredSquareRect(in: iconRect, ratio: symbolScaleRatio), in: iconRect)
            let drawRect = aspectFitRect(for: sourceImage.size, in: imageRect)

            if isTemplate {
                let foregroundImage = makeGradientSymbolImage(
                    size: size,
                    symbol: sourceImage,
                    symbolRect: drawRect
                )
                setContentShadow(size: size)
                foregroundImage.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
                break
            }

            setContentShadow(size: size)
            sourceImage.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)
        }

        return finish(image: image)
    }

    private func finish(image: NSImage) -> NSImage {
        image.unlockFocus()
        return image
    }

    func exportAppIconSet(named iconSetName: String, platforms: Set<ExportPlatform>, to folderURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let appIconSetURL = folderURL.appendingPathComponent(iconSetName, isDirectory: true)
        let filteredSpecs = specs.filter { platforms.contains($0.platform) }

        if fileManager.fileExists(atPath: appIconSetURL.path) {
            try fileManager.removeItem(at: appIconSetURL)
        }

        try fileManager.createDirectory(at: appIconSetURL, withIntermediateDirectories: true)

        for spec in filteredSpecs {
            let image = try render(size: CGFloat(spec.pixelSize))
            let fileURL = appIconSetURL.appendingPathComponent(spec.filename)
            try writePNG(image: image, to: fileURL, pixelSize: spec.pixelSize)
        }

        let contents = makeContentsJSON(specs: filteredSpecs)
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

    private func offsetRect(_ rect: NSRect, in canvasRect: NSRect) -> NSRect {
        rect.offsetBy(
            dx: canvasRect.width * contentOffsetXRatio,
            dy: canvasRect.height * contentOffsetYRatio
        )
    }

    private func setContentShadow(size: CGFloat) {
        guard shadowStrength > 0 else { return }

        let shadow = NSShadow()
        let distance = size * 0.025
        let radians = shadowAngle * .pi / 180
        shadow.shadowColor = NSColor.black.withAlphaComponent(shadowStrength * 0.7)
        shadow.shadowOffset = NSSize(width: CGFloat(Darwin.cos(radians)) * distance, height: CGFloat(Darwin.sin(radians)) * distance)
        shadow.shadowBlurRadius = size * 0.06
        shadow.set()
    }

    private func makeGradientSymbolImage(size: CGFloat, symbol: NSImage, symbolRect: NSRect) -> NSImage {
        let renderScale: CGFloat = size < 512 ? 2 : 1
        let pixelWidth = max(1, Int((size * renderScale).rounded(.up)))
        let pixelHeight = pixelWidth
        let bytesPerPixel = 4
        let bytesPerRow = pixelWidth * bytesPerPixel
        let byteCount = pixelHeight * bytesPerRow
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let startColor = foregroundColor.usingColorSpace(.deviceRGB) ?? foregroundColor
        let endSourceColor = useForegroundGradient ? secondaryForegroundColor : foregroundColor
        let endColor = endSourceColor.usingColorSpace(.deviceRGB) ?? endSourceColor
        let imageSize = NSSize(width: size, height: size)
        let scaledSymbolRect = NSRect(
            x: symbolRect.minX * renderScale,
            y: symbolRect.minY * renderScale,
            width: symbolRect.width * renderScale,
            height: symbolRect.height * renderScale
        )
        var maskPixels = [UInt8](repeating: 0, count: byteCount)
        var imagePixels = [UInt8](repeating: 0, count: byteCount)

        let maskCreated = maskPixels.withUnsafeMutableBytes { maskBytes in
            guard let maskBaseAddress = maskBytes.baseAddress,
                  let maskContext = CGContext(
                    data: maskBaseAddress,
                    width: pixelWidth,
                    height: pixelHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                  ) else {
                return false
            }

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: maskContext, flipped: false)
            symbol.draw(in: scaledSymbolRect, from: .zero, operation: .sourceOver, fraction: 1)
            maskContext.flush()
            NSGraphicsContext.restoreGraphicsState()
            return true
        }

        guard maskCreated else {
            return NSImage(size: imageSize)
        }

        for y in 0..<pixelHeight {
            for x in 0..<pixelWidth {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let alpha = CGFloat(maskPixels[offset + 3]) / 255

                guard alpha > 0 else {
                    imagePixels[offset] = 0
                    imagePixels[offset + 1] = 0
                    imagePixels[offset + 2] = 0
                    imagePixels[offset + 3] = 0
                    continue
                }

                let point = NSPoint(x: CGFloat(x), y: CGFloat(y))
                let progress = gradientProgress(at: point, in: scaledSymbolRect)
                let color = interpolatedColor(from: startColor, to: endColor, progress: progress)
                let red = color.redComponent * alpha
                let green = color.greenComponent * alpha
                let blue = color.blueComponent * alpha

                imagePixels[offset] = UInt8((red * 255).rounded())
                imagePixels[offset + 1] = UInt8((green * 255).rounded())
                imagePixels[offset + 2] = UInt8((blue * 255).rounded())
                imagePixels[offset + 3] = UInt8((alpha * 255).rounded())
            }
        }

        return imagePixels.withUnsafeMutableBytes { imageBytes in
            guard let imageBaseAddress = imageBytes.baseAddress,
                  let imageContext = CGContext(
                    data: imageBaseAddress,
                    width: pixelWidth,
                    height: pixelHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                  ),
                  let cgImage = imageContext.makeImage() else {
                return NSImage(size: imageSize)
            }

            return NSImage(cgImage: cgImage, size: imageSize)
        }
    }

    private func gradientProgress(at point: NSPoint, in rect: NSRect) -> CGFloat {
        let radians = foregroundGradientAngle * .pi / 180
        let direction = CGPoint(x: CGFloat(Darwin.cos(radians)), y: CGFloat(Darwin.sin(radians)))
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        let projections = corners.map { ($0.x * direction.x) + ($0.y * direction.y) }
        let minProjection = projections.min() ?? 0
        let maxProjection = projections.max() ?? 1
        let pointProjection = (point.x * direction.x) + (point.y * direction.y)
        let progress = (pointProjection - minProjection) / max(maxProjection - minProjection, 1)
        return min(max(progress, 0), 1)
    }

    private func interpolatedColor(from start: NSColor, to end: NSColor, progress: CGFloat) -> NSColor {
        let red = start.redComponent + ((end.redComponent - start.redComponent) * progress)
        let green = start.greenComponent + ((end.greenComponent - start.greenComponent) * progress)
        let blue = start.blueComponent + ((end.blueComponent - start.blueComponent) * progress)
        return NSColor(deviceRed: red, green: green, blue: blue, alpha: 1)
    }

    private func centeredSquareRect(in canvasRect: NSRect, ratio: Double) -> NSRect {
        let edge = min(canvasRect.width, canvasRect.height) * ratio
        return NSRect(
            x: canvasRect.midX - (edge / 2),
            y: canvasRect.midY - (edge / 2),
            width: edge,
            height: edge
        )
    }

    private func aspectFitRect(for imageSize: NSSize, in rect: NSRect) -> NSRect {
        let aspectRatio = imageSize.height == 0 ? 1 : imageSize.width / imageSize.height
        var width = rect.width
        var height = width / max(aspectRatio, 0.01)

        if height > rect.height {
            height = rect.height
            width = height * max(aspectRatio, 0.01)
        }

        return NSRect(
            x: rect.midX - (width / 2),
            y: rect.midY - (height / 2),
            width: width,
            height: height
        )
    }

    private func makeContentsJSON(specs: [IconSpec]) -> String {
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
