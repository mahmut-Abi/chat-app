# MCP 服务器连接改进方案 - 实现指南

## 概述

本指南说明如何使用改进的 MCP 客户端系统来解决您遇到的连接问题。

## 实现内容

### 1. EnhancedHttpMcpClient (改进的 HTTP 客户端)

**文件**: `lib/features/mcp/data/enhanced_http_mcp_client.dart`

**主要功能**:
- ✅ 自动端点探测
- ✅ 自定义健康检查路径
- ✅ 正确的 URL 构建
- ✅ 灵活的错误恢复
- ✅ 详细的日志记录

**特点**:
- 首先尝试自定义健康检查路径
- 如果失败，自动探测常见端点
- 支持非标准 API 路径
- 自动心跳检测

### 2. McpDiagnosticsService (诊断工具)

**文件**: `lib/features/mcp/data/mcp_diagnostics_service.dart`

**功能**:
- 检查网络连通性
- DNS 解析验证
- HTTP 连接测试
- 端点自动扫描
- 生成建议报告

### 3. 更新的 McpClientFactory

**文件**: `lib/features/mcp/data/mcp_client_factory.dart`

**改进**:
- 默认使用增强型 HTTP 客户端
- 支持自定义健康检查路径
- 保持向后兼容

## 使用方法

### 基本使用

```dart
// 创建增强型客户端（推荐）
final client = McpClientFactory.createClient(
  config,
  useEnhancedClient: true,  // 默认为 true
  customHealthCheckPath: '/api/kubernetes/sse',  // 自定义路径
);

// 连接
final success = await client.connect();
if (!success) {
  print('连接失败: \${client.lastError}');
}
```

### 诊断服务使用

```dart
// 创建诊断服务
final diagnostics = McpDiagnosticsService();

// 诊断服务器
final result = await diagnostics.diagnoseServer('http://10.18.127.227:8080');

// 查看结果
print('网络连接: \${result.networkConnectivity}');
print('DNS 解析: \${result.dnsResolution}');
print('HTTP 连接: \${result.httpConnection}');
print('可用端点: \${result.availableEndpoints}');
print('建议: \${result.recommendations}');
```

### 针对 Kubernetes SSE 服务器的使用

```dart
// 为 Kubernetes SSE 服务器配置
final config = McpConfig(
  id: 'kubernetes-mcp',
  name: 'Kubernetes MCP',
  connectionType: McpConnectionType.http,
  endpoint: 'http://10.18.127.227:8080',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 使用增强型客户端，指定自定义健康检查路径
final client = McpClientFactory.createEnhancedHttpClient(
  config,
  customHealthCheckPath: '/api/kubernetes/sse',
);

final success = await client.connect();
```

## 工作流程

### 连接流程

1. **检查自定义路径**
   - 如果指定了 `customHealthCheckPath`，首先尝试此路径
   - 如果成功，连接完成

2. **自动探测端点**
   - 尝试常见端点列表
   - 按顺序: `/health`, `/api/health`, `/ping`, `/api/kubernetes/sse`, `/sse`, 等
   - 第一个成功的端点用作健康检查

3. **启动心跳检测**
   - 每 30 秒检查一次健康状态
   - 失败时自动断开连接

### URL 构建流程

```
输入: http://10.18.127.227:8080/api/kubernetes/sse
     ↓
提取基础 URL: http://10.18.127.227:8080
     ↓
追加路径: /api/kubernetes/sse
     ↓
最终 URL: http://10.18.127.227:8080/api/kubernetes/sse
```

## 解决的问题

### ❌ 原来的问题

1. **硬编码的健康检查路径**: `/health` 路径不存在
2. **错误的 URL 构建**: 基础 URL 包含完整路径
3. **没有端点探测**: 无法适应服务器变化
4. **错误处理不完善**: 缺少恢复机制

### ✅ 改进后的解决方案

1. **灵活的路径配置**: 支持自定义健康检查路径
2. **正确的 URL 处理**: 分离基础 URL 和路径
3. **自动端点探测**: 尝试多个常见端点
4. **健壮的错误处理**: 自动重试和恢复

## 平台兼容性

所有平台（Web、移动、桌面）都可以使用：

- ✅ **Web**: HTTP 和 WebSocket 支持
- ✅ **iOS/Android**: HTTP 支持（优化的超时设置）
- ✅ **Windows/macOS/Linux**: 完整支持

## 日志记录

增强型客户端提供详细的日志记录，帮助调试：

```
[INFO] 改进的 HTTP MCP 客户端开始连接
[DEBUG] 自定义路径失败，开始自动探测端点...
[DEBUG] 探测端点: /health
[DEBUG] 端点探测失败: /health
[DEBUG] 探测端点: /api/kubernetes/sse
[INFO] 找到有效端点: /api/kubernetes/sse
[INFO] 连接成功（自动探测端点）
[DEBUG] 启动心跳检测
```

## 最佳实践

1. **始终使用增强型客户端**
   ```dart
   // 推荐
   final client = McpClientFactory.createClient(config, useEnhancedClient: true);
   
   // 不推荐
   final client = HttpMcpClient(config: config);  // 缺少自动探测
   ```

2. **为问题服务器指定自定义路径**
   ```dart
   final client = McpClientFactory.createClient(
     config,
     customHealthCheckPath: '/api/kubernetes/sse',
   );
   ```

3. **在生产环境前运行诊断**
   ```dart
   final diagnostics = McpDiagnosticsService();
   final result = await diagnostics.diagnoseServer(endpoint);
   
   if (!result.networkConnectivity) {
     // 网络问题
   } else if (!result.httpConnection) {
     // 服务器问题
   } else if (result.availableEndpoints.isEmpty) {
     // API 问题
   }
   ```

4. **检查建议**
   ```dart
   for (final recommendation in result.recommendations) {
     print('建议: $recommendation');
   }
   ```

## 集成检查清单

- [ ] 导入 `EnhancedHttpMcpClient`
- [ ] 导入 `McpDiagnosticsService`
- [ ] 更新 `McpClientFactory` 调用
- [ ] 测试与 Kubernetes SSE 服务器的连接
- [ ] 验证自动端点探测
- [ ] 检查日志输出
- [ ] 在所有平台上测试（Web、iOS、Android）
- [ ] 验证心跳检测

## 故障排除

### 问题: 连接仍然失败

**解决**:
1. 运行诊断服务
2. 检查网络连接
3. 验证 DNS 解析
4. 确认服务器在运行
5. 查看详细日志

### 问题: 自动探测不工作

**解决**:
1. 指定 `customHealthCheckPath`
2. 验证服务器使用的实际端点
3. 添加自定义端点到探测列表

## 性能考虑

- 连接超时: 10 秒
- 端点探测超时: 3 秒
- 心跳间隔: 30 秒
- 移动端超时: 8-15 秒（优化）

## 下一步

1. 测试改进的客户端
2. 收集诊断信息
3. 更新任何其他集成点
4. 监控日志以确保正常工作

---

有任何问题，请查看日志或运行诊断服务获取详细信息。
