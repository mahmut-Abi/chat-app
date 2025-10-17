import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import '../domain/mcp_config.dart';
import 'mcp_client_base.dart';
import '../../../core/services/log_service.dart';

/// HTTP 模式的 MCP 客户端
class HttpMcpClient extends McpClientBase {
  final Dio _dio;
  Timer? _heartbeatTimer;
  StreamController<String>? _sseController;
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

      // 执行健康检查
      final isHealthy = await healthCheck();
      if (isHealthy) {
        status = McpConnectionStatus.connected;
        _log.info('HTTP MCP 客户端连接成功', {'endpoint': config.endpoint});
        _startHeartbeat();
        return true;
      } else {
        status = McpConnectionStatus.error;
        _log.warning('HTTP MCP 客户端连接失败', {'error': lastError});
        return false;
      }
    } catch (e) {
      status = McpConnectionStatus.error;
      lastError = e.toString();
      _log.error('HTTP MCP 客户端连接异常', e);
      return false;
    }
  }

  @override
  Future<bool> healthCheck() async {
    _log.debug('执行健康检查', {'endpoint': config.endpoint});
    try {
      final response = await _dio.get(
        '/health',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final isHealthy = response.statusCode == 200;
      if (isHealthy) {
        lastHealthCheck = DateTime.now();
        lastError = null;
        _log.info('健康检查通过', {'endpoint': config.endpoint});
      } else {
        lastError = 'HTTP ${response.statusCode}';
        _log.warning('健康检查失败', {
          'endpoint': config.endpoint,
          'statusCode': response.statusCode,
        });
      }
      return isHealthy;
    } catch (e) {
      lastError = e.toString();
      _log.error('健康检查异常', e);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _log.info('HTTP MCP 客户端断开连接', {'endpoint': config.endpoint});
    _stopHeartbeat();
    _closeSseConnection();
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
      final isHealthy = await healthCheck();
      if (!isHealthy) {
        status = McpConnectionStatus.error;
        _log.error('MCP 心跳检测失败', lastError);
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

  /// SSE 连接
  Future<Stream<String>?> connectSSE(String endpoint) async {
    _log.info('建立 SSE 连接', {'endpoint': endpoint});
    try {
      _sseController = StreamController<String>();

      final response = await _dio.get<ResponseBody>(
        endpoint,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        response.data!.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (data) {
                _log.debug('收到 SSE 数据', {'dataLength': data.length});
                if (!_sseController!.isClosed) {
                  _sseController!.add(data);
                }
              },
              onError: (error) {
                _log.error('SSE 连接错误', error);
                if (!_sseController!.isClosed) {
                  _sseController!.addError(error);
                }
              },
              onDone: () {
                _log.info('SSE 连接关闭');
                if (!_sseController!.isClosed) {
                  _sseController!.close();
                }
              },
              cancelOnError: true,
            );
        return _sseController!.stream;
      }
      _log.warning('SSE 连接失败', {'statusCode': response.statusCode});
      return null;
    } catch (e) {
      _log.error('SSE 连接异常', e);
      return null;
    }
  }

  /// 关闭 SSE 连接
  void _closeSseConnection() {
    if (_sseController != null && !_sseController!.isClosed) {
      _log.debug('关闭 SSE 连接');
      _sseController!.close();
      _sseController = null;
    }
  }

  @override
  void dispose() {
    _log.debug('HTTP MCP 客户端释放资源', {'endpoint': config.endpoint});
    _stopHeartbeat();
    _closeSseConnection();
  }
}
