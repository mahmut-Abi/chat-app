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
