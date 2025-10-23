import 'package:dio/dio.dart';
import '../domain/mcp_config.dart';
import '../../../core/services/log_service.dart';
import 'mcp_health_check_strategy.dart';
import 'dart:io';

/// MCP 监控诊断结果
class MonitorDiagnosticResult {
  final String configId;
  final String endpoint;
  final DateTime timestamp;

  // 网络层诊断
  late bool dnsResolvable;
  late bool tcpConnectable;
  late bool tlsValid;
  String? dnsError;
  String? tcpError;
  String? tlsError;

  // HTTP 层诊断
  late bool httpReachable;
  int? httpStatusCode;
  String? httpError;
  final List<String> availableEndpoints = [];

  // 应用层诊断
  late bool mcpHealthy;
  late bool toolsAvailable;
  int? toolCount;
  String? mcpError;

  // 建议与帮助
  final List<String> recommendations = [];
  final List<String> debugInfo = [];

  MonitorDiagnosticResult({
    required this.configId,
    required this.endpoint,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isFullyHealthy =>
      dnsResolvable &&
      tcpConnectable &&
      httpReachable &&
      mcpHealthy &&
      toolsAvailable;

  bool get isIrrecoverable =>
      !dnsResolvable || !tcpConnectable || tlsError != null;

  String getSummary() {
    if (isFullyHealthy) return '应用完全健康';
    if (isIrrecoverable) return '不可修复的错误';

    final issues = <String>[];
    if (!dnsResolvable) issues.add('DNS解析失败');
    if (!tcpConnectable) issues.add('TCP连接失败');
    if (!httpReachable) issues.add('HTTP不可达');
    if (!mcpHealthy) issues.add('MCP不健康');
    if (!toolsAvailable) issues.add('工具不可用');

    return issues.join(', ');
  }
}

/// MCP 监控诊断服务
class McpMonitorDiagnosticsService {
  final LogService log = LogService();
  final Dio _dio = Dio();

  Future<MonitorDiagnosticResult> diagnose(McpConfig config) async {
    log.info('开始 MCP 诊断', {'configId': config.id, 'endpoint': config.endpoint});

    final result = MonitorDiagnosticResult(
      configId: config.id,
      endpoint: config.endpoint,
    );

    await _checkDnsResolution(config.endpoint, result);
    if (result.dnsResolvable) {
      await _checkTcpConnection(config.endpoint, result);
    }
    if (result.tcpConnectable) {
      await _checkTlsHandshake(config.endpoint, result);
      await _checkHttpReachability(config, result);
    }
    if (result.httpReachable) {
      await _checkMcpHealth(config, result);
      await _checkToolsAvailability(config, result);
    }

    _generateRecommendations(result);
    return result;
  }

  Future<void> _checkDnsResolution(
    String endpoint,
    MonitorDiagnosticResult result,
  ) async {
    try {
      final uri = Uri.parse(endpoint);
      final addresses = await InternetAddress.lookup(
        uri.host,
      ).timeout(const Duration(seconds: 5));
      result.dnsResolvable = addresses.isNotEmpty;
    } catch (e) {
      result.dnsResolvable = false;
      result.dnsError = e.toString();
    }
  }

  Future<void> _checkTcpConnection(
    String endpoint,
    MonitorDiagnosticResult result,
  ) async {
    try {
      final uri = Uri.parse(endpoint);
      final port = uri.port == 0
          ? (uri.scheme == 'https' ? 443 : 80)
          : uri.port;
      final socket = await Socket.connect(
        uri.host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      result.tcpConnectable = true;
    } catch (e) {
      result.tcpConnectable = false;
      result.tcpError = e.toString();
    }
  }

  Future<void> _checkTlsHandshake(
    String endpoint,
    MonitorDiagnosticResult result,
  ) async {
    try {
      final uri = Uri.parse(endpoint);
      if (uri.scheme != 'https') return;

      final socket = await SecureSocket.connect(
        uri.host,
        uri.port == 0 ? 443 : uri.port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      result.tlsValid = true;
    } catch (e) {
      result.tlsError = e.toString();
    }
  }

  Future<void> _checkHttpReachability(
    McpConfig config,
    MonitorDiagnosticResult result,
  ) async {
    final paths = ['/health', '/api/health', '/ping', '/', '/status'];

    for (final path in paths) {
      try {
        final url = config.endpoint.endsWith('/')
            ? config.endpoint + path.substring(1)
            : config.endpoint + path;

        final response = await _dio
            .get(
              url,
              options: Options(
                headers: config.headers,
                receiveTimeout: const Duration(seconds: 3),
                validateStatus: (status) => status != null && status < 500,
              ),
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode != null && response.statusCode! < 400) {
          result.httpReachable = true;
          result.httpStatusCode = response.statusCode;
          result.availableEndpoints.add(path);
          break;
        }
      } catch (e) {
        result.httpError = e.toString();
      }
    }
  }

  Future<void> _checkMcpHealth(
    McpConfig config,
    MonitorDiagnosticResult result,
  ) async {
    try {
      final strategies = [
        ProbeHealthCheckExecutor(),
        StandardHealthCheckExecutor(),
        ToolsListingHealthCheckExecutor(),
      ];

      for (final strategy in strategies) {
        final healthResult = await strategy.execute(
          config.endpoint,
          config.headers?.cast(),
        );
        if (healthResult.success) {
          result.mcpHealthy = true;
          return;
        }
      }
      result.mcpHealthy = false;
      result.mcpError = '所有健康检查策略均失败';
    } catch (e) {
      result.mcpHealthy = false;
      result.mcpError = e.toString();
    }
  }

  Future<void> _checkToolsAvailability(
    McpConfig config,
    MonitorDiagnosticResult result,
  ) async {
    try {
      final response = await _dio
          .get(
            config.endpoint + '/tools',
            options: Options(
              headers: config.headers,
              receiveTimeout: const Duration(seconds: 5),
              validateStatus: (status) => status != null && status < 500,
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        int toolCount = 0;
        if (response.data is List) {
          toolCount = (response.data as List).length;
        } else if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          if (map['tools'] is List) {
            toolCount = (map['tools'] as List).length;
          }
        }
        result.toolsAvailable = true;
        result.toolCount = toolCount;
      } else {
        result.toolsAvailable = false;
      }
    } catch (e) {
      result.toolsAvailable = false;
    }
  }

  void _generateRecommendations(MonitorDiagnosticResult result) {
    if (!result.dnsResolvable) {
      result.recommendations.add('检查网络配置 - DNS 解析失败');
      result.recommendations.add('尝试使用 IP 地址代替域名');
    }
    if (!result.tcpConnectable && result.dnsResolvable) {
      result.recommendations.add('检查服务器是否运行中');
      result.recommendations.add('检查防火墙配置');
    }
    if (!result.httpReachable && result.tcpConnectable) {
      result.recommendations.add('检查 HTTP 服务是否正常');
      result.recommendations.add('尝试探测其他端点');
    }
    if (!result.mcpHealthy && result.httpReachable) {
      result.recommendations.add('检查 MCP 服务器配置');
      result.recommendations.add('切换健康检查策略');
    }
    if (!result.toolsAvailable && result.mcpHealthy) {
      result.recommendations.add('检查 /tools 端点是否实现');
    }
  }
}
