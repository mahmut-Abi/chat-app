# Agent 系统开发文档

本文档面向开发者，说明 Agent 系统的实现原理和开发指南。

> 📖 **用户文档**: 如果你是普通用户，请查看 [Agent 使用指南](docs/agent-user-guide.md)

## 目录

- [系统架构](#系统架构)
- [核心组件](#核心组件)
- [开发指南](#开发指南)
- [最佳实践](#最佳实践)

---

## 系统架构

### 三层架构

```
Chat Interface (用户交互层)
        ↓
Agent Provider (状态管理层)
        ↓
Agent Repository (业务逻辑层)
        ↓
Agent Config / Tool Executor / Tool Storage
```

**核心层次**：
- **Domain Layer**: AgentConfig、AgentTool、ToolExecutionResult
- **Data Layer**: AgentRepository、ToolExecutorManager、DefaultAgents
- **Presentation Layer**: AgentProvider、AgentSelectorDialog、AgentManagementScreen

---

## 核心组件

### 1. AgentConfig

定义 Agent 的基本配置：

```dart
@freezed
class AgentConfig with _$AgentConfig {
  const factory AgentConfig({
    required String id,           // UUID
    required String name,         // Agent 名称
    required String description,  // 功能描述
    required List<String> toolIds,// 可用工具列表
    String? systemPrompt,         // 系统提示词
    @Default(true) bool isEnabled,
    @Default(false) bool isBuiltIn,
  }) = _AgentConfig;
}
```

### 2. AgentTool

定义工具的结构：

```dart
enum AgentToolType {
  calculator,     // 计算器
  search,        // 搜索
  fileOperation, // 文件操作
  codeExecution, // 代码执行
  custom,        // 自定义
}

@freezed
class AgentTool with _$AgentTool {
  const factory AgentTool({
    required String id,
    required String name,
    required String description,
    required AgentToolType type,
    required Map<String, dynamic> parameters,
    @Default(true) bool enabled,
  }) = _AgentTool;
}
```

### 3. AgentRepository

核心方法：

```dart
// Agent 管理
Future<AgentConfig> createAgent({...});
Future<void> updateAgent(AgentConfig agent);
Future<void> deleteAgent(String id);
Future<List<AgentConfig>> getAllAgents();

// Tool 管理
Future<AgentTool> createTool({...});
Future<List<AgentTool>> getAllTools();

// Tool 执行
Future<ToolExecutionResult> executeTool(
  AgentTool tool,
  Map<String, dynamic> arguments,
);
```

---

## 开发指南

### 添加新工具

#### 1. 定义工具类型

```dart
enum AgentToolType {
  // ... 现有类型
  weather,  // 新增
}
```

#### 2. 实现执行器

```dart
class WeatherExecutor implements ToolExecutor {
  @override
  Future<ToolExecutionResult> execute(Map<String, dynamic> arguments) async {
    try {
      final city = arguments['city'] as String;
      final weather = await _fetchWeather(city);
      
      return ToolExecutionResult(
        success: true,
        result: weather,
      );
    } catch (e) {
      return ToolExecutionResult(
        success: false,
        error: '获取天气失败: ${e.toString()}',
      );
    }
  }
}
```

#### 3. 注册执行器

```dart
ToolExecutorManager() {
  registerExecutor(AgentToolType.weather, WeatherExecutor());
}
```

#### 4. 创建工具配置

```dart
await repository.createTool(
  name: 'weather',
  description: '查询城市天气',
  type: AgentToolType.weather,
  parameters: {
    'type': 'object',
    'properties': {
      'city': {'type': 'string', 'description': '城市名称'},
    },
    'required': ['city'],
  },
);
```

### 创建内置 Agent

在 `lib/features/agent/data/default_agents.dart` 中：

```dart
await repository.createAgent(
  name: '数学专家',
  description: '专注于数学计算',
  toolIds: [calcTool.id],
  systemPrompt: '''你是一位数学专家，擅长解决各类数学问题。''',
  isBuiltIn: true,
  iconName: 'calculate',
);
```

---

## 最佳实践

### 1. Agent 设计原则

**单一职责** - 每个 Agent 专注特定领域
```dart
✅ Agent('数学专家', tools: [calculator])
❌ Agent('万能助手', tools: [calculator, search, file, code, ...])
```

**清晰提示词** - 明确 Agent 的能力和使用场景
```dart
✅ '''你是数学专家，擅长：1. 代数计算 2. 几何问题 3. 统计分析'''
❌ '''你是数学专家'''
```

### 2. 工具开发原则

**健壮的错误处理**
```dart
try {
  // 验证参数
  if (!arguments.containsKey('param')) {
    return ToolExecutionResult(success: false, error: '缺少参数');
  }
  
  // 执行逻辑
  final result = await _doWork(arguments);
  return ToolExecutionResult(success: true, result: result);
  
} catch (e) {
  LogService().error('执行失败', e);
  return ToolExecutionResult(success: false, error: e.toString());
}
```

**清晰的参数定义**
```dart
parameters: {
  'type': 'object',
  'properties': {
    'city': {
      'type': 'string',
      'description': '城市名称',
      'examples': ['北京', '上海'],
    },
  },
  'required': ['city'],
}
```

### 3. 性能优化

**缓存工具结果**
```dart
class CachedExecutor implements ToolExecutor {
  final Map<String, ToolExecutionResult> _cache = {};
  
  @override
  Future<ToolExecutionResult> execute(Map<String, dynamic> args) async {
    final key = _generateKey(args);
    if (_cache.containsKey(key)) return _cache[key]!;
    
    final result = await _actualExecute(args);
    _cache[key] = result;
    return result;
  }
}
```

**并行执行**
```dart
final results = await Future.wait([
  repository.executeTool(tool1, args1),
  repository.executeTool(tool2, args2),
]);
```

---

## 代码规范

- **Agent 名称**: 中文，简洁明确
- **工具名称**: snake_case
- **类名**: PascalCase
- **方法名**: camelCase
- **注释**: 使用 `///` 文档注释

---

## 相关文档

- [Agent 使用指南](docs/agent-user-guide.md) - 用户说明
- [项目结构](docs/PROJECT_STRUCTURE.md) - 项目组织
- [架构设计](docs/architecture.md) - 整体架构

---

## 常见问题

**Q: 如何添加新的 Agent？**  
A: 在 `default_agents.dart` 中添加初始化逻辑，或通过 UI 创建。

**Q: 工具执行失败怎么办？**  
A: 检查日志，验证参数，确保执行器正确实现。

**Q: 如何持久化配置？**  
A: AgentRepository 自动使用 Hive 处理持久化。

**Q: 可以动态加载工具吗？**  
A: 可以，实现 ToolExecutor 接口并注册到 ToolExecutorManager。

---

**最后更新**: 2025-01-18 | **版本**: 1.4.0
