# Agent 系统开发文档

本文档面向开发者，说明 Agent 系统的实现原理和开发指南。

> 📖 **用户文档**: 如果你是普通用户，请查看 [Agent 使用指南](docs/agent-user-guide.md)

## 目录

- [系统架构](#系统架构)
- [核心组件](#核心组件)
- [开发指南](#开发指南)
- [最佳实践](#最佳实践)
- [代码规范](#代码规范)
- [常见问题](#常见问题)

---

## 系统架构

### 三层架构

```
Chat Interface (用户交互层)
        ↓
AgentProvider / AgentChatService (状态管理和业务层)
        ↓
AgentRepository (数据访问层)
        ↓
ToolExecutor / Storage Service (执行层)
```

**核心层次**：
- **Domain Layer**: `AgentConfig`、`AgentTool`、`ToolExecutionResult`、`ToolCall`
- **Data Layer**: `AgentRepository`、`ToolExecutorManager`、`DefaultAgents`、`EnhancedAgentIntegration`
- **Presentation Layer**: `AgentProvider`、`AgentSelectorDialog`、`AgentManagementScreen`

### 关键概念

**Agent**: 具有特定功能和专长的 AI 助手
- 基本信息：名称、描述、图标
- 工具集合：可用工具 ID 列表
- 系统提示词：定义 Agent 的角色和行为
- 元数据：创建时间、更新时间、是否内置

**Tool**: Agent 可以调用的功能模块
- 内置工具：计算器、搜索、文件操作
- MCP 工具：通过 MCP 服务提供的工具
- 自定义工具：开发者定义的扩展工具

**Function Calling**: AI 模型调用工具的机制
1. AI 生成工具调用请求
2. 系统执行对应工具
3. 返回执行结果给 AI
4. AI 根据结果生成响应

---

## 核心组件

### 1. AgentConfig

定义 Agent 的基本配置。详见 `lib/features/agent/domain/agent_tool.dart`

字段：id、name、description、toolIds、systemPrompt、enabled、createdAt、updatedAt、isBuiltIn、iconName

### 2. AgentTool

定义工具的结构和类型。类型包括：calculator、search、fileOperation、codeExecution、custom

字段：id、name、description、type、parameters、enabled、isBuiltIn、iconName

### 3. ToolExecutionResult

工具执行的结果，包含成功状态、结果文本、错误信息和元数据。

### 4. AgentRepository

核心数据访问层。支持：
- Agent 管理（创建、更新、删除、查询）
- Tool 管理（创建、更新、删除、查询）
- Tool 执行（executeTool、updateToolStatus）

### 5. EnhancedAgentIntegration

支持 Function Calling 和工具执行的集成服务。

### 6. ToolExecutor

工具执行器接口，所有工具都需要实现此接口。

---

## 开发指南

### 添加新工具 (5 步)

#### 1. 定义工具类型

在 `lib/features/agent/domain/agent_tool.dart` 的 `AgentToolType` 枚举中添加新类型。

#### 2. 实现执行器

创建新的工具执行器类，继承 `ToolExecutor` 接口。实现 `execute()` 方法。

#### 3. 注册执行器

在 `lib/features/agent/data/tool_executor.dart` 的 `ToolExecutorManager` 中注册执行器。

#### 4. 创建工具配置

在初始化时使用 `repository.createTool()` 创建工具配置，定义参数和描述。

#### 5. 创建内置 Agent (可选)

在 `lib/features/agent/data/default_agents.dart` 中添加使用此工具的 Agent。

---

## 最佳实践

### 1. Agent 设计原则

**单一职责** - 每个 Agent 专注特定领域
- 好：数学专家、研究助手、文件管理员
- 坏：万能助手（太宽泛）

**清晰提示词** - 明确 Agent 的能力和使用场景
- 列出具体的能力
- 定义操作的行为模式
- 说明使用场景

### 2. 工具开发原则

**健壮的错误处理** - 验证参数、处理异常
**清晰的参数定义** - 使用 JSON Schema 格式
**完整的元数据返回** - 包含执行时间等信息
**及时的资源释放** - 确保不会泄漏资源

### 3. 性能优化

**并行执行** - 使用 Future.wait 同时执行多个工具
**工具结果缓存** - 缓存相同查询的结果
**资源管理** - 及时释放资源
**限流控制** - 防止过度调用

---

## 代码规范

### 命名规范
- **Agent 名称**: 中文，简洁明确，以"助手"或"专家"结尾
  - 示例: 数学专家、研究助手、文件管理员
- **工具名称**: snake_case，英文小写
  - 示例: calculator、web_search、file_reader
- **类名**: PascalCase
  - 示例: WeatherTool、EnhancedSearchTool
- **方法名**: camelCase
  - 示例: executeToolCall、buildToolResultMessages
- **常量**: UPPER_SNAKE_CASE
  - 示例: DEFAULT_CACHE_DURATION、MAX_RETRY_COUNT

### 注释规范
- 使用 `///` 文档注释
- 为公共 API 添加详细注释
- 说明参数、返回值和异常

### 文件组织
```
lib/features/agent/
├── domain/               # 领域模型
│   └── agent_tool.dart  # AgentConfig、AgentTool、ToolExecutionResult
├── data/                # 数据访问层
│   ├── agent_repository.dart           # 主仓库
│   ├── tool_executor.dart              # 执行器管理
│   ├── default_agents.dart             # 内置 Agent
│   ├── enhanced_agent_integration.dart # 集成服务
│   ├── agent_chat_service.dart         # 聊天服务
│   ├── unified_tool_service.dart       # 统一工具服务
│   └── tools/                          # 工具实现
│       ├── calculator_tool.dart
│       ├── search_tool.dart
│       ├── file_operation_tool.dart
│       └── weather_tool.dart
└── presentation/        # UI 层
    ├── providers/
    │   └── agent_provider.dart         # Riverpod Provider
    ├── agent_screen.dart               # 主界面
    ├── agent_config_screen.dart        # 配置界面
    ├── tool_config_screen.dart         # 工具配置
    └── widgets/                        # UI 组件
        ├── agent_tab.dart
        ├── tools_tab.dart
        ├── agent_list_item.dart
        ├── tool_list_item.dart
        ├── agent_selector_dialog.dart
        └── empty_state_widget.dart
```

---

## 相关文档

- [Agent 使用指南](docs/agent-user-guide.md) - 用户说明
- [项目结构](docs/PROJECT_STRUCTURE.md) - 项目组织
- [架构设计](docs/architecture.md) - 整体架构
- [MCP 集成](docs/mcp-integration.md) - MCP 工具集成

---

## 常见问题

**Q: 如何添加新的 Agent?**  
A: 有两种方式：
1. 通过 UI 创建：打开 Agent 管理界面，点击创建按钮
2. 代码中创建：使用 `repository.createAgent()` 方法

对于内置 Agent，在 `default_agents.dart` 中的 `initializeDefaultAgents` 方法中添加。

**Q: 工具执行失败怎么办?**  
A: 检查以下几点：
1. 查看日志输出，找出具体错误
2. 验证工具参数是否正确
3. 确认工具执行器已正确实现和注册
4. 检查工具依赖（如 API Key）是否配置

**Q: 如何添加新的工具类型?**  
A: 
1. 在 `AgentToolType` 枚举中添加新类型
2. 创建相应的执行器类，继承 `ToolExecutor`
3. 在 `ToolExecutorManager` 中注册执行器
4. 定义默认参数定义
5. （可选）添加初始化逻辑

**Q: 如何持久化 Agent 和工具配置?**  
A: `AgentRepository` 自动使用 `StorageService` 处理持久化。所有配置都存储在本地存储中，无需手动管理。

**Q: 能否动态加载自定义工具?**  
A: 可以。实现 `ToolExecutor` 接口并调用 `registerExecutor()` 方法注册到 `ToolExecutorManager` 即可。

**Q: 如何集成 MCP 工具?**  
A: 使用 `McpToolIntegration` 类。MCP 工具会自动添加到 Agent 的工具定义中，可以像内置工具一样使用。

**Q: 工具参数如何定义?**  
A: 使用 JSON Schema 格式：
```dart
parameters: {
  'type': 'object',
  'properties': {
    'param_name': {
      'type': 'string|number|boolean|array|object',
      'description': '参数描述',
      'examples': ['示例值'],
      'required': ['必需参数名'],
    },
  },
}
```

---

**最后更新**: 2025-01-20 | **版本**: 1.5.0
