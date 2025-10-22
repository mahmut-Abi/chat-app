# MCP 监控检查系统集成指南

## 快速开始

本指南说明如何在现有的 MCP 系统中集成改进的监控检查功能。

## 概览

改进包括：
- 7 种健康检查策略（灵活适配各种 MCP 服务器）
- 完整的监控程序（自动故障检测与恢复）
- 多层诊断服务（DNS/TCP/HTTP/MCP/工具层）
- 事件驱动架构（实时监控状态变化）

## 文件结构

```
lib/features/mcp/data/
├── mcp_health_check_strategy.dart     # 健康检查策略与执行器
├── mcp_monitor.dart                   # 监控程序与事件系统
├── mcp_monitor_diagnostics.dart       # 诊断服务
├── improved_mcp_client_base.dart      # 改进的客户端基类
├── http_mcp_client.dart               # HTTP 客户端（需更新）
└── stdio_mcp_client.dart              # Stdio 客户端（需更新）

test/unit/mcp/
├── mcp_health_check_strategy_test.dart
├── mcp_monitor_test.dart
└── mcp_monitor_diagnostics_test.dart

docs/
└── MCP_MONITORING_IMPROVEMENT.md       # 详细文档
```

## 集成步骤

### 1. 更新 HttpMcpClient

将 `HttpMcpClient` 改为继承 `ImprovedMcpClientBase`：

```dart
// 原来
class HttpMcpClient extends McpClientBase {
  // ...
}

// 改为
class HttpMcpClient extends ImprovedMcpClientBase {
  @override
  Future<bool> connect() async {
    status = McpConnectionStatus.connecting;
    
    // 你的现有连接逻辑
    // ...
    
    // 启动监控
    await monitor.start();
    return true;
  }
  
  @override
  Future<bool> healthCheck({HealthCheckStrategy? strategy}) async {
    if (strategy != null) {
      await monitor.switchStrategy(strategy);
    }
    final result = await monitor.performHealthCheck();
    return result.success;
  }
}
```

### 2. 更新 StdioMcpClient

类似地更新 `StdioMcpClient`：

```dart
class StdioMcpClient extends ImprovedMcpClientBase {
  // 监控适用于进程存活检查
  @override
  Future<bool> healthCheck({HealthCheckStrategy? strategy}) async {
    // 对 Stdio 客户端，可以只检查进程是否存在
    return _process != null && !_process!.kill();
  }
}
```

### 3. 在 AgentChatService 中使用

```dart
class AgentChatService {
  final McpRepository repository;
  final McpMonitor? monitor;
  
  Future<void> executeToolCall(String toolName, Map<String, dynamic> params) async {
    // 检查 MCP 连接状态
    if (monitor != null) {
      final health = await monitor.performDetailedHealthCheck();
      if (!health.success) {
        // 处理不健康的情况
        log.warning('MCP 不健康，工具调用可能失败', {'health': health});
        // 可以尝试自动恢复或降级处理
      }
    }
    
    // 继续工具调用
    // ...
  }
}
```

### 4. 在 UI 中显示诊断信息

```dart
class McpConfigScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: FutureBuilder<MonitorDiagnosticResult>(
        future: McpMonitorDiagnosticsService().diagnose(config),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final result = snapshot.data!;
            return Column(
              children: [
                // 健康状态指示器
                Container(
                  color: result.isFullyHealthy ? Colors.green : Colors.red,
                  child: Text(result.getSummary()),
                ),
                // 问题列表
                if (!result.isFullyHealthy)
                  ListView(
                    children: result.recommendations
                        .map((r) => ListTile(title: Text(r)))
                        .toList(),
                  ),
              ],
            );
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
```

### 5. 监听监控事件

```dart
class McpScreen extends ConsumerStatefulWidget {
  @override
  State<McpScreen> createState() => _McpScreenState();
}

class _McpScreenState extends ConsumerState<McpScreen> {
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    // 从某处获取 monitor
    final monitor = _getMonitor();
    
    _subscription = monitor.events.listen((event) {
      switch (event) {
        case McpMonitorEvent.connected:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已连接到 MCP 服务器')),
          );
        case McpMonitorEvent.disconnected:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已断开 MCP 连接')),
          );
        case McpMonitorEvent.healthCheckFailed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('MCP 健康检查失败')),
          );
        case McpMonitorEvent.recoverySuccess:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('MCP 连接已恢复')),
          );
        default:
          break;
      }
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

## 高级配置

### 自定义健康检查策略

```dart
class CustomHealthCheckExecutor implements HealthCheckExecutor {
  @override
  Future<HealthCheckResult> execute(
    String endpoint,
    Map<String, String>? headers,
  ) async {
    // 你的自定义检查逻辑
    // 例如：检查特定的业务端点
    try {
      final response = await Dio().get(
        '\$endpoint/api/custom-health',
        options: Options(headers: headers),
      );
      
      return HealthCheckResult(
        success: response.statusCode == 200,
        message: '自定义检查完成',
        duration: Duration.zero,
        strategy: HealthCheckStrategy.custom,
      );
    } catch (e) {
      return HealthCheckResult(
        success: false,
        message: '自定义检查失败: \$e',
        duration: Duration.zero,
        strategy: HealthCheckStrategy.custom,
      );
    }
  }
}

// 使用自定义执行器
monitor.setCustomExecutor(CustomHealthCheckExecutor());
await monitor.switchStrategy(HealthCheckStrategy.custom);
```

### 调整监控参数

```dart
monitor.healthCheckInterval = Duration(seconds: 60);  // 每 60 秒检查一次
monitor.maxRetries = 5;                               // 最多重试 5 次
monitor.retryDelay = Duration(seconds: 10);           // 每次重试间隔 10 秒
```

### 获取监控统计

```dart
// 成功率
final rate = monitor.getSuccessRate();
print('MCP 成功率: \${(rate * 100).toStringAsFixed(1)}%');

// 历史记录
final history = monitor.getHealthCheckHistory();
for (final check in history.sublist(max(0, history.length - 10))) {
  print('检查: \${check.timestamp} - \${check.success}');
}

// 最近检查
final latest = monitor.getLatestHealthCheck();
print('最近检查: \${latest?.message}');
```

## 常见场景

### 场景 1: 连接到不支持标准健康检查的 MCP 服务器

**问题**: 服务器没有 `/health` 端点

**解决方案**:
```dart
// 自动使用探测策略
monitor.strategy = HealthCheckStrategy.probe;
// 或者设置自定义探测路径
monitor.strategy = HealthCheckStrategy.standard;
// 或通过工具列表检查
monitor.strategy = HealthCheckStrategy.toolsListing;
```

### 场景 2: 网络不稳定

**问题**: 频繁连接中断

**解决方案**:
```dart
// 增加重试次数和延迟
monitor.maxRetries = 5;
monitor.retryDelay = Duration(seconds: 15);
monitor.healthCheckInterval = Duration(seconds: 60);
```

### 场景 3: 需要了解具体故障原因

**问题**: 不知道为什么 MCP 不可达

**解决方案**:
```dart
final diagnostics = McpMonitorDiagnosticsService();
final result = await diagnostics.diagnose(config);

if (!result.isFullyHealthy) {
  print('摘要: \${result.getSummary()}');
  print('建议:');
  for (final rec in result.recommendations) {
    print('  - \$rec');
  }
}
```

### 场景 4: 自动故障恢复

**问题**: 需要在故障时自动尝试恢复

**解决方案**: 监听恢复事件
```dart
monitor.events.listen((event) {
  if (event == McpMonitorEvent.recoveryAttempt) {
    print('尝试恢复连接...');
  }
  if (event == McpMonitorEvent.recoverySuccess) {
    print('连接已恢复！');
  }
  if (event == McpMonitorEvent.recoveryFailed) {
    print('恢复失败，需要手动干预');
    // 触发用户通知
  }
});
```

## 迁移清单

- [ ] 更新 `HttpMcpClient` 继承 `ImprovedMcpClientBase`
- [ ] 更新 `StdioMcpClient` 继承 `ImprovedMcpClientBase`
- [ ] 在 `AgentChatService` 中添加监控支持
- [ ] 在 MCP 配置界面显示诊断信息
- [ ] 添加监控事件监听
- [ ] 测试各种健康检查策略
- [ ] 测试故障恢复流程
- [ ] 更新相关文档
- [ ] 添加监控相关的日志

## 性能考虑

- **内存**: 监控历史最多 100 条，占用微小
- **CPU**: 后台定时器，间隔可配置
- **网络**: 根据检查间隔和超时配置

推荐配置:
```dart
monitor.healthCheckInterval = Duration(seconds: 30);  // 标准配置
// 对于高负载场景
monitor.healthCheckInterval = Duration(seconds: 60);
// 对于高可用需求
monitor.healthCheckInterval = Duration(seconds: 10);
```

## 故障排查

### 问题: 健康检查总是超时
**原因**: 服务器响应慢
**解决**: 
```dart
// 改用网络检查（更快）
monitor.switchStrategy(HealthCheckStrategy.networkOnly);
```

### 问题: 频繁触发恢复
**原因**: 检查间隔太短或阈值太低
**解决**:
```dart
monitor.healthCheckInterval = Duration(seconds: 60);
// 允许更多失败后才认为故障
// （修改源码中的 _failureCount >= 3 条件）
```

### 问题: 某个策略不工作
**原因**: MCP 服务器不支持该策略的端点
**解决**: 
```dart
// 自动探测
monitor.switchStrategy(HealthCheckStrategy.probe);
```

## 下一步

1. **集成监控指标**: 与 OpenTelemetry 或类似服务集成
2. **告警系统**: 在故障时发送告警
3. **性能分析**: 收集检查延迟数据
4. **故障预测**: 基于历史数据预测故障

## 相关文档

- [MCP 监控改进方案](./MCP_MONITORING_IMPROVEMENT.md)
- [健康检查策略详解](./MCP_HEALTH_CHECK_STRATEGIES.md)
- [故障排查指南](./MCP_TROUBLESHOOTING.md)
