import 'dart:async';
import 'package:dio/dio.dart';
import '../domain/mcp_config.dart';
import '../data/mcp_client_base.dart';
import '../../../core/services/log_service.dart';

/// Mobile-optimized MCP client with resource conservation
class MobileMcpClient extends McpClientBase {
  final Dio _dio;
  Timer? _healthCheckTimer;
  final LogService _log = LogService();
  bool _connectionLost = false;

  MobileMcpClient({required super.config, Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<bool> connect() async {
    _log.info('Mobile MCP connecting', {'endpoint': config.endpoint});
    try {
      status = McpConnectionStatus.connecting;
      _dio.options.baseUrl = config.endpoint;
      _dio.options.connectTimeout = const Duration(seconds: 8);
      _dio.options.receiveTimeout = const Duration(seconds: 8);
      if (config.headers != null) {
        _dio.options.headers.addAll(config.headers!);
      }
      final isHealthy = await healthCheck();
      if (isHealthy) {
        status = McpConnectionStatus.connected;
        _connectionLost = false;
        _startHealthCheck();
        return true;
      } else {
        status = McpConnectionStatus.error;
        _connectionLost = true;
        return false;
      }
    } catch (e) {
      status = McpConnectionStatus.error;
      lastError = e.toString();
      _connectionLost = true;
      return false;
    }
  }

  @override
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health')
          .timeout(const Duration(seconds: 5));
      final isHealthy = response.statusCode == 200;
      if (isHealthy) {
        _connectionLost = false;
      } else {
        _connectionLost = true;
      }
      return isHealthy;
    } catch (e) {
      _connectionLost = true;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    status = McpConnectionStatus.disconnected;
    _healthCheckTimer?.cancel();
  }

  @override
  Future<Map<String, dynamic>?> getContext(String contextId) async {
    if (_connectionLost) return null;
    try {
      final response = await _dio.get('/context/\$contextId');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      _connectionLost = true;
      return null;
    }
  }

  @override
  Future<bool> pushContext(String contextId, Map<String, dynamic> context) async {
    if (_connectionLost) return false;
    try {
      await _dio.post('/context/\$contextId', data: context);
      return true;
    } catch (e) {
      _connectionLost = true;
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> callTool(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    if (_connectionLost) return null;
    try {
      final response = await _dio.post('/tools/\$toolName', data: params);
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      _connectionLost = true;
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> listTools() async {
    if (_connectionLost) return null;
    try {
      final response = await _dio.get('/tools');
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      _connectionLost = true;
      return null;
    }
  }

  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (status != McpConnectionStatus.connected) return;
      await healthCheck();
    });
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
  }
}
