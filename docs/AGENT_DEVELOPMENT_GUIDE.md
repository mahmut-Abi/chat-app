# Agent 系统开发文档

本文档面向开发者，说明 Agent 系统的实现原理和开发指南。

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
- **Domain Layer**: AgentConfig、AgentTool、ToolExecutionResult、ToolCall
- **Data Layer**: AgentRepository、ToolExecutorManager、DefaultAgents、EnhancedAgentIntegration
- **Presentation Layer**: AgentProvider、AgentSelectorDialog、AgentManagementScreen

## 核心组件

### 1. AgentConfig
定义 Agent 的基本配置。详见 lib/features/agent/domain/agent_tool.dart

### 2. AgentTool
定义工具的结构和类型。

### 3. ToolExecutionResult
工具执行的结果，包含成功状态、结果文本、错误信息和元数据。

### 4. AgentRepository
核心数据访问层。支持 Agent 管理、Tool 管理、Tool 执行。

## 开发指南

### 添加新工具 (5 步)

#### 1. 定义工具类型
在 lib/features/agent/domain/agent_tool.dart 的 AgentToolType 枚举中添加新类型。

#### 2. 实现执行器
创建新的工具执行器类，继承 ToolExecutor 接口。实现 execute() 方法。

#### 3. 注册执行器
在 lib/features/agent/data/tool_executor.dart 的 ToolExecutorManager 中注册执行器。

#### 4. 创建工具配置
在初始化时使用 repository.createTool() 创建工具配置。

#### 5. 创建内置 Agent
在 lib/features/agent/data/default_agents.dart 中添加使用此工具的 Agent。

## 最佳实践

### 1. Agent 设计原则

**单一职责** - 每个 Agent 专注特定领域
- 好：数学专家、研究助手、文件管理员
- 坏：万能助手（太宽泛）

### 2. 工具开发原则

- 健壮的错误处理 - 验证参数、处理异常
- 清晰的参数定义 - 使用 JSON Schema 格式
- 完整的元数据返回 - 包含执行时间等信息
- 及时的资源释放 - 确保不会泄漏资源

## 代码规范

### 命名规范
- **Agent 名称**: 中文，以"助手"或"专家"结尾
- **工具名称**: snake_case，英文小写
- **类名**: PascalCase
- **方法名**: camelCase
- **常量**: UPPER_SNAKE_CASE

---

**最后更新**: 2025-01-20 | **版本**: 1.5.0
