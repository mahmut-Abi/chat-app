# iOS 页面转场问题修复

## 问题描述

1. iOS 设置页面右滑返回手势失效
2. 页面转场不流畅，有窗口残留

## 根本原因

### 问题 1: 右滑手势失效
- 使用了 `CustomTransitionPage` 自定义转场
- 自定义转场不支持 iOS 交互式手势

### 问题 2: 转场不流畅
- 所有页面都使用 `backgroundColor: Colors.transparent`
- 在转场动画期间，两个透明页面叠加导致视觉残留
- `CupertinoPageTransition` 需要页面有背景才能正确渲染

## 解决方案

### 方案 1: 使用 CupertinoPage (推荐)

```dart
if (PlatformUtils.isIOS) {
  return CupertinoPage(
    key: state.pageKey,
    child: child,
  );
}
```

**优点**:
- 自带原生右滑手势支持
- 转场动画流畅
- iOS 原生体验

**缺点**:
- 需要页面有不透明背景（但背景图片仍然可以显示）

### 方案 2: CustomTransitionPage + PopGestureDetector

```dart
return CustomTransitionPage(
  key: state.pageKey,
  child: Builder(
    builder: (context) {
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          // 处理手势
        },
        child: child,
      );
    },
  ),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    );
  },
);
```

**优点**:
- 支持透明背景
- 可以自定义转场动画

**缺点**:
- 需要手动实现右滑手势逻辑
- 代码复杂

### 方案 3: MaterialPageRoute with CupertinoPageTransitionsBuilder

```dart
return MaterialPage(
  key: state.pageKey,
  child: child,
);
```

然后在 ThemeData 中配置:
```dart
theme: ThemeData(
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
)
```

## 当前实现

当前使用的是 **方案 2**，但没有实现右滑手势支持。

```dart
if (PlatformUtils.isIOS) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: false,
        child: child,
      );
    },
  );
}
```

## 推荐修复

### 修复 1: 改为 CupertinoPage

这是最简单和最有效的解决方案：

```dart
if (PlatformUtils.isIOS) {
  return CupertinoPage(
    key: state.pageKey,
    child: child,
  );
}
```

`CupertinoPage` 会自动：
- 添加右滑手势支持
- 使用正确的转场动画
- 处理页面背景

**但需要注意**：`CupertinoPage` 需要页面有背景色，否则会显示白色或黑色。

由于我们的页面都是 `backgroundColor: Colors.transparent`，我们需要：

1. 确保 `BackgroundContainer` 总是提供一个背景色（已完成）
2. 或者为每个页面添加一个微透明的背景层

