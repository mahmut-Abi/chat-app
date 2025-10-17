# Agent 配置持久化说明

## 概述

Agent 配置和工具通过 Hive 数据库实现持久化存储，确保应用重启后数据不丢失。

## 存储机制

### 1. 存储位置

Agent 相关数据存储在 Hive 的 `settings` box 中，使用以下键格式：

- **Agent 配置**: `agent_{id}`
- **工具**: `agent_tool_{id}`

### 2. 数据格式

数据以 JSON 字符串格式存储：

```dart
// Agent 配置示例
{
  "id": "uuid-v4",
  "name": "我的助手",
  "description": "一个智能助手",
  "toolIds": ["tool-id-1", "tool-id-2"],
  "systemPrompt": "你是一个专业的助手",
  "enabled": true,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}

// 工具示例
{
  "id": "uuid-v4",
  "name": "calculator",
  "description": "执行数学计算",
  "type": "calculator",
  "parameters": {
    "type": "object",
    "properties": {
      "expression": {
        "type": "string",
        "description": "要计算的数学表达式"
      }
    },
    "required": ["expression"]
  },
  "enabled": true,
  "iconName": null
}
```

## API 接口

### AgentRepository

`AgentRepository` 提供了完整的 CRUD 操作：

#### 创建 Agent

```dart
final agent = await repository.createAgent(
  name: '我的助手',
  description: '一个智能助手',
  toolIds: ['tool-id-1', 'tool-id-2'],
  systemPrompt: '你是一个专业的助手',
);
```

数据会立即保存到 Hive，使用 `await _storage.saveSetting('agent_${agent.id}', jsonEncode(agent.toJson()))`。

#### 读取所有 Agent

```dart
final agents = await repository.getAllAgents();
```

该方法会：
1. 获取所有以 `agent_` 开头且不包含 `tool` 的键
2. 解析 JSON 字符串为 `AgentConfig` 对象
3. 返回 Agent 列表

#### 更新 Agent

```dart
final updated = agent.copyWith(name: '新名称');
await repository.updateAgent(updated);
```

更新操作会：
1. 自动更新 `updatedAt` 时间戳
2. 重新保存到 Hive

#### 删除 Agent

```dart
await repository.deleteAgent(agentId);
```

从 Hive 中删除对应的键。

### 工具操作

工具的操作与 Agent 类似：

```dart
// 创建工具
final tool = await repository.createTool(
  name: 'calculator',
  description: '执行数学计算',
  type: AgentToolType.calculator,
  parameters: {...},
);

// 读取所有工具
final tools = await repository.getAllTools();

// 更新工具
await repository.updateTool(tool);

// 更新工具状态
await repository.updateToolStatus(toolId, enabled: false);

// 删除工具
await repository.deleteTool(toolId);
```

## 数据一致性

### 1. 兼容性

代码支持两种数据格式：
- 新格式：JSON 字符串
- 旧格式：直接存储的 Map（向后兼容）

```dart
final Map<String, dynamic> json;
if (data is String) {
  json = jsonDecode(data) as Map<String, dynamic>;
} else if (data is Map<String, dynamic>) {
  json = data;
}
```

### 2. 错误处理

- 如果解析失败，会跳过该条数据而不是抛出异常
- 确保应用不会因为损坏的数据而崩溃

### 3. 事务保证

Hive 提供了自动的事务保证：
- 所有写操作都是原子的
- 数据立即持久化到磁盘
- 应用崩溃不会导致数据丢失

## 数据迁移

如果需要迁移 Agent 配置数据：

### 导出数据

```dart
final agents = await repository.getAllAgents();
final tools = await repository.getAllTools();

final exportData = {
  'agents': agents.map((a) => a.toJson()).toList(),
  'tools': tools.map((t) => t.toJson()).toList(),
};

final jsonString = jsonEncode(exportData);
// 保存到文件或导出
```

### 导入数据

```dart
final importData = jsonDecode(jsonString) as Map<String, dynamic>;

// 导入 Agent
final agentsList = importData['agents'] as List;
for (final agentJson in agentsList) {
  final agent = AgentConfig.fromJson(agentJson);
  await repository.saveConfig(agent);
}

// 导入工具
final toolsList = importData['tools'] as List;
for (final toolJson in toolsList) {
  final tool = AgentTool.fromJson(toolJson);
  await repository.updateTool(tool);
}
```

## 性能考虑

1. **读取性能**: Hive 是高性能的键值存储，读取速度非常快
2. **写入性能**: 写入操作会立即持久化，但对于批量操作建议使用事务
3. **内存占用**: Agent 配置数据量较小，不会占用大量内存

## 调试

可以通过日志查看持久化操作：

```dart
// AgentRepository 会记录所有操作
_log.info('创建 Agent 配置', {'name': name, 'toolsCount': toolIds.length});
_log.debug('Agent 配置已保存', {'agentId': agent.id});
```

## 测试持久化

要验证持久化是否正常工作：

1. 创建一个 Agent 或工具
2. 重启应用
3. 检查数据是否仍然存在

```dart
// 创建 Agent
final agent = await repository.createAgent(
  name: '测试 Agent',
  description: '测试持久化',
  toolIds: [],
);

// 重启应用后
final agents = await repository.getAllAgents();
final found = agents.any((a) => a.id == agent.id);
print('Agent 持久化成功: $found');
```

## 总结

Agent 配置的持久化机制：

✅ **已实现**:
- 使用 Hive 进行持久化存储
- 支持完整的 CRUD 操作
- 自动序列化/反序列化
- 数据一致性保证
- 向后兼容
- 错误处理

✅ **稳定性**:
- 事务保证
- 原子操作
- 崩溃恢复

✅ **性能**:
- 高速读写
- 低内存占用
- 支持大量配置

Agent 配置的持久化已经完全实现并可以正常使用。
