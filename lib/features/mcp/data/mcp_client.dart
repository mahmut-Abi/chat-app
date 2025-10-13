import 'package:dio/dio.dart';
import '../domain/mcp_config.dart';
import 'dart:async';

/// MCP 客户端
class McpClient {
  final Dio _dio;
  final McpConfig config;
  McpConnectionStatus _status = McpConnectionStatus.disconnected;
  Timer? _heartbeatTimer;

  McpClient({required this.config, Dio? dio}) : _dio = dio ?? Dio();

  McpConnectionStatus get status => _status;

  /// 连接到 MCP 服务器
  Future<bool> connect() async {
    try {
      _status = McpConnectionStatus.connecting;

      // 配置 Dio
      _dio.options.baseUrl = config.endpoint;
      if (config.headers != null) {
        _dio.options.headers.addAll(config.headers!);
      }

      // 尝试连接
      final response = await _dio.get('/health');

      if (response.statusCode == 200) {
        _status = McpConnectionStatus.connected;
        _startHeartbeat();
        return true;
      } else {
        _status = McpConnectionStatus.error;
        return false;
      }
    } catch (e) {
      _status = McpConnectionStatus.error;
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _stopHeartbeat();
    _status = McpConnectionStatus.disconnected;
  }

  /// 获取上下文
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

  /// 推送上下文
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

  /// 开始心跳检测
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      try {
        await _dio.get('/health');
      } catch (e) {
        _status = McpConnectionStatus.error;
        _stopHeartbeat();
      }
    });
  }

  /// 停止心跳检测
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void dispose() {
    _stopHeartbeat();
  }
}
