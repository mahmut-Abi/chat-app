# Bug #1: MCP 健康检查和 SSE 支持

## 问题描述
- MCP Server 健康检查功能无效，无法检测服务状态
- 不支持 SSE (Server-Sent Events) 协议
- MCP 查询工具功能缺失

## 修复内容

### 1. 增强 MCP 客户端基类
**文件**: `lib/features/mcp/data/mcp_client_base.dart`

添加了：
- `lastHealthCheck`: 记录最后一次健康检查时间
- `lastError`: 记录最后一次错误信息
- `healthCheck()`: 抽象方法，子类实现具体的健康检查逻辑

### 2. HTTP MCP 客户端增强
**文件**: `lib/features/mcp/data/http_mcp_client.dart`

**新增功能**:
- ✅ 实现了 `healthCheck()` 方法
  - 向 `/health` 端点发送 GET 请求
  - 5 秒超时设置
  - 更新 `lastHealthCheck` 和 `lastError` 状态
  
- ✅ SSE (Server-Sent Events) 支持
  - 新增 `connectSSE(String endpoint)` 方法
  - 返回 `Stream<String>` 用于接收实时事件
  - 正确的请求头设置: `Accept: text/event-stream`, `Cache-Control: no-cache`
  - 自动处理流数据和错误
  
- ✅ 改进心跳检测
  - 使用 `healthCheck()` 替代直接的 HTTP 调用
  - 更详细的错误日志

- ✅ 资源管理
  - 添加 `_closeSseConnection()` 方法
  - 在 `disconnect()` 和 `dispose()` 中正确关闭 SSE 连接

### 3. Stdio MCP 客户端增强
**文件**: `lib/features/mcp/data/stdio_mcp_client.dart`

**新增功能**:
- ✅ 实现了 `healthCheck()` 方法
  - 发送 `ping` 请求检查进程存活状态
  - 5 秒超时设置
  - 检查进程是否存在
  
- ✅ 增强日志记录
  - 使用 LogService 替代 print 语句
  - 所有关键操作都有详细日志
  - 错误信息包含上下文

- ✅ 错误处理改进
  - 更新 `lastError` 状态
  - 更新 `lastHealthCheck` 时间戳

## 使用示例

### HTTP 模式健康检查
```dart
final httpClient = HttpMcpClient(config: mcpConfig);
await httpClient.connect();

// 执行健康检查
final isHealthy = await httpClient.healthCheck();
if (isHealthy) {
  print('MCP Server 健康');
  print('最后检查时间: ${httpClient.lastHealthCheck}');
} else {
  print('MCP Server 异常: ${httpClient.lastError}');
}
```

### SSE 连接使用
```dart
final sseStream = await httpClient.connectSSE('/events');
if (sseStream != null) {
  sseStream.listen(
    (data) => print('收到事件: $data'),
    onError: (error) => print('错误: $error'),
    onDone: () => print('连接关闭'),
  );
}
```

### Stdio 模式健康检查
```dart
final stdioClient = StdioMcpClient(config: mcpConfig);
await stdioClient.connect();

// 定期健康检查
Timer.periodic(Duration(seconds: 30), (timer) async {
  final isHealthy = await stdioClient.healthCheck();
  if (!isHealthy) {
    print('进程异常，需要重启');
  }
});
```

## 测试验证
- [x] HTTP 健康检查正常工作
- [x] SSE 连接能正常接收事件流
- [x] Stdio ping 请求正常响应
- [x] 心跳检测自动运行
- [x] 错误状态正确记录
- [x] 日志信息详细完整

## 后续优化建议
1. 添加重连机制：健康检查失败时自动重连
2. 配置化超时时间：允许用户自定义健康检查和 SSE 的超时设置
3. 事件过滤：SSE 支持按事件类型过滤
4. Metrics 收集：记录健康检查成功率、平均响应时间等指标

## 相关文件
- `lib/features/mcp/data/mcp_client_base.dart`
- `lib/features/mcp/data/http_mcp_client.dart`
- `lib/features/mcp/data/stdio_mcp_client.dart`

## 修复日期
2025-01-XX

## 状态
✅ 已完成
