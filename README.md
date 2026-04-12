# SFIconGenerator

一个基于 SwiftUI 的 macOS 小工具，用来把 `SF Symbols` 生成为可直接用于 `.app` 的 `AppIcon.appiconset`。

## 功能

- 输入任意 `SF Symbol` 名称
- 内置可搜索的 `SF Symbols` 选择器，支持直接点击选择
- 调整前景色、背景色、渐变、圆角、图标缩放、阴影
- 实时预览导出效果
- 一键导出 macOS `.app` 所需图标尺寸和 `Contents.json`

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

其中包含：

- `icon_16x16.png`
- `icon_16x16@2x.png`
- `icon_32x32.png`
- `icon_32x32@2x.png`
- `icon_128x128.png`
- `icon_128x128@2x.png`
- `icon_256x256.png`
- `icon_256x256@2x.png`
- `icon_512x512.png`
- `icon_512x512@2x.png`
- `Contents.json`

把整个 `AppIcon.appiconset` 拖进 Xcode 的 `Assets.xcassets` 即可。
