# 日志使用指南

本文档介绍如何在 Flutter Chat App 中使用增强的日志功能。

## 基本日志记录

### 引入日志服务

```dart
import '../core/services/log_service.dart';

class MyClass {
  final LogService _log = LogService();
}
```

### 记录不同级别的日志

```dart
// Debug 日志 - 开发调试信息
_log.debug('调试信息', {'userId': userId, 'action': 'login'});

// Info 日志 - 一般信息
_log.info('用户登录成功', {'userId': userId});

// Warning 日志 - 警告信息
_log.warning('API 调用缓慢', {'duration': 3000, 'endpoint': '/api/chat'});

// Error 日志 - 错误信息
_log.error('数据库连接失败', exception, stackTrace);
```

## 日志上下文

日志上下文帮助追踪复杂操作的调用链：

```dart
Future<void> processUserRequest() async {
  _log.enterContext('processUserRequest');
  
  try {
    _log.info('开始处理用户请求');
    
    _log.enterContext('validateInput');
    await validateInput();
    _log.exitContext();
    
    _log.enterContext('fetchData');
    await fetchData();
    _log.exitContext();
    
    _log.info('请求处理完成');
  } finally {
    _log.exitContext();
  }
}
```

## 性能监控

使用性能计时器监控操作耗时：

```dart
Future<void> heavyOperation() async {
  _log.startPerformanceTimer('heavyOperation');
  
  try {
    // 执行耗时操作
    await someHeavyWork();
  } finally {
    _log.stopPerformanceTimer('heavyOperation');
  }
}
```

## 已添加日志的模块

### 核心模块
- ✅ **DioClient** - HTTP 请求和响应
- ✅ **OpenAIApiClient** - API 调用和流式响应
- ✅ **StorageService** - 数据存储操作

### 功能模块
- ✅ **ChatRepository** - 消息发送和接收
- ✅ **AgentRepository** - Agent 和工具管理
- ✅ **McpRepository** - MCP 配置管理
- ✅ **ModelsRepository** - 模型列表获取

## 新增的日志模块（第二批）

### 服务模块
- ✅ **SettingsRepository** - API 配置和应用设置管理
- ✅ **PromptsRepository** - 提示词模板管理
- ✅ **MenuService** - 原生菜单服务
- ✅ **DesktopService** - 桌面端服务（窗口管理、系统托盘）
- ✅ **PwaService** - PWA 服务（Service Worker）

### MCP 模块
- ✅ **HttpMcpClient** - HTTP 模式 MCP 客户端
  - 连接/断开连接
  - 上下文获取和推送
  - 工具调用
  - 心跳检测

### 工具类
- ✅ **PerformanceUtils** - 性能优化工具
  - 缓存管理
  - 性能监控

## 日志详细程度示例

### API 配置管理
```
[DEBUG] 开始创建 API 配置
  name: OpenAI
  provider: openai
  baseUrl: https://api.openai.com/v1
  hasOrganization: false
  hasProxy: true
  defaultModel: gpt-4

[INFO] API 配置创建成功
  configId: abc123
  name: OpenAI

[DEBUG] API 配置已保存到存储
  configId: abc123
```

### MCP 客户端连接
```
[INFO] HTTP MCP 客户端开始连接
  endpoint: http://localhost:8080
  configId: mcp-001

[DEBUG] 设置连接状态为 connecting
[DEBUG] 添加请求头
  headersCount: 2
[DEBUG] 发送健康检查请求

[INFO] HTTP MCP 客户端连接成功
  endpoint: http://localhost:8080

[DEBUG] 启动 MCP 心跳检测
```

### 桌面端服务
```
[INFO] 初始化桌面端服务
  isDesktop: true

[DEBUG] 初始化窗口管理器
[DEBUG] 初始化系统托盘
[DEBUG] 配置系统托盘监听器
[DEBUG] 配置窗口事件监听器

[INFO] 桌面端服务初始化完成
```

### 提示词模板管理
```
[DEBUG] 开始创建提示词模板
  name: 代码审查
  category: 编程
  tagsCount: 3
  contentLength: 256

[INFO] 提示词模板创建成功
  templateId: tpl-001
  name: 代码审查

[DEBUG] 提示词模板已保存
  templateId: tpl-001
```

## 日志统计

目前已为以下模块添加详细日志：

- **15** 个 Repository/Service 类
- **3** 个 Client 类
- **1** 个 Utils 类
- **超过 200** 个日志记录点

每个关键操作都包含：
1. **开始日志** - 记录输入参数
2. **中间状态** - 记录处理过程
3. **结果日志** - 记录成功/失败状态
