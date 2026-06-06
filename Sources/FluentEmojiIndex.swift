import Foundation

struct FluentEmojiAsset: Identifiable, Hashable {
    var id: String { imageURL.path }
    let name: String
    let imageURL: URL
}

enum FluentEmojiStyle: String, CaseIterable, Codable, Identifiable {
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

struct FluentEmojiIndex: Codable {
    struct Entry: Codable {
        let name: String
        let assetPathsByStyle: [FluentEmojiStyle.RawValue: String]
    }

    let folderPath: String
    let entries: [Entry]

    var assetCount: Int { entries.count }

    static func indexExists(for folderPath: String) -> Bool {
        let trimmedPath = folderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: indexFileURL(for: trimmedPath).path)
    }

    static func removeIndex(for folderPath: String) {
        let trimmedPath = folderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return }

        let fileURL = indexFileURL(for: trimmedPath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func load(folderPath: String) -> FluentEmojiIndex? {
        let trimmedPath = folderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty,
              let data = try? Data(contentsOf: indexFileURL(for: trimmedPath)),
              let index = try? JSONDecoder().decode(FluentEmojiIndex.self, from: data),
              index.folderPath == trimmedPath,
              !index.entries.isEmpty else {
            return nil
        }

        return index
    }

    func save() throws {
        let fileURL = Self.indexFileURL(for: folderPath)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL, options: .atomic)
    }

    func assets(for style: FluentEmojiStyle) -> [FluentEmojiAsset] {
        entries.compactMap { entry in
            guard let path = entry.assetPathsByStyle[style.rawValue] else { return nil }
            return FluentEmojiAsset(name: entry.name, imageURL: URL(fileURLWithPath: path))
        }
    }

    static func folderExists(at folderPath: String) -> Bool {
        let trimmedPath = folderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return false }

        let assetsURL = URL(fileURLWithPath: trimmedPath, isDirectory: true)
            .appendingPathComponent("assets", isDirectory: true)
        var isDirectory: ObjCBool = false

        return FileManager.default.fileExists(atPath: assetsURL.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    static func build(folderPath: String) -> FluentEmojiIndex? {
        let trimmedPath = folderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard folderExists(at: trimmedPath) else { return nil }

        let fileManager = FileManager.default
        let assetsURL = URL(fileURLWithPath: trimmedPath, isDirectory: true)
            .appendingPathComponent("assets", isDirectory: true)

        guard let emojiFolders = try? fileManager.contentsOfDirectory(
            at: assetsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let entries = emojiFolders.compactMap { emojiFolder -> Entry? in
            guard (try? emojiFolder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
                return nil
            }

            var assetPathsByStyle: [FluentEmojiStyle.RawValue: String] = [:]
            for style in FluentEmojiStyle.allCases {
                if let imageURL = bestImageURL(in: emojiFolder, style: style) {
                    assetPathsByStyle[style.rawValue] = imageURL.path
                }
            }

            guard !assetPathsByStyle.isEmpty else { return nil }
            return Entry(name: emojiFolder.lastPathComponent, assetPathsByStyle: assetPathsByStyle)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        guard !entries.isEmpty else { return nil }
        return FluentEmojiIndex(folderPath: trimmedPath, entries: entries)
    }

    private static func indexFileURL(for folderPath: String) -> URL {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupportURL
            .appendingPathComponent("SwiftIconGenerator", isDirectory: true)
            .appendingPathComponent("FluentEmojiIndexes", isDirectory: true)
            .appendingPathComponent("\(stableHash(folderPath)).json")
    }

    private static func stableHash(_ value: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325

        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }

        return String(hash, radix: 16)
    }

    private static func bestImageURL(in emojiFolder: URL, style: FluentEmojiStyle) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: emojiFolder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let urls = enumerator.compactMap { item -> URL? in
            guard let url = item as? URL,
                  url.pathExtension.localizedCaseInsensitiveCompare(style.fileExtension) == .orderedSame,
                  url.path.lowercased().contains("/\(style.folderName.lowercased())/"),
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                return nil
            }

            return url
        }

        return urls.sorted { lhs, rhs in
            imageRank(lhs, style: style) < imageRank(rhs, style: style)
        }.first
    }

    private static func imageRank(_ url: URL, style: FluentEmojiStyle) -> Int {
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
}
