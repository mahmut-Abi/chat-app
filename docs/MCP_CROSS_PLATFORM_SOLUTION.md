# MCP 跨平台支持指南

## 概述

本指南说明如何确保 MCP (Model Context Protocol) 功能在所有客户端平台上正常运行，包括：
- **Web 端** (浏览器)
- **移动端** (iOS/Android)
- **桌面端** (Windows/macOS/Linux)

## 平台兼容性矩阵

| 功能 | Web | iOS | Android | Windows | macOS | Linux |
|------|-----|-----|---------|---------|-------|-------|
| HTTP MCP | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Stdio MCP | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ |
| WebSocket | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 本地文件访问 | ✗ (沙箱) | ✗ | ✗ | ✓ | ✓ | ✓ |
| 进程启动 | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ |

## 核心解决方案

### 1. 平台检测层 (`platform_config.dart`)

提供统一的平台检测接口：

```dart
/// 检测当前平台
PlatformConfig.currentPlatform  // 返回: web/ios/android/windows/macos/linux

/// 平台特性检查
PlatformConfig.isMobile              // 检查是否为移动平台
PlatformConfig.isDesktop             // 检查是否为桌面平台
PlatformConfig.isWeb                 // 检查是否为 Web 平台
PlatformConfig.supportsStdioMode     // 检查是否支持 Stdio 模式
PlatformConfig.supportedMcpModes     // 获取支持的 MCP 连接类型列表
```

### 2. MCP 平台适配器 (`mcp_platform_adapter.dart`)

根据平台自动选择合适的 MCP 客户端：

```dart
/// 为当前平台创建 MCP 客户端
final client = McpPlatformAdapter.createClientForPlatform(config);

/// 验证配置与平台兼容性
if (McpPlatformAdapter.isConfigCompatibleWithPlatform(config)) {
  // 配置兼容
}

/// 获取支持的连接类型
final types = McpPlatformAdapter.getSupportedConnectionTypes();

/// 获取推荐的连接类型
final recommended = McpPlatformAdapter.getRecommendedConnectionType();
```

### 3. 平台特定客户端

#### Web MCP 客户端 (`web_mcp_client.dart`)
- CORS 支持
- 自动重连机制
- 较短的超时设置（适应网络延迟）
- 5 次重试限制

#### 移动 MCP 客户端 (`mobile_mcp_client.dart`)
- 资源优化（电池、内存）
- 更长的健康检查间隔 (60s)
- 连接丢失检测
- 快速故障转移

#### 桌面 MCP 客户端
- 支持所有连接模式（HTTP、Stdio、WebSocket）
- 使用现有的 `HttpMcpClient` 和 `StdioMcpClient`

## 实现指南

### 第 1 步：在应用初始化时检测平台

```dart
void main() {
  // 检测平台功能
  if (PlatformConfig.isWeb) {
    print('运行在 Web 平台');
  } else if (PlatformConfig.isMobile) {
    print('运行在移动平台');
  } else if (PlatformConfig.isDesktop) {
    print('运行在桌面平台');
  }
  
  runApp(const MyApp());
}
```

### 第 2 步：创建 MCP 配置时验证兼容性

```dart
final config = McpConfig(
  id: 'my-mcp-server',
  name: 'My MCP Server',
  connectionType: McpConnectionType.stdio,
  endpoint: '/path/to/server',
);

// 验证配置
if (!McpPlatformAdapter.isConfigCompatibleWithPlatform(config)) {
  // 平台不支持此配置
  if (PlatformConfig.isWeb || PlatformConfig.isMobile) {
    // 使用 HTTP 作为备选方案
    config = config.copyWith(connectionType: McpConnectionType.http);
  }
}
```

### 第 3 步：使用平台适配器创建客户端

```dart
// 自动为当前平台创建适合的客户端
final client = McpPlatformAdapter.createClientForPlatform(config);
final success = await client.connect();
```

### 第 4 步：处理平台特定的超时和错误

```dart
// Web 端：较短超时，支持重试
if (PlatformConfig.isWeb) {
  // 使用自动重连机制
  // 最多重试 5 次
}

// 移动端：保守的超时，节能模式
if (PlatformConfig.isMobile) {
  // 使用较长的健康检查间隔（60秒）
  // 快速检测连接丢失
}

// 桌面端：充足的超时，完全功能
if (PlatformConfig.isDesktop) {
  // 支持所有 MCP 模式
  // 标准的超时设置
}
```

## MCP 配置建议

### Web 端用户
- **推荐**：使用 HTTP MCP（远程服务器）
- **URL**：必须支持 CORS
- **超时**：10-30 秒
- **注意**：不支持 Stdio 模式

### 移动端用户
- **推荐**：使用 HTTP MCP（远程服务器）
- **网络**：优先使用 WiFi
- **超时**：8-15 秒（考虑网络延迟）
- **电池**：后台健康检查间隔为 60 秒
- **注意**：不支持本地进程启动

### 桌面端用户
- **推荐**：使用 Stdio MCP（本地服务器）
- **备选**：使用 HTTP MCP
- **超时**：30-60 秒
- **功能**：支持所有 MCP 模式

## 使用示例

### 完整的跨平台 MCP 初始化

```dart
Future<void> initializeMcpForPlatform(McpRepository repository) async {
  // 1. 获取支持的连接类型
  final supportedTypes = McpPlatformAdapter.getSupportedConnectionTypes();
  print('支持的 MCP 模式: $supportedTypes');
  
  // 2. 获取推荐的连接类型
  final recommended = McpPlatformAdapter.getRecommendedConnectionType();
  print('推荐的连接类型: $recommended');
  
  // 3. 创建配置
  late McpConfig config;
  
  if (PlatformConfig.isWeb) {
    config = McpConfig(
      id: 'web-mcp',
      name: 'Web MCP Server',
      connectionType: McpConnectionType.http,
      endpoint: 'https://mcp.example.com',
      headers: {'Authorization': 'Bearer token'},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  } else if (PlatformConfig.isMobile) {
    config = McpConfig(
      id: 'mobile-mcp',
      name: 'Mobile MCP Server',
      connectionType: McpConnectionType.http,
      endpoint: 'https://mcp.example.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  } else if (PlatformConfig.isDesktop) {
    // 优先使用 Stdio
    if (supportedTypes.contains(McpConnectionType.stdio)) {
      config = McpConfig(
        id: 'desktop-mcp',
        name: 'Desktop MCP Server',
        connectionType: McpConnectionType.stdio,
        endpoint: '/path/to/mcp-server',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      // 备选：HTTP
      config = McpConfig(
        id: 'desktop-mcp',
        name: 'Desktop MCP Server',
        connectionType: McpConnectionType.http,
        endpoint: 'http://localhost:3000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  
  // 4. 保存配置
  await repository.addConfig(config);
  
  // 5. 连接
  final success = await repository.connect(config);
  if (success) {
    print('✓ MCP 连接成功');
  } else {
    print('✗ MCP 连接失败');
  }
}
```

## 故障排除

### Web 端常见问题

**问题**：CORS 错误
- **原因**：MCP 服务器未配置 CORS 支持
- **解决**：确保服务器返回正确的 CORS 头

**问题**：连接超时
- **原因**：网络问题或服务器无响应
- **解决**：检查网络连接，增加超时时间

### 移动端常见问题

**问题**：电池耗尽
- **原因**：过于频繁的健康检查
- **解决**：移动客户端默认使用 60 秒间隔

**问题**：连接断开
- **原因**：网络切换或 4G/WiFi 切换
- **解决**：实现自动重连机制

### 桌面端常见问题

**问题**：Stdio 客户端无法启动进程
- **原因**：进程路径不正确或权限不足
- **解决**：验证进程路径和权限

**问题**：进程崩溃
- **原因**：服务器出错或资源不足
- **解决**：检查服务器日志

## 最佳实践

1. **始终检测平台**：在应用启动时检测平台并记录日志
2. **验证配置兼容性**：创建 MCP 配置前验证与平台的兼容性
3. **使用平台适配器**：不要直接实例化客户端，使用 `McpPlatformAdapter`
4. **处理故障**：实现适当的错误处理和回退机制
5. **监控连接**：记录连接状态变化和错误
6. **优化超时**：根据平台调整超时设置
7. **资源管理**：正确释放资源，避免内存泄漏

## 文件结构

```
lib/features/mcp/
├── platform/
│   ├── platform_config.dart           # 平台检测
│   ├── mcp_platform_adapter.dart      # 平台适配器
│   ├── web_mcp_client.dart            # Web 优化客户端
│   └── mobile_mcp_client.dart         # 移动优化客户端
├── data/
│   ├── mcp_client_factory.dart        # 已更新为使用平台适配器
│   ├── http_mcp_client.dart           # HTTP 客户端（桌面）
│   ├── stdio_mcp_client.dart          # Stdio 客户端（桌面）
│   └── ...
└── ...
```

## 相关文件

- 平台配置：`lib/features/mcp/platform/platform_config.dart`
- 平台适配器：`lib/features/mcp/platform/mcp_platform_adapter.dart`
- Web 客户端：`lib/features/mcp/platform/web_mcp_client.dart`
- 移动客户端：`lib/features/mcp/platform/mobile_mcp_client.dart`
- 工厂模式：`lib/features/mcp/data/mcp_client_factory.dart`

## 更新记录

**版本 2.0.0** (2025-01-21)
- 添加平台检测层
- 实现 MCP 平台适配器
- 创建 Web 优化客户端
- 创建移动优化客户端
- 更新 MCP 客户端工厂
- 支持所有客户端平台（Web、移动、桌面）
