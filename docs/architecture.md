# Flutter Chat App 架构设计文档

## 概览

Flutter Chat App 是一个跨平台的 AI 聊天应用，采用清晰的分层架构和模块化设计。

## 技术栈

- **框架**: Flutter 3.35+
- **语言**: Dart 3.9+
- **状态管理**: Riverpod 3.x
- **路由**: go_router
- **网络**: Dio + Retrofit
- **本地存储**: Hive
- **代码生成**: build_runner, json_serializable, freezed

## 项目结构

```
lib/
├── core/                   # 核心基础设施
│   ├── network/            # 网络层
│   │   ├── dio_client.dart # Dio 配置
│   │   ├── openai_api_client.dart # OpenAI API 客户端
│   │   └── api_exception.dart # API 异常定义
│   ├── storage/            # 本地存储
│   │   └── storage_service.dart # Hive 存储服务
│   ├── providers/          # 全局 Providers
│   │   └── providers.dart  # 统一的 Provider 导出
│   ├── routing/            # 路由配置
│   │   └── app_router.dart # go_router 配置
│   ├── error/              # 错误处理
│   │   └── error_handler.dart # 统一错误处理
│   └── utils/              # 工具类
│       ├── token_counter.dart
│       ├── markdown_export.dart
│       ├── pdf_export.dart
│       └── batch_operations.dart
├── features/               # 功能模块
│   ├── chat/               # 聊天功能
│   │   ├── data/
│   │   │   └── chat_repository.dart
│   │   ├── domain/
│   │   │   ├── conversation.dart
│   │   │   └── message.dart
│   │   └── presentation/
│   │       ├── chat_screen.dart
│   │       └── widgets/
│   ├── settings/           # 设置功能
│   ├── prompts/            # 提示词模板
│   ├── agent/              # AI Agent
│   ├── mcp/                # Model Context Protocol
│   └── token_usage/        # Token 使用统计
├── shared/                 # 共享组件
│   ├── widgets/            # 通用 UI 组件
│   └── themes/             # 主题配置
└── main.dart               # 应用入口
```

## 架构层次

### 1. 表现层 (Presentation Layer)

**职责**: UI 组件和用户交互

- **Screens**: 完整页面组件
- **Widgets**: 可复用的 UI 组件
- **State Management**: 使用 Riverpod 管理状态

```dart
class ChatScreen extends ConsumerStatefulWidget {
  // UI 逻辑
}
```

### 2. 业务逻辑层 (Domain Layer)

**职责**: 业务实体和规则

- **Entities**: 核心数据模型（Conversation, Message 等）
- **Use Cases**: 业务操作逻辑

```dart
class Conversation {
  final String id;
  final String title;
  final List<Message> messages;
  // ...
}
```

### 3. 数据层 (Data Layer)

**职责**: 数据获取和持久化

- **Repositories**: 数据仓库，封装数据源
- **Data Sources**: API 客户端、本地存储

```dart
class ChatRepository {
  final OpenAIApiClient _apiClient;
  final StorageService _storage;
  
  Future<Message> sendMessage(...) async {
    // 业务逻辑
  }
}
```

## 核心模块设计

### 聊天模块 (Chat)

**数据流**:
```
User Input → ChatScreen → ChatRepository → OpenAI API
                                         ↓
                                    StorageService
                                         ↓
                                    Local DB (Hive)
```

**关键功能**:
- 消息发送与接收
- 流式响应支持
- 对话管理（创建、删除、分组）
- 消息编辑与重新生成
- 图片附件支持

### 提示词模板 (Prompts)

**目的**: 管理可复用的提示词模板

**功能**:
- 创建/编辑/删除模板
- 分类和标签管理
- 收藏功能
- 快速插入对话

### Agent 系统

**设计**: 工具调用和任务执行

**组件**:
- **AgentTool**: 工具定义（搜索、计算器、文件操作等）
- **ToolExecutor**: 工具执行器
- **AgentIntegration**: Agent 与聊天集成

### MCP (Model Context Protocol)

**目的**: 连接外部服务和工具

**支持类型**:
- HTTP 连接
- Stdio (命令行) 连接

## 状态管理策略

### Provider 类型选择

```dart
// 简单状态
final counterProvider = StateProvider<int>((ref) => 0);

// 复杂业务逻辑
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.read(apiClientProvider),
    ref.read(storageServiceProvider),
  );
});

// 异步数据
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repo = ref.read(chatRepositoryProvider);
  return repo.getAllConversations();
});
```

### 依赖注入

所有核心服务通过 Riverpod Providers 进行依赖注入：

```dart
// core/providers/providers.dart
final dioClientProvider = Provider<DioClient>((ref) => DioClient());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.read(openAIApiClientProvider),
    ref.read(storageServiceProvider),
  );
});
```

## 数据持久化

### Hive 存储结构

```dart
// Box 名称
const String conversationsBox = 'conversations';
const String settingsBox = 'settings';
const String promptsBox = 'prompts';
const String agentsBox = 'agents';
```

### 数据序列化

使用 `json_serializable` 进行 JSON 序列化：

```dart
@JsonSerializable()
class Message {
  factory Message.fromJson(Map<String, dynamic> json) => 
      _$MessageFromJson(json);
  
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
```

## 网络层设计

### API 客户端

使用 Retrofit 定义 API 接口：

```dart
@RestApi()
abstract class OpenAIApiClient {
  @POST('/v1/chat/completions')
  Future<ChatCompletionResponse> createChatCompletion(
    @Body() ChatCompletionRequest request,
  );
}
```

### 错误处理

统一的错误处理机制：

```dart
class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    // ...
  }
}
```

## 路由配置

使用 go_router 进行声明式路由：

```dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ChatScreen(conversationId: id);
      },
    ),
  ],
);
```

## 主题系统

### 主题配置

支持深色/浅色主题切换和自定义颜色：

```dart
class AppTheme {
  static ThemeData lightTheme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  );
  
  static ThemeData darkTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
  );
}
```

## 测试策略

### 单元测试

- **Repository 层**: Mock API 客户端和存储服务
- **Domain 层**: 测试数据模型的序列化和业务逻辑
- **Utils 层**: 测试工具函数

```dart
@GenerateMocks([OpenAIApiClient, StorageService])
void main() {
  late ChatRepository repository;
  late MockOpenAIApiClient mockApiClient;
  late MockStorageService mockStorage;
  
  setUp(() {
    mockApiClient = MockOpenAIApiClient();
    mockStorage = MockStorageService();
    repository = ChatRepository(mockApiClient, mockStorage);
  });
  
  // 测试用例...
}
```

## 性能优化

### 1. Const 优化

尽可能使用 const 构造函数：

```dart
const SizedBox(height: 16)
const EdgeInsets.all(8)
```

### 2. Markdown 渲染缓存

使用缓存避免重复渲染：

```dart
final _markdownCache = <String, Widget>{};
```

### 3. 列表优化

使用 ListView.builder 进行懒加载：

```dart
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) => MessageBubble(message: messages[index]),
)
```

## 扩展性设计

### 插件化架构

- **Agent 工具**: 易于添加新的工具类型
- **MCP 连接**: 支持多种连接协议
- **主题系统**: 支持自定义主题色

### 多平台支持

- **Web**: PWA 支持
- **Desktop**: macOS, Windows, Linux
- **Mobile**: iOS, Android

## 安全性考虑

1. **API Key 存储**: 使用 flutter_secure_storage 加密存储
2. **数据隔离**: 用户数据本地存储，不上传云端
3. **输入验证**: 所有用户输入进行验证和清理

## 开发规范

1. **命名规范**: 遵循 Dart 官方风格指南
2. **代码格式**: 使用 `dart format` 格式化代码
3. **静态分析**: 通过 `flutter analyze` 检查
4. **提交规范**: 使用约定式提交（Conventional Commits）

## 部署

### Web 部署

```bash
flutter build web --release
```

### Desktop 部署

```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

### Mobile 部署

```bash
flutter build apk --release
flutter build ios --release
```

## 未来规划

1. **云同步**: 支持跨设备数据同步
2. **多语言**: 完整的国际化支持
3. **插件市场**: 允许用户自定义 Agent 工具
4. **协作功能**: 多人对话和分享
5. **语音支持**: 语音输入和输出

