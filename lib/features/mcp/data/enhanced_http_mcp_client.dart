import 'package:dio/dio.dart';
import 'dart:async';
import '../domain/mcp_config.dart';
import 'mcp_client_base.dart';
import '../../../core/services/log_service.dart';

class EnhancedHttpMcpClient extends McpClientBase {
  final Dio _dio;
  Timer? _heartbeatTimer;
  StreamController<String>? _sseController;
  final LogService _log = LogService();
  final String? customHealthCheckPath;
  String? _detectedHealthCheckPath;
  final Map<String, String> _detectedEndpoints = {};

  EnhancedHttpMcpClient({
    required super.config,
    Dio? dio,
    this.customHealthCheckPath,
  }) : _dio = dio ?? Dio();

  String _normalizePath(String path) {
    String normalized = path.trim();
    while (normalized.startsWith('//')) {
      normalized = normalized.substring(1);
    }
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    return normalized;
  }

  String _extractBaseUrl(String endpoint) {
    try {
      final uri = Uri.parse(endpoint);
      final port = uri.port;
      final portStr = (port == 80 || port == 443) ? '' : ':$port';
      return '${uri.scheme}://${uri.host}$portStr';
    } catch (e) {
      _log.error('解析 URL 失败', e);
      return endpoint;
    }
  }

  String _buildUrl(String baseUrl, String path) {
    final normalizedPath = _normalizePath(path);
    final base = baseUrl.trimRight();
    if (base.endsWith('/')) {
      return base + normalizedPath.substring(1);
    }
    return base + normalizedPath;
  }

  @override
  Future<bool> connect() async {
    _log.info('改进的 HTTP MCP 客户端开始连接', {'endpoint': config.endpoint});
    try {
      status = McpConnectionStatus.connecting;
      _configDio();

      if (customHealthCheckPath != null) {
        final isHealthy = await healthCheck();
        if (isHealthy) {
          status = McpConnectionStatus.connected;
          _log.info('连接成功（自定义路径）', {'path': customHealthCheckPath});
          _startHeartbeat();
          return true;
        }
      }

      _log.debug('开始自动探测端点...');
      final detected = await _detectEndpoints();
      if (detected) {
        status = McpConnectionStatus.connected;
        _log.info('连接成功（自动探测）', {'endpoints': _detectedEndpoints});
        _startHeartbeat();
        return true;
      }

      status = McpConnectionStatus.error;
      lastError = '无法连接到服务器';
      return false;
    } catch (e) {
      status = McpConnectionStatus.error;
      lastError = e.toString();
      _log.error('连接异常', e);
      return false;
    }
  }

  void _configDio() {
    final baseUrl = _extractBaseUrl(config.endpoint);
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    if (config.headers != null) {
      _dio.options.headers.addAll(config.headers!);
    }
  }

  Future<bool> _detectEndpoints() async {
    final baseUrl = _extractBaseUrl(config.endpoint);
    final paths = [
      '/health',
      '/api/health',
      '/ping',
      '/api/kubernetes/sse',
      '/sse',
      '/api/v1/health',
    ];

    for (final path in paths) {
      try {
        final url = _buildUrl(baseUrl, path);
        final response = await _dio
            .get(
              url,
              options: Options(
                receiveTimeout: const Duration(seconds: 3),
                validateStatus: (status) => status != null && status < 500,
              ),
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200 || response.statusCode == 101) {
          _detectedHealthCheckPath = path;
          _detectedEndpoints['health'] = path;
          _log.info('找到有效端点', {'path': path});
          return true;
        }
      } catch (e) {
        continue;
      }
    }
    return false;
  }

  @override
  Future<bool> healthCheck() async {
    try {
      final path =
          customHealthCheckPath ?? _detectedHealthCheckPath ?? '/health';
      final url = _buildUrl(_extractBaseUrl(config.endpoint), path);
      final response = await _dio.get(
        url,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final isHealthy = response.statusCode == 200;
      if (isHealthy) {
        lastHealthCheck = DateTime.now();
        lastError = null;
      } else {
        lastError = 'HTTP ${response.statusCode}';
      }
      return isHealthy;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _stopHeartbeat();
    _closeSseConnection();
    status = McpConnectionStatus.disconnected;
  }

  @override
  Future<Map<String, dynamic>?> getContext(String contextId) async {
    try {
      final url = _buildUrl(
        _extractBaseUrl(config.endpoint),
        '/context/$contextId',
      );
      final response = await _dio.get(url);
      return response.statusCode == 200
          ? response.data as Map<String, dynamic>?
          : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> pushContext(
    String contextId,
    Map<String, dynamic> context,
  ) async {
    try {
      final url = _buildUrl(
        _extractBaseUrl(config.endpoint),
        '/context/$contextId',
      );
      final response = await _dio.post(url, data: context);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> callTool(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    try {
      final url = _buildUrl(
        _extractBaseUrl(config.endpoint),
        '/tools/$toolName',
      );
      final response = await _dio.post(url, data: params);
      return response.statusCode == 200
          ? response.data as Map<String, dynamic>?
          : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> listTools() async {
    try {
      final url = _buildUrl(_extractBaseUrl(config.endpoint), '/tools');
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map<String, dynamic>) {
          if (data['tools'] is List) {
            return (data['tools'] as List).cast<Map<String, dynamic>>();
          }
          if (data['data'] is List) {
            return (data['data'] as List).cast<Map<String, dynamic>>();
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, String> getDetectedEndpoints() => _detectedEndpoints;

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!await healthCheck()) {
        status = McpConnectionStatus.error;
        _stopHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _closeSseConnection() {
    if (_sseController != null && !_sseController!.isClosed) {
      _sseController!.close();
      _sseController = null;
    }
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _closeSseConnection();
  }
}
