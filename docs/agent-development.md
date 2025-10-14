# Agent 开发指南

本文档介绍如何在 Flutter Chat App 中开发和集成 AI Agent。

## 架构概览

### Agent 系统组成

Agent 系统由以下核心组件构成：

1. **Agent 定义** (`lib/features/agent/domain/agent.dart`)
   - Agent 实体类，定义 Agent 的基本属性
   - 包含 ID、名称、描述、工具列表等

2. **工具系统** (`lib/features/agent/domain/tool.dart`)
   - 工具接口定义
   - 工具执行器管理
   - 内置工具实现

3. **Agent 集成** (`lib/features/agent/data/agent_integration.dart`)
   - Agent 与聊天系统的集成逻辑
   - 工具调用处理
   - 结果返回

4. **MCP 支持** (`lib/features/mcp/`)
   - Model Context Protocol 集成
   - 外部工具连接
   - 工具发现和注册

## 创建自定义 Agent

### 步骤 1: 定义 Agent

```dart
final customAgent = Agent(
  id: 'custom-agent-id',
  name: '自定义助手',
  description: '这是一个自定义的 AI 助手',
  systemPrompt: '你是一个专业的助手...',
  tools: [
    // 添加工具
  ],
  enabled: true,
);
```

### 步骤 2: 实现工具

工具需要实现 `Tool` 接口：

```dart
class CustomTool extends Tool {
  @override
  String get name => 'custom_tool';

  @override
  String get description => '工具描述';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'input': {
        'type': 'string',
        'description': '输入参数',
      },
    },
    'required': ['input'],
  };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final input = args['input'] as String;
    // 实现工具逻辑
    return '工具执行结果';
  }
}
```

### 步骤 3: 注册工具

在 `ToolExecutorManager` 中注册你的工具：

```dart
final toolExecutor = ToolExecutorManager();
toolExecutor.registerTool(CustomTool());
```

## 内置工具

### 网页搜索工具

```dart
final webSearchTool = Tool(
  name: 'web_search',
  description: '搜索网页内容',
  parameters: {
    'query': '搜索关键词',
  },
);
```

### 计算器工具

```dart
final calculatorTool = Tool(
  name: 'calculator',
  description: '执行数学计算',
  parameters: {
    'expression': '数学表达式',
  },
);
```

### 文件操作工具

```dart
final fileReaderTool = Tool(
  name: 'read_file',
  description: '读取文件内容',
  parameters: {
    'path': '文件路径',
  },
);
```

## Agent 使用示例

### 在聊天中使用 Agent

```dart
// 创建带 Agent 的对话
final conversation = Conversation(
  id: uuid.v4(),
  title: 'Agent 对话',
  agentId: 'custom-agent-id',
  messages: [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 发送消息时，Agent 会自动处理工具调用
final stream = chatRepository.sendMessageStream(
  conversationId: conversation.id,
  content: '请帮我计算 123 + 456',
  config: ModelConfig(
    model: 'gpt-4',
    enableTools: true,
  ),
);
```

### 处理工具调用

Agent 系统会自动：

1. 解析 AI 返回的工具调用请求
2. 执行相应的工具
3. 将工具结果返回给 AI
4. 继续生成最终回复

```dart
// 工具调用流程示例
class AgentIntegration {
  Future<void> handleToolCall(ToolCall toolCall) async {
    // 1. 查找工具
    final tool = _toolExecutor.getTool(toolCall.name);
    
    // 2. 执行工具
    final result = await tool.execute(toolCall.arguments);
    
    // 3. 返回结果
    return result;
  }
}
```

## MCP 集成

### 连接 MCP 服务器

```dart
final mcpConfig = McpServerConfig(
  id: 'mcp-server-1',
  name: 'MCP 服务器',
  type: McpConnectionType.stdio,
  command: 'node',
  args: ['server.js'],
  enabled: true,
);

// 连接服务器
await mcpService.connect(mcpConfig);
```

### 发现 MCP 工具

```dart
// 获取服务器提供的工具列表
final tools = await mcpService.listTools(mcpConfig.id);

// 将工具添加到 Agent
final agent = customAgent.copyWith(
  tools: [...customAgent.tools, ...tools],
);
```

### 调用 MCP 工具

```dart
// 通过 MCP 调用工具
final result = await mcpService.callTool(
  serverId: mcpConfig.id,
  toolName: 'remote_tool',
  arguments: {'param': 'value'},
);
```

## 最佳实践

### 1. 工具设计原则

- **单一职责**：每个工具应该只做一件事
- **参数验证**：始终验证输入参数
- **错误处理**：优雅处理异常情况
- **性能优化**：避免长时间阻塞操作

### 2. Agent 配置

```dart
final agent = Agent(
  // 清晰的标识
  id: 'well-defined-id',
  name: '简洁的名称',
  
  // 详细的描述
  description: '准确描述 Agent 的能力和用途',
  
  // 精心设计的系统提示
  systemPrompt: '''
    你是一个专业的助手。
    你的主要职责是...
    请遵循以下规则：
    1. ...
    2. ...
  ''',
  
  // 合适的工具集
  tools: [
    // 只添加必要的工具
  ],
);
```

### 3. 错误处理

```dart
@override
Future<String> execute(Map<String, dynamic> args) async {
  try {
    // 参数验证
    if (!args.containsKey('required_param')) {
      throw ArgumentError('缺少必需参数: required_param');
    }
    
    // 执行工具逻辑
    final result = await performOperation(args);
    
    return result;
  } on ArgumentError catch (e) {
    return '参数错误: ${e.message}';
  } catch (e) {
    return '执行失败: $e';
  }
}
```

### 4. 日志记录

```dart
import 'package:logger/logger.dart';

class CustomTool extends Tool {
  final _logger = Logger();

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    _logger.i('开始执行工具: $name');
    _logger.d('参数: $args');
    
    try {
      final result = await performOperation(args);
      _logger.i('工具执行成功');
      return result;
    } catch (e) {
      _logger.e('工具执行失败', error: e);
      rethrow;
    }
  }
}
```

## 调试和测试

### 单元测试

```dart
void main() {
  group('CustomTool', () {
    late CustomTool tool;

    setUp(() {
      tool = CustomTool();
    });

    test('should execute successfully', () async {
      final result = await tool.execute({'input': 'test'});
      expect(result, isNotEmpty);
    });

    test('should handle missing parameters', () async {
      expect(
        () => tool.execute({}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

### 集成测试

```dart
void main() {
  testWidgets('Agent integration test', (tester) async {
    // 设置测试环境
    final agent = CustomAgent();
    final chatRepo = MockChatRepository();
    
    // 构建应用
    await tester.pumpWidget(MyApp(
      chatRepository: chatRepo,
    ));
    
    // 发送消息
    await tester.enterText(
      find.byType(TextField),
      '请使用工具执行任务',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    
    // 验证结果
    expect(find.text('工具执行结果'), findsOneWidget);
  });
}
```

## 常见问题

### Q: 如何处理长时间运行的工具？

A: 使用 `Isolate` 或 `compute` 在后台执行：

```dart
@override
Future<String> execute(Map<String, dynamic> args) async {
  return compute(_heavyOperation, args);
}

static String _heavyOperation(Map<String, dynamic> args) {
  // 耗时操作
  return result;
}
```

### Q: 如何限制工具的执行时间？

A: 使用 `timeout`：

```dart
@override
Future<String> execute(Map<String, dynamic> args) async {
  try {
    return await performOperation(args)
      .timeout(Duration(seconds: 30));
  } on TimeoutException {
    return '工具执行超时';
  }
}
```

### Q: 如何在工具间共享状态？

A: 使用 Riverpod 提供的状态管理：

```dart
final sharedStateProvider = StateProvider<Map<String, dynamic>>((ref) => {});

class StatefulTool extends ConsumerWidget {
  @override
  Future<String> execute(WidgetRef ref, Map<String, dynamic> args) async {
    final state = ref.read(sharedStateProvider);
    // 使用共享状态
    return result;
  }
}
```

## 参考资源

- [MCP 协议规范](https://modelcontextprotocol.io/)
- [OpenAI Function Calling](https://platform.openai.com/docs/guides/function-calling)
- [Flutter 异步编程](https://dart.dev/codelabs/async-await)
- [Riverpod 文档](https://riverpod.dev/)

## 贡献

如果你开发了通用的 Agent 或工具，欢迎提交 PR 贡献到项目中！

请确保：

1. 代码遵循项目的编码规范
2. 添加完整的文档和示例
3. 包含单元测试
4. 更新相关文档
