# SwiftIconGenerator

一个基于 SwiftUI 的 macOS 小工具，用来把 `SF Symbols` 或 `Emoji` 生成为可直接用于 Swift/Xcode 项目的 `AppIcon.appiconset`。

项目现在同时包含：

- 标准 macOS Xcode 工程：`SwiftIconGenerator.xcodeproj`
- 原始 Swift Package 结构，便于命令行构建和迭代

## 功能

- 输入任意 `SF Symbol` 名称
- 支持 `Emoji Icon` 输入和常用 emoji 直接选择
- 内置可搜索的 `SF Symbols` 选择器，支持直接点击选择
- 调整前景色、背景色、渐变、圆角、内容留白、图标缩放、阴影
- 实时预览导出效果
- 一键导出适用于 Xcode 的 `AppIcon.appiconset`，覆盖 iPhone、iPad、App Store 和 macOS
- 导出时可按渠道筛选 iPhone、iPad、App Store、macOS

## 运行

推荐方式：

```text
打开 SwiftIconGenerator.xcodeproj
```

然后直接在 Xcode 中运行，工程已绑定标准 `AppIcon` 应用图标。

也可以继续使用命令行：

```bash
swift run
```

命令行方式主要用于快速构建；标准 app 图标和资源绑定以 Xcode 工程为准。

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
