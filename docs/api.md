# Flutter Chat App API 文档

## 核心 API 接口

### ChatRepository

#### sendMessage

发送消息并获取响应。

```dart
Future<Message> sendMessage({
  required String conversationId,
  required String content,
  required ModelConfig config,
  List<Message>? conversationHistory,
})
```

**参数**:
- `conversationId`: 对话 ID
- `content`: 消息内容
- `config`: 模型配置（温度、tokens 等）
- `conversationHistory`: 对话历史（可选）

**返回**: 助手的回复消息

#### sendMessageStream

使用流式响应发送消息。

```dart
Stream<String> sendMessageStream({
  required String conversationId,
  required String content,
  required ModelConfig config,
  List<Message>? conversationHistory,
})
```

**返回**: 消息片段的 Stream

#### createConversation

创建新对话。

```dart
Future<Conversation> createConversation({
  String? title,
  String? systemPrompt,
  List<String>? tags,
  String? groupId,
})
```

**参数**:
- `title`: 对话标题（默认: "New Conversation"）
- `systemPrompt`: 系统提示词（可选）
- `tags`: 标签列表（可选）
- `groupId`: 所属分组 ID（可选）

**返回**: 创建的对话对象

#### getAllConversations

获取所有对话（排除临时对话）。

```dart
List<Conversation> getAllConversations()
```

**返回**: 对话列表

### PromptsRepository

#### createTemplate

创建新的提示词模板。

```dart
Future<PromptTemplate> createTemplate({
  required String name,
  required String content,
  String category = '通用',
  List<String> tags = const [],
})
```

#### getAllTemplates

获取所有模板。

```dart
Future<List<PromptTemplate>> getAllTemplates()
```

#### toggleFavorite

切换模板的收藏状态。

```dart
Future<void> toggleFavorite(String id)
```

### SettingsRepository

#### updateSettings

更新应用设置。

```dart
Future<void> updateSettings(AppSettings settings)
```

#### getAllApiConfigs

获取所有 API 配置。

```dart
Future<List<ApiConfig>> getAllApiConfigs()
```

## 数据模型

### Conversation

对话实体。

```dart
class Conversation {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? systemPrompt;
  final List<String> tags;
  final String? groupId;
  final bool isPinned;
  final bool isTemporary;
  final Map<String, dynamic> settings;
}
```

### Message

消息实体。

```dart
class Message {
  final String id;
  final MessageRole role;  // user / assistant / system
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final bool hasError;
  final String? errorMessage;
  final int? tokenCount;
  final List<ImageAttachment>? images;
}
```

### PromptTemplate

提示词模板。

```dart
class PromptTemplate {
  final String id;
  final String name;
  final String content;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
}
```

### ApiConfig

API 配置。

```dart
class ApiConfig {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String? proxyUrl;
  final bool isDefault;
}
```

## Providers

### 全局 Providers

```dart
// core/providers/providers.dart

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final openAIApiClientProvider = Provider<OpenAIApiClient>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return OpenAIApiClient(dioClient);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.read(openAIApiClientProvider),
    ref.read(storageServiceProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(storageServiceProvider));
});

final promptsRepositoryProvider = Provider<PromptsRepository>((ref) {
  return PromptsRepository(ref.read(storageServiceProvider));
});
```

### 状态 Providers

```dart
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(ref.read(settingsRepositoryProvider)),
);
```

## 工具类

### TokenCounter

Token 计数器。

```dart
class TokenCounter {
  static int countTokens(String text);
  static int estimateTokensForConversation(List<Message> messages);
}
```

### MarkdownExport

导出对话为 Markdown 格式。

```dart
class MarkdownExport {
  static String exportConversation(Conversation conversation);
  static String exportConversations(List<Conversation> conversations);
}
```

### PdfExport

导出对话为 PDF。

```dart
class PdfExport {
  static Future<void> exportConversationsToPdf(
    List<Conversation> conversations,
  );
}
```

### BatchOperations

批量操作工具。

```dart
class BatchOperations {
  static Future<void> batchDelete(
    List<String> ids,
    Future<void> Function(String) deleteFunc,
  );
  
  static Future<File?> batchExportMarkdown(
    List<Conversation> conversations,
  );
  
  static Future<void> batchAddTags(
    List<Conversation> conversations,
    List<String> tags,
    Future<void> Function(Conversation) saveFunc,
  );
}
```

## 事件处理

### 消息发送流程

1. 用户输入消息
2. ChatScreen 调用 `_sendMessage()`
3. ChatRepository.sendMessage() 构建请求
4. OpenAI API 响应
5. 保存到本地存储
6. 更新 UI

### 对话管理流程

1. 创建对话（标记为 isTemporary=true）
2. 发送第一条消息时自动保存
3. 更新对话列表

## 错误处理

使用统一的 ErrorHandler：

```dart
try {
  await repository.someOperation();
} catch (e) {
  ErrorHandler.showErrorSnackBar(context, message: ErrorHandler.getErrorMessage(e));
}
```

## 最佳实践

1. **使用 const**: 尽可能使用 const 构造函数
2. **检查 mounted**: 异步操作后检查 widget 是否还挂载
3. **释放资源**: 在 dispose() 中释放 Controller 和监听器
4. **使用 Stream**: 对于实时数据使用 Stream
5. **错误处理**: 总是捕获并处理异常

