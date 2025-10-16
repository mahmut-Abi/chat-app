import 'package:dio/dio.dart';
import 'dart:async';
import '../domain/mcp_config.dart';
import 'mcp_client_base.dart';
import '../../../core/services/log_service.dart';

/// HTTP 模式的 MCP 客户端
class HttpMcpClient extends McpClientBase {
  final Dio _dio;
  Timer? _heartbeatTimer;
  final LogService _log = LogService();

  HttpMcpClient({required super.config, Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<bool> connect() async {
    _log.info('HTTP MCP 客户端开始连接', {
      'endpoint': config.endpoint,
      'configId': config.id,
    });
    try {
      status = McpConnectionStatus.connecting;
      _log.debug('设置连接状态为 connecting');

      // 配置 Dio
      _dio.options.baseUrl = config.endpoint;
      if (config.headers != null) {
        _log.debug('添加请求头', {'headersCount': config.headers!.length});
        _dio.options.headers.addAll(config.headers!);
      }

      // 尝试连接
      _log.debug('发送健康检查请求');
      final response = await _dio.get('/health');

      if (response.statusCode == 200) {
        status = McpConnectionStatus.connected;
        _log.info('HTTP MCP 客户端连接成功', {'endpoint': config.endpoint});
        _startHeartbeat();
        return true;
      } else {
        status = McpConnectionStatus.error;
        _log.warning('HTTP MCP 客户端连接失败', {'statusCode': response.statusCode});
        return false;
      }
    } catch (e) {
      status = McpConnectionStatus.error;
      _log.error('HTTP MCP 客户端连接异常', e);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _log.info('HTTP MCP 客户端断开连接', {'endpoint': config.endpoint});
    _stopHeartbeat();
    status = McpConnectionStatus.disconnected;
    _log.debug('设置连接状态为 disconnected');
  }

  @override
  Future<Map<String, dynamic>?> getContext(String contextId) async {
    _log.debug('获取 MCP 上下文', {'contextId': contextId});
    try {
      final response = await _dio.get('/context/$contextId');
      if (response.statusCode == 200) {
        _log.debug('成功获取上下文', {'contextId': contextId});
        return response.data as Map<String, dynamic>;
      }
      _log.warning('获取上下文失败', {
        'contextId': contextId,
        'statusCode': response.statusCode,
      });
      return null;
    } catch (e) {
      _log.error('获取上下文异常', e);
      return null;
    }
  }

  @override
  Future<bool> pushContext(
    String contextId,
    Map<String, dynamic> context,
  ) async {
    _log.debug('推送 MCP 上下文', {
      'contextId': contextId,
      'dataKeys': context.keys.toList(),
    });
    try {
      final response = await _dio.post('/context/$contextId', data: context);
      final success = response.statusCode == 200;
      if (success) {
        _log.debug('成功推送上下文', {'contextId': contextId});
      } else {
        _log.warning('推送上下文失败', {
          'contextId': contextId,
          'statusCode': response.statusCode,
        });
      }
      return success;
    } catch (e) {
      _log.error('推送上下文异常', e);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> callTool(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    _log.info('调用 MCP 工具', {
      'toolName': toolName,
      'paramsKeys': params.keys.toList(),
    });
    try {
      final response = await _dio.post('/tools/$toolName', data: params);
      if (response.statusCode == 200) {
        _log.info('MCP 工具调用成功', {'toolName': toolName});
        return response.data as Map<String, dynamic>;
      }
      _log.warning('MCP 工具调用失败', {
        'toolName': toolName,
        'statusCode': response.statusCode,
      });
      return null;
    } catch (e) {
      _log.error('MCP 工具调用异常', e);
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> listTools() async {
    _log.debug('获取 MCP 工具列表');
    try {
      final response = await _dio.get('/tools');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final tools = data.cast<Map<String, dynamic>>();
          _log.info('获取到 MCP 工具列表', {'count': tools.length});
          return tools;
        }
      }
      _log.warning('获取工具列表失败', {'statusCode': response.statusCode});
      return null;
    } catch (e) {
      _log.error('获取工具列表异常', e);
      return null;
    }
  }

  /// 开始心跳检测
  void _startHeartbeat() {
    _log.debug('启动 MCP 心跳检测');
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      try {
        await _dio.get('/health');
        _log.debug('MCP 心跳检测正常');
      } catch (e) {
        status = McpConnectionStatus.error;
        _log.error('MCP 心跳检测失败', e);
        _stopHeartbeat();
      }
    });
  }

  /// 停止心跳检测
  void _stopHeartbeat() {
    if (_heartbeatTimer != null) {
      _log.debug('停止 MCP 心跳检测');
    }
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void dispose() {
    _log.debug('HTTP MCP 客户端释放资源', {'endpoint': config.endpoint});
    _stopHeartbeat();
  }
}
