# Bug #18: 移除会话分享功能

## 问题描述
- 去除会话分享功能

## 修复内容

### 1. 移除分享相关导入

**文件**: `lib/features/chat/presentation/widgets/message_bubble.dart`

移除:
```dart
import '../../../../core/utils/share_utils.dart';
```

### 2. 移除消息操作中的分享

**文件**: `lib/shared/widgets/message_actions.dart`

移除:
```dart
final VoidCallback? onShare;  // 参数

// UI 中的分享按钮
if (onShare != null)
  IconButton(
    icon: const Icon(Icons.share, size: 16),
    onPressed: onShare,
    tooltip: '分享',
  ),
```

### 3. 移除上下文菜单中的分享

**文件**: `lib/features/chat/presentation/widgets/message_bubble.dart`

移除:
```dart
ListTile(
  leading: const Icon(Icons.share),
  title: const Text('分享'),
  onTap: () {
    Navigator.pop(context);
    ShareUtils.shareText(message.content);
  },
),
```

### 4. 更新调用点

**文件**: `lib/features/chat/presentation/widgets/message_bubble.dart`

移除 MessageActions 中的 onShare 参数:
```dart
MessageActions(
  isUserMessage: isUser,
  onCopy: () => _copyMessage(context),
  // onShare: () => ShareUtils.shareText(message.content),  // 已删除
  onEdit: isUser && onEdit != null ? () => _showEditDialog(context) : null,
  onDelete: onDelete,
  onRegenerate: !isUser && onRegenerate != null ? onRegenerate : null,
)
```

## 影响范围

- ✅ 桌面端消息操作栏不再显示分享按钮
- ✅ 移动端长按菜单不再显示分享选项
- ✅ 简化了代码，移除了不必要的依赖

## 相关文件
- `lib/features/chat/presentation/widgets/message_bubble.dart`
- `lib/shared/widgets/message_actions.dart`

## 修复日期
2025-01-XX

## 状态
✅ 已完成
