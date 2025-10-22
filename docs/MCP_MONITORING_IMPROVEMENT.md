# MCP 监控检查系统改进方案

## 概述

本方案解决 MCP 功能中监控检查不够齐全的问题，特别是对不支持某些检查方式的 MCP 服务器的适配。

## 核心改进

### 1. 灵活的健康检查策略 (HealthCheckStrategy)

支持多种检查方式，自动选择最适合的策略：

- **standard**: 标准 HTTP GET 请求到 /health 端点
- **probe**: 对多个端点进行探测（自动发现）
- **toolsListing**: 通过工具列表端点检查
- **networkOnly**: 只检查网络连通性
- **custom**: 自定义检查（由使用者提供）
- **disabled**: 禁用健康检查

**优点**：
- 适配多种 MCP 服务器实现
- 自动降级处理
- 不强制要求特定的健康检查端点

### 2. 完整的监控系统 (McpMonitor)

提供全功能的连接监控和恢复机制：

**主要功能**：
- 定期健康检查
- 自动故障检测
- 智能恢复策略
- 策略自动切换
- 历史记录追踪

**使用示例**：
```dart
final monitor = McpMonitor(
  config: mcpConfig,
  strategy: HealthCheckStrategy.probe,
  healthCheckInterval: Duration(seconds: 30),
  maxRetries: 3,
);

await monitor.start();

// 监听事件
monitor.events.listen((event) {
  print('MCP 事件: \$event');
});

// 获取统计信息
print('成功率: \${monitor.getSuccessRate()}');
print('最新检查: \${monitor.getLatestHealthCheck()}');
```

### 3. 多层诊断服务 (McpMonitorDiagnosticsService)

逐层诊断 MCP 连接问题：

**诊断层次**：
1. DNS 解析检查
2. TCP 连接检查
3. TLS 会话检查
4. HTTP 可达性检查
5. MCP 应用层检查
6. 工具可用性检查

**自动生成建议**（基于诊断结果）

**使用示例**：
```dart
final diagnostics = McpMonitorDiagnosticsService();
final result = await diagnostics.diagnose(config);

print('诊断摘要: \${result.getSummary()}');
print('完全健康: \${result.isFullyHealthy}');
print('不可修复: \${result.isIrrecoverable}');
print('建议: \${result.recommendations}');
```

### 4. 改进的客户端基类 (ImprovedMcpClientBase)

集成监控功能的客户端基类：

```dart
class MyMcpClient extends ImprovedMcpClientBase {
  @override
  Future<bool> connect() async {
    // 实现连接逻辑
    // 自动获得监控支持
  }
  
  @override
  Future<bool> healthCheck({HealthCheckStrategy? strategy}) async {
    final s = strategy ?? monitor.strategy;
    // 使用指定策略执行健康检查
    final result = await monitor.performHealthCheck();
    return result.success;
  }
}
```

## 架构图

```
MCP 服务器
    ↓
┌─────────────────────────────────────┐
│  多策略健康检查执行器               │
│  ├─ StandardHealthCheckExecutor     │
│  ├─ ProbeHealthCheckExecutor        │
│  ├─ ToolsListingHealthCheckExecutor │
│  └─ NetworkOnlyHealthCheckExecutor  │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  McpMonitor (监控程序)              │
│  ├─ 定期健康检查                    │
│  ├─ 故障自动检测                    │
│  ├─ 智能恢复策略                    │
│  └─ 事件流                          │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  McpMonitorDiagnosticsService       │
│  ├─ DNS 诊断                        │
│  ├─ TCP 诊断                        │
│  ├─ TLS 诊断                        │
│  ├─ HTTP 诊断                       │
│  ├─ MCP 诊断                        │
│  └─ 工具诊断                        │
└─────────────────────────────────────┘
    ↓
ImprovedMcpClientBase
    ↓
应用层 (Agent 系统等)
```

## 关键特性

### 1. 自动策略选择

当一种检查策略失败时，自动尝试其他策略：

```
probe 失败 → toolsListing 失败 → networkOnly 成功
           ↓
        使用 networkOnly 继续监控
```

### 2. 故障自动恢复

```dart
// 配置可选
monitor.maxRetries = 3;        // 最多重试 3 次
monitor.retryDelay = Duration(seconds: 5); // 每次间隔 5 秒
```

### 3. 历史记录与统计

```dart
final history = monitor.getHealthCheckHistory();
final successRate = monitor.getSuccessRate();
final latest = monitor.getLatestHealthCheck();
```

### 4. 事件驱动

```dart
monitor.events.listen((event) {
  switch (event) {
    case McpMonitorEvent.connected:
      print('已连接');
    case McpMonitorEvent.disconnected:
      print('已断开');
    case McpMonitorEvent.healthCheckPassed:
      print('检查通过');
    case McpMonitorEvent.healthCheckFailed:
      print('检查失败');
    case McpMonitorEvent.recoveryAttempt:
      print('尝试恢复');
    case McpMonitorEvent.recoverySuccess:
      print('恢复成功');
    case McpMonitorEvent.recoveryFailed:
      print('恢复失败');
    case McpMonitorEvent.strategyChanged:
      print('策略已更改');
  }
});
```

## 集成指南

### 步骤 1: 更新现有客户端

将现有的 `HttpMcpClient` 继承改为 `ImprovedMcpClientBase`：

```dart
class HttpMcpClient extends ImprovedMcpClientBase {
  // 现有实现保持不变
  // 新增监控支持
  
  @override
  Future<bool> connect() async {
    // 现有连接逻辑
    await monitor.start();
    return true;
  }
}
```

### 步骤 2: 在 AgentChatService 中使用

```dart
class AgentChatService {
  final McpMonitor monitor;
  
  // 发送消息前检查连接
  Future<void> sendMessage(String message) async {
    final health = await monitor.performHealthCheck();
    if (!health.success) {
      print('警告: MCP 服务器不健康');
      // 自动降级处理
    }
  }
}
```

### 步骤 3: 在 UI 中显示诊断信息

```dart
// 在 MCP 管理界面显示诊断结果
final diagnostics = McpMonitorDiagnosticsService();
final result = await diagnostics.diagnose(config);

scaffold(
  body: Column([
    Text(result.getSummary()),
    ...result.recommendations.map((r) => Text('• \$r')),
  ]),
);
```

## 文件清单

新增文件：
1. `mcp_health_check_strategy.dart` - 健康检查策略与执行器
2. `mcp_monitor.dart` - 监控程序与事件系统
3. `mcp_monitor_diagnostics.dart` - 诊断服务
4. `improved_mcp_client_base.dart` - 改进的客户端基类

## 性能考虑

- **健康检查间隔**: 默认 30 秒（可配置）
- **超时时间**: 单个检查 5 秒（可配置）
- **历史记录**: 最多保留 100 条（自动淘汰）
- **重试策略**: 指数退避可选实现

## 向后兼容性

现有的 `McpClientBase` 保持不变，新的 `ImprovedMcpClientBase` 是增强版本。

## 测试覆盖

建议添加测试：
1. 各种策略的执行器单元测试
2. 监控程序的集成测试
3. 诊断服务的端到端测试
4. 故障恢复场景测试

## 示例使用

```dart
// 创建 MCP 配置
final config = McpConfig(
  id: 'test-mcp',
  name: 'Test MCP',
  connectionType: McpConnectionType.http,
  endpoint: 'http://localhost:8000',
);

// 创建带监控的客户端
final client = HttpMcpClient(config: config);

// 连接
await client.connect();

// 监听监控事件
client.monitor.events.listen((event) {
  print('事件: \$event');
});

// 执行诊断
final diagnostics = McpMonitorDiagnosticsService();
final result = await diagnostics.diagnose(config);
print('诊断结果: \${result.getSummary()}');

// 断开连接
await client.disconnect();
client.dispose();
```

## 故障排查

### 问题: 所有策略都失败
**解决**:
1. 检查服务器是否启动
2. 检查网络连接
3. 检查防火墙设置
4. 运行诊断服务获取详细信息

### 问题: 检查间隔太短/太长
**解决**:
```dart
monitor.healthCheckInterval = Duration(seconds: 60); // 调整间隔
```

### 问题: 频繁触发恢复
**解决**:
```dart
monitor.maxRetries = 5;        // 增加重试次数
monitor.retryDelay = Duration(seconds: 10); // 增加延迟
```

## 未来改进方向

1. 支持自定义检查条件
2. 指数退避重试策略
3. 连接池管理
4. 详细的性能指标收集
5. 与 OpenTelemetry 集成
