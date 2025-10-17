import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../domain/mcp_config.dart';
import 'mcp_client_base.dart';
import '../../../core/services/log_service.dart';

/// Stdio 模式的 MCP 客户端
/// 通过启动外部进程并通过 stdin/stdout 通信
class StdioMcpClient extends McpClientBase {
  Process? _process;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _requestId = 0;
  final LogService _log = LogService();

  StdioMcpClient({required super.config});

  @override
  Future<bool> connect() async {
    _log.info('Stdio MCP 客户端开始连接', {
      'command': config.endpoint,
      'args': config.args,
    });
    try {
      status = McpConnectionStatus.connecting;
      _log.debug('设置连接状态为 connecting');

      // 启动外部进程
      _process = await Process.start(
        config.endpoint,
        config.args ?? [],
        environment: config.env,
        runInShell: true,
      );
      _log.debug('进程启动成功', {'pid': _process!.pid});

      // 监听 stdout
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleStdout,
            onError: (error) {
              _log.error('Stdio MCP stdout 错误', error);
              status = McpConnectionStatus.error;
              lastError = error.toString();
            },
          );

      // 监听 stderr
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) => _log.warning('Stdio MCP stderr', {'message': line}),
          );

      // 等待进程启动
      await Future.delayed(const Duration(milliseconds: 500));

      // 发送初始化请求
      _log.debug('发送初始化请求');
      final initialized = await _sendRequest('initialize', {
        'protocolVersion': '1.0',
        'capabilities': {},
      });

      if (initialized != null) {
        status = McpConnectionStatus.connected;
        lastHealthCheck = DateTime.now();
        _log.info('Stdio MCP 客户端连接成功');
        return true;
      } else {
        status = McpConnectionStatus.error;
        lastError = '初始化失败';
        _log.warning('Stdio MCP 客户端连接失败');
        return false;
      }
    } catch (e) {
      status = McpConnectionStatus.error;
      lastError = e.toString();
      _log.error('Stdio MCP 客户端连接异常', e);
      return false;
    }
  }

  @override
  Future<bool> healthCheck() async {
    _log.debug('执行 Stdio MCP 健康检查');
    try {
      // 检查进程是否存活
      if (_process == null) {
        lastError = '进程未启动';
        _log.warning('健康检查失败：进程未启动');
        return false;
      }

      // 发送 ping 请求
      final result = await _sendRequest('ping', {}).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          lastError = '健康检查超时';
          return null;
        },
      );

      final isHealthy = result != null;
      if (isHealthy) {
        lastHealthCheck = DateTime.now();
        lastError = null;
        _log.info('健康检查通过');
      } else {
        _log.warning('健康检查失败', {'error': lastError});
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
    _log.info('Stdio MCP 客户端断开连接');
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _process?.kill();
    _process = null;
    _pendingRequests.clear();
    status = McpConnectionStatus.disconnected;
    _log.debug('设置连接状态为 disconnected');
  }

  @override
  Future<Map<String, dynamic>?> getContext(String contextId) async {
    _log.debug('获取 MCP 上下文', {'contextId': contextId});
    return await _sendRequest('context/get', {'contextId': contextId});
  }

  @override
  Future<bool> pushContext(
    String contextId,
    Map<String, dynamic> context,
  ) async {
    final result = await _sendRequest('context/push', {
      'contextId': contextId,
      'context': context,
    });
    return result != null;
  }

  @override
  Future<Map<String, dynamic>?> callTool(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    _log.info('调用 MCP 工具', {'toolName': toolName});
    return await _sendRequest('tools/call', {
      'name': toolName,
      'arguments': params,
    });
  }

  @override
  Future<List<Map<String, dynamic>>?> listTools() async {
    _log.debug('获取 MCP 工具列表');
    final result = await _sendRequest('tools/list', {});
    if (result != null && result['tools'] is List) {
      final tools = (result['tools'] as List).cast<Map<String, dynamic>>();
      _log.info('获取到 MCP 工具列表', {'count': tools.length});
      return tools;
    }
    return null;
  }

  /// 发送 JSON-RPC 请求
  Future<Map<String, dynamic>?> _sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    if (_process == null) {
      return null;
    }

    final id = _requestId++;
    final request = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id.toString()] = completer;

    try {
      final jsonStr = jsonEncode(request);
      _process!.stdin.writeln(jsonStr);
      await _process!.stdin.flush();

      // 超时 30 秒
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingRequests.remove(id.toString());
          _log.warning('请求超时', {'method': method});
          throw TimeoutException('Request timeout');
        },
      );
    } catch (e) {
      _pendingRequests.remove(id.toString());
      _log.error('发送请求异常', e);
      return null;
    }
  }

  /// 处理 stdout 输出
  void _handleStdout(String line) {
    if (line.trim().isEmpty) return;

    try {
      final json = jsonDecode(line) as Map<String, dynamic>;

      // 处理响应
      if (json.containsKey('id')) {
        final id = json['id'].toString();
        final completer = _pendingRequests.remove(id);

        if (completer != null) {
          if (json.containsKey('result')) {
            completer.complete(json['result'] as Map<String, dynamic>);
          } else if (json.containsKey('error')) {
            completer.completeError(Exception(json['error']));
          }
        }
      }
      // 处理通知和事件
      else if (json.containsKey('method')) {
        _log.debug('收到通知', {'method': json['method']});
      }
    } catch (e) {
      _log.error('处理 stdout 异常', {'error': e.toString(), 'line': line});
    }
  }

  @override
  void dispose() {
    _log.debug('Stdio MCP 客户端释放资源');
    disconnect();
  }
}
