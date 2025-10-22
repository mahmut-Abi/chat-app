import '../domain/mcp_config.dart';
import 'mcp_health_check_strategy.dart';
import 'mcp_monitor.dart';
import '../../../core/services/log_service.dart';

/// 改进的 MCP 客户端基类，支持多策略健康检查
abstract class ImprovedMcpClientBase {
  final McpConfig config;
  final LogService log = LogService();
  
  McpConnectionStatus status = McpConnectionStatus.disconnected;
  DateTime? lastHealthCheck;
  String? lastError;
  
  // 监控相关
  late McpMonitor monitor;
  HealthCheckStrategy? preferredStrategy;
  
  ImprovedMcpClientBase({
    required this.config,
    this.preferredStrategy,
  }) {
    _initializeMonitor();
  }
  
  void _initializeMonitor() {
    final strategy = preferredStrategy ?? HealthCheckStrategy.probe;
    monitor = McpMonitor(
      config: config,
      strategy: strategy,
      healthCheckInterval: const Duration(seconds: 30),
      maxRetries: 3,
    );
  }
  
  /// 连接到 MCP 服务器
  Future<bool> connect();
  
  /// 断开连接
  Future<void> disconnect();
  
  /// 健康检查（带策略支持）
  Future<bool> healthCheck({HealthCheckStrategy? strategy});
  
  /// 获取健康检查结果
  Future<HealthCheckResult> performDetailedHealthCheck({
    HealthCheckStrategy? strategy,
  }) {
    final s = strategy ?? monitor.strategy;
    return monitor.performHealthCheck();
  }
  
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
  void dispose() {
    monitor.dispose();
  }
}
