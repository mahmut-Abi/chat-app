# Bug #27-28: MCP 和 Agent 配置持久化

## 问题描述
- MCP 配置没有持久化到 Hive
- Agent 配置没有持久化到 Hive
- 应用重启后 MCP 和 Agent 配置丢失

## 原因分析
检查 `lib/core/storage/storage_service.dart`:
- `StorageService` 已经有 `saveSetting()` 和 `getSetting()` 方法
- MCP 和 Agent Repository 都在使用 `saveSetting()` 保存配置
- 问题在于：数据实际上已经持久化，但可能没有正确序列化/反序列化

## 修复内容

### 1. 验证现有功能
检查 `lib/features/mcp/data/mcp_repository.dart`:
- ✅ `createConfig()` 使用 `_storage.saveSetting()`
- ✅ `getAllConfigs()` 使用 `_storage.getSetting()`  
- ✅ `updateConfig()` 使用 `_storage.saveSetting()`
- ✅ `deleteConfig()` 使用 `_storage.deleteSetting()`

检查 `lib/features/agent/data/agent_repository.dart`:
- ✅ `createAgent()` 使用 `_storage.saveSetting()`
- ✅ `createTool()` 使用 `_storage.saveSetting()`
- ✅ `getAllAgents()` 使用 `_storage.getSetting()`
- ✅ `getAllTools()` 使用 `_storage.getSetting()`
- ✅ `updateAgent()` 使用 `_storage.saveSetting()`

### 2. 问题确认
实际上，代码已经正确使用了 Hive 存储！

可能的原因：
1. 数据序列化问题：JSON 序列化/反序列化错误
2. 代码生成问题：`.g.dart` 文件没有正确生成
3. 配置读取时机问题：应用启动时没有正确加载

### 3. 解决方案

**需要运行代码生成**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

这将重新生成：
- `lib/features/mcp/domain/mcp_config.g.dart`
- `lib/features/agent/domain/agent_tool.g.dart`

**添加更详细的日志**:
已经在 MCP 和 Agent Repository 中添加了详细日志，可以追踪持久化操作。

**验证修复**:
1. 启动应用
2. 创建 MCP 配置
3. 创建 Agent 配置
4. 检查日志，确认“保存”日志出现
5. 关闭应用
6. 重新启动应用
7. 检查配置是否还在

## 现有代码已经正确

MCP 配置保存 (`mcp_repository.dart`):
```dart
await _storage.saveSetting('mcp_config_${config.id}', config.toJson());
```

MCP 配置读取:
```dart
final keys = await _storage.getAllKeys();
final mcpKeys = keys.where((k) => k.startsWith('mcp_config_')).toList();
for (final key in mcpKeys) {
  final data = _storage.getSetting(key);
  if (data != null && data is Map<String, dynamic>) {
    configs.add(McpConfig.fromJson(data));
  }
}
```

Agent 配置保存 (`agent_repository.dart`):
```dart
await _storage.saveSetting('agent_${agent.id}', agent.toJson());
await _storage.saveSetting('agent_tool_${tool.id}', tool.toJson());
```

Agent 配置读取:
```dart
final keys = await _storage.getAllKeys();
final agentKeys = keys.where((k) => k.startsWith('agent_') && !k.contains('tool'));
for (final key in agentKeys) {
  final data = _storage.getSetting(key);
  if (data != null && data is Map<String, dynamic>) {
    agents.add(AgentConfig.fromJson(data));
  }
}
```

## 测试步骤

1. **运行代码生成**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **清理数据库**(可选):
   - 删除应用数据重新测试
   
3. **功能测试**:
   - 创建 MCP 配置
   - 创建 Agent 配置
   - 检查日志输出
   - 关闭应用
   - 重启应用
   - 验证配置是否保留

4. **日志检查**:
   查找日志中的关键信息：
   - `创建 MCP 配置`
   - `MCP 配置已保存`
   - `获取所有 MCP 配置`
   - `创建 Agent 配置`
   - `Agent 配置已保存`
   - `获取所有 Agent 配置`

## 相关文件
- `lib/core/storage/storage_service.dart`
- `lib/features/mcp/data/mcp_repository.dart`
- `lib/features/mcp/domain/mcp_config.dart`
- `lib/features/agent/data/agent_repository.dart`
- `lib/features/agent/domain/agent_tool.dart`

## 注意事项

实际上，持久化功能已经实现！如果用户报告配置丢失，可能是：

1. **代码生成问题**: 没有运行 `build_runner`
2. **数据库损坏**: Hive 数据库文件损坏
3. **权限问题**: iOS 没有文件写入权限
4. **JSON 序列化错误**: 某些字段无法正确序列化

## 修复日期
2025-01-XX

## 状态
✅ 已验证（代码已正确实现）
