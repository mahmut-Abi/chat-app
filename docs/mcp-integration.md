# MCP (Model Context Protocol) 集成文档

## 概述

本项目已完整实现 MCP (Model Context Protocol) 支持，允许与外部 MCP 服务器进行通信，以提供上下文信息和工具调用能力。

## 支持的连接模式

### 1. HTTP 模式

HTTP 模式通过 HTTP/HTTPS 协议与 MCP 服务器通信。

**配置参数：**
- **名称**：服务器标识名称
- **连接类型**：HTTP
- **端点 URL**：服务器地址，如 `http://localhost:3000`
- **请求头**：可选的 HTTP 请求头（支持认证等）
- **描述**：可选的服务器描述信息

**特性：**
- 支持 RESTful API 通信
- 自动心跳检测（每 30 秒）
- 连接状态监控
- 支持自定义 HTTP 头

### 2. Stdio 模式

Stdio 模式通过启动外部进程并通过标准输入/输出（stdin/stdout）进行 JSON-RPC 通信。

**配置参数：**
- **名称**：服务器标识名称
- **连接类型**：Stdio
- **命令路径**：可执行文件路径，如 `/path/to/mcp-server`
- **命令参数**：可选的命令行参数（空格分隔）
- **环境变量**：可选的环境变量键值对
- **描述**：可选的服务器描述信息

**特性：**
- 支持 JSON-RPC 2.0 协议
- 进程生命周期管理
- stderr 日志捕获
- 请求超时控制（30 秒）

## 核心功能

### 连接管理

```dart
// 连接到 MCP 服务器
await mcpRepository.connect(config);

// 断开连接
await mcpRepository.disconnect(configId);

// 获取连接状态
final status = mcpRepository.getConnectionStatus(configId);
```

### 上下文操作

```dart
// 获取上下文
final context = await client.getContext(contextId);

// 推送上下文
await client.pushContext(contextId, {
  'key': 'value',
});
```

### 工具调用

```dart
// 列出可用工具
final tools = await client.listTools();

// 调用工具
final result = await client.callTool('toolName', {
  'param1': 'value1',
});
```

## 架构设计

### 文件结构

```
lib/features/mcp/
├── data/
│   ├── mcp_client_base.dart          # 客户端基类
│   ├── http_mcp_client.dart          # HTTP 客户端实现
│   ├── stdio_mcp_client.dart         # Stdio 客户端实现
│   ├── mcp_client_factory.dart       # 客户端工厂
│   ├── mcp_repository.dart           # 数据仓库
│   ├── mcp_provider.dart             # Riverpod Provider
│   └── mcp_integration.dart          # 与聊天功能集成
├── domain/
│   └── mcp_config.dart               # 配置模型
└── presentation/
    └── mcp_screen.dart               # UI 界面
```

### 类关系

```
McpClientBase (抽象基类)
    ├── HttpMcpClient    (HTTP 实现)
    └── StdioMcpClient   (Stdio 实现)

McpClientFactory  → 根据配置创建客户端
McpRepository     → 管理配置和客户端实例
McpIntegration    → 与聊天功能集成
```

## 使用示例

### 添加 HTTP 服务器

1. 打开 MCP 配置页面
2. 点击右上角"添加"按钮
3. 输入配置信息：
   - 名称：My MCP Server
   - 连接类型：HTTP
   - 端点 URL：http://localhost:3000
   - 描述：示例服务器
4. 点击"添加"保存

### 添加 Stdio 服务器

1. 打开 MCP 配置页面
2. 点击右上角"添加"按钮
3. 输入配置信息：
   - 名称：Local MCP Server
   - 连接类型：Stdio
   - 命令路径：/usr/local/bin/mcp-server
   - 命令参数：--port 3000 --verbose
   - 环境变量：
     - API_KEY=your-key
     - DEBUG=true
   - 描述：本地 Stdio 服务器
4. 点击"添加"保存

### 启动和停止连接

- 使用开关按钮启用/禁用服务器
- 点击播放/停止按钮连接/断开服务器
- 连接状态实时显示：
  - 绿色：已连接
  - 橙色：连接中
  - 红色：连接失败
  - 灰色：未连接

