# SwiftIconGenerator

Built with GPT-5.4 (OpenCode) via vibe coding.

[中文说明 / Chinese README](./README.zh-CN.md)

SwiftIconGenerator is a macOS SwiftUI app for generating Xcode-ready app icon sets from either `SF Symbols` or `Emoji`.

It is designed for quickly creating polished `AppIcon.appiconset` assets that can be dropped directly into `Assets.xcassets`.

## Features

- Generate icons from `SF Symbols`
- Generate icons from `Emoji`
- Search and pick from a built-in SF Symbols list
- Pick from a built-in emoji list
- Open the macOS system emoji picker
- Live preview at multiple icon sizes
- Tune appearance with:
  - foreground color
  - background color
  - gradient
  - corner radius
  - content padding
  - symbol scale
  - shadow
- Visual size presets: `Compact`, `Balanced`, `Bold`
- Export a named `.appiconset`
- Filter export targets by platform:
  - iPhone
  - iPad
  - App Store
  - macOS

## Export Output

The app exports a complete Xcode-compatible `AppIcon.appiconset` including `Contents.json`.

Example output files:

- `appicon-iphone-60@2x.png`
- `appicon-iphone-60@3x.png`
- `appicon-ipad-76@1x.png`
- `appicon-ipad-76@2x.png`
- `appicon-ipad-83.5@2x.png`
- `appicon-appstore-1024.png`
- `appicon-mac-16@1x.png`
- `appicon-mac-16@2x.png`
- `appicon-mac-32@1x.png`
- `appicon-mac-32@2x.png`
- `appicon-mac-128@1x.png`
- `appicon-mac-128@2x.png`
- `appicon-mac-256@1x.png`
- `appicon-mac-256@2x.png`
- `appicon-mac-512@1x.png`
- `appicon-mac-512@2x.png`
- `Contents.json`

Drop the generated `.appiconset` folder into your Xcode project's `Assets.xcassets`.

## Run

Recommended:

1. Open `SwiftIconGenerator.xcodeproj`
2. Run the `SwiftIconGenerator` scheme in Xcode

The project is configured as a standard macOS app project and includes a proper app icon.

You can also run it from the command line:

```bash
swift run
```

## Usage

1. Choose `SF Symbols` or `Emoji`
2. Select or enter your icon content
3. Adjust appearance settings
4. Choose the icon set name
5. Select export platforms
6. Export the `.appiconset`

## Project Layout

- `SwiftIconGenerator.xcodeproj`: standard macOS Xcode project
- `SwiftIconGenerator/`: app resources such as `Info.plist` and `Assets.xcassets`
- `Sources/`: SwiftUI app source code and icon rendering logic
- `Package.swift`: Swift Package definition for command-line builds

## Notes

- The Xcode project is the primary way to run the app.
- The Swift Package remains available for quick builds and local iteration.
- Emoji rendering uses text drawing, while SF Symbols rendering uses AppKit symbol images.

## License

This project is licensed under the MIT License. See [`LICENSE`](./LICENSE).
