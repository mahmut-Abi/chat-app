# 背景图片系统文档

## 概述

Chat App 支持自定义背景图片功能，背景图片会在整个应用中生效，包括所有页面（对话界面、设置界面等）和 AppBar。

## 系统架构

### 三层结构

```
BackgroundContainer (最外层)
    ↓
MaterialApp.router
    ↓
各个页面 (HomeScreen, ChatScreen, SettingsScreen 等)
```

### 核心组件

#### 1. BackgroundContainer
**位置**: `lib/shared/widgets/background_container.dart`

**职责**:
- 在应用最外层提供全局背景图片
- 监听背景设置变化并实时更新
- 优化性能：缓存背景 Widget，避免不必要的重建

**实现逻辑**:
```dart
// 无背景图片时
if (backgroundImage == null) {
  return Container(
    color: Theme.of(context).scaffoldBackgroundColor,  // 使用主题背景色
    child: widget.child,
  );
}

// 有背景图片时
return Stack([
  RepaintBoundary(child: 背景图片),
  widget.child,  // 所有页面内容
]);
```

#### 2. 页面透明配置

所有需要显示背景图片的页面都需要设置透明背景：

```dart
Scaffold(
  backgroundColor: Colors.transparent,  // 透明以显示背景
  appBar: AppBar(
    backgroundColor: Colors.transparent,  // AppBar 也透明
    elevation: 0,
  ),
  body: ...
)
```

**已配置透明的页面**:
- ✅ `HomeScreen` - 主页
- ✅ `ChatScreen` - 聊天界面
- ✅ `ModernSettingsScreen` - 设置界面
- ✅ 所有 AppBar

#### 3. AppSettings
**位置**: `lib/features/settings/domain/api_config.dart`

**背景相关字段**:
```dart
class AppSettings {
  final String? backgroundImage;      // 背景图片路径
  final double backgroundOpacity;     // 背景可见度 (0.0-1.0)
}
```

**backgroundOpacity 含义**:
- `0.0` = 背景完全不可见（内容完全不透明）
- `0.5` = 背景 50% 可见
- `0.8` = 背景 80% 可见（默认值）
- `1.0` = 背景完全可见（内容完全透明）

**实现原理**:
```dart
final contentOverlayOpacity = 1.0 - backgroundOpacity;
Container(
  color: scaffoldBackgroundColor.withValues(alpha: contentOverlayOpacity),
)
```

## 使用方法

### 用户操作

1. **设置背景图片**:
   - 进入「设置」→「外观」→「背景设置」
   - 选择预设背景或上传自定义图片
   - 调整背景可见度滑块
   - 点击「保存」

2. **清除背景图片**:
   - 在背景设置页面点击「清除背景」
   - 或设置页面选择「无背景」

### 开发者操作

#### 添加新页面时确保背景显示

```dart
class NewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,  // 1. 设置 Scaffold 透明
      appBar: AppBar(
        backgroundColor: Colors.transparent,  // 2. 设置 AppBar 透明
        elevation: 0,                         // 3. 移除阴影
      ),
      body: YourContent(),
    );
  }
}
```

#### 读取背景设置

```dart
final settings = ref.watch(appSettingsProvider);
settings.when(
  data: (settings) {
    final bgImage = settings.backgroundImage;
    final bgOpacity = settings.backgroundOpacity;
    // 使用设置
  },
  loading: () => CircularProgressIndicator(),
  error: (e, s) => ErrorWidget(e),
);
```

#### 更新背景设置

```dart
final settingsNotifier = ref.read(appSettingsProvider.notifier);
await settingsNotifier.updateSettings(
  currentSettings.copyWith(
    backgroundImage: 'path/to/image.jpg',
    backgroundOpacity: 0.8,
  ),
);
```

## 性能优化

### 1. Widget 缓存
```dart
Widget? _cachedBackgroundStack;

// 仅在设置变化时重建
if (needsRebuild) {
  _cachedBackgroundStack = null;
}
_cachedBackgroundStack ??= _buildBackgroundStack();
```

### 2. RepaintBoundary
```dart
RepaintBoundary(
  child: _cachedBackgroundStack,  // 隔离重绘
)
```

### 3. 条件监听
```dart
final needsRebuild = 
    _currentBackgroundImage != settings.backgroundImage ||
    _currentOpacity != settings.backgroundOpacity;
```

## 测试验证

### 手动测试清单

- [ ] 无背景图片时，显示主题背景色（iOS 上不是黑色）
- [ ] 设置背景图片后，所有页面都显示背景
- [ ] AppBar 显示背景图片（透明效果）
- [ ] 对话界面显示背景图片
- [ ] 设置界面显示背景图片
- [ ] 调整背景可见度滑块时，实时预览生效
- [ ] 切换浅色/深色主题时，背景正常显示
- [ ] 清除背景后，恢复主题背景色

### 测试不同的 backgroundOpacity 值

| Opacity | 效果 | 推荐用途 |
|---------|------|----------|
| 0.0-0.3 | 背景几乎不可见 | 需要高对比度的文字内容 |
| 0.4-0.6 | 背景半透明 | 平衡美观和可读性 |
| 0.7-0.9 | 背景较明显 | 美观为主，浅色背景 |
| 1.0 | 背景完全可见 | 仅用于测试或特殊场景 |

## 常见问题

### Q1: iOS 上初始界面显示黑色背景
**原因**: 无背景图片时，`BackgroundContainer` 没有提供默认背景色
**解决**: 已修复，现在无背景时会使用 `Theme.of(context).scaffoldBackgroundColor`

### Q2: 背景图片在某些页面不显示
**原因**: 页面的 Scaffold 或 AppBar 没有设置 `backgroundColor: Colors.transparent`
**解决**: 为该页面的 Scaffold 和 AppBar 添加透明背景

### Q3: 背景可见度调整不生效
**原因**: 可能是缓存问题或设置未正确保存
**解决**: 
1. 检查 `backgroundOpacity` 是否正确保存到 Storage
2. 确认 `BackgroundContainer` 监听了设置变化
3. 查看日志确认设置更新事件

### Q4: 背景图片加载失败
**原因**: 
- 文件路径错误
- 文件被删除
- assets 未正确配置

**解决**: 
1. 检查 `pubspec.yaml` 中 assets 配置
2. 验证文件路径是否存在
3. 查看 errorBuilder 的错误提示

## 代码示例

### 完整的背景设置流程

```dart
// 1. 用户选择背景图片
final result = await FilePicker.platform.pickFiles(
  type: FileType.image,
);

if (result != null) {
  final imagePath = result.files.single.path!;
  
  // 2. 读取当前设置
  final currentSettings = await ref.read(appSettingsProvider.future);
  
  // 3. 更新设置
  final newSettings = currentSettings.copyWith(
    backgroundImage: imagePath,
    backgroundOpacity: 0.8,
  );
  
  // 4. 保存设置（会自动触发 UI 更新）
  await ref.read(appSettingsProvider.notifier).updateSettings(newSettings);
}
```

### 预览背景效果

```dart
Stack(
  fit: StackFit.expand,
  children: [
    // 背景图片
    Image.file(File(imagePath), fit: BoxFit.cover),
    // 遮罩层
    Container(
      color: Colors.white.withValues(alpha: 1.0 - opacity),
    ),
    // 内容
    Center(child: Text('预览效果')),
  ],
)
```

## 相关文件

- `lib/shared/widgets/background_container.dart` - 核心容器
- `lib/features/settings/presentation/background_settings_screen.dart` - 设置页面
- `lib/features/settings/domain/api_config.dart` - 数据模型
- `lib/main.dart` - BackgroundContainer 包裹位置
- `lib/features/chat/presentation/chat_screen.dart` - 聊天页面配置
- `lib/features/chat/presentation/home_screen.dart` - 主页配置
- `lib/features/settings/presentation/modern_settings_screen.dart` - 设置页面配置

## 更新历史

- **2025-01-18**: 修复 iOS 黑色背景问题，为无背景时添加默认背景色
- **2025-01-18**: 确认背景图片功能在所有页面正常工作
- **初始版本**: 实现全局背景图片功能
