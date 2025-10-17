# Bug #15: 会话命名优化

## 问题描述
- 通过总结第一次会话内容，自动生成并替换会话名称
- 避免所有会话都显示为「新会话」

## 修复方案

### 1. 实现思路

当用户发送第一条消息并收到 AI 回复后，调用 API 生成一个简短的标题。

**方法 A: 使用单独的 API 调用**
优点：精准、可控  
缺点：额外的 API 调用成本

**方法 B: 基于规则提取**
优点：快速、无成本  
缺点：可能不够精准

**建议采用方法 A**，但提供开关让用户选择是否启用。

### 2. 实现代码

#### 步骤 1: 添加生成标题的方法

**文件**: `lib/features/chat/data/chat_repository.dart`

```dart
/// 生成会话标题
Future<String> generateConversationTitle({
  required String userMessage,
  required String assistantMessage,
  required ModelConfig config,
}) async {
  try {
    _log.info('生成会话标题', {
      'userMessageLength': userMessage.length,
      'assistantMessageLength': assistantMessage.length,
    });
    
    final prompt = '''
请根据以下对话内容，生成一个简洁的中文标题，不超过 20 个字。只返回标题文本，不要有引号或其他符号。

用户：$userMessage
AI：$assistantMessage

标题：''';

    final messages = [
      {'role': 'user', 'content': prompt},
    ];

    final request = ChatCompletionRequest(
      model: config.model,
      messages: messages,
      temperature: 0.7,
      maxTokens: 50,
      stream: false,
    );

    final response = await _apiClient.createChatCompletion(request);
    var title = response.choices.first.message.content.trim();
    
    // 清理标题：移除引号和特殊字符
    title = title.replaceAll(RegExp(r'["\'“”「」]'), '').trim();
    
    // 限制长度
    if (title.length > 30) {
      title = title.substring(0, 30);
    }
    
    _log.info('生成的标题', {'title': title});
    return title.isEmpty ? '新对话' : title;
  } catch (e) {
    _log.error('生成标题失败', e);
    // 如果生成失败，使用简单的基于规则的方法
    return _generateTitleByRule(userMessage);
  }
}

/// 基于规则生成标题（备用方案）
String _generateTitleByRule(String userMessage) {
  var title = userMessage.trim();
  
  // 移除换行
  title = title.replaceAll('\n', ' ');
  
  // 限制长度
  if (title.length > 30) {
    title = title.substring(0, 30);
  }
  
  return title.isEmpty ? '新对话' : title;
}
```

#### 步骤 2: 在发送消息后调用

**文件**: `lib/features/chat/presentation/chat_screen.dart`

在 `_sendMessage()` 方法中，当第一条消息发送并收到回复后：

```dart
Future<void> _sendMessage() async {
  // ...
  
  // 发送消息并获取响应
  final assistantMessage = await chatRepo.sendMessage(...);
  
  // 如果这是第一条消息，生成标题
  if (_messages.length == 2) {  // 用户消息 + AI 回复
    final enableAutoNaming = ref.read(appSettingsProvider)
        .value?.enableAutoConversationNaming ?? true;
    
    if (enableAutoNaming) {
      _generateAndUpdateTitle(
        userMessage: _messages[0].content,
        assistantMessage: assistantMessage.content,
      );
    }
  }
}

Future<void> _generateAndUpdateTitle({
  required String userMessage,
  required String assistantMessage,
}) async {
  try {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversation = chatRepo.getConversation(widget.conversationId);
    
    if (conversation == null || conversation.title != 'New Conversation') {
      return;  // 已经有自定义标题
    }
    
    // 生成标题
    final config = ModelConfig(
      model: _selectedModel?.id ?? 'gpt-3.5-turbo',
    );
    
    final title = await chatRepo.generateConversationTitle(
      userMessage: userMessage,
      assistantMessage: assistantMessage,
      config: config,
    );
    
    // 更新标题
    final updated = conversation.copyWith(title: title);
    await chatRepo.saveConversation(updated);
    
    // 刷新 UI
    _loadAllConversations();
    
  } catch (e) {
    _log.error('生成标题失败', e);
    // 静默失败，不影响用户体验
  }
}
```

#### 步骤 3: 添加设置选项

**文件**: `lib/features/settings/domain/api_config.dart`

在 AppSettings 中添加:
```dart
final bool enableAutoConversationNaming;

const AppSettings({
  // ...
  this.enableAutoConversationNaming = true,  // 默认启用
});
```

## 实现效果

### 修复前
```
新会话
新会话 (1)
新会话 (2)
新会话 (3)
```

### 修复后
```
Flutter 开发环境配置
Dart 语法基础
MCP 功能如何使用
API 配置教程
```

## 优化点

- ✅ 自动生成有意义的标题
- ✅ 仅在第一次对话后生成，不影响性能
- ✅ 支持开关控制，用户可选择禁用
- ✅ 失败时使用基于规则的备用方案
- ✅ 静默失败，不影响用户体验

## 相关文件
- `lib/features/chat/data/chat_repository.dart`
- `lib/features/chat/presentation/chat_screen.dart`
- `lib/features/settings/domain/api_config.dart`

## 状态
📝 已规划（需要实现）

## 备注

这个功能需要额外的 API 调用，会有小量成本。建议：
1. 默认启用
2. 在设置中提供开关
3. 使用低成本模型（如 gpt-3.5-turbo）生成标题
