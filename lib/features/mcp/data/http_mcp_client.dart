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
  int _failureCount = 0;
  static const int _maxFailures = 3;

  HttpMcpClient({required super.config, Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// 调整 URL 路径（移除开头的 /）
  String _normalizePath(String path) {
    String normalized = path;
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized.isEmpty ? '' : '/$normalized';
  }

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

      // 执行健康检查（带自动降级方案）
      final isHealthy = await healthCheckWithFallback();
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

  /// 健康检查改进版本：带自动降级路径检测
  Future<bool> healthCheckWithFallback() async {
    final paths = [
      '/health',
      '/ping',
      '/status',
      '/tools',
      '/api/health',
      '/api/ping',
    ];
    _log.info('执行健康检查（带自动降级）');

    for (final path in paths) {
      try {
        final response = await _dio
            .get(
              path,
              options: Options(
                receiveTimeout: const Duration(seconds: 4),
                validateStatus: (status) => status != null && status < 500,
              ),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          _log.info('健康检查成功', {'path': path});
          lastHealthCheck = DateTime.now();
          lastError = null;
          return true;
        }
      } catch (e) {
        // 继续尝试下一个路径
      }
    }

    // 所有路径都失败，尝试网络连接检查
    _log.debug('健康检查路径失败，尝试网络连接');
    try {
      final response = await _dio
          .get(
            '',
            options: Options(
              receiveTimeout: const Duration(seconds: 3),
              validateStatus: (status) => status != null,
            ),
          )
          .timeout(const Duration(seconds: 3));
      lastHealthCheck = DateTime.now();
      lastError = null;
      return true;
    } catch (e) {
      lastError = '无法连接服务器';
      return false;
    }
  }

  /// 为 Kubernetes SSE 服务器优化的健康检查
  Future<bool> healthCheckForSSEServer() async {
    _log.debug('Kubernetes SSE 服务器健康检查', {'endpoint': config.endpoint});
    try {
      // 氺试略斥橣 SSE 端点以检测连接
      final response = await _dio.get(
        '/api/kubernetes/sse',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          followRedirects: true,
        ),
      );

      // SSE 端点返回 200 表示正常
      if (response.statusCode == 200) {
        lastHealthCheck = DateTime.now();
        lastError = null;
        _log.info('Kubernetes SSE 服务器健康检查成功', {'endpoint': config.endpoint});
        return true;
      } else {
        lastError = 'Kubernetes SSE: HTTP ${response.statusCode}';
        _log.warning('Kubernetes SSE 健康检查失败', {
          'statusCode': response.statusCode,
        });
        return false;
      }
    } catch (e) {
      lastError = 'Kubernetes SSE: ${e.toString()}';
      _log.error('Kubernetes SSE 健康检查异常', e);
      return false;
    }
  }

  /// 尝试其他健康检查端点
  Future<bool> _tryAlternativeHealthChecks() async {
    final endpoints = ['health', 'api/health', 'ping', 'api/ping', 'tools'];

    for (final endpoint in endpoints) {
      try {
        final response = await _dio.get(
          endpoint,
          options: Options(receiveTimeout: const Duration(seconds: 3)),
        );
        if (response.statusCode == 200) {
          _log.info('替代健康检查拓扑成功', {'endpoint': endpoint});
          return true;
        }
      } catch (e) {
        _log.debug('替代端点失败', {'endpoint': endpoint});
      }
    }
    return false;
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

  /// 获取工具列表（增强版）
  Future<List<Map<String, dynamic>>?> listToolsEnhanced() async {
    _log.debug('获取 MCP 工具列表(增强)');
    try {
      final response = await _dio.get('/tools');
      if (response.statusCode == 200) {
        final data = response.data;

        // 众加处理哬各 API 哬各的哬各形式
        List<Map<String, dynamic>>? tools;

        if (data is List) {
          // 直接返回列表
          tools = data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic>) {
          // 处理 nested 结构（如 {"tools": [...]})
          if (data['tools'] is List) {
            tools = (data['tools'] as List).cast<Map<String, dynamic>>();
          } else if (data['data'] is List) {
            tools = (data['data'] as List).cast<Map<String, dynamic>>();
          } else if (data['items'] is List) {
            tools = (data['items'] as List).cast<Map<String, dynamic>>();
          }
        }

        if (tools != null) {
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
      // 使用广播流，支持多个监听器
      _sseController = StreamController<String>.broadcast();

      final response = await _dio.get<ResponseBody>(
        endpoint,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        response.data!.stream
            .cast<List<int>>()
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

  /// 获取提示词列表
  Future<List<Map<String, dynamic>>?> listPrompts() async {
    _log.debug('获取提示词列表');
    try {
      final response = await _dio.get('/prompts');
      if (response.statusCode == 200) {
        final data = response.data;

        List<Map<String, dynamic>>? prompts;
        if (data is List) {
          prompts = data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic>) {
          if (data['prompts'] is List) {
            prompts = (data['prompts'] as List).cast<Map<String, dynamic>>();
          } else if (data['data'] is List) {
            prompts = (data['data'] as List).cast<Map<String, dynamic>>();
          }
        }

        if (prompts != null) {
          _log.info('获取到提示词列表', {'count': prompts.length});
          return prompts;
        }
      }
      _log.warning('获取提示词列表失败');
      return null;
    } catch (e) {
      _log.error('获取提示词列表异常', e);
      return null;
    }
  }

  /// 获取资源列表
  Future<List<Map<String, dynamic>>?> listResources() async {
    _log.debug('获取资源列表');
    try {
      final response = await _dio.get('/resources');
      if (response.statusCode == 200) {
        final data = response.data;

        List<Map<String, dynamic>>? resources;
        if (data is List) {
          resources = data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic>) {
          if (data['resources'] is List) {
            resources = (data['resources'] as List)
                .cast<Map<String, dynamic>>();
          } else if (data['data'] is List) {
            resources = (data['data'] as List).cast<Map<String, dynamic>>();
          }
        }

        if (resources != null) {
          _log.info('获取到资源列表', {'count': resources.length});
          return resources;
        }
      }
      _log.warning('获取资源列表失败');
      return null;
    } catch (e) {
      _log.error('获取资源列表异常', e);
      return null;
    }
  }

  @override
  void dispose() {
    _log.debug('HTTP MCP 客户端释放资源', {'endpoint': config.endpoint});
    _stopHeartbeat();
    _closeSseConnection();
  }
}
