# MCP 和 Agent 功能扩展

## 概述

为 MCP 服务和 Agent 功能添加了启用/停用开关，并编写了完整的单元测试确保功能可用。

## MCP 功能扩展

### 新增功能

1. **启用/停用开关**
   - 每个 MCP 配置都有独立的启用/停用开关
   - 使用 Switch 组件实现
   - 停用的 MCP 服务不能连接

2. **UI 改进**
   - 连接状态图标颜色区分（绿色/黄色/红色/灰色）
   - 连接按钮在停用时被禁用
   - 自动断开连接当服务被停用时

### 技术实现

**启用/停用逻辑** (`lib/features/mcp/presentation/mcp_screen.dart`):
```dart
Switch(
  value: config.enabled,
  onChanged: (value) async {
    final repository = ref.read(mcpRepositoryProvider);
    final updated = config.copyWith(enabled: value);
    await repository.updateConfig(updated);
    // 如果停用且正在连接，则断开连接
    if (!value && connectionStatus == McpConnectionStatus.connected) {
      await repository.disconnect(config.id);
    }
    ref.invalidate(mcpConfigsProvider);
  },
)
```

**连接按钮状态**:
```dart
IconButton(
  icon: Icon(
    connectionStatus == McpConnectionStatus.connected
        ? Icons.stop
        : Icons.play_arrow,
  ),
  onPressed: config.enabled ? () async {
    // 连接/断开逻辑
  } : null, // 停用时禁用按钮
)
```

## Agent 功能扩展

### 新增功能

1. **Agent 启用/停用**
   - 每个 Agent 配置都有独立的启用/停用开关
   - 停用的 Agent 不会在对话中被使用

2. **工具启用/停用**
   - 每个工具都有独立的启用/停用开关
   - 停用的工具不会被 Agent 调用
   - 新增 `updateToolStatus` 方法

3. **UI 改进**
   - 使用颜色区分启用/停用状态
     - 启用：主题颜色（蓝色）+ 绿色文字
     - 停用：灰色图标 + 灰色文字
   - 状态标签显示（已启用/已停用）

### 技术实现

**Agent 启用/停用** (`lib/features/agent/presentation/agent_screen.dart`):
```dart
Switch(
  value: agent.enabled,
  onChanged: (value) async {
    final repository = ref.read(agentRepositoryProvider);
    final updated = agent.copyWith(enabled: value);
    await repository.updateAgent(updated);
    ref.invalidate(agentConfigsProvider);
  },
)
```

**工具启用/停用**:
```dart
Switch(
  value: tool.enabled,
  onChanged: (value) async {
    final repository = ref.read(agentRepositoryProvider);
    await repository.updateToolStatus(tool.id, value);
    ref.invalidate(agentToolsProvider);
  },
)
```

**Repository 新增方法** (`lib/features/agent/data/agent_repository.dart`):
```dart
Future<void> updateToolStatus(String id, bool enabled) async {
  final keys = await _storage.getAllKeys();
  final toolKey = keys.firstWhere(
    (k) => k == 'agent_tool_$id',
    orElse: () => '',
  );
  
  if (toolKey.isEmpty) return;
  
  final data = _storage.getSetting(toolKey);
  if (data != null && data is Map<String, dynamic>) {
    final tool = AgentTool.fromJson(data);
    final updated = AgentTool(
      id: tool.id,
      name: tool.name,
      description: tool.description,
      type: tool.type,
      parameters: tool.parameters,
      enabled: enabled,
      iconName: tool.iconName,
    );
    await updateTool(updated);
  }
}
```

## 单元测试

### MCP 测试 (`test/unit/mcp_config_test.dart`)

**测试覆盖**:
- ✅ 创建 MCP 配置（默认值和自定义值）
- ✅ 更新配置
- ✅ JSON 序列化和反序列化
- ✅ 启用/停用切换
- ✅ 连接状态枚举

**测试统计**: 6 个测试，全部通过

### Agent 测试 (`test/unit/agent_config_test.dart` 和 `test/unit/agent_repository_test.dart`)

**AgentConfig 测试**:
- ✅ 创建 Agent 配置（默认值和自定义值）
- ✅ 更新配置
- ✅ JSON 序列化和反序列化
- ✅ 启用/停用切换

**AgentTool 测试**:
- ✅ 创建工具（默认值和自定义值）
- ✅ JSON 序列化和反序列化
- ✅ 启用/停用状态
- ✅ 工具类型枚举

**ToolExecutionResult 测试**:
- ✅ 成功结果
- ✅ 错误结果
- ✅ JSON 序列化和反序列化

**测试统计**: 22 个测试，全部通过

### 运行测试

```bash
# 运行所有新增测试
flutter test test/unit/mcp_config_test.dart test/unit/agent_config_test.dart test/unit/agent_repository_test.dart test/unit/mcp_repository_test.dart

# 结果：28 个测试全部通过 ✅
```

## UI 示例

### MCP 列表
```
┌─────────────────────────────────────┐
│ ◉ Test MCP         ON  ▶️  ✏️  🗑️  │
│   http://localhost:3000             │
│   ● 已连接                          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ◯ Disabled MCP     OFF  ⏸  ✏️  🗑️  │
│   http://localhost:3001             │
│   ○ 未连接                          │
└─────────────────────────────────────┘
```

### Agent 列表
```
┌─────────────────────────────────────┐
│ 🤖 Search Agent    ON   ✏️  🗑️      │
│    搜索助手                         │
│    ● 已启用                         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ⚙️ Code Agent      OFF  ✏️  🗑️      │
│    代码助手                         │
│    ○ 已停用                         │
└─────────────────────────────────────┘
```

### 工具列表
```
┌─────────────────────────────────────┐
│ 🔍 Web Search      ON   🗑️          │
│    网络搜索工具                     │
│    ● 已启用                         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ⚙️ Calculator      OFF  🗑️          │
│    计算器工具                       │
│    ○ 已停用                         │
└─────────────────────────────────────┘
```

## 使用说明

### MCP 服务

1. **启用 MCP 服务**
   - 打开 MCP 配置页面
   - 找到要启用的服务
   - 打开启用开关
   - 点击连接按钮连接服务

2. **停用 MCP 服务**
   - 打开 MCP 配置页面
   - 找到要停用的服务
   - 关闭启用开关
   - 服务会自动断开连接

### Agent 和工具

1. **启用 Agent**
   - 打开 Agent 管理页面
   - 在 Agent 标签页找到要启用的 Agent
   - 打开启用开关
   - 启用的 Agent 可以在对话中使用

2. **管理工具**
   - 打开 Agent 管理页面
   - 切换到工具标签页
   - 打开/关闭工具的启用开关
   - 只有启用的工具会被 Agent 调用

## 注意事项

1. **MCP 服务**
   - 停用 MCP 服务会自动断开连接
   - 停用的服务不能手动连接
   - 启用状态会持久化到本地存储

2. **Agent 和工具**
   - 停用的 Agent 不会在对话中被使用
   - 停用的工具不会被任何 Agent 调用
   - 启用状态会立即生效

3. **测试覆盖**
   - 所有核心功能都有单元测试
   - 测试确保启用/停用逻辑正确
   - JSON 序列化和反序列化经过验证

## 相关文件

### MCP
- `lib/features/mcp/domain/mcp_config.dart` - 数据模型
- `lib/features/mcp/presentation/mcp_screen.dart` - UI 实现
- `test/unit/mcp_config_test.dart` - 单元测试
- `test/unit/mcp_repository_test.dart` - 仓库测试

### Agent
- `lib/features/agent/domain/agent_tool.dart` - 数据模型
- `lib/features/agent/data/agent_repository.dart` - 仓库实现
- `lib/features/agent/presentation/agent_screen.dart` - UI 实现
- `test/unit/agent_config_test.dart` - 单元测试
- `test/unit/agent_repository_test.dart` - 仓库测试
