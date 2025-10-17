# Bug #12-14: 头像位置和模型名称显示

## 问题描述

### Bug #12: 头像位置调整
- 会话中大模型和用户的头像图标需要移到对话气泡上方

### Bug #14: 模型名称显示
- 大模型头像后面需要显示当前使用的模型名称

## 修复内容

### 1. 重构 MessageBubble 组件

**文件**: `lib/features/chat/presentation/widgets/message_bubble.dart`

**修改前的布局**:
```
[头像] [消息内容] [头像]
```

**修改后的布局**:
```
[头像] [用户名/模型名]
[消息内容]
```

### 2. 主要代码变更

**添加 modelName 参数**:
```dart
class MessageBubble extends StatelessWidget {
  final Message message;
  // ...
  final String? modelName;  // 新增
  
  const MessageBubble({
    // ...
    this.modelName,  // 新增
  });
}
```

**重构布局**:
```dart
return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 头像和名称在上方
    Row(
      children: [
        _buildAvatar(context, isUser),
        const SizedBox(width: 8),
        Text(
          isUser ? '用户' : (modelName ?? 'AI 助手'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    // 消息内容
    Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: _buildMessageContent(context, isMobile, isUser),
        ),
      ],
    ),
  ],
);
```

### 3. 更新 ChatMessageList

**文件**: `lib/features/chat/presentation/widgets/chat_message_list.dart`

添加 `currentModelName` 参数并传递给 MessageBubble:

```dart
class ChatMessageList extends StatelessWidget {
  // ...
  final String? currentModelName;  // 新增
  
  const ChatMessageList({
    // ...
    this.currentModelName,  // 新增
  });
  
  @override
  Widget build(BuildContext context) {
    // ...
    return MessageBubble(
      message: message,
      modelName: message.role == MessageRole.assistant ? currentModelName : null,
      // ...
    );
  }
}
```

### 4. 更新 ChatScreen

**文件**: `lib/features/chat/presentation/chat_screen.dart`

在调用 ChatMessageList 时传递模型名称:

```dart
ChatMessageList(
  messages: _messages,
  scrollController: _scrollController,
  isMobile: isMobile,
  currentModelName: _selectedModel?.name,  // 新增
  onDeleteMessage: _deleteMessage,
  onRegenerateMessage: _regenerateMessage,
  onEditMessage: _editMessage,
)
```

## 效果对比

### 修复前
```
[👤]  用户消息内容...  [👤]
[🤖]  AI 回复内容...  [🤖]
```

### 修复后
```
[👤] 用户
用户消息内容...

[🤖] GPT-4
AI 回复内容...
```

## 视觉改进

- ✅ 头像和名称在消息上方，布局更清晰
- ✅ 显示当前使用的模型名称
- ✅ 用户可以一眼看出哪个模型回复的
- ✅ 布局更符合现代聊天应用的设计规范

## 相关文件
- `lib/features/chat/presentation/widgets/message_bubble.dart`
- `lib/features/chat/presentation/widgets/chat_message_list.dart`
- `lib/features/chat/presentation/chat_screen.dart`

## 修复日期
2025-01-XX

## 状态
✅ 已完成
