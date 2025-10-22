# MCP 连接状态不更新问题修复

## 问题描述
MCP 连接成功后，UI 仍显示"未连接"状态，但日志显示连接成功。

## 根本原因
1. `mcpConnectionStatusProvider` 是一个普通 Provider，会缓存结果
2. 连接成功时，状态被更新到 `_clients[configId]` 中的 client.status
3. 但 Provider 的缓存没有被清理，所以 UI 仍显示旧状态

## 修复方案

### 1. 改进 Provider 设计
将 `mcpConnectionStatusProvider` 改为 `autoDispose`，这样可以避免长期缓存：

```dart
final mcpConnectionStatusProvider =
    Provider.family.autoDispose<McpConnectionStatus, String>((ref, configId) {
      final repository = ref.watch(mcpRepositoryProvider);
      return repository.getConnectionStatus(configId) ??
          McpConnectionStatus.disconnected;
    });
```

### 2. 连接后立即刷新状态
在 `mcp_screen.dart` 的连接按钮中添加：

```dart
else {
  final success = await ref
      .read(mcpRepositoryProvider)
      .connect(config);
  // 等待连接完成
  await Future.delayed(const Duration(milliseconds: 800));
}
// 立即刷新 Provider 缓存
ref.invalidate(mcpConnectionStatusProvider(config.id));
```

### 3. 实现状态回调通知
可选：在 McpRepository 中添加回调，当连接状态变化时主动通知：

```dart
void Function(McpConnectionStatus)? onConnectionStatusChanged;

Future<bool> connect(McpConfig config) async {
  // ... 连接逻辑 ...
  if (success) {
    _clients[config.id] = client;
    // 通知状态变化
    onConnectionStatusChanged?.call(McpConnectionStatus.connected);
  }
}
```

## 已应用的修复

✅ 将 `mcpConnectionStatusProvider` 改为 autoDispose
✅ 连接后添加 800ms 延迟以确保状态完全更新
✅ 连接后显式调用 `ref.invalidate()` 清理缓存
✅ 添加调试日志以跟踪连接状态

## 测试方法

1. 创建 MCP 配置（HTTP 端点）
2. 点击播放按钮启动连接
3. 观察日志和 UI 状态的变化
4. 状态应从"未连接"→"连接中"→"已连接"

## 预期结果

连接成功后，UI 会显示"已连接"状态，查看工具按钮会出现。
