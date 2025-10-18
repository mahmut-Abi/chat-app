# Bug #041: iOS端页面跳转重叠和延迟问题

## 问题描述
在iOS端跳转页面时出现以下问题：
1. **页面重合** - 新旧页面同时显示，视觉混乱
2. **跳转延迟** - 页面切换不流畅，有卡顿感
3. **背景闪烁** - 透明背景导致的视觉问题

## 根本原因分析

### 1. BackgroundContainer全局化导致的问题 (Commit: 49447e0)

**问题代码位置**: `lib/main.dart`
```dart
return BackgroundContainer(
  child: MaterialApp.router(
    title: 'Chat App',
    routerConfig: AppRouter.router,
  ),
);
```

**问题分析**:
- BackgroundContainer 包裹在 MaterialApp 外层
- 内部使用 `Stack` + `Positioned.fill` 结构
- 所有页面使用 `Colors.transparent` 背景
- 页面切换时，Stack中的背景图层和内容层都在重新渲染
- iOS的页面转场动画与透明背景Stack叠加，导致页面重叠

### 2. 透明背景叠加问题

**受影响页面**: 所有Scaffold都设置了透明背景
```dart
Scaffold(
  backgroundColor: Colors.transparent,  // 透明背景
  extendBodyBehindAppBar: true,        // chat_screen.dart 还启用了这个
)
```

**问题**:
- iOS页面转场时，旧页面和新页面同时在屏幕上
- 透明背景让背后的内容透出来
- Stack层叠导致视觉混乱

### 3. GoRouter配置缺少iOS优化

**问题代码**: `lib/core/routing/app_router.dart`
- 没有自定义 pageBuilder
- 没有针对iOS优化转场动画
- 使用默认的Material转场，在透明背景下表现不佳

### 4. BackgroundContainer渲染性能问题

**问题**:
- 每次路由切换都会触发整个Stack重建
- 背景图片可能被重复加载
- 遮罩层计算在每次build中进行

## 修复方案

### 方案一：优化GoRouter转场动画（推荐✅）

为iOS添加Cupertino风格的页面转场，避免Material转场的透明度问题。

### 方案二：条件性使用BackgroundContainer

仅在桌面端使用全局BackgroundContainer，移动端使用页面级背景。

### 方案三：优化BackgroundContainer性能

添加RepaintBoundary和缓存机制，减少重建。

## 推荐修复步骤

### 第一阶段（立即修复，影响最小）
1. 修改app_router.dart，为所有路由添加pageBuilder
2. iOS使用CupertinoPage，其他平台使用MaterialPage  
3. 为iOS平台的Scaffold添加不透明背景

### 第二阶段（性能优化）
1. 优化BackgroundContainer，添加RepaintBoundary
2. 缓存背景widget，减少重建
3. 添加shouldRebuild检查

## 相关文件
- `lib/core/routing/app_router.dart`
- `lib/main.dart`
- `lib/shared/widgets/background_container.dart`
- `lib/features/chat/presentation/chat_screen.dart`
- `lib/features/chat/presentation/home_screen.dart`

## 状态
🔄 待修复

## 优先级
🔴 高 - 影响iOS用户体验

## 日期
2025-10-18
