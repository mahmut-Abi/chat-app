# BUG-001: message_bubble.dart 重复方法定义

## 问题描述
文件 `lib/features/chat/presentation/widgets/message_bubble.dart` 中存在重复的方法定义:
- `_showContextMenu` (2次)
- `_buildImageAttachments` (2次)  
- `_buildAvatar` (2次)

## 错误信息
```
error • The name '_showContextMenu' is already defined
error • The name '_buildImageAttachments' is already defined
error • The method '_ImageViewerScreen' isn't defined for the type 'MessageBubble'
```

## 根本原因
之前的代码编辑导致方法被重复添加到类中。

## 修复方案
1. 移除重复的方法定义
2. 保留正确的实现版本（带有 Theme.of(context).colorScheme.error 的版本）
3. 修复未使用的导入
4. 将 `_ImageViewerScreen` 改为 `ImageViewerScreen`

## 修复内容
- 删除了 3 个未使用的导入包
- 移除了重复的 `_showContextMenu` 方法
- 移除了重复的 `_buildImageAttachments` 方法
- 移除了重复的 `_buildAvatar` 方法
- 修正 ImageViewerScreen 类名引用

## 验证
```bash
flutter analyze lib/features/chat/presentation/widgets/message_bubble.dart
```

## 状态
✅ 已修复
