# Platform Dialog 使用指南

本文档说明如何在项目中使用平台自适应的 Dialog 组件。

## 概述

`PlatformDialog` 组件会根据运行平台自动选择合适的 Dialog 样式:
- **iOS/macOS**: 使用 `CupertinoAlertDialog` (iOS 原生风格)
- **Android/Windows/Linux/Web**: 使用 `AlertDialog` (Material Design 风格)

## 核心组件

### 1. showPlatformConfirmDialog - 确认对话框

```dart
final confirmed = await showPlatformConfirmDialog(
  context: context,
  title: '删除对话',
  content: '确定要删除这个对话吗?此操作无法撤销。',
  confirmText: '删除',
  isDestructive: true,
);

if (confirmed) {
  // 执行删除操作
}
```

### 2. showPlatformInputDialog - 输入对话框

```dart
final result = await showPlatformInputDialog(
  context: context,
  title: '重命名对话',
  initialValue: conversation.title,
  placeholder: '请输入标题',
  confirmText: '保存',
);

if (result != null && result.isNotEmpty) {
  // 使用输入的内容
}
```

### 3. showPlatformLoadingDialog - 加载对话框

```dart
showPlatformLoadingDialog(
  context: context,
  message: '正在加载...',
);

try {
  await someAsyncOperation();
} finally {
  if (mounted) Navigator.pop(context);
}
```

## 平台差异

### iOS/macOS
- 半透明圆角背景
- 按钮横向排列
- destructive 按钮显示为红色
- CupertinoTextField 输入框

### Android/其他平台
- Material Design 卡片样式
- 按钮右对齐
- OutlineInputBorder 输入框
