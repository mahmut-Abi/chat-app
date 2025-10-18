# 内置 Agent 说明文档

本文档介绍应用中的内置 Agent 及其使用方法。

## 📋 概述

应用内置了 5 个预配置的 Agent，每个 Agent 都针对特定的使用场景进行了优化，配备了相应的工具和系统提示词。

## 🤖 内置 Agent 列表

### 1. 通用助手 📋

**图标**: `assistant`  
**描述**: 全能型助手，可以帮助你解答问题、进行计算和搜索

**配备工具**:
- 计算器工具
- 搜索工具

**系统提示词**:
```
你是一个友好、专业的通用助手。

你可以：
1. 回答各类问题
2. 进行数学计算
3. 搜索相关信息

请用清晰、准确的方式回答用户的问题。
```

**适用场景**:
- 日常对话
- 一般性问题咨询
- 需要计算或搜索的综合任务

**使用示例**:
```
用户: 帮我计算 (23 + 45) * 2
助手: 让我为你计算：(23 + 45) * 2 = 136
```

---

### 2. 数学专家 🔢

**图标**: `calculate`  
**描述**: 专注于数学计算和问题解答

**配备工具**:
- 计算器工具

**系统提示词**:
```
你是一位经验丰富的数学专家。

你擅长：
1. 代数计算和方程求解
2. 几何问题分析
3. 统计和概率计算
4. 数学概念解释

请提供详细的解题步骤和清晰的解释。
```

**适用场景**:
- 数学作业辅导
- 数学公式推导
- 统计数据分析
- 数学概念学习

**使用示例**:
```
用户: 解方程 2x + 5 = 15
助手: 让我帮你一步步求解：
1. 2x + 5 = 15
2. 2x = 15 - 5
3. 2x = 10
4. x = 5

因此，方程的解是 x = 5
```

---

### 3. 研究助手 🔍

**图标**: `search`  
**描述**: 帮助进行学术研究和信息收集

**配备工具**:
- 搜索工具
- 文件操作工具

**系统提示词**:
```
你是一个专业的研究助手。

你可以帮助：
1. 搜索和收集相关文献
2. 整理和分析资料
3. 提供研究思路和建议
4. 管理研究文档

请提供结构化的研究支持。
```

**适用场景**:
- 学术研究
- 文献综述
- 资料整理
- 研究方向规划

**使用示例**:
```
用户: 帮我搜索关于人工智能在医疗领域的应用
助手: 我为你搜索了相关内容：
1. AI 辅助诊断系统
2. 医学影像智能分析
3. 药物研发加速
...
```

---

### 4. 文件管理员 📁

**图标**: `folder`  
**描述**: 专注于文件和目录管理

**配备工具**:
- 文件操作工具

**系统提示词**:
```
你是一个高效的文件管理助手。

你可以：
1. 读取和写入文件
2. 列出目录内容
3. 获取文件信息
4. 整理和组织文件

请帮助用户高效管理文件。
```

**适用场景**:
- 文件内容查看
- 文件信息获取
- 目录结构浏览
- 文件组织管理

**使用示例**:
```
用户: 查看当前目录的文件
助手: 当前目录包含以下文件：
📁 documents/
📁 images/
📄 readme.txt
📄 config.json
```

---

### 5. 编程助手 💻

**图标**: `code`  
**描述**: 帮助解决编程问题和代码审查

**配备工具**:
- 文件操作工具
- 搜索工具

**系统提示词**:
```
你是一个经验丰富的编程助手。

你擅长：
1. 代码编写和审查
2. 调试和问题排查
3. 技术文档查询
4. 最佳实践建议

请提供清晰的代码示例和解释。
```

**适用场景**:
- 代码开发
- Bug 调试
- 代码审查
- 技术学习

**使用示例**:
```
用户: 帮我审查这段 Python 代码
助手: 让我分析一下你的代码：
1. 代码结构清晰
2. 建议添加错误处理
3. 可以优化性能...
```

## 🔧 技术实现

### 初始化流程

内置 Agent 在应用首次启动时自动创建：

```dart
// lib/features/agent/data/default_agents.dart
class DefaultAgents {
  static Future<void> initializeDefaultAgents(
    AgentRepository repository,
  ) async {
    // 检查是否已初始化
    final existingAgents = await repository.getAllAgents();
    if (existingAgents.any((a) => a.isBuiltIn)) return;
    
    // 创建内置 Agent
    await _createBuiltInAgents(repository);
  }
}
```

### Provider 集成

通过 Riverpod Provider 管理初始化：

```dart
// lib/features/agent/presentation/providers/agent_provider.dart
final initializeDefaultAgentsProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(agentRepositoryProvider);
  await ref.watch(initializeDefaultToolsProvider.future);
  await DefaultAgents.initializeDefaultAgents(repository);
});
```

### 数据模型

Agent 配置包含以下字段：

```dart
class AgentConfig {
  final String id;           // 唯一标识
  final String name;         // 名称
  final String? description; // 描述
  final List<String> toolIds;// 工具 ID 列表
  final String? systemPrompt;// 系统提示词
  final bool isBuiltIn;      // 是否为内置 Agent
  final String? iconName;    // 图标名称
  // ...
}
```

## 📝 使用指南

### 1. 选择 Agent

在聊天界面点击功能菜单，选择需要的 Agent：

```
聊天输入框 → 功能菜单(+) → Agent → 选择内置 Agent
```

### 2. 开始对话

选择 Agent 后，该 Agent 的系统提示词和工具将自动应用到对话中。

### 3. 切换 Agent

随时可以切换到其他 Agent 或取消 Agent 选择。

### 4. 自定义 Agent

除了使用内置 Agent，用户还可以：
- 创建自定义 Agent
- 修改内置 Agent（创建副本）
- 配置不同的工具组合

## 🎯 最佳实践

### 选择合适的 Agent

| 任务类型 | 推荐 Agent | 原因 |
|---------|-----------|------|
| 数学计算 | 数学专家 | 专注数学，提供详细步骤 |
| 信息搜索 | 研究助手 | 搜索+文件管理能力 |
| 代码相关 | 编程助手 | 代码专业知识 |
| 文件操作 | 文件管理员 | 文件管理专家 |
| 综合任务 | 通用助手 | 多功能支持 |

### Agent 与工具的关系

- **Agent** = 系统提示词 + 工具集合
- **工具** = 具体执行能力（计算、搜索、文件操作等）
- 好的 Agent 配置需要合适的提示词和工具组合

### 提示词设计原则

1. **明确身份**: 清楚说明 Agent 的角色
2. **列出能力**: 说明 Agent 可以做什么
3. **设定风格**: 定义回答的方式和风格
4. **注重专业**: 针对特定场景优化

## 🔄 维护和更新

### 重置内置 Agent

如果内置 Agent 被修改或删除，可以重置：

```dart
await DefaultAgents.resetDefaultAgents(repository);
```

### 添加新的内置 Agent

在 `default_agents.dart` 中添加新的 Agent 配置：

```dart
defaultAgents.add(
  repository.createAgent(
    name: '新 Agent',
    description: '描述',
    toolIds: [tool1.id, tool2.id],
    systemPrompt: '系统提示词',
    isBuiltIn: true,
    iconName: '图标名',
  ),
);
```

### 更新现有 Agent

修改 `default_agents.dart` 中对应 Agent 的配置，然后重置。

## 🐛 故障排查

### Agent 没有显示

**可能原因**:
- 工具未初始化
- 初始化失败

**解决方案**:
```dart
// 检查日志
await ref.read(initializeDefaultToolsProvider.future);
await ref.read(initializeDefaultAgentsProvider.future);
```

### Agent 工具不工作

**可能原因**:
- 工具未注册
- 工具执行失败

**解决方案**:
- 检查 `ToolExecutorManager` 是否注册了对应工具
- 查看工具执行日志

### Agent 被意外删除

**解决方案**:
```dart
// 重置内置 Agent
await DefaultAgents.resetDefaultAgents(repository);
```

## 📚 相关文档

- [Agent 功能验证](agent-functionality-verification.md)
- [Agent 开发指南](agent-development.md)
- [Agent 持久化](agent-persistence.md)
- [项目结构说明](project-structure.md)

---

**最后更新**: 2025-01-18  
**维护人员**: Development Team
