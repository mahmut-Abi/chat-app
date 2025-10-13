# iOS 玻璃质感效果实现指南

## 概述

本项目已实现完整的 iOS 玻璃质感(Frosted Glass/Glass Morphism)效果,支持 iOS 26+ 系统。玻璃质感使用了 BackdropFilter 和渐变色等技术,为应用提供现代化的视觉体验。

## 核心组件

### GlassContainer

主要的玻璃质感容器组件,支持自定义参数:

```dart
GlassContainer(
  blur: 20.0,              // 模糊强度
  opacity: 0.15,            // 背景透明度
  borderRadius: BorderRadius.circular(12),
  enableShadow: true,       // 启用阴影
  backgroundColor: Colors.white,  // 自定义背景色
  child: YourWidget(),
)
```

**参数说明:**

- `blur`: 背景模糊程度 (0-30),默认 20.0
- `opacity`: 背景颜色透明度 (0-1),默认 0.15
- `borderRadius`: 圆角半径
- `border`: 自定义边框
- `padding`: 内边距
- `backgroundColor`: 自定义背景色,默认根据主题自动适配
- `enableShadow`: 是否启用阴影效果,默认 true

### GlassCard

预设样式的玻璃卡片组件,适合快速使用:

```dart
GlassCard(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(8),
  child: YourContent(),
)
```

## iOS 平台配置

### 1. Info.plist 配置

已在 `ios/Runner/Info.plist` 中添加必要配置:

```xml
<!-- 启用 iOS 毛玻璃效果 -->
<key>UIViewControllerBasedStatusBarAppearance</key>
<false/>
<key>UIStatusBarStyle</key>
<string>UIStatusBarStyleLightContent</string>
```

### 2. AppDelegate 配置

已在 `ios/Runner/AppDelegate.swift` 中进行优化:

```swift
if let window = self.window {
  // 设置窗口透明度,支持毛玻璃效果
  window.backgroundColor = UIColor.clear
  window.isOpaque = false
  
  // 启用深色模式支持
  if #available(iOS 13.0, *) {
    window.overrideUserInterfaceStyle = .unspecified
  }
}
```

## 使用示例

### 1. 输入区域

```dart
GlassContainer(
  blur: 15.0,
  opacity: 0.15,
  padding: const EdgeInsets.all(16),
  border: Border(
    top: BorderSide(color: Theme.of(context).dividerColor),
  ),
  child: TextField(...),
)
```

### 2. 功能卡片

```dart
GlassContainer(
  blur: 10.0,
  opacity: 0.1,
  borderRadius: BorderRadius.circular(8),
  enableShadow: false,
  child: InkWell(
    onTap: onPressed,
    child: Column(
      children: [
        Icon(icon),
        Text(label),
      ],
    ),
  ),
)
```

### 3. 对话框和浮层

```dart
GlassCard(
  padding: EdgeInsets.all(24),
  child: Column(
    children: [
      Text('Dialog Title'),
      // ... content
    ],
  ),
)
```

## 平台差异

### iOS 平台

- 使用完整的 BackdropFilter 实现
- 支持渐变色背景增强玻璃质感
- 默认启用阴影效果
- 模糊效果更强,视觉效果最佳

### 其他平台 (Android, Web, Desktop)

- 使用降低强度的 BackdropFilter
- 半透明背景色
- 模糊强度为 iOS 的 50%
- 自动适配明暗主题

## 性能优化

1. **避免过度使用**: 不要在列表的每个项目上都使用玻璃效果
2. **合理设置模糊值**: 模糊值越大,性能开销越大
3. **禁用不必要的阴影**: 对于小组件可以设置 `enableShadow: false`
4. **使用 RepaintBoundary**: 对于复杂的玻璃容器,考虑包裹 RepaintBoundary

```dart
RepaintBoundary(
  child: GlassContainer(
    child: ComplexWidget(),
  ),
)
```

## 主题适配

GlassContainer 会自动根据当前主题(明暗模式)调整:

- **亮色主题**: 白色半透明背景 + 黑色淡边框
- **暗色主题**: 黑色半透明背景 + 白色淡边框

可以通过 `backgroundColor` 参数自定义背景色:

```dart
GlassContainer(
  backgroundColor: Colors.blue.withValues(alpha: 0.2),
  child: ...,
)
```

## 最佳实践

1. **输入框和工具栏**: 使用中等模糊 (blur: 15-20)
2. **卡片组件**: 使用轻度模糊 (blur: 10-15)
3. **对话框**: 使用强模糊 (blur: 25-30)
4. **小组件**: 禁用阴影以提升性能
5. **深色背景**: 增加 opacity 以提升可读性

## 常见问题

### Q: 为什么在 Android 上效果不如 iOS?

A: 这是平台特性差异。iOS 对 BackdropFilter 的支持和渲染效果更好。为了保持跨平台一致性,在非 iOS 平台使用了降低强度的实现。

### Q: 如何调整玻璃效果的强度?

A: 通过调整 `blur` 和 `opacity` 参数:
- 增加 blur 值可以增强模糊效果
- 降低 opacity 值可以增加透明度

### Q: 玻璃效果影响性能吗?

A: 有一定性能开销,特别是在复杂布局中。建议:
- 避免在滚动列表中大量使用
- 对于静态内容可以放心使用
- 使用 `enableShadow: false` 减少开销

## 未来改进

- [ ] 支持动态模糊强度动画
- [ ] 添加更多预设样式 (GlassButton, GlassAppBar 等)
- [ ] 优化 Android 平台的渲染性能
- [ ] 支持自定义渐变方向和颜色
