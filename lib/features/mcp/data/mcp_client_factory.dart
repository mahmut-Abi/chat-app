import '../domain/mcp_config.dart';
import 'mcp_client_base.dart';
import 'http_mcp_client.dart';
import 'stdio_mcp_client.dart';

/// MCP 客户端工厂
class McpClientFactory {
  /// 根据配置创建相应的 MCP 客户端
  static McpClientBase createClient(McpConfig config) {
    switch (config.connectionType) {
      case McpConnectionType.http:
        return HttpMcpClient(config: config);
      case McpConnectionType.stdio:
        return StdioMcpClient(config: config);
    }
  }
}
