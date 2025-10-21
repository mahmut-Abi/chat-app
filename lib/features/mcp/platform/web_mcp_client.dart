import 'dart:async';
import 'package:dio/dio.dart';
import '../domain/mcp_config.dart';
import '../data/mcp_client_base.dart';
import '../../../core/services/log_service.dart';

/// Web-optimized MCP client with CORS and timeout handling
class WebMcpClient extends McpClientBase {
  final Dio _dio;
  Timer? _healthCheckTimer;
  Timer? _reconnectTimer;
  final LogService _log = LogService();
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  WebMcpClient({required super.config, Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<bool> connect() async {
    _log.info('Web MCP connecting', {'endpoint': config.endpoint});
    try {
      status = McpConnectionStatus.connecting;
      _dio.options.baseUrl = config.endpoint;
      _dio.options.connectTimeout = const Duration(seconds: 10);
      _dio.options.receiveTimeout = const Duration(seconds: 10);
      if (config.headers != null) {
        _dio.options.headers.addAll(config.headers!);
      }
      final isHealthy = await healthCheck();
      if (isHealthy) {
        status = McpConnectionStatus.connected;
        _reconnectAttempts = 0;
        _startHealthCheck();
        return true;
      } else {
        status = McpConnectionStatus.error;
        _startReconnect();
        return false;
      }
    } catch (e) {
      status = McpConnectionStatus.error;
      lastError = e.toString();
      _startReconnect();
      return false;
    }
  }

  @override
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health')
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    status = McpConnectionStatus.disconnected;
    _healthCheckTimer?.cancel();
    _reconnectTimer?.cancel();
  }

  @override
  Future<Map<String, dynamic>?> getContext(String contextId) async {
    try {
      final response = await _dio.get('/context/\$contextId');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> pushContext(String contextId, Map<String, dynamic> context) async {
    try {
      await _dio.post('/context/\$contextId', data: context);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> callTool(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _dio.post('/tools/\$toolName', data: params)
          .timeout(const Duration(seconds: 30));
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> listTools() async {
    try {
      final response = await _dio.get('/tools');
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (status != McpConnectionStatus.connected) return;
      if (!await healthCheck()) {
        status = McpConnectionStatus.error;
        _startReconnect();
      }
    });
  }

  void _startReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      status = McpConnectionStatus.error;
      return;
    }
    _reconnectTimer = Timer(_reconnectDelay, () async {
      _reconnectAttempts++;
      await connect();
    });
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}
