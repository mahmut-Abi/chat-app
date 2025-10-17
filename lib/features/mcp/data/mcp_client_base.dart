import '../domain/mcp_config.dart';

/// MCP 客户端基类
abstract class McpClientBase {
  final McpConfig config;
  McpConnectionStatus status = McpConnectionStatus.disconnected;
  DateTime? lastHealthCheck;
  String? lastError;

  McpClientBase({required this.config});

  /// 连接到 MCP 服务器
  Future<bool> connect();

  /// 断开连接
  Future<void> disconnect();

  /// 健康检查
  Future<bool> healthCheck();

  /// 获取上下文
  Future<Map<String, dynamic>?> getContext(String contextId);

  /// 推送上下文
  Future<bool> pushContext(String contextId, Map<String, dynamic> context);

  /// 调用工具
  Future<Map<String, dynamic>?> callTool(
    String toolName,
    Map<String, dynamic> params,
  );

  /// 获取可用工具列表
  Future<List<Map<String, dynamic>>?> listTools();

  /// 释放资源
  void dispose();
}
