import '../domain/mcp_config.dart';
import '../data/mcp_client_base.dart';
import '../data/http_mcp_client.dart';
import '../data/stdio_mcp_client.dart';
import 'platform_config.dart';
import '../../../core/services/log_service.dart';

/// MCP Platform Adapter - Platform-aware MCP client factory
class McpPlatformAdapter {
  static final _log = LogService();

  /// Create appropriate MCP client based on platform and connection type
  static McpClientBase createClientForPlatform(McpConfig config) {
    _log.info('Creating MCP client for platform', {
      'platform': PlatformConfig.currentPlatform.toString(),
      'connectionType': config.connectionType.toString(),
      'endpoint': config.endpoint,
    });

    if (PlatformConfig.isWeb) {
      if (config.connectionType == McpConnectionType.stdio) {
        _log.warning('Stdio mode not supported on web, using HTTP fallback');
      }
      return HttpMcpClient(config: config);
    }

    if (PlatformConfig.isMobile) {
      if (config.connectionType == McpConnectionType.stdio) {
        _log.warning('Stdio mode not supported on mobile, using HTTP fallback');
      }
      return HttpMcpClient(config: config);
    }

    switch (config.connectionType) {
      case McpConnectionType.http:
        return HttpMcpClient(config: config);
      case McpConnectionType.stdio:
        return StdioMcpClient(config: config);
    }
  }

  /// Validate if config is compatible with current platform
  static bool isConfigCompatibleWithPlatform(McpConfig config) {
    if (config.connectionType == McpConnectionType.stdio) {
      return PlatformConfig.supportsStdioMode;
    }
    if (config.connectionType == McpConnectionType.http) {
      return PlatformConfig.supportsHttpMode;
    }
    return true;
  }

  /// Get list of compatible connection types for current platform
  static List<McpConnectionType> getSupportedConnectionTypes() {
    final supported = <McpConnectionType>[];
    if (PlatformConfig.supportsHttpMode) {
      supported.add(McpConnectionType.http);
    }
    if (PlatformConfig.supportsStdioMode) {
      supported.add(McpConnectionType.stdio);
    }
    return supported;
  }

  /// Get recommended connection type for current platform
  static McpConnectionType getRecommendedConnectionType() {
    return PlatformConfig.isDesktop ? McpConnectionType.stdio : McpConnectionType.http;
  }
}
