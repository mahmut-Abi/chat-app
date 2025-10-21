import '../domain/mcp_config.dart';
import 'mcp_client_base.dart';
import 'http_mcp_client.dart';
import 'stdio_mcp_client.dart';
import 'enhanced_http_mcp_client.dart';
import '../../../core/services/log_service.dart';

/// MCP 客户端工厂 - 支持增强型客户端和自动端点探测
class McpClientFactory {
  static final _log = LogService();

  /// 根据配置创建相应的 MCP 客户端
  /// 
  /// 优先使用增强型 HTTP 客户端，支持自动端点探测
  static McpClientBase createClient(
    McpConfig config, {
    String? customHealthCheckPath,
    bool useEnhancedClient = true,
  }) {
    _log.info('Creating MCP client', {
      'type': config.connectionType.toString(),
      'enhanced': useEnhancedClient,
    });

    // 对于 HTTP 连接，优先使用增强型客户端
    if (config.connectionType == McpConnectionType.http && useEnhancedClient) {
      return EnhancedHttpMcpClient(
        config: config,
        customHealthCheckPath: customHealthCheckPath,
      );
    }

    // 标准工厂方法
    switch (config.connectionType) {
      case McpConnectionType.http:
        return HttpMcpClient(config: config);
      case McpConnectionType.stdio:
        return StdioMcpClient(config: config);
    }
  }

  /// 创建增强型 HTTP 客户端，用于已知有问题的服务器
  static EnhancedHttpMcpClient createEnhancedHttpClient(
    McpConfig config, {
    String? customHealthCheckPath,
  }) {
    return EnhancedHttpMcpClient(
      config: config,
      customHealthCheckPath: customHealthCheckPath,
    );
  }
}
