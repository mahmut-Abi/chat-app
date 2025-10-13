# 历史会话问题诊断指南

## 问题描述

用户报告：
1. 每个历史会话的内容一样
2. 有时候只能创建一个历史会话

## 已实施的修复

### 1. ChatRepository.createConversation
- ✅ 修改为立即保存对话到存储
- ✅ 使用 UUID 生成唯一 ID
- ✅ 删除空对话检查

### 2. HomeScreen._createNewConversation
- ✅ 创建后重新加载所有对话
- ✅ 确保列表同步

### 3. ChatScreen 保存逻辑
- ✅ 所有消息操作都正确保存
- ✅ 添加错误提示

### 4. 单元测试
- ✅ 验证对话 ID 唯一性
- ✅ 验证立即保存
- ✅ 所有测试通过

## 可能的其他原因

### 1. 路由导航问题
**症状**: 使用 `context.push()` 可能导致多个 ChatScreen 实例共存

**解决方案**: 使用 `context.go()` 或 `context.pushReplacement()`

```dart
// 修改前
context.push('/chat/${conversation.id}');

// 修改后
context.go('/chat/${conversation.id}'); // 替换当前路由
```

### 2. ChatScreen 状态重用
**症状**: `_messages` 使用 `addAll()` 可能累积消息

**解决方案**: 在加载前清空

```dart
void _loadConversation() {
  final chatRepo = ref.read(chatRepositoryProvider);
  final conversation = chatRepo.getConversation(widget.conversationId);
  if (conversation != null) {
    setState(() {
      _messages.clear(); // 添加这一行
      _messages.addAll(conversation.messages);
    });
  }
}
```

### 3. Hive 缓存问题
**症状**: Hive 可能缓存了旧数据

**解决方案**: 添加调试日志

```dart
void _loadConversation() {
  final chatRepo = ref.read(chatRepositoryProvider);
  final conversation = chatRepo.getConversation(widget.conversationId);
  if (kDebugMode) {
    print('ChatScreen._loadConversation:');
    print('  conversationId: ${widget.conversationId}');
    print('  conversation: ${conversation?.title}');
    print('  messages count: ${conversation?.messages.length ?? 0}');
  }
  if (conversation != null) {
    setState(() {
      _messages.clear();
      _messages.addAll(conversation.messages);
    });
  }
}
```

### 4. Widget Key 问题
**症状**: GoRouter 可能重用 Widget 实例

**解决方案**: 为 ChatScreen 添加 Key

```dart
GoRoute(
  path: '/chat/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return ChatScreen(
      key: ValueKey(id), // 添加 key
      conversationId: id,
    );
  },
),
```

## 诊断步骤

### 步骤 1: 启用调试日志

1. 运行应用并打开调试控制台
2. 创建 3 个不同的对话
3. 查看控制台输出：

```
createConversation: 创建新对话 <UUID1>
createConversation: 创建新对话 <UUID2>
createConversation: 创建新对话 <UUID3>
```

4. 验证 UUID 是否不同

### 步骤 2: 检查存储

运行以下命令：

```bash
flutter test test/unit/conversation_creation_test.dart
```

应该看到 3 个不同的 UUID。

### 步骤 3: 检查路由

1. 创建一个对话
2. 发送一条消息
3. 创建另一个对话
4. 发送不同的消息
5. 切换回第一个对话
6. 检查消息是否正确

### 步骤 4: 检查状态

在 `ChatScreen._loadConversation()` 中添加日志：

```dart
if (kDebugMode) {
  print('=== ChatScreen._loadConversation ===');
  print('widget.conversationId: ${widget.conversationId}');
  print('conversation?.id: ${conversation?.id}');
  print('conversation?.title: ${conversation?.title}');
  print('messages count: ${conversation?.messages.length}');
  for (int i = 0; i < (conversation?.messages.length ?? 0); i++) {
    print('  message $i: ${conversation!.messages[i].content.substring(0, min(50, conversation.messages[i].content.length))}');
  }
}
```

## 建议的修复

根据以上分析，建议实施以下修复：

1. ✅ **添加 Widget Key** - 确保 Widget 不被重用
2. ✅ **清空 _messages** - 避免消息累积
3. ✅ **使用 context.go()** - 替换而不是堆叠路由
4. ✅ **添加调试日志** - 方便追踪问题

