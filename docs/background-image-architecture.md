# 背景图片架构说明

## 架构概览

### 三层结构

```
BackgroundContainer (全局背景层)
        ↓
  MaterialApp.router (路由层)
        ↓
    Scaffold (页面层 - 透明)
```

## 核心组件

### 1. BackgroundContainer (全局背景容器)

**位置**: `lib/shared/widgets/background_container.dart`  
**作用**: 在MaterialApp外层提供全局背景图片支持

**关键特性**:
- 使用Stack布局，背景图在最底层
- 监听appSettingsProvider的背景设置变化
- 支持assets和本地文件路径
- 背景不透明度可调节(0.0-1.0)
- 性能优化：缓存背景widget + RepaintBoundary

**代码结构**:
```dart
Stack(
  children: [
    RepaintBoundary(  // 优化重绘
      child: 背景图 + 遮罩层
    ),
    widget.child,  // MaterialApp及所有页面
  ],
)
```

### 2. 页面透明度设置

**所有Scaffold配置**:
```dart
Scaffold(
  backgroundColor: Colors.transparent,  // 透明，让背景图穿透
  appBar: AppBar(
    backgroundColor: Colors.transparent,  // AppBar也透明
    elevation: 0,
  ),
)
```

**目的**: 让BackgroundContainer的背景图能够穿透到所有页面

### 3. iOS页面转场优化

**位置**: `lib/core/routing/app_router.dart`

**问题**: iOS的Cupertino转场在透明背景下会导致新旧页面重叠

**解决方案**: 使用CustomTransitionPage + SlideTransition

```dart
if (PlatformUtils.isIOS) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 自定义右滑进入动画
      return SlideTransition(
        position: animation.drive(
          Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        ),
        child: child,
      );
    },
  );
}
```

**优势**:
- ✅ 转场动画流畅，无重叠
- ✅ 符合iOS人机界面规范
- ✅ 背景图片始终可见
- ✅ 性能优化，不触发额外重建

## 背景图片设置流程

### 用户设置流程

```
用户在设置页面选择背景图
        ↓
  StorageService保存配置
        ↓
appSettingsProvider通知变化
        ↓
BackgroundContainer重建
        ↓
  清除缓存，加载新背景
        ↓
  所有页面自动显示新背景
```

### 关键代码位置

**设置保存**:
- `lib/features/settings/presentation/widgets/improved_background_settings.dart`
- 调用 `settingsRepo.updateBackgroundImage(path, opacity)`

**配置存储**:
- `lib/features/settings/domain/api_config.dart` - AppSettings数据类
- `lib/core/storage/storage_service.dart` - Hive持久化

**背景渲染**:
- `lib/shared/widgets/background_container.dart` - 渲染逻辑

## 背景图片显示范围

### ✅ 背景图可见的界面

所有使用透明Scaffold的页面（即全部页面）：

**聊天相关**:
- HomeScreen (主页)
- ChatScreen (对话界面)

**设置相关**:
- ModernSettingsScreen (设置主页)
- ApiConfigScreen (API配置)
- BackgroundSettingsScreen (背景设置)

**其他功能**:
- ModelsScreen (模型管理)
- PromptsScreen (提示词管理)
- McpScreen (MCP配置)
- LogsScreen (日志查看)
- TokenUsageScreen (Token统计)
- AgentScreen (Agent管理)

### 透明度说明

**backgroundOpacity 参数含义**:
- `0.0` = 背景完全不可见（内容100%不透明）
- `0.5` = 背景50%可见（内容层50%遮罩）
- `0.8` = 背景80%可见（内容层20%遮罩）**默认值**
- `1.0` = 背景完全可见（内容完全透明）

**实现**:
```dart
final contentOverlayOpacity = 1.0 - backgroundOpacity;
// 在背景图上叠加一层半透明遮罩
```

## 性能优化机制

### 1. 缓存机制
```dart
Widget? _cachedBackgroundStack;

// 只在设置变化时重建
if (needsRebuild) {
  _cachedBackgroundStack = null;
}
```

### 2. RepaintBoundary
```dart
RepaintBoundary(
  child: _cachedBackgroundStack!,
)
```
隔离背景层重绘，避免影响页面内容

### 3. 条件渲染
```dart
// 没有背景图时直接返回child，不构建Stack
if (backgroundImage == null || backgroundImage.isEmpty) {
  return widget.child;
}
```

## iOS特殊处理

### 问题根源
- iOS的Cupertino转场会同时显示新旧两个页面
- 透明Scaffold + Stack背景 = 三层叠加
- 视觉上出现页面重叠和混乱

### 解决方案
使用`CustomTransitionPage`实现自定义转场动画：
- ✅ 右滑进入/退出动画（符合iOS规范）
- ✅ 动画期间不透明，避免重叠
- ✅ 动画完成后保持透明，背景图可见
- ✅ 使用Curves.easeInOut，流畅自然

### Android平台
继续使用MaterialPage的默认转场，无需特殊处理。

## 测试验证

### 功能测试
1. ✅ 设置背景图片后，所有页面都能看到
2. ✅ 调节透明度，背景图亮度正确变化
3. ✅ 移除背景图，显示主题默认背景色
4. ✅ 深浅色主题切换，背景遮罩层正确调整

### iOS转场测试
1. ✅ 主页 → 聊天页面（无重叠）
2. ✅ 聊天页面间快速切换（流畅）
3. ✅ 返回主页（背景图一直可见）
4. ✅ 打开设置、模型等页面（背景图可见）
5. ✅ 抽屉打开/关闭（无异常）

### 性能测试
1. ✅ 背景图只加载一次，切换页面不重复加载
2. ✅ RepaintBoundary隔离重绘区域
3. ✅ 帧率保持60fps

## 相关文件

**核心架构**:
- `lib/main.dart` - BackgroundContainer包裹位置
- `lib/shared/widgets/background_container.dart` - 背景容器实现
- `lib/core/routing/app_router.dart` - iOS转场配置

**设置相关**:
- `lib/features/settings/domain/api_config.dart` - AppSettings数据模型
- `lib/features/settings/presentation/widgets/improved_background_settings.dart` - 背景设置UI

**所有页面**: 11个screen文件使用透明Scaffold

## 最佳实践

### 添加新页面时

**必须**:
```dart
Scaffold(
  backgroundColor: Colors.transparent,  // 必须透明
  appBar: AppBar(
    backgroundColor: Colors.transparent,  // AppBar也透明
    elevation: 0,
  ),
)
```

**路由配置**:
```dart
GoRoute(
  path: '/new-page',
  pageBuilder: (context, state) => _buildPage(
    context, state, const NewPage(),
  ),
)
```
使用pageBuilder而不是builder，让iOS自动使用自定义转场。

## 故障排除

### 背景图不显示
1. 检查Scaffold是否设置为transparent
2. 检查AppBar是否设置为transparent
3. 检查backgroundOpacity是否为0（完全不可见）
4. 检查图片路径是否正确

### iOS页面重叠
1. 检查是否使用了pageBuilder（而不是builder）
2. 检查_buildPage方法是否正确实现
3. 检查是否导入了platform_utils

### 性能问题
1. 检查RepaintBoundary是否生效
2. 检查缓存是否正常工作
3. 使用Flutter DevTools分析重绘区域

## 更新日志

**2025-10-18**:
- ✅ 重构iOS转场，使用CustomTransitionPage
- ✅ 恢复所有Scaffold透明背景
- ✅ 确保背景图片在所有页面和AppBar可见
- ✅ 优化BackgroundContainer性能

**2025-10-18 (之前)**:
- 将BackgroundContainer移至MaterialApp外层
- 添加缓存和RepaintBoundary优化

## 参考文档
- [GoRouter Custom Transitions](https://pub.dev/documentation/go_router/latest/topics/Transitions-topic.html)
- [Flutter SlideTransition](https://api.flutter.dev/flutter/widgets/SlideTransition-class.html)
- [RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
