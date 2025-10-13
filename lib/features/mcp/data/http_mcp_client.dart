import 'package:dio/dio.dart';
import 'dart:async';
import '../domain/mcp_config.dart';
import 'mcp_client_base.dart';

/// HTTP 模式的 MCP 客户端
class HttpMcpClient extends McpClientBase {
  final Dio _dio;
  Timer? _heartbeatTimer;

  HttpMcpClient({required super.config, Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<bool> connect() async {
    try {
      status = McpConnectionStatus.connecting;

      // 配置 Dio
      _dio.options.baseUrl = config.endpoint;
      if (config.headers != null) {
        _dio.options.headers.addAll(config.headers!);
      }

      // 尝试连接
      final response = await _dio.get('/health');

      if (response.statusCode == 200) {
        status = McpConnectionStatus.connected;
        _startHeartbeat();
        return true;
      } else {
        status = McpConnectionStatus.error;
        return false;
      }
    } catch (e) {
      status = McpConnectionStatus.error;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _stopHeartbeat();
    status = McpConnectionStatus.disconnected;
  }

  @override
  Future<Map<String, dynamic>?> getContext(String contextId) async {
    try {
      final response = await _dio.get('/context/$contextId');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
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
      final response = await _dio.post('/context/$contextId', data: context);
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
      final response = await _dio.post('/tools/$toolName', data: params);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> listTools() async {
    try {
      final response = await _dio.get('/tools');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 开始心跳检测
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      try {
        await _dio.get('/health');
      } catch (e) {
        status = McpConnectionStatus.error;
        _stopHeartbeat();
      }
    });
  }

  /// 停止心跳检测
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void dispose() {
    _stopHeartbeat();
  }
}
