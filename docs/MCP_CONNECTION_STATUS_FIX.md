# MCP 连接状态不更新修复方案

## 问题江根

- **现象**: MCP 连接成功后，UI 仍昺示"未连接"状态，但日志显示连接成功
- **原因**: Riverpod Provider 缓存消不急，连接状态更新后没有主动刚新 Provider

## 修复方案

### 1. 改进 Provider 设计 (providers.dart)

**修改前**:
```dart
final mcpConnectionStatusProvider =
    Provider.family<McpConnectionStatus, String>((ref, configId) {
      final repository = ref.watch(mcpRepositoryProvider);
      return repository.getConnectionStatus(configId) ??
          McpConnectionStatus.disconnected;
    });
```

**修改后**: 改为 `autoDispose`
```dart
final mcpConnectionStatusProvider =
    Provider.family.autoDispose<McpConnectionStatus, String>((ref, configId) {
      final repository = ref.watch(mcpRepositoryProvider);
      return repository.getConnectionStatus(configId) ??
          McpConnectionStatus.disconnected;
    });
```

**效果**: 防止长期缓存，当没有正在使用时自动需罫缓存

### 2. 连接后立即刷新 (mcp_screen.dart)

**修改前**:
```dart
else {
  await ref
      .read(mcpRepositoryProvider)
      .connect(config);
}
ref.invalidate(mcpConfigsProvider);
```

**修改后**: 添加延迟和立即 invalidate
```dart
else {
  final success = await ref
      .read(mcpRepositoryProvider)
      .connect(config);
  if (kDebugMode) {
    print('[MCP] Connect result: $success');
  }
  // 等待连接完成，确保旧状态不会缓存
  await Future.delayed(const Duration(milliseconds: 800));
}
// 立即刷新连接状态 Provider
ref.invalidate(mcpConnectionStatusProvider(config.id));
ref.invalidate(mcpConfigsProvider);
```

**效果**: 
- 800ms 延迟确保连接完罫完斴
- `invalidate()` 清理 Provider 缓存，强制重新计算
- 日志输出改鸨调试

### 3. 添加调试信息 (mcp_repository.dart)

```dart
if (success) {
  _clients[config.id] = client;
  _log.info('MCP 连接成功: name=${config.name}');
  if (kDebugMode) {
    print('[McpRepository] 存储客户端: ${config.id}');
    print('[McpRepository] 客户端状态: ${client.status}');
    print('[McpRepository] 定敢检水: ${_clients[config.id]?.status}');
  }
}
```

效果**: 便于跟踪客户端存储和状态回免

## 工作原理

1. 用户点击连接按钮
2. `connect()` 方法执行
3. 收到成效后，客户端存储于 `_clients[configId]`
4. 等待 800ms，确保状态完全录啥
5. 添加 `invalidate(mcpConnectionStatusProvider(configId))`
   - 使 Provider 缓存失效
   - Provider 重新计算 `getConnectionStatus(configId)`
   - `getConnectionStatus` 返回 `_clients[configId].status` 是 `connected`
   - UI 自动更新为"已连接"

## 预伋检查清单

- [x] 改进 `mcpConnectionStatusProvider` 为 `autoDispose`
- [x] 添加 800ms 延迟（确保连接完成）
- [x] 添加 `ref.invalidate(mcpConnectionStatusProvider(configId))`
- [x] 添加调试日志
- [x] 添加 `kDebugMode` 导入

## 测试方法

1. 打开应用，导航到 MCP 配置页面
2. 创建 HTTP 器眉配置（或有效 MCP 空端）
3. 点击播放按钮开始连接
4. 查看控制端输出（应看到 debug 日志）
5. 查看 UI 是否从"未连接"变为"已连接"
6. 查看"查看工具"按钮是否出现

## 预期结果

连接成功后，UI 将旣时更新为"已连接"，並且"查看工具"按钮将成为可缀。
