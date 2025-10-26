# AGENTS.md - Chat App 开发指南

## 项目概述

**Chat App** 是一个功能丰富的跨平台 AI 聊天应用，支持多个 LLM 提供商、MCP 服务器集成、智能代理系统等。

## 快速开始

### 系统要求
- Flutter SDK >= 3.8.0
- Dart >= 3.8.0
- iOS 12.0+ 或 Android 6.0+

### 开发环境设置

```bash
# 克隆项目
git clone https://github.com/your-repo/chat-app.git
cd chat-app

# 安装依赖
flutter pub get

# 代码生成
flutter pub run build_runner build

# 运行应用
flutter run
```

## 项目结构

```
lib/
├── main.dart                              # 应用入口
├── core/
│   ├── services/                          # 核心服务（日志、存储、网络）
│   ├── storage/                           # 本地存储层
│   ├── providers/                         # Riverpod providers
│   └── utils/                             # 工具函数
├── features/
│   ├── chat/                              # 聊天功能
│   │   ├── data/                          # 数据层（Repository）
│   │   ├── domain/                        # 领域层（Entity）
│   │   └── presentation/                  # UI 层（Screen、Widget）
│   ├── agent/                             # Agent 系统
│   ├── mcp/                               # MCP 集成
│   ├── models/                            # 模型管理
│   ├── prompts/                           # 提示词库
│   ├── settings/                          # 设置
│   ├── logs/                              # 日志查看
│   └── token_usage/                       # Token 统计
└── shared/
    ├── themes/                            # 主题系统
    ├── widgets/                           # 共享组件
    └── utils/                             # 共享工具
```

## 代码规范

### 命名规范

#### 文件和目录
- 目录名：snake_case（全小写，单词用下划线分隔）
  - ✓ `chat_screen.dart`
  - ✗ `ChatScreen.dart` 或 `chat-screen.dart`

#### 类名
- PascalCase（每个单词首字母大写，无分隔）
  - ✓ `class ChatRepository {}`
  - ✗ `class chat_repository {}` 或 `class ChatRepository_ {}`

#### 变量和函数
- camelCase（首字母小写，后续单词首字母大写）
  - ✓ `final messageList = [];`
  - ✗ `final MessageList = [];` 或 `final message_list = [];`

#### 常量
- UPPER_SNAKE_CASE（全大写，单词用下划线分隔）
  - ✓ `const MAX_RETRY_COUNT = 3;`
  - ✗ `const maxRetryCount = 3;` 或 `const max_retry_count = 3;`

### 代码风格

#### 导入
```dart
// 1. dart 导入
import 'dart:async';
import 'dart:convert';

// 2. package 导入
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. 相对导入
import '../models/chat.dart';
import '../../core/services/log_service.dart';
```

#### const 的使用
- 所有不变的对象都应该标记为 const
- Widget 构造函数如果没有状态变化，使用 const

```dart
// 好
const Center(
  child: CircularProgressIndicator(),
)

// 不好
Center(
  child: CircularProgressIndicator(),
)
```

#### 文档注释
- 使用 `///` 为公共 API 添加文档注释
- 简要说明、参数、返回值、异常

```dart
/// 获取聊天消息列表
/// 
/// [conversationId] 会话 ID
/// [limit] 返回消息数量限制
/// 
/// 返回消息列表，按时间排序
/// 
/// 抛出 [ChatException] 如果加载失败
Future<List<Message>> getMessages(
  String conversationId, {
  int limit = 50,
}) async { ... }
```

### 代码质量

#### Lint 检查
```bash
# 检查代码问题
flutter analyze

# 自动修复
dart fix --apply
```

#### 测试
- 单元测试文件放在 `test/unit/` 目录
- 集成测试放在 `test/integration/` 目录
- 测试文件名：`{source_file}_test.dart`

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/unit/chat_repository_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

## 特性模块开发

### 分层架构

每个功能模块遵循三层架构：

```
features/{feature}/
├── data/                    # 数据层
│   ├── {feature}_repository.dart
│   ├── models/              # 数据模型
│   ├── local/               # 本地存储
│   └── remote/              # 远程 API
├── domain/                  # 领域层
│   ├── entities/            # 实体定义
│   └── use_cases/           # 业务逻辑（可选）
└── presentation/            # 表现层
    ├── screens/             # 页面
    ├── widgets/             # 组件
    └── providers/           # Riverpod providers
```

### 实现示例

#### 1. 定义实体

```dart
// domain/chat.dart
@JsonSerializable()
class Message {
  final String id;
  final String content;
  final DateTime createdAt;
  
  const Message({
    required this.id,
    required this.content,
    required this.createdAt,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) => 
    _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
```

#### 2. 创建 Repository

```dart
// data/chat_repository.dart
class ChatRepository {
  final StorageService _storage;
  final ChatApiClient _apiClient;
  
  ChatRepository(this._storage, this._apiClient);
  
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final messages = await _apiClient.fetchMessages(conversationId);
      await _storage.saveMessages(messages);
      return messages;
    } catch (e) {
      LogService().error('Failed to fetch messages', e);
      rethrow;
    }
  }
}
```

#### 3. 创建 Provider

```dart
// presentation/providers.dart
final chatRepositoryProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  final apiClient = ref.watch(chatApiClientProvider);
  return ChatRepository(storage, apiClient);
});

final messagesProvider = FutureProvider.family((ref, String conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(conversationId);
});
```

#### 4. 创建 Widget

```dart
// presentation/screens/chat_screen.dart
class ChatScreen extends ConsumerWidget {
  final String conversationId;
  
  const ChatScreen({required this.conversationId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(
      messagesProvider(conversationId),
    );
    
    return messagesAsync.when(
      data: (messages) => _buildMessageList(messages),
      loading: () => const LoadingWidget(),
      error: (error, st) => ErrorWidget(error: error),
    );
  }
  
  Widget _buildMessageList(List<Message> messages) {
    // 构建消息列表
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) => MessageTile(
        message: messages[index],
      ),
    );
  }
}
```

## 性能优化指南

### 性能目标
- **启动时间**: < 3 秒
- **内存占用**: < 150 MB
- **帧率**: 稳定 60 FPS
- **网络延迟**: < 2 秒 (P90)
- **包大小**: < 100 MB

### 关键优化

#### 1. 图片加载
- 使用 CachedNetworkImage 进行图片缓存
- 设置合适的缓存大小
- 提供占位图和错误占位图

```dart
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => ShimmerLoading(),
  errorWidget: (context, url, error) => ErrorImage(),
  cacheManager: _customCacheManager,
)
```

#### 2. 列表优化
- 使用 ListView 的 itemBuilder
- 避免在 build 中创建大对象
- 使用 RepaintBoundary 限制重绘范围

#### 3. Provider 优化
- 使用 select() 缩小监听范围
- 避免不必要的 watch
- 合理设置 cache duration

```dart
// ✓ 好：只监听需要的部分
final name = ref.watch(
  userProvider.select((user) => user?.name),
);

// ✗ 坏：监听整个对象
final user = ref.watch(userProvider);
final name = user?.name;
```

## 常见任务

### 添加新功能

1. 创建功能目录：`lib/features/{feature}/`
2. 按三层架构组织代码
3. 创建对应的测试文件
4. 更新导入和 providers
5. 运行 lint 检查和测试

### 修复 Bug

1. 创建 test case 重现 bug
2. 修复代码
3. 验证 test case 通过
4. 提交前运行全部测试

### 性能优化

1. 使用 DevTools 分析性能瓶颈
2. 使用 profile 模式进行基准测试
3. 实施优化措施
4. 对比优化前后的指标

## 调试技巧

### 日志记录
```dart
final log = LogService();
log.info('消息加载成功', {'count': messages.length});
log.warning('连接超时', {'timeout': 30});
log.error('API 调用失败', exception);
```

### DevTools
```bash
# 启动 DevTools
flutter pub global run devtools

# 在应用运行时查看性能、日志等
```

### Profile 模式
```bash
# Profile 模式运行
flutter run --profile

# 生成性能报告
flutter run --profile --trace-startup
```

## 常见问题

### Q: 如何处理大列表？
A: 使用虚拟化滚动（ListView 自动处理），或使用
```dart
CustomScrollView(
  slivers: [
    SliverList.builder(
      itemBuilder: (context, index) => ...,
      itemCount: items.length,
    ),
  ],
)
```

### Q: 如何处理状态管理？
A: 使用 Riverpod providers，将状态定义为 provider：
```dart
final messageCountProvider = StateProvider((ref) => 0);
final selectedChatProvider = StateProvider<Chat?>((ref) => null);
```

### Q: 如何测试异步代码？
A: 使用 `testWidgets` 和等待：
```dart
testWidgets('加载消息', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pump(); // 等待异步完成
  expect(find.text('消息'), findsOneWidget);
});
```

## 相关资源

- [Flutter 文档](https://flutter.dev/docs)
- [Riverpod 文档](https://riverpod.dev)
- [Dart 代码风格指南](https://dart.dev/guides/language/effective-dart/style)
- [Project 结构](./docs/PROJECT_STRUCTURE.md)
- [优化计划](./docs/OPTIMIZATION_PLAN.md)
- [iOS MCP SSE 修复](./docs/iOS_MCP_SSE_FIXES.md)
