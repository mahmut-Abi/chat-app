# iOS 调试指南

## 查看日志的方法

### 方法 1: 应用内日志查看器

1. 打开应用
2. 进入「设置」→「高级」→「日志查看」
3. 查看日志，特别关注：
   - 🔴 **Error** 级别（红色）
   - 🟠 **Warning** 级别（橙色）
   - 🔵 **Debug** 级别（蓝色）- 包含页面转场信息

4. 点击右上角「导出」按钮，复制所有日志

### 方法 2: Xcode Console

如果通过 Xcode 运行：

1. 打开 Xcode
2. Product → Run (或 Cmd+R)
3. 查看底部的 Console 面板
4. 使用过滤器搜索关键词：
   - `Building page`
   - `BackgroundContainer`
   - `transition`
   - `navigation`
   - `ERROR`
   - `WARNING`

### 方法 3: 设备日志 (真机调试)

1. 连接 iPhone 到 Mac
2. 打开 Console.app (Mac 应用)
3. 选择你的设备
4. 运行应用，查看实时日志

---

## 需要的调试信息

请提供以下信息帮助定位问题：

### 1. 基本环境
- iOS 版本：____
- 设备型号：____
- Flutter 版本：运行 `flutter --version`

### 2. 问题重现步骤
```
例如：
1. 从主页点击进入「设置」
2. 在设置页面向右滑动返回
3. 观察到：_____ (描述看到的问题)
```

### 3. 日志内容

**错误日志** (如果有):
```
贴在这里
```

**转场相关日志**:
```
贴在这里
```

---

## 常见问题排查

### 问题 1: 页面转场有白色闪烁

**可能原因**:
- Scaffold backgroundColor 不是 transparent
- BackgroundContainer 没有正确提供背景

**检查日志**:
搜索 `BackgroundContainer rebuild`，确认：
- `hasImage` 的值
- `opacity` 的值

### 问题 2: 右滑手势不响应

**可能原因**:
- 使用了 CustomTransitionPage 而不是 CupertinoPage
- PopScope 阻止了返回行为

**检查日志**:
搜索 `Building page`，确认：
- `platform` 是否为 `iOS`
- 是否使用了 CupertinoPage

### 问题 3: 页面转场有残留或黑色背景

**可能原因**:
- ColoredBox 没有正确应用
- 页面层级问题

**检查点**:
1. 查看 BackgroundContainer 是否在最外层
2. 确认所有页面 Scaffold 使用 `backgroundColor: Colors.transparent`

---

## 导出完整日志的命令

在应用的日志查看界面：

1. 点击「导出日志」按钮
2. 选择导出格式：
   - **文本格式** - 易读
   - **JSON 格式** - 结构化
   - **CSV 格式** - 可导入 Excel

3. 日志会复制到剪贴板，然后粘贴发送给我

---

## 实时调试技巧

### 1. 使用 Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

然后在浏览器中查看：
- Widget Inspector - 查看页面层级
- Performance - 查看渲染性能
- Logging - 查看实时日志

### 2. 添加断点

在 Xcode 中可以添加断点到：
- `app_router.dart` 的 `_buildPage` 方法
- `background_container.dart` 的 `build` 方法

### 3. 查看 Widget 树

在应用运行时按：
- **Cmd+Shift+P** (Mac)
- 然后输入 `Flutter: Toggle Debug Paint`

可以看到页面边界和层级

---

## 当前代码的调试点

我已经在以下位置添加了调试日志：

### app_router.dart
```dart
LogService().debug('Building page', {
  'path': state.path,
  'platform': PlatformUtils.isIOS ? 'iOS' : 'other',
  'pageKey': state.pageKey.toString(),
});
```

### background_container.dart  
```dart
LogService().debug('BackgroundContainer rebuild', {
  'hasImage': settings.backgroundImage != null,
  'opacity': settings.backgroundOpacity,
});
```

这些日志会帮助我们了解：
- 页面何时被构建
- 使用的是什么平台的页面
- 背景容器何时重建
- 背景图片配置情况

