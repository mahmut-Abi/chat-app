# MCP 配置调试指南

## 问题描述

在对话页面选择 MCP 时显示"暂无MCP配置,请先在设置中创建",但实际上已经在设置页面配置了 MCP。

## 诊断步骤

本次修改添加了详细的调试日志,帮助诊断 MCP 配置加载问题。

### 1. 添加的调试日志位置

#### McpRepository

文件: `lib/features/mcp/data/mcp_repository.dart`

**addConfig() 方法**:
- 记录配置添加操作
- 显示配置 ID 和存储键
- 验证保存是否成功

**getAllConfigs() 方法**:
- 记录开始获取配置
- 显示所有存储键
- 过滤出 MCP 配置键
- 记录每个配置的解析结果
- 显示最终返回的配置数量

#### StorageService

文件: `lib/core/storage/storage_service.dart`

- saveSetting(): 记录保存的键和值类型,验证保存结果
- getSetting(): 记录读取的键,显示是否找到值
- getAllKeys(): 记录总键数和键列表

#### ChatFunctionMenu

文件: `lib/features/chat/presentation/widgets/chat_function_menu.dart`

- _showMcpSelector(): 记录 MCP 选择器显示过程和加载结果

### 2. 如何使用调试日志

在 Debug 模式下运行应用:

```bash
flutter run -d macos --debug
# 或
flutter run -d chrome --debug
```

### 3. 预期日志输出示例

**添加 MCP 配置时**:
```
[McpRepository] 添加 MCP 配置: 我的MCP服务器
[McpRepository]   ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
[McpRepository]   存储键: mcp_config_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
[StorageService] 保存设置: key=mcp_config_..., valueType=String
[StorageService] 验证保存: 成功
```

**在聊天页面选择 MCP 时**:
```
[ChatFunctionMenu] 开始显示 MCP 选择器
[McpRepository] 开始获取所有 MCP 配置
[StorageService] getAllKeys: 总共 X 个键
[McpRepository] MCP 配置键: [mcp_config_xxx]
[McpRepository] 成功解析配置: 我的MCP服务器
[McpRepository] 返回 1 个配置
[ChatFunctionMenu] MCP 列表加载完成: 1 个配置
```

### 4. 常见问题诊断

#### 配置保存失败
- 检查 StorageService.init() 是否被调用
- 检查应用是否有写入权限

#### 配置读取为空  
- 查看日志中 MCP 配置键列表
- 检查保存时是否成功
- 检查是否有解析错误

#### 配置解析失败
- 检查错误信息
- 可能需要清除旧数据重新创建
- 检查 McpConfig.fromJson() 实现

### 5. 调试完成后

- 这些日志仅在 Debug 模式输出
- Release 模式会自动移除
- 调试完成后可考虑移除部分详细日志

---

## Agent 配置调试

和 MCP 一样，Agent 配置也添加了详细的调试日志。

### 添加的调试日志位置

#### AgentRepository

文件: `lib/features/agent/data/agent_repository.dart`

**createAgent() 方法**:
- 记录配置创建操作
- 显示配置 ID 和存储键
- 验证保存是否成功

**getAllAgents() 方法**:
- 记录开始获取配置
- 显示所有存储键
- 过滤出 Agent 配置键 (排除 tool 相关键)
- 记录每个配置的解析结果
- 显示最终返回的配置数量

#### ChatFunctionMenu

文件: `lib/features/chat/presentation/widgets/chat_function_menu.dart`

- _showAgentSelector(): 记录 Agent 选择器显示过程和加载结果

### 预期日志输出示例

**创建 Agent 配置时**:
```
[AgentRepository] Agent 配置已保存
[AgentRepository]   ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
[AgentRepository]   存储键: agent_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
[StorageService] 保存设置: key=agent_..., valueType=String
[StorageService] 验证保存: 成功
[AgentRepository] 验证保存: 成功
```

**在聊天页面选择 Agent 时**:
```
[ChatFunctionMenu] 开始显示 Agent 选择器
[AgentRepository] 开始获取所有 Agent 配置
[StorageService] getAllKeys: 总共 X 个键
[AgentRepository] Agent 配置键: [agent_xxx]
[AgentRepository] 成功解析配置: 我的Agent
[AgentRepository] 返回 1 个配置
[ChatFunctionMenu] Agent 列表加载完成: 1 个配置
[ChatFunctionMenu]   - 我的Agent (enabled: true)
```

### 注意事项

- Agent 配置键格式: `agent_{id}`
- Agent 工具键格式: `agent_tool_{id}`
- getAllAgents() 会过滤掉包含 "tool" 的键，只返回 Agent 配置
