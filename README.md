# SFIconGenerator

一个基于 SwiftUI 的 macOS 小工具，用来把 `SF Symbols` 生成为可直接用于 Swift/Xcode 项目的 `AppIcon.appiconset`。

## 功能

- 输入任意 `SF Symbol` 名称
- 内置可搜索的 `SF Symbols` 选择器，支持直接点击选择
- 调整前景色、背景色、渐变、圆角、内容留白、图标缩放、阴影
- 实时预览导出效果
- 一键导出适用于 Xcode 的 `AppIcon.appiconset`，覆盖 iPhone、iPad、App Store 和 macOS

## 运行

```bash
swift run
```

也可以直接用 Xcode 打开该目录作为 Swift Package 运行。

## 导出结果

导出后会生成：

```text
AppIcon.appiconset/
```

其中包含 Xcode 常用的 app icon 尺寸，例如：

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

把整个 `AppIcon.appiconset` 拖进 Xcode 的 `Assets.xcassets` 即可。
